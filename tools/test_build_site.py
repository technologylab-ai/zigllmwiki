#!/usr/bin/env python3
"""Exercise publication provenance, link resolution, and artifact boundaries."""

from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

try:
    from tools import build_site
except ModuleNotFoundError:
    import build_site


class SiteBuildTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.git("init", "-q")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "user.name", "Site fixture")
        self.write(".zig-version", "0.16.0\n")
        self.write(".gitignore", ".zig-cache/\n")
        self.write("index.md", "# Index\n\n[[alpha|The page]]\n")
        self.write("wiki/alpha.md", """---
id: alpha-id
title: Alpha
kind: concept
status: source-verified
zig: "0.16.0"
summary: A source-backed page.
updated: 2026-09-06
sources:
  - "[[primary]]"
proofs:
  - proofs/witness.zig
platforms: ["linux"]
---
# Alpha

[[primary#Scope|Evidence]] and [proof](../proofs/witness.zig#L1).
""")
        self.write("sources/primary.md", """---
id: source-primary
title: Primary source
kind: source
status: captured
captured: 2026-09-06
revision: abcdef0123456789
url: https://example.invalid/pinned
sha256: original-pin
---
# Primary source

[[alpha-id]]
""")
        self.write("proofs/witness.zig", 'test "witness" {}\n')
        self.write("build.zig", 'const proof = "proofs/witness.zig";\n')
        for name in build_site.SITE_FILES:
            self.write("site/" + name, "fixture " + name + "\n")
        self.write("site/vendor/LICENSE.txt", "Fixture license\n")
        self.write("site/vendor/manifest.json", json.dumps([{
            "package": "fixture", "files_sha256": {
                "LICENSE.txt": hashlib.sha256(b"Fixture license\n").hexdigest(),
            },
        }]))
        self.commit()

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.root), *args], check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        ).stdout

    def write(self, relative, value):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value.encode("utf-8") if isinstance(value, str) else value)
        return path

    def commit(self):
        self.git("add", "--all")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "fixture")

    def test_projection_preserves_provenance_and_typed_edges(self):
        payload, blobs = build_site.collect(self.root)
        documents = {item["path"]: item for item in payload["documents"]}
        self.assertEqual(payload["version"], 1)
        self.assertEqual(payload["repository"], build_site.REPOSITORY)
        self.assertEqual(payload["zig"], "0.16.0")
        self.assertFalse(payload["dirty"])
        self.assertEqual(payload["revision"], self.git("rev-parse", "HEAD").decode().strip())
        alpha = documents["wiki/alpha.md"]
        self.assertTrue(alpha["body"].startswith("# Alpha") or alpha["body"].startswith("\n# Alpha"))
        self.assertEqual(alpha["sources"], ["sources/primary.md"])
        self.assertEqual(alpha["proofs"], ["proofs/witness.zig"])
        self.assertEqual(alpha["sha256"], hashlib.sha256((self.root / "wiki/alpha.md").read_bytes()).hexdigest())
        source = documents["sources/primary.md"]
        self.assertEqual(source["metadata"]["url"], "https://example.invalid/pinned")
        self.assertEqual(source["metadata"]["sha256"], "original-pin")
        self.assertEqual(source["status"], "captured")
        self.assertEqual(source["updated"], "")
        self.assertEqual(documents["proofs/witness.zig"]["status"], "")
        self.assertEqual(documents["index.md"]["kind"], "")
        edges = {(edge["source"], edge["target"], edge["type"]) for edge in payload["edges"]}
        self.assertIn(("wiki/alpha.md", "sources/primary.md", "source"), edges)
        self.assertIn(("wiki/alpha.md", "proofs/witness.zig", "proof"), edges)
        self.assertIn(("sources/primary.md", "wiki/alpha.md", "link"), edges)
        self.assertEqual(set(blobs), build_site.SITE_FILES | {"data.json", ".nojekyll", "vendor/LICENSE.txt", "vendor/manifest.json"})
        self.assertEqual(json.loads(blobs["data.json"]), payload)

    def test_aliases_preserve_canonical_ids_and_omit_ambiguous_stems(self):
        self.write("docs/same.md", "# One\n")
        self.write("reports/same.md", "# Two\n")
        self.write("docs/alpha-id.md", "# Colliding stem\n")
        self.commit()
        aliases = build_site.collect(self.root)[0]["aliases"]
        self.assertNotIn("same", aliases)
        self.assertEqual(aliases["docs/same.md"], "docs/same.md")
        self.assertEqual(aliases["alpha-id"], "wiki/alpha.md")
        self.assertEqual(aliases["alpha"], "wiki/alpha.md")
        self.assertEqual(aliases["wiki/alpha"], "wiki/alpha.md")

    def test_duplicate_ids_and_unresolved_evidence_fail(self):
        self.write("docs/duplicate.md", "---\nid: alpha-id\n---\n# Duplicate\n")
        self.commit()
        with self.assertRaisesRegex(build_site.BuildError, "Duplicate document identifier"):
            build_site.collect(self.root)
        (self.root / "docs/duplicate.md").unlink()
        self.write("proofs/witness.zig", 'test "witness" {}\n')
        (self.root / "proofs/witness.zig").unlink()
        self.commit()
        with self.assertRaisesRegex(build_site.BuildError, "unresolved proofs"):
            build_site.collect(self.root)

    def test_links_handle_fragments_references_and_ignore_code(self):
        aliases = {"wiki/alpha.md": "wiki/alpha.md", "alpha": "wiki/alpha.md",
                   "docs/a (copy).md": "docs/a (copy).md", "sources/primary.md": "sources/primary.md"}
        body = """[[alpha#Heading|Alias]]
[copy](../docs/a%20(copy).md#Part)
[source][evidence]
[evidence]: ../sources/primary.md#Scope
`[[not-a-link]]`
```text
[[also-not-a-link]]
```
"""
        targets = build_site.markdown_targets(body)
        self.assertNotIn("[[not-a-link]]", targets)
        self.assertNotIn("[[also-not-a-link]]", targets)
        resolved = {build_site.resolve(value, "wiki/alpha.md", aliases) for value in targets}
        self.assertEqual(resolved, {"wiki/alpha.md", "docs/a (copy).md", "sources/primary.md"})

    def test_traversal_and_external_targets_never_resolve(self):
        aliases = {"wiki/alpha.md": "wiki/alpha.md"}
        for value in ("../../wiki/alpha.md", "%2e%2e/%2e%2e/wiki/alpha.md", "/wiki/alpha.md",
                      "//example.invalid/wiki/alpha.md", "https://example.invalid/wiki/alpha.md",
                      "javascript:alert(1)", "..\\wiki\\alpha.md"):
            with self.subTest(value=value):
                self.assertIsNone(build_site.resolve(value, "wiki/alpha.md", aliases))

    def test_untracked_notes_are_ignored_and_dirty_inputs_are_labelled(self):
        original = build_site.collect(self.root)[1]["data.json"]
        self.write("private-local-note.md", "Do not publish this note.\n")
        self.assertEqual(build_site.collect(self.root)[1]["data.json"], original)
        self.write("index.md", "# Changed input\n")
        with self.assertRaisesRegex(build_site.BuildError, "--allow-dirty"):
            build_site.collect(self.root)
        self.assertTrue(build_site.collect(self.root, allow_dirty=True)[0]["dirty"])

    def test_only_explicit_documents_and_assets_enter_the_artifact(self):
        for path in (".env", ".agents/private.md", "docs/.hidden/private.md", "sources/snapshots/capture.md",
                     "sources/snapshots/capture.json.gz", "site/README-data.md", "site/unrelated.txt", "tools/example.py"):
            self.write(path, "Excluded bytes.\n")
        self.commit()
        payload, blobs = build_site.collect(self.root)
        self.assertEqual(len(payload["documents"]), 4)
        self.assertEqual(set(blobs), build_site.SITE_FILES | {"data.json", ".nojekyll", "vendor/LICENSE.txt", "vendor/manifest.json"})

    def test_vendor_hashes_and_file_allowlist_are_enforced(self):
        self.write("site/vendor/LICENSE.txt", "Changed vendor bytes\n")
        with self.assertRaisesRegex(build_site.BuildError, "Vendor checksum mismatch"):
            build_site.collect(self.root, allow_dirty=True)
        self.write("site/vendor/LICENSE.txt", "Fixture license\n")
        self.write("site/vendor/unreviewed.js", "alert('not in manifest');")
        with self.assertRaisesRegex(build_site.BuildError, "Vendor manifest and asset set differ"):
            build_site.collect(self.root, allow_dirty=True)
        manifest = [{"files_sha256": {"../../private.js": "a" * 64}}]
        with self.assertRaisesRegex(build_site.BuildError, "Invalid or duplicate vendor path"):
            build_site.vendor_files(json.dumps(manifest))

    def test_unregistered_proof_fails_before_publication(self):
        self.write("proofs/unregistered.zig", 'test "not registered" {}\n')
        self.commit()
        with self.assertRaisesRegex(build_site.BuildError, "no registered path"):
            build_site.collect(self.root)

    def test_registered_c_shim_retains_the_proof_edge(self):
        self.write("proofs/shim.c", "int bridge(void) { return 0; }\n")
        self.write("build.zig", 'const a = "proofs/witness.zig";\nconst b = "proofs/shim.c";\n')
        self.write("docs/bridge.md", "---\nproofs:\n  - proofs/shim.c\n---\n# Bridge\n")
        self.commit()
        payload = build_site.collect(self.root)[0]
        documents = {value["path"]: value for value in payload["documents"]}
        self.assertEqual(documents["proofs/shim.c"]["layer"], "proof")
        self.assertEqual(documents["proofs/shim.c"]["status"], "")
        self.assertEqual(documents["docs/bridge.md"]["proofs"], ["proofs/shim.c"])

    def test_images_are_tracked_bounded_and_inert(self):
        self.write("index.md", "# Index\n\n![Chart](docs/chart.svg)\n![Local](docs/untracked.png)\n")
        self.write("docs/chart.svg", '<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0"/></svg>')
        self.commit()
        self.write("docs/untracked.png", b"\x89PNG\r\n\x1a\nlocal")
        blobs = build_site.collect(self.root)[1]
        self.assertIn("files/docs/chart.svg", blobs)
        self.assertNotIn("files/docs/untracked.png", blobs)
        self.assertEqual(build_site.collect(self.root)[0]["assets"], ["docs/chart.svg"])
        self.write("docs/chart.svg", '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>')
        with self.assertRaisesRegex(build_site.BuildError, "Active SVG"):
            build_site.collect(self.root, allow_dirty=True)

    def test_input_symlinks_and_byte_limits_fail(self):
        path = self.root / "index.md"
        path.unlink()
        path.symlink_to(self.root / "sources/primary.md")
        with self.assertRaisesRegex(build_site.BuildError, "Symlink input"):
            build_site.collect(self.root, allow_dirty=True)
        path.unlink()
        self.write("index.md", "# Index\n")
        with mock.patch.object(build_site, "MAX_DOCUMENT_BYTES", 5):
            with self.assertRaisesRegex(build_site.BuildError, "byte limit"):
                build_site.collect(self.root, allow_dirty=True)
        with mock.patch.object(build_site, "MAX_TOTAL_BYTES", 5):
            with self.assertRaisesRegex(build_site.BuildError, "Total input bytes"):
                build_site.collect(self.root, allow_dirty=True)

    def test_artifact_is_deterministic_and_rejects_unexpected_files(self):
        _, first = build_site.collect(self.root)
        _, second = build_site.collect(self.root)
        self.assertEqual(first, second)
        output = self.root / ".zig-cache/site"
        build_site.write_artifact(self.root, output, first)
        build_site.write_artifact(self.root, output, second, check=True)
        (output / "private.txt").write_text("Unrelated output", encoding="utf-8")
        with self.assertRaisesRegex(build_site.BuildError, "unexpected file"):
            build_site.write_artifact(self.root, output, first)
        with self.assertRaisesRegex(build_site.BuildError, "under .zig-cache"):
            build_site.write_artifact(self.root, self.root / "site", first)

    def test_frontmatter_fails_instead_of_silently_losing_unknown_structure(self):
        for value in ("---\ntitle: one\ntitle: two\n---\n", "---\ntitle: >\n  folded\n---\n", "---\nunterminated"):
            with self.subTest(value=value), self.assertRaises(build_site.BuildError):
                build_site.frontmatter(value)
        metadata, body = build_site.frontmatter("---\ntitle: 'It''s quoted'\nplatforms: []\n---\nBody\n")
        self.assertEqual(metadata, {"title": "It's quoted", "platforms": []})
        self.assertEqual(body, "Body\n")


if __name__ == "__main__":
    unittest.main()
