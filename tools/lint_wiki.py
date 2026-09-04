#!/usr/bin/env python3
"""Deterministic checks for the Markdown knowledge base."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WIKI_FILES = [ROOT / "index.md", *sorted((ROOT / "wiki").glob("**/*.md"))]
SOURCE_FILES = sorted((ROOT / "sources").glob("**/*.md"))
CONTENT_FILES = WIKI_FILES + SOURCE_FILES
MAINTAINED_ZIG_FILES = [
    *sorted(ROOT.glob("*.zig")),
    *sorted((ROOT / "proofs").glob("**/*.zig")),
]
ZIG_LINE_LENGTH_MAX = 100
ALL_MARKDOWN = [
    path
    for path in ROOT.glob("**/*.md")
    if ".git" not in path.parts and ".zig-cache" not in path.parts
]
WIKILINK = re.compile(r"!?\[\[([^\]]+)\]\]")
KEY = re.compile(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$")
PROOF = re.compile(r"^\s+-\s+(proofs/[^\s]+\.zig)\s*$")
REGISTERED_PROOF = re.compile(r'"(proofs/[^"\s]+\.zig)"')


def issue_from_failure(message: str) -> dict[str, object]:
    """Turn the stable human diagnostic into a machine-readable issue."""
    code = "WIKI_VALIDATION_FAILED"
    category = "validation"

    if message.startswith("zig version is "):
        code = "STALE_COMPILER_VERSION"
        category = "version"
    elif "verified page targets" in message:
        code = "STALE_VERIFIED_PAGE_VERSION"
        category = "version"
    elif "page targets" in message and "baseline is" in message:
        code = "STALE_PAGE_VERSION"
        category = "version"
    elif "broken source evidence" in message:
        code = "BROKEN_EVIDENCE_SOURCE_LINK"
        category = "evidence"
    elif "missing snapshot" in message:
        code = "BROKEN_EVIDENCE_SNAPSHOT_MISSING"
        category = "evidence"
    elif " sha256 is " in message or "has no corresponding sha256" in message:
        code = "BROKEN_EVIDENCE_SNAPSHOT_HASH"
        category = "evidence"
    elif "not registered in build.zig" in message:
        code = "BROKEN_EVIDENCE_PROOF_UNREGISTERED"
        category = "evidence"
    elif "registered proof does not exist" in message or ": missing proofs/" in message:
        code = "BROKEN_EVIDENCE_PROOF_MISSING"
        category = "evidence"
    elif "broken wikilink" in message:
        code = "BROKEN_WIKILINK"
        category = "link"
    elif "ambiguous wikilink" in message:
        code = "AMBIGUOUS_WIKILINK"
        category = "link"
    elif "orphan wiki page" in message:
        code = "ORPHAN_WIKI_PAGE"
        category = "graph"
    elif "Zig source line is" in message:
        code = "ZIG_LINE_TOO_LONG"
        category = "style"
    elif "fenced Zig is forbidden" in message:
        code = "UNVERIFIED_INLINE_ZIG"
        category = "evidence"
    elif "missing source key revision" in message:
        code = "UNPINNED_SOURCE_REVISION"
        category = "evidence"
    elif "missing source key captured" in message:
        code = "SOURCE_CAPTURE_DATE_MISSING"
        category = "evidence"
    elif "frontmatter" in message or "missing frontmatter key" in message:
        code = "INVALID_FRONTMATTER"
        category = "schema"
    elif "duplicate id" in message:
        code = "DUPLICATE_CONTENT_ID"
        category = "schema"
    elif "unsupported status" in message:
        code = "UNSUPPORTED_CONTENT_STATUS"
        category = "schema"
    elif "unsupported wiki kind" in message:
        code = "UNSUPPORTED_WIKI_KIND"
        category = "schema"

    location: dict[str, object] = {}
    location_match = re.match(r"^([^:]+)(?::(\d+))?:\s", message)
    if location_match:
        location["path"] = location_match.group(1)
        if location_match.group(2):
            location["line"] = int(location_match.group(2))

    issue: dict[str, object] = {
        "code": code,
        "category": category,
        "severity": "error",
        "message": message,
    }
    if location:
        issue["location"] = location
    return issue


def lint_report(
    failures: list[str],
    baseline: str,
    actual: str | None,
    graph: dict[str, object],
) -> dict[str, object]:
    issues = [issue_from_failure(failure) for failure in failures]
    categories: dict[str, int] = defaultdict(int)
    for issue in issues:
        category = issue["category"]
        assert isinstance(category, str)
        categories[category] += 1
    return {
        "schema_version": 1,
        "command": "lint",
        "ok": not issues,
        "zig_baseline": baseline,
        "zig_actual": actual,
        "summary": {
            "errors": len(issues),
            "issues_by_category": dict(sorted(categories.items())),
            "wiki_pages": len(WIKI_FILES),
            "sources": len(SOURCE_FILES),
        },
        "issues": issues,
        "graph": graph,
    }


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


def frontmatter_items(lines: list[str], key: str) -> list[str]:
    """Read a list from the deliberately small frontmatter schema."""
    try:
        end = lines.index("---", 1)
    except ValueError:
        return []
    items: list[str] = []
    in_key = False
    for line in lines[1:end]:
        key_match = KEY.match(line)
        if key_match:
            in_key = key_match.group(1) == key
            continue
        if in_key and line.startswith("  - "):
            items.append(line[4:].strip().strip('"'))
    return items


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


def resolved_link(
    raw_target: str,
    stems: dict[str, list[Path]],
    paths: set[str],
) -> Path | None:
    """Resolve an already-extracted wikilink to a repository-relative path."""
    target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
    if not target:
        return None
    if "/" in target:
        normalized = target.removesuffix(".md").lstrip("/")
        if normalized in paths:
            return Path(f"{normalized}.md")
        return None

    target_name = target[:-3] if target.endswith(".md") else target
    matches = stems.get(target_name, [])
    return matches[0] if len(matches) == 1 else None


def graph_report(
    stems: dict[str, list[Path]],
    paths: set[str],
    baseline: str,
) -> dict[str, object]:
    """Return deterministic, count-based graph signals for semantic review."""
    wiki_paths = {path.relative_to(ROOT) for path in WIKI_FILES}
    source_paths = {path.relative_to(ROOT) for path in SOURCE_FILES}
    index_path = Path("index.md")
    inbound_wiki: dict[Path, set[Path]] = defaultdict(set)
    outbound_wiki: dict[Path, set[Path]] = defaultdict(set)
    source_evidence: dict[Path, set[Path]] = defaultdict(set)

    for path in WIKI_FILES:
        relative = path.relative_to(ROOT)
        for raw_target in links_outside_fences(path.read_text(encoding="utf-8")):
            target = resolved_link(raw_target, stems, paths)
            if target in wiki_paths and target != relative:
                outbound_wiki[relative].add(target)
                inbound_wiki[target].add(relative)
            elif target in source_paths:
                source_evidence[relative].add(target)

    pages: list[dict[str, object]] = []
    for relative in sorted(wiki_paths - {index_path}, key=str):
        conceptual_backlinks = inbound_wiki[relative] - {index_path}
        indexed = index_path in inbound_wiki[relative]
        outgoing_count = len(outbound_wiki[relative])
        source_count = len(source_evidence[relative])

        # The score is deliberately structural, not a semantic truth score.
        # Index discovery: 30; non-index backlinks: 30; outward navigation: 20;
        # cited source records: 20. Partial credit exposes thin connections.
        score = 30 if indexed else 0
        score += 30 if len(conceptual_backlinks) >= 2 else 15 * len(conceptual_backlinks)
        score += 20 if outgoing_count >= 2 else 10 * outgoing_count
        score += 20 if source_count >= 2 else 10 * source_count

        if not inbound_wiki[relative]:
            band = "orphan"
        elif score < 60:
            band = "weak"
        elif score < 80:
            band = "connected"
        else:
            band = "strong"

        pages.append(
            {
                "path": relative.as_posix(),
                "score": score,
                "band": band,
                "indexed": indexed,
                "conceptual_backlinks": sorted(
                    path.as_posix() for path in conceptual_backlinks
                ),
                "outgoing_wiki_links": sorted(
                    path.as_posix() for path in outbound_wiki[relative]
                ),
                "source_evidence_links": sorted(
                    path.as_posix() for path in source_evidence[relative]
                ),
            }
        )

    edges = sum(len(targets) for targets in outbound_wiki.values())
    return {
        "schema_version": 1,
        "zig_baseline": baseline,
        "scoring": {
            "index_discovery": 30,
            "conceptual_backlinks": "15 for one, 30 for two or more",
            "outgoing_wiki_links": "10 for one, 20 for two or more",
            "source_evidence_links": "10 for one, 20 for two or more",
            "bands": {
                "orphan": "no inbound wiki link",
                "weak": "inbound but score below 60",
                "connected": "score 60-79",
                "strong": "score 80-100",
            },
        },
        "summary": {
            "wiki_pages_excluding_index": len(pages),
            "directed_wiki_edges": edges,
            "orphans": sum(page["band"] == "orphan" for page in pages),
            "weak": sum(page["band"] == "weak" for page in pages),
            "connected": sum(page["band"] == "connected" for page in pages),
            "strong": sum(page["band"] == "strong" for page in pages),
        },
        "pages": pages,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--graph-report",
        action="store_true",
        help="emit a deterministic JSON graph/backlink report after verification",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="emit human-readable diagnostics or the versioned lint JSON schema",
    )
    args = parser.parse_args()

    failures: list[str] = []
    baseline = (ROOT / ".zig-version").read_text(encoding="utf-8").strip()
    try:
        actual = subprocess.run(
            ["zig", "version"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as error:
        actual = None
        failures.append(f"unable to determine zig version: {error}")
    if actual is not None and actual != baseline:
        failures.append(f"zig version is {actual}, expected exact baseline {baseline}")

    # TigerStyle's 100-character ceiling is stricter than zig fmt's canonical
    # whitespace rules. Check maintained Zig sources, excluding captured source
    # snapshots, generated cache files, and foreign-language shims.
    for path in MAINTAINED_ZIG_FILES:
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(),
            start=1,
        ):
            if len(line) > ZIG_LINE_LENGTH_MAX:
                failures.append(
                    f"{path.relative_to(ROOT)}:{line_number}: Zig source line is "
                    f"{len(line)} characters; maximum is {ZIG_LINE_LENGTH_MAX}"
                )

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
    source_evidence_references: set[tuple[Path, str]] = set()
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
            if meta.get("kind") not in {"concept", "pattern", "principle", "platform", "map"}:
                failures.append(f"{relative}: unsupported wiki kind {meta.get('kind')}")
            for required in ("zig", "updated", "sources", "proofs", "platforms"):
                if required not in meta:
                    failures.append(f"{relative}: missing frontmatter key {required}")
            zig_version = meta.get("zig")
            if zig_version not in {baseline, "n/a", None}:
                if status in {"source-verified", "runtime-verified"}:
                    failures.append(
                        f"{relative}: verified page targets {zig_version!r}, baseline is {baseline}"
                    )
                else:
                    failures.append(
                        f"{relative}: page targets {zig_version!r}, baseline is {baseline}"
                    )
            if any(line.strip().startswith("```zig") for line in lines):
                failures.append(
                    f"{relative}: fenced Zig is forbidden; link an executable proof instead"
                )
            for source_item in frontmatter_items(lines, "sources"):
                match = WIKILINK.fullmatch(source_item)
                if match:
                    source_evidence_references.add((relative, match.group(1)))
                else:
                    failures.append(
                        f"{relative}: broken source evidence item {source_item!r}"
                    )

        if path in SOURCE_FILES:
            for required in ("captured", "revision"):
                if not meta.get(required):
                    failures.append(f"{relative}: missing source key {required}")

            for key, snapshot_name in sorted(meta.items()):
                if not key.startswith("snapshot"):
                    continue

                hash_key = key.replace("snapshot", "sha256", 1)
                expected_hash = meta.get(hash_key)
                if not expected_hash:
                    failures.append(
                        f"{relative}: {key} has no corresponding {hash_key}"
                    )
                    continue

                snapshot = ROOT / snapshot_name
                if not snapshot.is_file():
                    failures.append(f"{relative}: missing snapshot {snapshot_name}")
                    continue

                actual_hash = hashlib.sha256(snapshot.read_bytes()).hexdigest()
                if actual_hash != expected_hash:
                    failures.append(
                        f"{relative}: {snapshot_name} sha256 is {actual_hash}, "
                        f"expected {expected_hash}"
                    )

        for line in lines:
            match = PROOF.match(line)
            if match and not (ROOT / match.group(1)).is_file():
                failures.append(f"{relative}: missing {match.group(1)}")

    stems, paths = link_names()
    source_paths = {path.relative_to(ROOT) for path in SOURCE_FILES}
    broken_source_evidence: set[tuple[Path, str]] = set()
    for relative, raw_target in sorted(
        source_evidence_references,
        key=lambda item: (str(item[0]), item[1]),
    ):
        target = resolved_link(raw_target, stems, paths)
        if target not in source_paths:
            failures.append(
                f"{relative}: broken source evidence wikilink [[{raw_target}]]"
            )
            broken_source_evidence.add((relative, raw_target))

    for path in ALL_MARKDOWN:
        relative = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        for raw_target in links_outside_fences(text):
            if (relative, raw_target) in broken_source_evidence:
                continue
            target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
            if not target:
                continue
            if "/" in target:
                normalized = target.removesuffix(".md").lstrip("/")
                if normalized not in paths:
                    failures.append(
                        f"{relative}: broken wikilink [[{raw_target}]]"
                    )
                continue
            target_name = target[:-3] if target.endswith(".md") else target
            matches = stems.get(target_name, [])
            if not matches:
                failures.append(
                    f"{relative}: broken wikilink [[{raw_target}]]"
                )
            elif len(matches) > 1:
                rendered = ", ".join(str(match) for match in matches)
                failures.append(
                    f"{relative}: ambiguous wikilink [[{raw_target}]] -> {rendered}"
                )

    report = graph_report(stems, paths, baseline)
    report_pages = report["pages"]
    assert isinstance(report_pages, list)
    for page in report_pages:
        assert isinstance(page, dict)
        if page["band"] == "orphan":
            failures.append(
                f"{page['path']}: orphan wiki page has no inbound wiki link"
            )

    result = lint_report(failures, baseline, actual, report)
    if args.format == "json":
        print(json.dumps(result, indent=2, sort_keys=True))
    elif failures:
        print("wiki verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
    elif args.graph_report:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            f"wiki verification passed: {len(WIKI_FILES)} pages, "
            f"{len(SOURCE_FILES)} sources, Zig {actual}"
        )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
