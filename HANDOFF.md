# Project handoff — 2026-09-04

This is the durable continuation note for a fresh coding-agent session. The
repository itself is the source of truth; this file explains where to enter it
and which gaps must not be mistaken for completed work.

## State at handoff

The repository is a usable Obsidian-first, agent-first Zig 0.16.0 systems
knowledge base. M0 (trustworthy foundation), M2 (TigerStyle in Zig), and the
cross-platform M3 decision synthesis are complete. M1 covers the public
`std.Io` field-guide surface targeted by the roadmap, including blocked-call
cancellation on macOS, Linux, and Windows. The exact Windows implementation
mapping and synchronous cancellation harness ran, but custom IOCP and broader
APC/device/load behavior remain unproved.

The active compiler is exactly the value in `.zig-version`: `0.16.0`. Do not
silently follow Zig master, 0.15 examples, or a future 0.16 patch. The installed
release source is API truth.

## First five minutes of a new session

1. Read `AGENTS.md` completely, then `.agents/skills/zig-wiki/SKILL.md`.
2. Read `.zig-version`, `index.md`, `ROADMAP.md`, and `CURATION.md`.
3. Run `git status --short`; preserve any user changes.
4. Run `zig version` and require the exact `.zig-version` value.
5. Run `zig build verify` before relying on the checkout.

For a focused lookup, use:

`python3 tools/wiki.py query async sleep timeout --format json`

For a machine-readable health check, use:

`python3 tools/wiki.py lint --format json`

For a bounded, read-only network review of pinned-source heads and new Zig
releases, use:

`python3 tools/wiki.py review --format json`

Protect the current retrieval behavior with:

`PYTHONDONTWRITEBYTECODE=1 python3 tools/retrieval_benchmark.py --enforce-policy`

The `ingest` and `upgrade` subcommands are intentionally plan-only. They never
write knowledge or change `.zig-version`; an agent applies a reviewed plan and
runs the full workflow in `AGENTS.md`.

## Evidence and editing contract

- `sources/` contains pinned primary evidence. Once cited, preserve the record
  and add a new record for a new revision.
- `wiki/` is synthesized guidance. Every page declares Zig/platform scope,
  sources, and proofs in frontmatter.
- `proofs/` is the only home for runnable Zig. Do not paste fenced Zig into the
  wiki. Register every proof in `build.zig`.
- `index.md` is the retrieval map, `CURATION.md` is source-pipeline truth,
  `ROADMAP.md` is work/status truth, and `log.md` is append-only history.
- `source-verified` is not runtime evidence. Cross-compilation is not runtime
  evidence. Runtime status names the OS, environment, and date.
- Keep the `std.Io` interface separate from `std.Io.Threaded`, experimental
  evented implementations, and custom OS backends. `async` does not guarantee
  a thread, event loop, or concurrent progress.

## Maintenance automation and retrieval

`.github/workflows/wiki-review.yml` runs weekly and on manual dispatch with
read-only repository permission. It downloads the exact `.zig-version`
compiler from Zig's official index, checks the archive SHA-256, runs the full
verifier and Python tests, performs the network review and retrieval benchmark,
asserts that maintenance did not mutate the checkout, and retains an
out-of-tree review packet for 30 days.

The first green hosted gates are
[read-only review run 33911520101](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911520101)
and [Windows run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858).
The latter completed the full verifier with 70/70 build steps, 67 passing tests,
and 7 intentional platform skips before rerunning both Windows-specific proofs.

That workflow intentionally cannot edit content or open a pull request. L-009
in `ROADMAP.md` reserves that job for a separately authorized coding-agent
consumer. A source-head difference is only a review prompt, not evidence that
the pinned record or its synthesis is stale.

The reviewed 25-query dataset currently reports MRR 1.0, hit@3 1.0, and
recall@5 0.98. This supports the current `index.md` plus deterministic lexical
ranking; it is not production telemetry. The dated decision and reconsideration
triggers are in `reports/2026-09-04-retrieval-benchmark.md`.

## Major completed content

- Exact Zig 0.16 baseline, release-note inventory, process initialization and
  capability threading.
- `Future`, `Group`, `Select`, `Batch`, synchronization primitives, clocks,
  deadlines, files, buffering, atomic publication, networking, DNS, child
  processes, entropy, testing I/O, and error diagnostics.
- The requested matklad systems/Zig essays plus a larger selected corpus on
  invariants, cancellation, structured concurrency, retries, allocation,
  representation lifetime, benchmarking, source archaeology, and control-flow
  shape.
- TigerStyle rule inventory: all 71 principles have focused applied guidance;
  code-bearing claims link to registered Zig 0.16 proofs.
- Linux `io_uring`, macOS kqueue/Dispatch/AIO, Windows IOCP/overlapped design,
  exact shipped Zig backend mappings, and one cross-platform decision table.

Start platform design with `wiki/platform-io-backend-decision-table.md`, not
with an assumption that one “evented” label has portable semantics.

## Platform evidence matrix

| Platform | What actually ran | What did not run |
| --- | --- | --- |
| macOS arm64 | Full local verification; Threaded task/cancellation proofs; blocked pipe-read interruption; Dispatch I/O adapter and experimental Dispatch mapping; all portable proofs. | Product kqueue reactor/load tests, cold-storage matrix, Dispatch cancellation/write/durability matrix. |
| Linux x86_64 (`ssh omarx1`) | Zig 0.16.0 blocked pipe-read cancellation; low-level `io_uring` finite SQ/probing, registered file+buffer lifetime, and target/cancel CQE reconciliation. | Older kernels, other filesystems/devices, resource tags, multishot behavior, high-level `std.Io.Uring` readiness, and decision-grade load measurements. |
| Windows Server 2025 Datacenter 24H2, x86_64, build 26100.33296 | Full verification plus native mapping and synchronous blocked-read cancellation ran with Zig 0.16.0; both Windows harnesses also compile for x86, x86_64, and aarch64. | APC races, batch/device cancellation breadth, custom IOCP immediate-success/cancel/shutdown paths, and load evidence. |

Rerun the complete current tree on Linux with:

`tools/verify_linux_ssh.sh omarx1`

The script copies the checkout to a validated temporary directory, runs the
full verifier with the remote `zig`, reports kernel/`io_uring` state, and cleans
up that directory. It does not alter the remote user's checkout.

For exact commands, hosted Windows dispatch/artifacts, evidence-promotion
rules, and known CRLF, shell, timer, token-scope, and platform-interpretation
traps, read `docs/platform-testing.md` before changing any platform claim.

## Deliberate decisions

- Obsidian remains the human backend. The Markdown vault is the product and
  only content store. `docs/decisions/0001-obsidian-first.md` lists the triggers
  for reconsidering a read-only generated site.
- Python 3.10+ standard-library tools own Markdown parsing, deterministic JSON,
  hashes, graph checks, and inspection reports. Zig owns build orchestration,
  executable claims, target compilation, and runtime evidence. This is the
  documented `TOOL-001` exception, not accidental tool sprawl.
- Zig 0.16's shipped `std.Io.Threaded` is the portable, feature-complete default
  but allocates task state and may grow workers. The experimental high-level
  Uring/Kqueue/Dispatch implementations are not presented as production-ready.
- Zig 0.16 Windows `std.Io.Threaded` is not IOCP: it combines synchronous worker
  I/O with selected APC-based NtDll/AFD paths. A custom IOCP backend has a
  separate stable-`OVERLAPPED` ownership contract.

## Honest remaining work

1. Extend the established Windows runner from synchronous Threaded
   cancellation into watchdog-backed APC/batch/device and custom IOCP lifecycle
   and load evidence before promoting those broader claims.
2. Extend the platform performance matrix only for a concrete workload,
   hardware, filesystem/device, queue depth, and correctness witness.
3. Continue selected TigerBeetle storage/recovery/operations ingestion by a
   named design question; do not bulk-summarize documentation.
4. Revisit a web backend only when an ADR trigger is real.
5. Build the TigerStyle evented HTTP server in a dedicated project; feed its
   reusable decisions, proofs, and postmortems back into this wiki.
6. Connect a separately authorized agent to the scheduled review packet if
   automatic review PRs become desirable; do not give the existing read-only
   workflow write authority merely to collapse those responsibilities.

No agent should describe these items as “running” unless an agent or runner is
actually executing them. Update `ROADMAP.md` at assignment and handoff
boundaries.

## Git and publication

The canonical repository is the private GitHub repository
`technologylab-ai/zigllmwiki`, on branch `main`. Confirm `git remote -v` after
cloning and inspect the most recent `Zig wiki read-only review` run before
trusting hosted automation. No credentials or platform secrets belong in this
repository.
