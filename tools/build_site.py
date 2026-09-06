#!/usr/bin/env python3
"""Build a bounded static projection of tracked wiki documents."""

from __future__ import annotations

import argparse
import hashlib
import json
import posixpath
import re
import stat
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit


REPOSITORY = "https://github.com/technologylab-ai/zigllmwiki"
MAX_FILES = 8192
MAX_DOCUMENT_BYTES = 2 * 1024 * 1024
MAX_ASSET_BYTES = 8 * 1024 * 1024
MAX_TOTAL_BYTES = 64 * 1024 * 1024
MAX_LINKS_PER_DOCUMENT = 4096
MAX_EDGES = 65536
SITE_FILES = {"index.html", "app.js", "styles.css", "graph.js"}
BLOCKED_PARTS = {"node_modules", "__pycache__", "worktrees", "cache", "secrets"}
KEY = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*):(?:\s+(.*))?$")


class BuildError(ValueError):
    """The input cannot produce an attributable publication."""


def git(root, *arguments):
    result = subprocess.run(
        ["git", "--no-optional-locks", "-C", str(root), *arguments],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode:
        raise BuildError(result.stderr.decode("utf-8", errors="replace").strip())
    return result.stdout


def safe_path(value):
    parts = PurePosixPath(value).parts
    return bool(parts) and not value.startswith("/") and "\\" not in value and all(
        part not in ("", ".", "..") and not part.startswith(".")
        and part not in BLOCKED_PARTS and not any(ord(char) < 32 for char in part)
        for part in parts
    )


def document_path(value):
    if not safe_path(value):
        return False
    path = PurePosixPath(value)
    parts = path.parts
    if len(parts) == 1:
        return path.suffix == ".md"
    if parts[0] in ("wiki", "sources"):
        return len(parts) == 2 and path.suffix == ".md"
    if parts[0] == "proofs":
        return len(parts) == 2 and path.suffix in (".zig", ".c")
    return parts[0] in ("docs", "reports") and path.suffix == ".md"


def asset_path(value):
    if not safe_path(value):
        return False
    parts = PurePosixPath(value).parts
    return len(parts) >= 2 and parts[0] == "site" and (
        len(parts) == 2 and parts[1] in SITE_FILES or parts[1] == "vendor"
    )


def tracked_files(root):
    result = {}
    for item in git(root, "ls-files", "--stage", "-z").split(b"\0"):
        if not item:
            continue
        identity, path = item.split(b"\t", 1)
        mode, _, stage = identity.decode("ascii").split()
        if stage != "0":
            raise BuildError("Unmerged index entries prevent publication")
        result[path.decode("utf-8")] = mode
        if len(result) > MAX_FILES:
            raise BuildError("Tracked file count exceeds the site limit")
    return result


def read_regular(root, relative, limit):
    path = root / relative
    current = root
    for part in PurePosixPath(relative).parts:
        current = current / part
        if current.is_symlink():
            raise BuildError("Symlink input is forbidden: " + relative)
    try:
        if not stat.S_ISREG(path.stat().st_mode):
            raise BuildError("Input is not a regular file: " + relative)
        with path.open("rb") as handle:
            data = handle.read(limit + 1)
    except OSError as error:
        raise BuildError("Cannot read " + relative + ": " + str(error)) from error
    if len(data) > limit:
        raise BuildError("Input exceeds its byte limit: " + relative)
    return data


def scalar(value):
    value = value.strip()
    if value.startswith('"'):
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError as error:
            raise BuildError("Invalid quoted frontmatter value") from error
        if not isinstance(parsed, str):
            raise BuildError("Frontmatter scalar must contain text")
        return parsed
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    return value


def frontmatter(text):
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return {}, text
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise BuildError("Frontmatter has no closing delimiter")
    metadata = {}
    key = None
    for original in lines[1:end]:
        line = original.rstrip("\r\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = KEY.fullmatch(line)
        if match:
            key, value = match.group(1), (match.group(2) or "").strip()
            if key in metadata:
                raise BuildError("Duplicate frontmatter key: " + key)
            if value in ("", "[]"):
                metadata[key] = []
            elif value.startswith("["):
                try:
                    metadata[key] = json.loads(value)
                except json.JSONDecodeError as error:
                    raise BuildError("Inline frontmatter lists must use JSON syntax") from error
                if not isinstance(metadata[key], list) or not all(isinstance(v, str) for v in metadata[key]):
                    raise BuildError("Frontmatter lists must contain text")
            elif value in ("|", ">", "|-", ">-"):
                raise BuildError("Unsupported multiline frontmatter; preserve it explicitly before publishing")
            else:
                metadata[key] = scalar(value)
        elif line.startswith("  - ") and key and isinstance(metadata[key], list):
            metadata[key].append(scalar(line[4:]))
        else:
            raise BuildError("Unsupported frontmatter line: " + line)
    return metadata, "".join(lines[end + 1:])


def aliases_for(documents):
    candidates = defaultdict(set)
    identifiers = {}
    paths = {document["path"] for document in documents}
    for document in documents:
        path = document["path"]
        identifier = document["id"]
        if identifier in identifiers or identifier in paths and identifier != path:
            raise BuildError("Duplicate document identifier: " + identifier)
        identifiers[identifier] = path
        name = PurePosixPath(path)
        for alias in (path, str(name.with_suffix("")), name.name, name.stem, identifier):
            candidates[alias].add(path)
    aliases = {path: path for path in paths}
    aliases.update(identifiers)
    for key, values in candidates.items():
        if len(values) == 1:
            aliases.setdefault(key, next(iter(values)))
    return dict(sorted(aliases.items()))


def local_target(value, source):
    value = value.strip()
    if value.startswith("[[") and value.endswith("]]"):
        value = value[2:-2].split("|", 1)[0]
    if value.startswith("<") and value.endswith(">"):
        value = value[1:-1]
    value = unquote(re.sub(r"\\([()\[\] #])", r"\1", value))
    try:
        parsed = urlsplit(value)
    except ValueError:
        return None
    if parsed.scheme or parsed.netloc or value.startswith("/") or "\\" in value:
        return None
    if not parsed.path:
        return source
    result = posixpath.normpath(posixpath.join(posixpath.dirname(source), parsed.path))
    return result if safe_path(result) else None


def resolve(value, source, aliases, global_first=False):
    bare = value.strip()
    wiki = bare.startswith("[[") and bare.endswith("]]")
    if wiki:
        bare = bare[2:-2].split("|", 1)[0]
    bare = unquote(bare.split("#", 1)[0].split("?", 1)[0])
    if (wiki or global_first) and safe_path(bare) and bare in aliases:
        return aliases[bare]
    target = local_target(value, source)
    return aliases.get(target) if target else None


def markdown_targets(body):
    visible = []
    fence = None
    for line in body.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if marker:
            text = marker.group(1)
            if fence is None:
                fence = text
            elif text[0] == fence[0] and len(text) >= len(fence):
                fence = None
            continue
        if fence is None:
            visible.append(line)
    text = re.sub(r"<!--.*?-->", "", "\n".join(visible), flags=re.S)
    text = re.sub(r"(`+).*?\1", "", text, flags=re.S)
    targets = ["[[" + value + "]]" for value in re.findall(r"\[\[([^]\n]+)\]\]", text)]
    if len(targets) > MAX_LINKS_PER_DOCUMENT:
        raise BuildError("A document exceeds its link limit")
    for ordinal, match in enumerate(re.finditer(r"!?\[(?!\[)[^]\n]*\]\(", text)):
        if ordinal >= MAX_LINKS_PER_DOCUMENT:
            raise BuildError("A document exceeds its link limit")
        start = match.end()
        depth, escaped, end = 1, False, start
        for end in range(start, min(len(text), start + 4096)):
            char = text[end]
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    break
        if depth != 0:
            continue
        content = text[start:end].strip()
        if content.startswith("<") and ">" in content:
            targets.append(content[1:content.index(">")])
        elif content:
            targets.append(re.split(r"\s+[\"']", content, maxsplit=1)[0])
    definitions = dict(re.findall(r"^ {0,3}\[([^]\n]+)\]:\s*<?([^\s>]+)>?", text, flags=re.M))
    for label, reference in re.findall(r"\[([^]\n]+)\]\[([^]\n]*)\]", text):
        if reference or label:
            target = definitions.get(reference or label)
            if target:
                targets.append(target)
    if len(targets) > MAX_LINKS_PER_DOCUMENT:
        raise BuildError("A document exceeds its link limit")
    return targets


def safe_svg(data, path):
    if b"<!DOCTYPE" in data.upper() or b"<!ENTITY" in data.upper():
        raise BuildError("SVG declarations are forbidden: " + path)
    try:
        root = ET.fromstring(data)
    except ET.ParseError as error:
        raise BuildError("Invalid SVG: " + path) from error
    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1].lower() in ("script", "foreignobject", "iframe", "object", "embed"):
            raise BuildError("Active SVG content is forbidden: " + path)
        for key, value in element.attrib.items():
            name = key.rsplit("}", 1)[-1].lower()
            if name.startswith("on") or name == "href" and not value.startswith("#"):
                raise BuildError("External or active SVG reference: " + path)
        content = " ".join(element.attrib.values()) + (element.text or "")
        references = re.findall(r"url\(\s*([^)]*)\)", content, re.I)
        if any(not value.strip(" \t\r\n'\"").startswith("#") for value in references) or "@import" in content.lower():
            raise BuildError("External SVG style reference: " + path)


def vendor_files(data):
    try:
        packages = json.loads(data)
    except (json.JSONDecodeError, UnicodeError) as error:
        raise BuildError("Invalid vendor manifest") from error
    if not isinstance(packages, list) or not packages:
        raise BuildError("The vendor manifest must list packages")
    result = {}
    for package in packages:
        if not isinstance(package, dict) or not isinstance(package.get("files_sha256"), dict):
            raise BuildError("Each vendor package must pin file hashes")
        for path, digest in package["files_sha256"].items():
            if not safe_path(path) or path == "manifest.json" or path in result:
                raise BuildError("Invalid or duplicate vendor path: " + path)
            if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                raise BuildError("Invalid vendor SHA-256: " + path)
            result[path] = digest
    if not result:
        raise BuildError("The vendor manifest contains no files")
    return result


def collect(root, allow_dirty=False):
    revision = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii").strip()
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise BuildError("HEAD must identify a full Git commit")
    status = git(root, "status", "--porcelain", "--untracked-files=no")
    tracked = tracked_files(root)
    documents = []
    blobs = {}
    inputs = 0

    def read(path, limit):
        nonlocal inputs
        if path in tracked and tracked[path] not in ("100644", "100755"):
            raise BuildError("Tracked input is not a regular file: " + path)
        result = read_regular(root, path, limit)
        inputs += len(result)
        if inputs > MAX_TOTAL_BYTES:
            raise BuildError("Total input bytes exceed the site limit")
        return result

    if ".zig-version" not in tracked:
        raise BuildError("The compiler version must be tracked")
    zig = read(".zig-version", 128).decode("utf-8").strip()
    if "build.zig" not in tracked:
        raise BuildError("Proof registration requires tracked build.zig")
    build_source = read("build.zig", MAX_DOCUMENT_BYTES).decode("utf-8")
    registered = set(re.findall(r'"(proofs/[^"\n]+\.(?:zig|c))"', build_source))
    for path in sorted(path for path in tracked if document_path(path)):
        raw = read(path, MAX_DOCUMENT_BYTES)
        text = raw.decode("utf-8")
        layer = {"wiki": "wiki", "sources": "source", "proofs": "proof"}.get(path.split("/", 1)[0], "project")
        if layer == "proof" and path not in registered:
            raise BuildError("Proof has no registered path in build.zig: " + path)
        metadata, body = frontmatter(text) if path.endswith(".md") else ({}, text)
        for field in ("id", "title", "kind", "status", "summary", "updated"):
            if field in metadata and not isinstance(metadata[field], str):
                raise BuildError(path + ": metadata field must contain text: " + field)
        title = metadata.get("title")
        if not title:
            heading = re.search(r"^#\s+(.+)$", body, flags=re.M) if path.endswith(".md") else None
            title = heading.group(1).strip() if heading else PurePosixPath(path).name
        documents.append({
            "path": path, "id": metadata.get("id") or path, "title": title,
            "layer": layer, "kind": metadata.get("kind", ""), "status": metadata.get("status", ""),
            "summary": metadata.get("summary", ""), "updated": metadata.get("updated", ""),
            "platforms": metadata.get("platforms", []), "sources": [], "proofs": [],
            "body": body, "links": [], "metadata": metadata, "sha256": hashlib.sha256(raw).hexdigest(),
        })
    aliases = aliases_for(documents)
    edges = set()
    images = set()
    for document in documents:
        path = document["path"]
        for field, edge_type in (("sources", "source"), ("proofs", "proof")):
            references = document["metadata"].get(field, [])
            if not isinstance(references, list):
                raise BuildError(path + ": " + field + " must be a list")
            for reference in references:
                target = resolve(reference, path, aliases, global_first=True)
                if target is None:
                    raise BuildError(path + ": unresolved " + field + " reference: " + reference)
                document[field].append(target)
                edges.add((path, target, edge_type))
            document[field] = sorted(set(document[field]))
        if not isinstance(document["platforms"], list):
            raise BuildError(path + ": platforms must be a list")
        for reference in markdown_targets(document["body"]) if path.endswith(".md") else []:
            target = resolve(reference, path, aliases)
            if target and target != path:
                document["links"].append(target)
                edges.add((path, target, "link"))
            image = local_target(reference, path)
            if image in tracked and PurePosixPath(image).suffix.lower() in (".svg", ".png"):
                images.add(image)
        document["links"] = sorted(set(document["links"]))
        if len(edges) > MAX_EDGES:
            raise BuildError("The graph exceeds its edge limit")
    for path in sorted(images):
        data = read(path, MAX_ASSET_BYTES)
        if path.lower().endswith(".svg"):
            safe_svg(data, path)
        elif not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise BuildError("Image does not contain a PNG signature: " + path)
        blobs["files/" + path] = data
    assets = {path for path in tracked if asset_path(path)}
    if allow_dirty and (root / "site").exists():
        for path in (root / "site").rglob("*"):
            relative = path.relative_to(root).as_posix()
            if asset_path(relative) and (path.is_file() or path.is_symlink()):
                assets.add(relative)
            if len(assets) > MAX_FILES:
                raise BuildError("Site asset count exceeds the limit")
    missing = {"site/" + name for name in SITE_FILES | {"vendor/manifest.json"}} - assets
    if missing:
        raise BuildError("Missing tracked site assets: " + ", ".join(sorted(missing)))
    manifest = read("site/vendor/manifest.json", MAX_ASSET_BYTES)
    hashes = vendor_files(manifest)
    expected = {"site/" + name for name in SITE_FILES | {"vendor/manifest.json"}}
    expected.update("site/vendor/" + name for name in hashes)
    if assets != expected:
        raise BuildError("Vendor manifest and asset set differ: " + ", ".join(sorted(assets ^ expected)))
    for path in sorted(assets):
        data = manifest if path == "site/vendor/manifest.json" else read(path, MAX_ASSET_BYTES)
        if path.startswith("site/vendor/") and path != "site/vendor/manifest.json":
            if hashlib.sha256(data).hexdigest() != hashes[path.removeprefix("site/vendor/")]:
                raise BuildError("Vendor checksum mismatch: " + path)
        blobs[path.removeprefix("site/")] = data
    dirty = bool(status or assets - tracked.keys())
    if dirty and not allow_dirty:
        raise BuildError("Tracked changes require --allow-dirty for a development preview")
    if git(root, "rev-parse", "HEAD").decode("ascii").strip() != revision:
        raise BuildError("HEAD changed during the site build")
    if git(root, "status", "--porcelain", "--untracked-files=no") != status:
        raise BuildError("Tracked state changed during the site build")
    payload = {
        "version": 1, "zig": zig, "revision": revision, "repository": REPOSITORY,
        "dirty": dirty, "documents": documents, "aliases": aliases, "assets": sorted(images),
        "edges": [{"source": source, "target": target, "type": kind} for source, target, kind in sorted(edges)],
    }
    blobs["data.json"] = (json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")
    blobs[".nojekyll"] = b""
    if len(blobs) > MAX_FILES or sum(map(len, blobs.values())) > MAX_TOTAL_BYTES:
        raise BuildError("The generated artifact exceeds its file or byte limit")
    return payload, blobs


def write_artifact(root, output, blobs, check=False):
    if output.is_symlink():
        raise BuildError("The output directory must not be a symlink")
    output = output.resolve()
    if output == root or output in root.parents:
        raise BuildError("The output directory overlaps the repository root")
    if root in output.parents and output.relative_to(root).parts[0] != ".zig-cache":
        raise BuildError("In-repository output must stay under .zig-cache")
    if root not in output.parents and output.exists() and any(output.iterdir()) and not check:
        raise BuildError("An external output directory must be new or empty")
    if output.exists():
        for path in output.rglob("*"):
            if path.is_symlink() or path.is_file() and path.relative_to(output).as_posix() not in blobs:
                raise BuildError("Output contains an unexpected file: " + str(path))
    for relative, data in blobs.items():
        path = output / relative
        if check:
            if not path.is_file() or path.read_bytes() != data:
                raise BuildError("Generated output differs: " + relative)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--allow-dirty", action="store_true", help="Label a development projection with uncommitted inputs")
    parser.add_argument("--check", action="store_true", help="Compare existing output without writing files")
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output or root / ".zig-cache" / "site"
    try:
        payload, blobs = collect(root, args.allow_dirty)
        write_artifact(root, output, blobs, args.check)
    except (BuildError, OSError, UnicodeError) as error:
        parser.exit(1, "site build failed: " + str(error) + "\n")
    print(json.dumps({"documents": len(payload["documents"]), "edges": len(payload["edges"]),
                      "files": len(blobs), "revision": payload["revision"], "dirty": payload["dirty"]}, sort_keys=True))


if __name__ == "__main__":
    main()
