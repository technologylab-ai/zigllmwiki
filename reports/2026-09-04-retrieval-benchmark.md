# Retrieval benchmark decision — 2026-09-04

## Decision

Do not add hybrid or embedding search yet. Keep the current deterministic
`index.md` plus lexical ranking in `tools/wiki.py query` as the default agent
retrieval path.

This is a decision about the current vault and benchmark, not a claim that
lexical retrieval will remain sufficient as the corpus grows.

## Evidence

The reviewed dataset in `benchmarks/retrieval_queries.json` contains 25 agent
questions across `std.Io`, concurrency, Linux, macOS, Windows, TigerStyle,
diagnostics, testing, and Zig mechanics. It is pinned to Zig `0.16.0` and
versioned as `2026-09-04.1`.

The deterministic run on 2026-09-04 produced:

| Metric | Result | Policy minimum |
| --- | ---: | ---: |
| Mean reciprocal rank | 1.000 | 0.850 |
| Hit rate at 3 | 1.000 | 0.950 |
| Mean recall at 5 | 0.980 | 0.850 |

Every query placed at least one reviewed relevant page first. The only partial
recall result was `sleep-deadline`: its primary time/deadline page ranked first,
while the secondary async/concurrency page ranked seventh and therefore fell
outside recall@5. There were no queries without a relevant result in the top
five.

Reproduce the result with:

```text
PYTHONDONTWRITEBYTECODE=1 python3 tools/retrieval_benchmark.py --format text --enforce-policy
```

The scheduled read-only review also records the complete JSON result as an
artifact, so threshold regressions are visible without modifying the wiki.

## Limits and reconsideration triggers

The dataset is a reviewed in-vault sample, not production query telemetry. It
does not yet cover multilingual questions, misspellings, deliberately vague
prompts, unseen terminology, retrieval latency, or the quality of an alternative
hybrid implementation. Relevance labels have not had independent multi-reviewer
adjudication.

Re-evaluate hybrid retrieval when any of these occurs:

- a benchmark policy threshold fails;
- real coding-agent queries repeatedly miss known pages;
- corpus growth creates ambiguous lexical matches;
- a larger adversarial/paraphrase dataset exposes vocabulary mismatch; or
- a candidate hybrid implementation can be compared on the same fixed dataset,
  including determinism, latency, storage, and offline-operation costs.

Until then, hybrid search would add operational state and ranking opacity without
an observed retrieval failure to solve.
