#!/usr/bin/env python3
"""Focused tests for the deterministic wiki maintenance commands."""

from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import lint_wiki, wiki


PAGE = """---
id: io-deadlines
title: I/O deadlines and cancellation
kind: concept
status: source-verified
zig: "0.16.0"
summary: Use one absolute deadline and distinguish cancellation acknowledgement.
updated: 2026-09-04
sources:
  - "[[zig-stdlib]]"
proofs:
  - proofs/deadline.zig
platforms:
  - cross-platform
---

# I/O deadlines

Carry one deadline through every retry and wait.
"""


class WikiCommandTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        for directory in ("wiki", "sources", "proofs", "tools"):
            (self.root / directory).mkdir()
        self.write(".zig-version", "0.16.0\n")
        self.write("AGENTS.md", "# Agent contract\n")
        self.write(
            "index.md",
            "---\nid: index\ntitle: Index\nkind: map\nstatus: draft\n"
            'zig: "0.16.0"\nsummary: Index.\nupdated: 2026-09-04\n'
            "sources: []\nproofs: []\nplatforms:\n  - cross-platform\n---\n"
            "\n[[io-deadlines]]\n",
        )
        self.write("wiki/io-deadlines.md", PAGE)
        self.write(
            "sources/zig-stdlib.md",
            "---\nid: source-zig-stdlib\ntitle: Zig standard library\n"
            "kind: source\nstatus: captured\nsummary: Exact source.\n"
            "captured: 2026-09-04\nrevision: zig-0.16.0\n"
            "url: https://example.invalid/zig/0.16.0\n---\n",
        )
        self.write("proofs/deadline.zig", 'test "deadline" {}\n')

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write(self, relative: str, content: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def snapshot(self) -> dict[str, str]:
        return {
            path.relative_to(self.root).as_posix(): hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
            for path in sorted(self.root.glob("**/*"))
            if path.is_file()
        }

    def test_query_ranks_page_and_returns_evidence(self) -> None:
        report = wiki.query_report(self.root, "deadline cancellation")

        self.assertTrue(report["ok"])
        self.assertFalse(report["mutates_repository"])
        matches = report["matches"]
        self.assertIsInstance(matches, list)
        self.assertEqual(matches[0]["path"], "wiki/io-deadlines.md")
        self.assertEqual(matches[0]["sources"], ["zig-stdlib"])
        self.assertEqual(matches[0]["proofs"], ["proofs/deadline.zig"])

    def test_ingest_local_source_is_plan_only_and_hashes_input(self) -> None:
        local_source = self.root / "article.txt"
        local_source.write_text("primary evidence\n", encoding="utf-8")
        before = self.snapshot()

        report = wiki.ingest_report(
            self.root,
            str(local_source),
            "commit-0123456789abcdef",
            title="New bounded I/O article",
            related_query="deadline",
        )

        self.assertEqual(before, self.snapshot())
        self.assertEqual(report["mode"], "plan-only")
        self.assertFalse(report["mutates_repository"])
        expected_hash = hashlib.sha256(local_source.read_bytes()).hexdigest()
        self.assertEqual(report["source"]["sha256"], expected_hash)
        self.assertEqual(
            report["proposed_record"]["path"],
            "sources/new-bounded-i-o-article.md",
        )

    def test_ingest_rejects_moving_revision(self) -> None:
        for revision in ("main", "develop"):
            with self.subTest(revision=revision):
                with self.assertRaisesRegex(wiki.CommandError, "moving name"):
                    wiki.ingest_report(
                        self.root,
                        "https://example.invalid/project",
                        revision,
                        title="Moving source",
                    )

    def test_ingest_does_not_overclaim_remote_revision_immutability(self) -> None:
        weak = wiki.ingest_report(
            self.root,
            "https://example.invalid/project/releases/release-0.16",
            "release-0.16",
            title="Weak revision",
        )
        weak_assessment = weak["source"]["revision_assessment"]
        self.assertEqual(weak_assessment["status"], "review-required")
        self.assertFalse(weak_assessment["immutability_verified"])
        self.assertEqual(
            weak["proposed_record"]["action"],
            "confirm-revision-then-create",
        )

        revision = "0123456789abcdef0123456789abcdef01234567"
        strong = wiki.ingest_report(
            self.root,
            f"https://example.invalid/project/blob/{revision}/README.md",
            revision,
            title="Content addressed revision",
        )
        strong_assessment = strong["source"]["revision_assessment"]
        self.assertEqual(
            strong_assessment["status"], "content-address-like-syntax"
        )
        self.assertEqual(strong_assessment["full_hex_identifier"], revision)
        self.assertFalse(strong_assessment["remote_identity_checked"])
        self.assertFalse(strong_assessment["immutability_verified"])

    def test_upgrade_inventories_without_changing_baseline(self) -> None:
        before = self.snapshot()

        report = wiki.upgrade_report(self.root, "0.17.0")

        self.assertEqual(before, self.snapshot())
        self.assertEqual(report["mode"], "plan-only")
        self.assertEqual(report["current_baseline"], "0.16.0")
        inventory = report["inventory"]
        self.assertIn(
            "wiki/io-deadlines.md",
            inventory["verified_pages_to_invalidate_before_reverification"],
        )
        self.assertEqual(inventory["proofs_to_compile"], ["proofs/deadline.zig"])

    def test_review_reports_upstream_and_release_candidates_without_mutation(self) -> None:
        pinned = "1" * 40
        latest = "2" * 40
        self.write(
            "sources/project.md",
            "---\nid: source-project\ntitle: Project\nkind: source\n"
            "status: captured\nsummary: Project source.\ncaptured: 2026-09-04\n"
            f"revision: {pinned}\n"
            f"url: https://github.com/owner/project/blob/{pinned}/README.md\n"
            "---\n",
        )
        before = self.snapshot()

        def fetch(url: str) -> object:
            if url == "https://api.github.com/repos/owner/project/commits?per_page=1":
                return [{"sha": latest}]
            if url == wiki.ZIG_DOWNLOAD_INDEX:
                return {"master": {}, "0.16.0": {}, "0.16.1": {}, "0.17.0": {}}
            raise AssertionError(f"unexpected endpoint {url}")

        report = wiki.review_report(self.root, fetch_json=fetch)

        self.assertEqual(before, self.snapshot())
        self.assertTrue(report["ok"])
        self.assertFalse(report["mutates_repository"])
        self.assertTrue(report["review_required"])
        self.assertEqual(report["zig_releases"]["candidates"], ["0.16.1", "0.17.0"])
        self.assertEqual(
            report["source_revision_candidates"][0]["path"],
            "sources/project.md",
        )
        self.assertEqual(
            report["source_revision_candidates"][0]["action"],
            "review-and-add-a-new-source-record-if-relevant",
        )
        self.assertIn("coarse", report["signal_interpretation"])
        self.assertIn("does not show", report["signal_interpretation"])
        self.assertIn("stale", report["signal_interpretation"])

    def test_review_collects_explicit_network_errors(self) -> None:
        pinned = "1" * 40
        self.write(
            "sources/project.md",
            "---\nid: source-project\ntitle: Project\nkind: source\n"
            "status: captured\nsummary: Project source.\ncaptured: 2026-09-04\n"
            f"revision: {pinned}\n"
            f"url: https://github.com/owner/project/tree/{pinned}\n---\n",
        )

        def offline(_: str) -> object:
            raise wiki.FetchError("mock endpoint is offline")

        report = wiki.review_report(self.root, fetch_json=offline)

        self.assertFalse(report["ok"])
        self.assertEqual(report["summary"]["network_errors"], 2)
        self.assertEqual(
            [issue["code"] for issue in report["issues"]],
            ["REMOTE_REVISION_FETCH_FAILED", "ZIG_RELEASE_FETCH_FAILED"],
        )
        self.assertTrue(
            all("mock endpoint is offline" in issue["message"] for issue in report["issues"])
        )

    def test_review_maps_gist_to_bounded_commit_history(self) -> None:
        gist_id = "442a6bf555914893e9891c11519de94f"
        upstream = wiki.remote_upstream(f"https://gist.github.com/karpathy/{gist_id}")

        self.assertEqual(
            upstream,
            (
                "github-gist",
                gist_id,
                f"https://api.github.com/gists/{gist_id}/commits?per_page=1",
            ),
        )
        self.assertEqual(
            wiki.latest_remote_revision(
                "github-gist",
                [{"version": "a" * 40}],
            ),
            "a" * 40,
        )

    def test_public_gist_head_does_not_require_api_scope(self) -> None:
        completed = subprocess.CompletedProcess(
            args=["git", "ls-remote"],
            returncode=0,
            stdout=f"{'a' * 40}\tHEAD\n",
            stderr="",
        )
        with mock.patch.object(wiki.subprocess, "run", return_value=completed) as run:
            revision = wiki.fetch_git_remote_head(
                "https://gist.github.com/example.git", timeout=7.0
            )

        self.assertEqual(revision, "a" * 40)
        run.assert_called_once_with(
            ["git", "ls-remote", "https://gist.github.com/example.git", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
            timeout=7.0,
        )

    def test_lint_issue_schema_names_stale_and_broken_evidence(self) -> None:
        report = lint_wiki.lint_report(
            [
                "zig version is 0.15.2, expected exact baseline 0.16.0",
                "proofs/missing.zig: not registered in build.zig",
                "sources/local.md: missing snapshot sources/snapshots/local.txt",
                "wiki/io.md: broken source evidence wikilink [[missing-source]]",
            ],
            "0.16.0",
            "0.15.2",
            {"schema_version": 1, "pages": []},
        )

        self.assertFalse(report["ok"])
        self.assertEqual(
            [issue["code"] for issue in report["issues"]],
            [
                "STALE_COMPILER_VERSION",
                "BROKEN_EVIDENCE_PROOF_UNREGISTERED",
                "BROKEN_EVIDENCE_SNAPSHOT_MISSING",
                "BROKEN_EVIDENCE_SOURCE_LINK",
            ],
        )
        self.assertEqual(report["summary"]["issues_by_category"]["evidence"], 3)

    def test_lint_wrapper_preserves_machine_report(self) -> None:
        fake = {
            "schema_version": 1,
            "command": "lint",
            "ok": True,
            "summary": {"errors": 0, "wiki_pages": 2, "sources": 1},
            "issues": [],
        }
        self.write(
            "tools/lint_wiki.py",
            "import json\nprint(json.dumps(" + repr(fake) + "))\n",
        )

        report, returncode = wiki.lint_command(self.root, run_verify=False)

        self.assertEqual(returncode, 0)
        self.assertTrue(report["ok"])
        self.assertFalse(report["mutates_repository"])
        self.assertEqual(report["verification"], {"ran": False, "ok": None})

    def test_json_error_contract_is_stable(self) -> None:
        report = wiki.error_report("upgrade", "bad target")
        encoded = json.dumps(report, sort_keys=True)

        self.assertIn('"code": "INVALID_COMMAND_INPUT"', encoded)
        self.assertFalse(report["ok"])
        self.assertFalse(report["mutates_repository"])


if __name__ == "__main__":
    unittest.main()
