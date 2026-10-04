# Zig LLM Wiki

A source-driven, LLM-maintained knowledge base for writing robust systems
software with exact Zig 0.17.0.

The wiki is optimized for coding agents first and humans second. It combines
current Zig APIs, `std.Io` semantics, concurrency and cancellation, operating
system I/O facilities, and TigerStyle engineering principles. Claims should be
easy to locate, hard to misread, and backed by primary sources or executable
proofs.

## Start here

- Open this directory as an Obsidian vault, then open [[index]].
- Coding agents should read [AGENTS.md](AGENTS.md) before consulting or editing
  the wiki.
- Run `zig build verify` before accepting content changes.
- Run `tools/verify_linux_ssh.sh omarx1` for the complete Linux runtime suite.
- Dispatch `Windows runtime verification` in GitHub Actions for the exact
  Windows x64 host/proof suite and retained evidence packet. ARM64 is an
  experimental opt-in (`native_arm64_runtime=true`); its 0.17 qualification is deferred.
- Use `python3 tools/wiki.py query ...`, `lint`, plan-only `ingest`/`upgrade`,
  and read-only `review` as documented in [AGENTS.md](AGENTS.md).
- Use [ROADMAP.md](ROADMAP.md) as the persistent project plan.
- Use [CURATION.md](CURATION.md) to see which sources are merely discovered,
  pinned, synthesized, or backed by executable proof.
- Read [HANDOFF.md](HANDOFF.md) when continuing the project in a fresh agent
  session; it records exact platform evidence, deliberate decisions, and honest
  remaining gaps.
- Read the [platform testing runbook](docs/platform-testing.md) before changing
  macOS, Linux, Windows, cancellation, timing, or hosted-verification claims.

The required compiler version is recorded in [.zig-version](.zig-version).
The active baseline is Zig 0.17.0, upgraded on 2026-10-04.
Dated Zig 0.16 source records and runtime receipts preserve their original scope.

The [Zig 0.16 to 0.17 migration guide](docs/zig-0.16-to-0.17-migration.md)
records the Baz dependency ports, semantic traps, and native verification limits.
The upgrade ports current proofs and invalidates earlier verification labels before requalification.
Default verification uses Debug for correctness proofs and ReleaseSafe for the timed fixture.
The guide records the separate 0.16 ReleaseSafe macOS Dispatch baseline failure.

## Repository shape

```text
sources/            pinned source records; evidence is not rewritten
wiki/               maintained synthesis and cross-links
proofs/             executable Zig evidence referenced by wiki pages
benchmarks/          reviewed agent-retrieval regression queries
tools/               query, lint, review, benchmark, and evidence utilities
.github/workflows/   read-only scheduled review packet
.agents/skills/     repo-scoped coding-agent workflow for wiki operations
index.md             content map read before retrieval
log.md               append-only maintenance history
AGENTS.md            schema and maintenance contract
ROADMAP.md           work across content, LLM, and backend lanes
CURATION.md          transparent source-selection and ingestion ledger
HANDOFF.md           durable continuation state and platform evidence matrix
docs/platform-testing.md  macOS/Linux/Windows verification and evidence runbook
```

## Why there is no backend yet

Obsidian already supplies local Markdown browsing, full-text search, backlinks,
and an interactive graph. Building a server now would create a second concern
before the content model has earned one. The Markdown vault is the product and
the source of truth; a future web UI can consume it without changing that.

The decision and the triggers for revisiting it are recorded in
[ADR 0001](docs/decisions/0001-obsidian-first.md).
