# Independent performance review

A user-authorized max-reasoning subagent reviewed the current standalone
`e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad` source and its measured packet on
2026-09-05. This was read-only analysis: no edits, builds, benchmarks or remote
jobs. The recommendations below are queued experiments, not claimed gains.
Primary implementation and counters are pinned by
[[zig-http-response-batching-2026-09-05]]; contender inputs by
[[techempower-r23-comparison-inputs]].

## Findings and priority

The deep-pipeline counters show about 16 responses per send at every depth,
with maximum 32 spans and 2,512 submitted bytes. The 80-span capacity is not
binding. A depth-128 pipeline still requires eight serial batch sends through
one pending data operation; parsing the next group waits for batch completion.
The global 64-callback turn budget is reached in these loads.

Compaction amounts to approximately 0/24.5/73.5/171.5 bytes per response at
client depths 16/32/64/128. It cannot explain the whole plateau: depth 16 already
plateaus with zero suffix copies. This arithmetic does not quantify its CPU
cost. A later contiguous unread cursor, compacted only when receive needs space,
is a smaller experiment than immediately introducing segmented request input.

First isolate token-addressed Linux operation cells. Admission scans the entire
operation array; completion lookup stops at the matching record and therefore
does not always scan all 258 entries. Preserve separate accept/cancel-accept and
per-connection data/cancel capacity, with bounds, exact token/generation/kind
and occupied/free assertions. The existing transport accepts opaque tokens,
including arbitrary test values and missing-target cancellation. Centralize an
explicit addressing contract or pass a separate cell identity; silently decoding
private server token fields would break that abstraction. Keep close/deinit audits.

For a potentially larger single-owner gain, run a 2×2 matrix:

| Server batch limit | Global callbacks per turn |
| --- | --- |
| 16 | 64 |
| 64 | 64 |
| 16 | 256 |
| 64 | 256 |

These larger limits are not implemented today. Increase cells and gather metadata
through checked startup accounting, keeping aggregate send caps and one pending
data operation. Retain flush barriers, oldest-unsent deadlines, distinct output
cells, input borrows and terminal cancellation ownership. Measure client depth
128 first, then depth 16 as the regression control. Count turns, callbacks/turn,
SQEs/submit, CQEs/poll and responses/send to identify amortization rather than
assuming the mechanism. The current scan advances its start by one slot per
turn, so assess a cold connection among continuously ready deep pipelines before
changing defaults. A count budget still cannot preempt application code.

Then compare gathered spans with a bounded startup-reserved contiguous send
buffer for tiny responses, holding batch/quantum fixed and counting copied bytes.
This would preserve ordinary per-request callback/validation and dynamic headers;
it is not permission to cache whole responses or redefine borrowing as kernel
zero-copy. Separately test bounded literal/integer header appends and reuse of
existing callback timing samples without weakening deadline checks. The pinned
libreactor accumulates contiguous responses and flushes after ready input, but
its framing/callback/resource work is not identical to this framework.

Multiple independent I/O owners remain a later multicore experiment, with
startup-partitioned connection/operation/buffer budgets. Do not multiply a
single-owner sample by a core count and call the result measured scaling.

## Experiment discipline

Use finite alternating ABBA blocks, source/binary hashes, exact affinity,
frequency observations and CPU-level activity. The earlier seeded code-control
shuffle grouped binaries in time and could not isolate a regression. Collect
cycles/instructions per timed response when an appropriate profiler is actually
available; none was run in this iteration. Existing process CPU percentages and
short noisy samples are insufficient to attribute the fast/slow regimes.

Keep exact Zig 0.16.0 ReleaseSafe and assertions. Required gates include distinct
generated/borrowed bodies, forced partial sends, malformed-prefix order, empty
flush fairness, multi-cell slow-reader cancellation, slot reuse, startup heap
arithmetic, zero final owners and zero late allocations. Linux/macOS need their
own native gates. Larger client depths remain separate from TechEmpower's
plaintext depth 16, and corrected wrk percentiles remain unqualified.

Inspected source boundaries in the standalone project: server parse/batch/send
and completion paths, Config.heapBytes, callback scheduling/timestamps and header
formatting; Linux admission/CQE searches; common transport token tests; and raw
comparison counters. The review found no demonstrated ownership corruption and
made no claim that a particular unmeasured optimization will achieve parity.
