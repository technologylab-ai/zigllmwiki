#!/usr/bin/env python3
"""Deterministic checks for the Markdown knowledge base."""

from __future__ import annotations

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WIKI_FILES = [ROOT / "index.md", *sorted((ROOT / "wiki").glob("**/*.md"))]
SOURCE_FILES = sorted((ROOT / "sources").glob("**/*.md"))
CONTENT_FILES = WIKI_FILES + SOURCE_FILES
ALL_MARKDOWN = [
    path
    for path in ROOT.glob("**/*.md")
    if ".git" not in path.parts and ".zig-cache" not in path.parts
]
WIKILINK = re.compile(r"!?\[\[([^\]]+)\]\]")
KEY = re.compile(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$")
PROOF = re.compile(r"^\s+-\s+(proofs/[^\s]+\.zig)\s*$")
REGISTERED_PROOF = re.compile(r'"(proofs/[^"\s]+\.zig)"')


def frontmatter(path: Path) -> tuple[dict[str, str], list[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("missing opening YAML frontmatter delimiter")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise ValueError("missing closing YAML frontmatter delimiter") from error

    values: dict[str, str] = {}
    for line in lines[1:end]:
        match = KEY.match(line)
        if match:
            values[match.group(1)] = (match.group(2) or "").strip().strip('"')
    return values, lines


def link_names() -> tuple[dict[str, list[Path]], set[str]]:
    stems: dict[str, list[Path]] = defaultdict(list)
    paths: set[str] = set()
    for path in ALL_MARKDOWN:
        relative = path.relative_to(ROOT)
        stems[path.stem].append(relative)
        paths.add(relative.with_suffix("").as_posix())
    return stems, paths


def links_outside_fences(text: str) -> list[str]:
    """Return Obsidian links while ignoring illustrative fenced blocks."""
    targets: list[str] = []
    in_fence = False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            targets.extend(WIKILINK.findall(line))
    return targets


def main() -> int:
    failures: list[str] = []
    baseline = (ROOT / ".zig-version").read_text(encoding="utf-8").strip()
    actual = subprocess.run(
        ["zig", "version"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if actual != baseline:
        failures.append(f"zig version is {actual}, expected exact baseline {baseline}")

    proof_files = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "proofs").glob("**/*.zig")
    }
    build_text = (ROOT / "build.zig").read_text(encoding="utf-8")
    registered_proofs = set(REGISTERED_PROOF.findall(build_text))
    for proof in sorted(proof_files - registered_proofs):
        failures.append(f"{proof}: not registered in build.zig")
    for proof in sorted(registered_proofs - proof_files):
        failures.append(f"build.zig: registered proof does not exist: {proof}")

    ids: dict[str, Path] = {}
    allowed_status = {
        "stub",
        "draft",
        "source-verified",
        "runtime-verified",
        "superseded",
        "captured",
    }

    for path in CONTENT_FILES:
        relative = path.relative_to(ROOT)
        try:
            meta, lines = frontmatter(path)
        except ValueError as error:
            failures.append(f"{relative}: {error}")
            continue

        for required in ("id", "title", "kind", "status", "summary"):
            if not meta.get(required):
                failures.append(f"{relative}: missing frontmatter key {required}")

        page_id = meta.get("id")
        if page_id:
            if page_id in ids:
                failures.append(
                    f"{relative}: duplicate id {page_id} also used by {ids[page_id]}"
                )
            ids[page_id] = relative

        status = meta.get("status")
        if status and status not in allowed_status:
            failures.append(f"{relative}: unsupported status {status}")

        if path in WIKI_FILES:
            for required in ("zig", "updated", "sources", "proofs", "platforms"):
                if required not in meta:
                    failures.append(f"{relative}: missing frontmatter key {required}")
            if status in {"source-verified", "runtime-verified"}:
                zig_version = meta.get("zig")
                if zig_version not in {baseline, "n/a"}:
                    failures.append(
                        f"{relative}: verified page targets {zig_version!r}, baseline is {baseline}"
                    )
            if any(line.strip().startswith("```zig") for line in lines):
                failures.append(
                    f"{relative}: fenced Zig is forbidden; link an executable proof instead"
                )

        if path in SOURCE_FILES:
            for required in ("captured", "revision"):
                if not meta.get(required):
                    failures.append(f"{relative}: missing source key {required}")

        for line in lines:
            match = PROOF.match(line)
            if match and not (ROOT / match.group(1)).is_file():
                failures.append(f"{relative}: missing {match.group(1)}")

    stems, paths = link_names()
    for path in ALL_MARKDOWN:
        text = path.read_text(encoding="utf-8")
        for raw_target in links_outside_fences(text):
            target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
            if not target:
                continue
            if "/" in target:
                normalized = target.removesuffix(".md").lstrip("/")
                if normalized not in paths:
                    failures.append(
                        f"{path.relative_to(ROOT)}: broken wikilink [[{raw_target}]]"
                    )
                continue
            target_name = target[:-3] if target.endswith(".md") else target
            matches = stems.get(target_name, [])
            if not matches:
                failures.append(
                    f"{path.relative_to(ROOT)}: broken wikilink [[{raw_target}]]"
                )
            elif len(matches) > 1:
                rendered = ", ".join(str(match) for match in matches)
                failures.append(
                    f"{path.relative_to(ROOT)}: ambiguous wikilink [[{raw_target}]] -> {rendered}"
                )

    if failures:
        print("wiki verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print(
        f"wiki verification passed: {len(WIKI_FILES)} pages, "
        f"{len(SOURCE_FILES)} sources, Zig {actual}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
