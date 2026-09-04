#!/usr/bin/env python3
"""Evaluate deterministic wiki query retrieval against reviewed relevance cases."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Callable, Sequence


DEFAULT_ROOT = Path(__file__).resolve().parents[1]
if str(DEFAULT_ROOT) not in sys.path:
    sys.path.insert(0, str(DEFAULT_ROOT))

from tools import wiki  # noqa: E402


Query = Callable[[Path, str, int], dict[str, object]]


class BenchmarkError(Exception):
    """The benchmark fixture or query result is malformed."""


def load_dataset(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise BenchmarkError(f"unable to load benchmark dataset {path}: {error}") from error
    if not isinstance(value, dict):
        raise BenchmarkError("benchmark dataset root must be an object")
    if value.get("schema_version") != 1:
        raise BenchmarkError("benchmark dataset schema_version must be 1")
    return value


def policy_number(policy: dict[str, object], key: str) -> float:
    value = policy.get(key)
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise BenchmarkError(f"decision_policy.{key} must be a number")
    result = float(value)
    if result < 0.0 or result > 1.0:
        raise BenchmarkError(f"decision_policy.{key} must be between zero and one")
    return result


def rounded(value: float) -> float:
    return round(value, 6)


def benchmark_report(
    root: Path,
    dataset_path: Path,
    query: Query = wiki.query_report,
) -> dict[str, object]:
    dataset = load_dataset(dataset_path)
    baseline = (root / ".zig-version").read_text(encoding="utf-8").strip()
    if dataset.get("zig_baseline") != baseline:
        raise BenchmarkError(
            f"dataset baseline {dataset.get('zig_baseline')!r} does not match {baseline!r}"
        )
    limit = dataset.get("query_limit")
    if not isinstance(limit, int) or isinstance(limit, bool) or limit < 5 or limit > 100:
        raise BenchmarkError("query_limit must be an integer between 5 and 100")
    policy = dataset.get("decision_policy")
    if not isinstance(policy, dict):
        raise BenchmarkError("decision_policy must be an object")
    thresholds = {
        "mean_reciprocal_rank": policy_number(policy, "minimum_mean_reciprocal_rank"),
        "hit_rate_at_3": policy_number(policy, "minimum_hit_rate_at_3"),
        "mean_recall_at_5": policy_number(policy, "minimum_mean_recall_at_5"),
    }
    queries = dataset.get("queries")
    if not isinstance(queries, list) or not queries:
        raise BenchmarkError("queries must be a non-empty array")

    seen_ids: set[str] = set()
    cases: list[dict[str, object]] = []
    for case in queries:
        if not isinstance(case, dict):
            raise BenchmarkError("every benchmark query must be an object")
        case_id = case.get("id")
        query_text = case.get("query")
        relevant = case.get("relevant")
        if not isinstance(case_id, str) or not case_id:
            raise BenchmarkError("every benchmark query needs a non-empty id")
        if case_id in seen_ids:
            raise BenchmarkError(f"duplicate benchmark query id {case_id!r}")
        seen_ids.add(case_id)
        if not isinstance(query_text, str) or not query_text.strip():
            raise BenchmarkError(f"query {case_id!r} has no query text")
        if not isinstance(relevant, list) or not relevant:
            raise BenchmarkError(f"query {case_id!r} has no relevant pages")
        if not all(isinstance(path, str) for path in relevant):
            raise BenchmarkError(f"query {case_id!r} has a non-string relevant path")
        missing = [path for path in relevant if not (root / path).is_file()]
        if missing:
            raise BenchmarkError(
                f"query {case_id!r} references missing relevant pages: {', '.join(missing)}"
            )

        query_result = query(root, query_text, limit)
        matches = query_result.get("matches")
        if not isinstance(matches, list):
            raise BenchmarkError(f"query layer returned no matches array for {case_id!r}")
        retrieved: list[str] = []
        top_matches: list[dict[str, object]] = []
        for match in matches:
            if not isinstance(match, dict) or not isinstance(match.get("path"), str):
                raise BenchmarkError(f"query layer returned a malformed match for {case_id!r}")
            path = str(match["path"])
            retrieved.append(path)
            top_matches.append({"path": path, "score": match.get("score")})

        relevant_set = set(relevant)
        relevant_ranks = [
            index
            for index, path in enumerate(retrieved, start=1)
            if path in relevant_set
        ]
        first_rank = min(relevant_ranks) if relevant_ranks else None
        recall_at_5 = len(relevant_set.intersection(retrieved[:5])) / len(relevant_set)
        cases.append(
            {
                "id": case_id,
                "category": case.get("category", ""),
                "query": query_text,
                "relevant": relevant,
                "first_relevant_rank": first_rank,
                "reciprocal_rank": rounded(0.0 if first_rank is None else 1.0 / first_rank),
                "hit_at_1": first_rank is not None and first_rank <= 1,
                "hit_at_3": first_rank is not None and first_rank <= 3,
                "hit_at_5": first_rank is not None and first_rank <= 5,
                "recall_at_5": rounded(recall_at_5),
                "top_matches": top_matches,
            }
        )

    count = len(cases)
    metrics = {
        "query_count": count,
        "mean_reciprocal_rank": rounded(
            sum(float(case["reciprocal_rank"]) for case in cases) / count
        ),
        "hit_rate_at_1": rounded(sum(bool(case["hit_at_1"]) for case in cases) / count),
        "hit_rate_at_3": rounded(sum(bool(case["hit_at_3"]) for case in cases) / count),
        "hit_rate_at_5": rounded(sum(bool(case["hit_at_5"]) for case in cases) / count),
        "mean_recall_at_5": rounded(
            sum(float(case["recall_at_5"]) for case in cases) / count
        ),
    }
    checks = {
        name: float(metrics[name]) >= minimum
        for name, minimum in thresholds.items()
    }
    meets_policy = all(checks.values())
    misses = [str(case["id"]) for case in cases if not case["hit_at_5"]]
    return {
        "schema_version": 1,
        "command": "retrieval-benchmark",
        "ok": True,
        "mutates_repository": False,
        "zig_baseline": baseline,
        "dataset": dataset_path.relative_to(root).as_posix(),
        "dataset_version": dataset.get("dataset_version"),
        "query_layer": "tools/wiki.py query: deterministic lexical ranking plus index boost",
        "metrics": metrics,
        "decision": {
            "thresholds": thresholds,
            "checks": checks,
            "meets_policy": meets_policy,
            "hybrid_search_justified": not meets_policy,
            "recommendation": (
                "keep-index-and-lexical-query"
                if meets_policy
                else "evaluate-hybrid-retrieval-on-the-failed-cases"
            ),
            "queries_without_a_relevant_top_5_result": misses,
        },
        "cases": cases,
    }


def print_text(report: dict[str, object]) -> None:
    metrics = report["metrics"]
    decision = report["decision"]
    assert isinstance(metrics, dict)
    assert isinstance(decision, dict)
    print(
        f"{metrics['query_count']} queries: MRR={metrics['mean_reciprocal_rank']}, "
        f"hit@3={metrics['hit_rate_at_3']}, recall@5={metrics['mean_recall_at_5']}"
    )
    print(
        f"policy met: {str(decision['meets_policy']).lower()}; "
        f"recommendation: {decision['recommendation']}"
    )


def parser() -> argparse.ArgumentParser:
    command = argparse.ArgumentParser(description=__doc__)
    command.add_argument("--root", default=str(DEFAULT_ROOT))
    command.add_argument(
        "--dataset",
        default="benchmarks/retrieval_queries.json",
        help="dataset path relative to the repository root",
    )
    command.add_argument("--format", choices=("text", "json"), default="text")
    command.add_argument(
        "--enforce-policy",
        action="store_true",
        help="exit with status 1 when the reviewed retrieval threshold is missed",
    )
    return command


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = Path(args.root).resolve()
    dataset_path = Path(args.dataset)
    if not dataset_path.is_absolute():
        dataset_path = root / dataset_path
    try:
        report = benchmark_report(root, dataset_path)
    except (BenchmarkError, OSError) as error:
        report = {
            "schema_version": 1,
            "command": "retrieval-benchmark",
            "ok": False,
            "mutates_repository": False,
            "issues": [
                {
                    "code": "INVALID_BENCHMARK",
                    "category": "benchmark",
                    "severity": "error",
                    "message": str(error),
                }
            ],
        }
        if args.format == "json":
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            print(f"retrieval benchmark failed: {error}", file=sys.stderr)
        return 2
    if args.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    decision = report["decision"]
    assert isinstance(decision, dict)
    if args.enforce_policy and not decision["meets_policy"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
