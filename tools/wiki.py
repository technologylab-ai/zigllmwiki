#!/usr/bin/env python3
"""Deterministic, conservative command layer for the Zig LLM Wiki."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


DEFAULT_ROOT = Path(__file__).resolve().parents[1]
FRONTMATTER_KEY = re.compile(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$")
TERM = re.compile(r"[A-Za-z0-9_][A-Za-z0-9_.-]*")
WIKILINK = re.compile(r"!?\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]")
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT_HASH = re.compile(r"(?<![0-9a-f])[0-9a-f]{40}(?![0-9a-f])", re.IGNORECASE)
STABLE_SEMVER = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
MOVING_REVISION = re.compile(
    r"^(?:head|latest|main|master|trunk|tip|stable|nightly|dev|develop|development)$",
    re.IGNORECASE,
)
FULL_HEX_IDENTIFIER = re.compile(r"(?<![0-9A-Fa-f])[0-9A-Fa-f]{40,64}(?![0-9A-Fa-f])")
ZIG_DOWNLOAD_INDEX = "https://ziglang.org/download/index.json"
REMOTE_REPOSITORIES = {
    "matklad.github.io": "matklad/matklad.github.io",
    "www.matklad.github.io": "matklad/matklad.github.io",
    "ziglang.org": "ziglang/zig",
    "www.ziglang.org": "ziglang/zig",
}


class CommandError(Exception):
    """A validation error that is safe to expose to command callers."""


class FetchError(Exception):
    """A remote endpoint failed without exposing response bodies or credentials."""


@dataclass(frozen=True)
class Document:
    path: Path
    scalar: dict[str, str]
    lists: dict[str, list[str]]
    body: str


FetchJson = Callable[[str], object]


def repository_root(path: str | Path) -> Path:
    root = Path(path).resolve()
    required = (".zig-version", "index.md", "AGENTS.md")
    missing = [name for name in required if not (root / name).is_file()]
    if missing:
        rendered = ", ".join(missing)
        raise CommandError(f"not a Zig wiki root; missing: {rendered}")
    return root


def parse_document(path: Path) -> Document:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        raise CommandError(f"{path}: missing opening YAML frontmatter delimiter")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise CommandError(
            f"{path}: missing closing YAML frontmatter delimiter"
        ) from error

    scalar: dict[str, str] = {}
    lists: dict[str, list[str]] = {}
    current_key: str | None = None
    for line in lines[1:end]:
        key_match = FRONTMATTER_KEY.match(line)
        if key_match:
            current_key = key_match.group(1)
            raw_value = (key_match.group(2) or "").strip()
            if raw_value == "[]":
                scalar[current_key] = ""
                lists[current_key] = []
            else:
                scalar[current_key] = raw_value.strip('"')
            continue
        if current_key is not None and line.startswith("  - "):
            value = line[4:].strip().strip('"')
            lists.setdefault(current_key, []).append(value)

    return Document(
        path=path,
        scalar=scalar,
        lists=lists,
        body="\n".join(lines[end + 1 :]),
    )


def normalized_terms(text: str) -> list[str]:
    return sorted({term.casefold() for term in TERM.findall(text)})


def source_names(document: Document) -> list[str]:
    names: list[str] = []
    for item in document.lists.get("sources", []):
        match = WIKILINK.fullmatch(item)
        names.append(match.group(1) if match else item)
    return names


def indexed_stems(root: Path) -> set[str]:
    text = (root / "index.md").read_text(encoding="utf-8")
    return {match.group(1) for match in WIKILINK.finditer(text)}


def query_report(root: Path, query: str, limit: int = 8) -> dict[str, object]:
    terms = normalized_terms(query)
    if not terms:
        raise CommandError("query must contain at least one searchable term")
    if limit < 1 or limit > 100:
        raise CommandError("query limit must be between 1 and 100")

    indexed = indexed_stems(root)
    phrase = query.strip().casefold()
    matches: list[dict[str, object]] = []
    for path in sorted((root / "wiki").glob("**/*.md")):
        document = parse_document(path)
        relative = path.relative_to(root).as_posix()
        title = document.scalar.get("title", "")
        summary = document.scalar.get("summary", "")
        page_id = document.scalar.get("id", "")
        title_text = title.casefold()
        summary_text = summary.casefold()
        identity_text = f"{page_id} {relative}".casefold()
        body_text = document.body.casefold()

        score = 0
        matched_terms: list[str] = []
        for term in terms:
            term_score = 0
            if term in title_text:
                term_score += 12
            if term in summary_text:
                term_score += 8
            if term in identity_text:
                term_score += 6
            term_score += min(body_text.count(term), 5)
            if term_score:
                matched_terms.append(term)
                score += term_score
        if not matched_terms:
            continue
        if phrase and phrase in f"{title_text} {summary_text}":
            score += 20
        elif phrase and phrase in body_text:
            score += 5
        if path.stem in indexed:
            score += 2

        matches.append(
            {
                "path": relative,
                "id": page_id,
                "title": title,
                "summary": summary,
                "status": document.scalar.get("status", ""),
                "zig": document.scalar.get("zig", ""),
                "platforms": document.lists.get("platforms", []),
                "sources": source_names(document),
                "proofs": document.lists.get("proofs", []),
                "matched_terms": matched_terms,
                "score": score,
            }
        )

    matches.sort(key=lambda match: (-int(match["score"]), str(match["path"])))
    return {
        "schema_version": 1,
        "command": "query",
        "ok": True,
        "mutates_repository": False,
        "zig_baseline": (root / ".zig-version").read_text(encoding="utf-8").strip(),
        "query": query,
        "terms": terms,
        "match_count": len(matches),
        "matches": matches[:limit],
    }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.casefold()).strip("-")
    if not slug:
        raise CommandError("unable to derive a source-record id; pass --id")
    return slug


def source_record_matches(root: Path, needle: str) -> list[str]:
    matches = []
    for path in sorted((root / "sources").glob("**/*.md")):
        if needle in path.read_text(encoding="utf-8"):
            matches.append(path.relative_to(root).as_posix())
    return matches


def revision_assessment(revision: str) -> dict[str, object]:
    """Describe syntax strength without claiming a remote ref was verified."""
    full_identifier = FULL_HEX_IDENTIFIER.search(revision)
    return {
        "status": (
            "content-address-like-syntax" if full_identifier else "review-required"
        ),
        "full_hex_identifier": full_identifier.group(0) if full_identifier else None,
        "remote_identity_checked": False,
        "immutability_verified": False,
        "note": (
            "A full hexadecimal identifier is present, but the command does not "
            "contact the origin to prove what it names or whether the URL resolves to it."
            if full_identifier
            else "The revision is not content-address-like; confirm that it is an exact, "
            "immutable tag/version/revision before creating the source record."
        ),
    }


def ingest_report(
    root: Path,
    source: str,
    revision: str,
    title: str | None = None,
    record_id: str | None = None,
    expected_sha256: str | None = None,
    related_query: str | None = None,
) -> dict[str, object]:
    revision = revision.strip()
    if not revision:
        raise CommandError("ingest requires a non-empty pinned --revision")
    if MOVING_REVISION.fullmatch(revision):
        raise CommandError(
            f"revision {revision!r} is a moving name; resolve an immutable revision"
        )
    if expected_sha256 is not None:
        expected_sha256 = expected_sha256.casefold()
        if not SHA256.fullmatch(expected_sha256):
            raise CommandError("--sha256 must be exactly 64 hexadecimal characters")

    parsed = urlparse(source)
    source_kind: str
    source_identity: str
    actual_sha256: str | None = None
    if parsed.scheme:
        if parsed.scheme != "https" or not parsed.netloc:
            raise CommandError("remote sources must use an absolute https URL")
        source_kind = "remote"
        source_identity = source
    else:
        source_path = Path(source).expanduser()
        if not source_path.is_absolute():
            source_path = root / source_path
        source_path = source_path.resolve()
        if not source_path.is_file():
            raise CommandError(f"local source does not exist or is not a file: {source_path}")
        source_kind = "local"
        source_identity = str(source_path)
        actual_sha256 = sha256_file(source_path)
        if expected_sha256 is not None and expected_sha256 != actual_sha256:
            raise CommandError(
                f"local source sha256 is {actual_sha256}, expected {expected_sha256}"
            )

    inferred_name = title or Path(parsed.path or source_identity).stem
    slug = slugify(record_id or inferred_name)
    if slug.startswith("source-"):
        page_id = slug
        filename_slug = slug.removeprefix("source-")
    else:
        page_id = f"source-{slug}"
        filename_slug = slug
    proposed_path = root / "sources" / f"{filename_slug}.md"
    evidence_key = "url" if source_kind == "remote" else "path"
    existing = source_record_matches(root, source_identity)
    proposed_relative = proposed_path.relative_to(root).as_posix()
    if proposed_path.exists() and proposed_relative not in existing:
        raise CommandError(
            f"proposed source record path is occupied by different evidence: "
            f"{proposed_path.relative_to(root)}"
        )
    query_text = related_query or inferred_name
    related = query_report(root, query_text, limit=12)["matches"]
    assert isinstance(related, list)
    assessment = revision_assessment(revision)

    proposed_frontmatter: dict[str, object] = {
        "id": page_id,
        "title": title or inferred_name,
        "kind": "source",
        "status": "captured",
        "summary": "REQUIRED: one retrieval-oriented evidence summary",
        "captured": "REQUIRED: YYYY-MM-DD",
        "revision": revision,
        evidence_key: source_identity,
    }
    if source_kind == "local":
        proposed_frontmatter["sha256"] = actual_sha256
        proposed_frontmatter["snapshot"] = (
            f"sources/snapshots/{filename_slug}{Path(source_identity).suffix}.txt"
        )
    elif expected_sha256 is not None:
        proposed_frontmatter["sha256"] = expected_sha256

    return {
        "schema_version": 1,
        "command": "ingest",
        "ok": True,
        "mode": "plan-only",
        "mutates_repository": False,
        "zig_baseline": (root / ".zig-version").read_text(encoding="utf-8").strip(),
        "source": {
            "kind": source_kind,
            "identity": source_identity,
            "revision": revision,
            "revision_assessment": assessment,
            "sha256": actual_sha256 or expected_sha256,
        },
        "existing_records_with_same_identity": existing,
        "proposed_record": {
            "action": (
                "reuse-existing"
                if existing
                else "create-after-review"
                if assessment["status"] == "content-address-like-syntax"
                else "confirm-revision-then-create"
            ),
            "path": existing[0] if existing else proposed_relative,
            "frontmatter": proposed_frontmatter,
        },
        "related_pages": related,
        "required_workflow": [
            "Confirm the revision at its origin is immutable; syntax assessment is not verification.",
            "Create the source record before citing or synthesizing it.",
            "Review related pages and update an existing page before creating overlap.",
            "Port runnable Zig claims into proofs/ and register every proof in build.zig.",
            "Update index.md, append log.md, and update ROADMAP.md when scope changes.",
            "Run zig build verify with the exact .zig-version compiler.",
        ],
    }


def fetch_json_url(url: str, timeout: float = 15.0) -> object:
    """Fetch one primary JSON endpoint with bounded time and stable errors."""
    parsed = urlparse(url)
    headers = {
        "Accept": "application/json",
        "User-Agent": "zigllmwiki-read-only-review/1",
    }
    if parsed.netloc.casefold() == "api.github.com":
        headers["Accept"] = "application/vnd.github+json"
        headers["X-GitHub-Api-Version"] = "2022-11-28"
        if token := os.environ.get("GITHUB_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
    request = Request(url, headers=headers)
    try:
        with urlopen(request, timeout=timeout) as response:
            payload = response.read()
    except HTTPError as error:
        raise FetchError(
            f"HTTP {error.code} {error.reason} from {parsed.netloc}"
        ) from error
    except URLError as error:
        reason = getattr(error, "reason", "unknown network failure")
        raise FetchError(f"network failure from {parsed.netloc}: {reason}") from error
    except TimeoutError as error:
        raise FetchError(f"timeout from {parsed.netloc}") from error

    try:
        return json.loads(payload)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise FetchError(f"invalid JSON from {parsed.netloc}: {error}") from error


def pinned_commit(revision: str, url: str) -> str | None:
    """Find an immutable commit in frontmatter, falling back to its URL."""
    for value in (revision, url):
        if match := COMMIT_HASH.search(value):
            return match.group(0).casefold()
    return None


def remote_upstream(url: str) -> tuple[str, str, str] | None:
    """Map a captured URL to one primary revision endpoint."""
    parsed = urlparse(url)
    host = parsed.netloc.casefold()
    parts = [part for part in parsed.path.split("/") if part]
    if host == "github.com" and len(parts) >= 2:
        repository = f"{parts[0]}/{parts[1].removesuffix('.git')}"
        endpoint = f"https://api.github.com/repos/{repository}/commits?per_page=1"
        return "github-repository", repository, endpoint
    if host == "gist.github.com" and len(parts) >= 2:
        gist_id = parts[1]
        endpoint = f"https://api.github.com/gists/{gist_id}/commits?per_page=1"
        return "github-gist", gist_id, endpoint
    if repository := REMOTE_REPOSITORIES.get(host):
        endpoint = f"https://api.github.com/repos/{repository}/commits?per_page=1"
        return "github-repository", repository, endpoint
    return None


def latest_remote_revision(kind: str, payload: object) -> str:
    if kind == "github-repository":
        if not isinstance(payload, list) or not payload:
            raise CommandError("GitHub commits endpoint returned no commits")
        first = payload[0]
        if not isinstance(first, dict) or not isinstance(first.get("sha"), str):
            raise CommandError("GitHub commits endpoint omitted the latest sha")
        revision = first["sha"].casefold()
    elif kind == "github-gist":
        if not isinstance(payload, list) or not payload:
            raise CommandError("GitHub gist commits endpoint returned no commits")
        first = payload[0]
        if not isinstance(first, dict):
            raise CommandError("GitHub gist commits endpoint returned a malformed commit")
        version = first.get("version")
        if not isinstance(version, str):
            raise CommandError("GitHub gist commits endpoint omitted the latest version")
        revision = version.casefold()
    else:
        raise AssertionError(f"unsupported upstream kind {kind}")
    if not COMMIT_HASH.fullmatch(revision):
        raise CommandError(f"remote endpoint returned a non-commit revision {revision!r}")
    return revision


def stable_versions(payload: object) -> list[str]:
    if not isinstance(payload, dict):
        raise CommandError("Zig download index root is not an object")
    versions = []
    for value in payload:
        if STABLE_SEMVER.fullmatch(value):
            versions.append(value)
    return sorted(versions, key=lambda value: tuple(int(part) for part in value.split(".")))


def review_report(
    root: Path,
    fetch_json: FetchJson | None = None,
    timeout: float = 15.0,
) -> dict[str, object]:
    """Report upstream movement and Zig releases without mutating the vault."""
    if timeout <= 0 or timeout > 120:
        raise CommandError("review timeout must be greater than zero and at most 120 seconds")
    fetch = fetch_json or (lambda url: fetch_json_url(url, timeout=timeout))
    baseline = (root / ".zig-version").read_text(encoding="utf-8").strip()
    baseline_match = STABLE_SEMVER.fullmatch(baseline)
    if baseline_match is None:
        raise CommandError(f".zig-version is not a stable semantic version: {baseline!r}")
    baseline_key = tuple(int(part) for part in baseline.split("."))

    upstream_groups: dict[tuple[str, str], dict[str, object]] = {}
    skipped_local: list[str] = []
    unmapped_remote: list[dict[str, str]] = []
    for path in sorted((root / "sources").glob("**/*.md")):
        document = parse_document(path)
        relative = path.relative_to(root).as_posix()
        url = document.scalar.get("url")
        if not url:
            skipped_local.append(relative)
            continue
        upstream = remote_upstream(url)
        if upstream is None:
            unmapped_remote.append({"path": relative, "url": url})
            continue
        kind, identity, endpoint = upstream
        key = (kind, identity.casefold())
        group = upstream_groups.setdefault(
            key,
            {
                "kind": kind,
                "identity": identity,
                "endpoint": endpoint,
                "records": [],
            },
        )
        records = group["records"]
        assert isinstance(records, list)
        revision = document.scalar.get("revision", "")
        records.append(
            {
                "path": relative,
                "declared_revision": revision,
                "pinned_commit": pinned_commit(revision, url),
            }
        )

    issues: list[dict[str, str]] = []
    upstreams: list[dict[str, object]] = []
    source_candidates: list[dict[str, str]] = []
    for key in sorted(upstream_groups):
        group = upstream_groups[key]
        endpoint = str(group["endpoint"])
        records = group["records"]
        assert isinstance(records, list)
        records.sort(key=lambda record: str(record["path"]))
        output: dict[str, object] = {
            "kind": group["kind"],
            "identity": group["identity"],
            "endpoint": endpoint,
            "records": records,
        }
        try:
            latest = latest_remote_revision(str(group["kind"]), fetch(endpoint))
            output["latest_revision"] = latest
            advanced = []
            uncheckable = []
            for record in records:
                path = str(record["path"])
                pinned = record["pinned_commit"]
                if not isinstance(pinned, str):
                    uncheckable.append(path)
                elif pinned != latest:
                    advanced.append(path)
                    source_candidates.append(
                        {
                            "path": path,
                            "upstream": str(group["identity"]),
                            "pinned_revision": pinned,
                            "latest_revision": latest,
                            "action": "review-and-add-a-new-source-record-if-relevant",
                        }
                    )
            output["state"] = (
                "remote-head-differs" if advanced else "matches-remote-head"
            )
            output["advanced_records"] = advanced
            output["uncheckable_records"] = uncheckable
        except (FetchError, CommandError) as error:
            output["state"] = "fetch-error"
            output["error"] = str(error)
            issues.append(
                {
                    "code": "REMOTE_REVISION_FETCH_FAILED",
                    "category": "network",
                    "severity": "error",
                    "message": f"{group['identity']}: {error}",
                }
            )
        upstreams.append(output)

    release_candidates: list[str] = []
    release_state: dict[str, object] = {"endpoint": ZIG_DOWNLOAD_INDEX}
    try:
        versions = stable_versions(fetch(ZIG_DOWNLOAD_INDEX))
        release_candidates = [
            version
            for version in versions
            if tuple(int(part) for part in version.split(".")) > baseline_key
        ]
        release_state.update(
            {
                "state": "new-release-available" if release_candidates else "current",
                "latest_stable": versions[-1] if versions else None,
                "candidates": release_candidates,
            }
        )
    except (FetchError, CommandError) as error:
        release_state.update({"state": "fetch-error", "error": str(error)})
        issues.append(
            {
                "code": "ZIG_RELEASE_FETCH_FAILED",
                "category": "network",
                "severity": "error",
                "message": f"ziglang.org download index: {error}",
            }
        )

    source_candidates.sort(key=lambda candidate: candidate["path"])
    return {
        "schema_version": 1,
        "command": "review",
        "ok": not issues,
        "mode": "read-only",
        "mutates_repository": False,
        "zig_baseline": baseline,
        "review_required": bool(source_candidates or release_candidates),
        "summary": {
            "upstreams": len(upstreams),
            "source_records_with_different_remote_head": len(source_candidates),
            "zig_release_candidates": len(release_candidates),
            "network_errors": len(issues),
            "local_records_skipped": len(skipped_local),
            "remote_records_unmapped": len(unmapped_remote),
        },
        "zig_releases": release_state,
        "source_revision_candidates": source_candidates,
        "upstreams": upstreams,
        "local_records_skipped": skipped_local,
        "remote_records_unmapped": unmapped_remote,
        "issues": issues,
        "signal_interpretation": (
            "A remote-head difference is only a coarse prompt to inspect new upstream "
            "work. Immutable source records remain valid evidence: this signal does not "
            "show that the cited document changed, that a claim became stale, or that a "
            "record should be rewritten."
        ),
        "required_action": (
            "Review candidates manually. Preserve cited records; add a new immutable "
            "record and rerun the ingest/upgrade workflow only when evidence is relevant."
        ),
    }


def upgrade_report(
    root: Path,
    target: str,
    compiler: str | None = None,
) -> dict[str, object]:
    if not SEMVER.fullmatch(target):
        raise CommandError("upgrade target must be an exact semantic version such as 0.16.1")
    baseline = (root / ".zig-version").read_text(encoding="utf-8").strip()
    compiler_version: str | None = None
    if compiler is not None:
        try:
            compiler_version = subprocess.run(
                [compiler, "version"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
        except (OSError, subprocess.CalledProcessError) as error:
            raise CommandError(f"unable to run target compiler {compiler!r}: {error}") from error
        if compiler_version != target:
            raise CommandError(
                f"target compiler reports {compiler_version!r}, expected {target!r}"
            )

    pages: list[dict[str, str]] = []
    verified_to_invalidate: list[str] = []
    for path in [root / "index.md", *sorted((root / "wiki").glob("**/*.md"))]:
        document = parse_document(path)
        relative = path.relative_to(root).as_posix()
        status = document.scalar.get("status", "")
        zig = document.scalar.get("zig", "")
        pages.append({"path": relative, "status": status, "zig": zig})
        if status in {"source-verified", "runtime-verified"} and zig not in {
            target,
            "n/a",
        }:
            verified_to_invalidate.append(relative)

    proofs = sorted(
        path.relative_to(root).as_posix()
        for path in (root / "proofs").glob("**/*.zig")
    )
    sources_for_current = []
    sources_for_target = []
    for path in sorted((root / "sources").glob("**/*.md")):
        text = path.read_text(encoding="utf-8")
        relative = path.relative_to(root).as_posix()
        if baseline in text:
            sources_for_current.append(relative)
        if target in text:
            sources_for_target.append(relative)

    return {
        "schema_version": 1,
        "command": "upgrade",
        "ok": True,
        "mode": "plan-only",
        "mutates_repository": False,
        "current_baseline": baseline,
        "target_version": target,
        "target_compiler": compiler,
        "target_compiler_version": compiler_version,
        "already_active": target == baseline,
        "inventory": {
            "pages": pages,
            "verified_pages_to_invalidate_before_reverification": (
                verified_to_invalidate
            ),
            "proofs_to_compile": proofs,
            "sources_mentioning_current_version": sources_for_current,
            "sources_mentioning_target_version": sources_for_target,
        },
        "required_workflow": [
            "Add target release sources without overwriting prior source records.",
            "Inventory every page and proof carrying the prior version.",
            "Remove verified status before relying on claims under the target compiler.",
            "Change .zig-version only as an explicit reviewed upgrade edit.",
            "Compile and run all proofs with the exact target compiler and platform matrix.",
            "Migrate useful examples, repair links and index entries, then rerun lint.",
            "Append one upgrade log entry with compiler identity and unresolved gaps.",
        ],
    }


def lint_command(root: Path, run_verify: bool = True) -> tuple[dict[str, object], int]:
    verification: dict[str, object] = {"ran": run_verify}
    if run_verify:
        process = subprocess.run(
            ["zig", "build", "verify", "--summary", "all"],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
        )
        verification.update(
            {
                "ok": process.returncode == 0,
                "returncode": process.returncode,
                "stdout": process.stdout,
                "stderr": process.stderr,
            }
        )

    lint = subprocess.run(
        [sys.executable, str(root / "tools" / "lint_wiki.py"), "--format", "json"],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
    )
    try:
        report = json.loads(lint.stdout)
    except json.JSONDecodeError as error:
        raise CommandError(
            f"lint_wiki.py did not emit valid JSON: {error}; stderr: {lint.stderr.strip()}"
        ) from error
    if not isinstance(report, dict):
        raise CommandError("lint_wiki.py JSON root must be an object")
    report["mutates_repository"] = False
    verification.setdefault("ok", None)
    report["verification"] = verification

    issues = report.get("issues")
    if not isinstance(issues, list):
        raise CommandError("lint_wiki.py JSON report has no issues array")
    if run_verify and not verification["ok"]:
        issues.append(
            {
                "code": "BUILD_VERIFY_FAILED",
                "category": "proof",
                "severity": "error",
                "message": "zig build verify failed; inspect verification stderr",
            }
        )
        report["ok"] = False
        summary = report.get("summary")
        if isinstance(summary, dict):
            summary["errors"] = len(issues)
    return report, 0 if report.get("ok") else 1


def print_json(value: object) -> None:
    print(json.dumps(value, indent=2, sort_keys=True))


def print_query(report: dict[str, object]) -> None:
    matches = report["matches"]
    assert isinstance(matches, list)
    print(
        f"Zig {report['zig_baseline']} query {report['query']!r}: "
        f"{report['match_count']} matches"
    )
    for match in matches:
        assert isinstance(match, dict)
        print(f"- {match['path']} [{match['status']}; score {match['score']}]")
        print(f"  {match['summary']}")
        sources = match["sources"]
        proofs = match["proofs"]
        assert isinstance(sources, list)
        assert isinstance(proofs, list)
        if sources:
            print(f"  sources: {', '.join(str(item) for item in sources)}")
        if proofs:
            print(f"  proofs: {', '.join(str(item) for item in proofs)}")


def print_plan(report: dict[str, object]) -> None:
    print(
        f"{report['command']} plan only; repository mutation: "
        f"{str(report['mutates_repository']).lower()}"
    )
    if report["command"] == "ingest":
        proposed = report["proposed_record"]
        assert isinstance(proposed, dict)
        print(f"proposed source record: {proposed['path']}")
        existing = report["existing_records_with_same_identity"]
        assert isinstance(existing, list)
        if existing:
            print(f"existing identity matches: {', '.join(str(item) for item in existing)}")
    else:
        print(f"baseline: {report['current_baseline']} -> target: {report['target_version']}")
        inventory = report["inventory"]
        assert isinstance(inventory, dict)
        candidates = inventory["verified_pages_to_invalidate_before_reverification"]
        proofs = inventory["proofs_to_compile"]
        assert isinstance(candidates, list)
        assert isinstance(proofs, list)
        print(f"verified pages requiring invalidation/review: {len(candidates)}")
        print(f"proofs requiring target-compiler verification: {len(proofs)}")
    workflow = report["required_workflow"]
    assert isinstance(workflow, list)
    for number, step in enumerate(workflow, start=1):
        print(f"{number}. {step}")


def print_lint(report: dict[str, object]) -> None:
    if report.get("ok"):
        summary = report["summary"]
        assert isinstance(summary, dict)
        print(
            f"wiki lint passed: {summary['wiki_pages']} pages, "
            f"{summary['sources']} sources"
        )
        return
    print("wiki lint failed:", file=sys.stderr)
    issues = report.get("issues", [])
    assert isinstance(issues, list)
    for issue in issues:
        assert isinstance(issue, dict)
        print(f"- [{issue['code']}] {issue['message']}", file=sys.stderr)


def print_review(report: dict[str, object]) -> None:
    summary = report["summary"]
    assert isinstance(summary, dict)
    print(
        f"read-only review for Zig {report['zig_baseline']}: "
        f"{summary['source_records_with_different_remote_head']} coarse remote-head candidates, "
        f"{summary['zig_release_candidates']} release candidates, "
        f"{summary['network_errors']} network errors"
    )
    releases = report["zig_releases"]
    assert isinstance(releases, dict)
    candidates = releases.get("candidates", [])
    if isinstance(candidates, list) and candidates:
        print(f"Zig releases to review: {', '.join(str(item) for item in candidates)}")
    print(str(report["signal_interpretation"]))
    print(str(report["required_action"]))
    issues = report["issues"]
    assert isinstance(issues, list)
    for issue in issues:
        assert isinstance(issue, dict)
        print(f"- [{issue['code']}] {issue['message']}", file=sys.stderr)


def parser() -> argparse.ArgumentParser:
    command = argparse.ArgumentParser(description=__doc__)
    command.add_argument(
        "--root",
        default=str(DEFAULT_ROOT),
        help="repository root (defaults to the parent of tools/)",
    )
    subcommands = command.add_subparsers(dest="command", required=True)

    query = subcommands.add_parser("query", help="rank relevant pages and their evidence")
    query.add_argument("terms", nargs="+", help="terms to search for")
    query.add_argument("--limit", type=int, default=8)
    query.add_argument("--format", choices=("text", "json"), default="text")

    ingest = subcommands.add_parser("ingest", help="validate and plan a source ingest")
    ingest.add_argument("source", help="absolute https URL or local file")
    ingest.add_argument(
        "--revision",
        required=True,
        help="claimed exact source revision; origin confirmation is still required",
    )
    ingest.add_argument("--title")
    ingest.add_argument("--id", dest="record_id")
    ingest.add_argument("--sha256", dest="expected_sha256")
    ingest.add_argument("--related-query")
    ingest.add_argument("--format", choices=("text", "json"), default="text")

    lint = subcommands.add_parser("lint", help="run proof verification and structural lint")
    lint.add_argument(
        "--deterministic-only",
        action="store_true",
        help="skip Zig proof execution; intended for focused lint diagnosis only",
    )
    lint.add_argument("--format", choices=("text", "json"), default="text")

    review = subcommands.add_parser(
        "review",
        help="read-only check of upstream source revisions and Zig releases",
    )
    review.add_argument(
        "--timeout",
        type=float,
        default=15.0,
        help="per-endpoint network timeout in seconds",
    )
    review.add_argument("--format", choices=("text", "json"), default="text")

    upgrade = subcommands.add_parser(
        "upgrade", help="inventory and plan an explicit Zig release upgrade"
    )
    upgrade.add_argument("target", help="exact target semantic version")
    upgrade.add_argument("--compiler", help="target Zig executable to version-check")
    upgrade.add_argument("--format", choices=("text", "json"), default="text")
    return command


def error_report(command: str | None, message: str) -> dict[str, object]:
    return {
        "schema_version": 1,
        "command": command,
        "ok": False,
        "mutates_repository": False,
        "issues": [
            {
                "code": "INVALID_COMMAND_INPUT",
                "category": "input",
                "severity": "error",
                "message": message,
            }
        ],
    }


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        root = repository_root(args.root)
        if args.command == "query":
            report = query_report(root, " ".join(args.terms), args.limit)
            if args.format == "json":
                print_json(report)
            else:
                print_query(report)
            return 0
        if args.command == "ingest":
            report = ingest_report(
                root,
                args.source,
                args.revision,
                title=args.title,
                record_id=args.record_id,
                expected_sha256=args.expected_sha256,
                related_query=args.related_query,
            )
            if args.format == "json":
                print_json(report)
            else:
                print_plan(report)
            return 0
        if args.command == "lint":
            report, returncode = lint_command(
                root, run_verify=not args.deterministic_only
            )
            if args.format == "json":
                print_json(report)
            else:
                print_lint(report)
            return returncode
        if args.command == "review":
            report = review_report(root, timeout=args.timeout)
            if args.format == "json":
                print_json(report)
            else:
                print_review(report)
            return 0 if report["ok"] else 1
        if args.command == "upgrade":
            report = upgrade_report(root, args.target, compiler=args.compiler)
            if args.format == "json":
                print_json(report)
            else:
                print_plan(report)
            return 0
        raise AssertionError(f"unhandled command {args.command}")
    except CommandError as error:
        report = error_report(getattr(args, "command", None), str(error))
        if getattr(args, "format", "text") == "json":
            print_json(report)
        else:
            print(f"{args.command} failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
