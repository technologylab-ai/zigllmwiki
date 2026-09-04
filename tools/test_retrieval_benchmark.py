#!/usr/bin/env python3
"""Tests for the deterministic retrieval benchmark."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools import retrieval_benchmark


class RetrievalBenchmarkTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "wiki").mkdir()
        (self.root / ".zig-version").write_text("0.16.0\n", encoding="utf-8")
        for name in ("alpha", "beta", "gamma", "noise"):
            (self.root / "wiki" / f"{name}.md").write_text(
                f"# {name}\n",
                encoding="utf-8",
            )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_dataset(self, queries: list[dict[str, object]]) -> Path:
        path = self.root / "dataset.json"
        path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "dataset_version": "test-1",
                    "zig_baseline": "0.16.0",
                    "query_limit": 5,
                    "decision_policy": {
                        "minimum_mean_reciprocal_rank": 0.8,
                        "minimum_hit_rate_at_3": 0.75,
                        "minimum_mean_recall_at_5": 1.0,
                    },
                    "queries": queries,
                }
            ),
            encoding="utf-8",
        )
        return path

    def test_metrics_and_hybrid_decision_are_deterministic(self) -> None:
        dataset = self.write_dataset(
            [
                {"id": "first", "query": "first", "relevant": ["wiki/alpha.md"]},
                {"id": "fourth", "query": "fourth", "relevant": ["wiki/beta.md"]},
            ]
        )

        def query(_: Path, text: str, __: int) -> dict[str, object]:
            paths = (
                ["wiki/alpha.md", "wiki/noise.md"]
                if text == "first"
                else [
                    "wiki/noise.md",
                    "wiki/gamma.md",
                    "wiki/alpha.md",
                    "wiki/beta.md",
                ]
            )
            return {
                "matches": [
                    {"path": path, "score": 10 - index}
                    for index, path in enumerate(paths)
                ]
            }

        report = retrieval_benchmark.benchmark_report(
            self.root,
            dataset,
            query=query,
        )

        self.assertEqual(report["metrics"]["mean_reciprocal_rank"], 0.625)
        self.assertEqual(report["metrics"]["hit_rate_at_3"], 0.5)
        self.assertEqual(report["metrics"]["mean_recall_at_5"], 1.0)
        self.assertFalse(report["decision"]["meets_policy"])
        self.assertTrue(report["decision"]["hybrid_search_justified"])
        self.assertFalse(report["mutates_repository"])

    def test_missing_relevant_page_is_rejected(self) -> None:
        dataset = self.write_dataset(
            [
                {
                    "id": "missing",
                    "query": "missing page",
                    "relevant": ["wiki/missing.md"],
                }
            ]
        )

        with self.assertRaisesRegex(
            retrieval_benchmark.BenchmarkError,
            "references missing relevant pages",
        ):
            retrieval_benchmark.benchmark_report(self.root, dataset)

    def test_dataset_baseline_must_match_repository(self) -> None:
        dataset = self.write_dataset(
            [{"id": "alpha", "query": "alpha", "relevant": ["wiki/alpha.md"]}]
        )
        value = json.loads(dataset.read_text(encoding="utf-8"))
        value["zig_baseline"] = "0.17.0"
        dataset.write_text(json.dumps(value), encoding="utf-8")

        with self.assertRaisesRegex(
            retrieval_benchmark.BenchmarkError,
            "does not match",
        ):
            retrieval_benchmark.benchmark_report(self.root, dataset)


if __name__ == "__main__":
    unittest.main()
