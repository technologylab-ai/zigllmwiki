# Zig LLM Wiki — agent contract

This repository is an LLM-maintained, source-driven wiki for Zig systems
programming. Optimize edits for accurate retrieval and application by coding
agents. Humans browse the same files in Obsidian.

## Non-negotiable baseline

- Read `.zig-version`; it is the only active Zig target. It is currently
  `0.16.0`. Do not introduce examples for master, 0.15, or an assumed future
  patch release.
- Treat installed release source for that exact compiler as the API truth.
  Official versioned release notes and standard-library documentation come
  next. Prefer OS vendor documentation for kernel/API facts and pinned primary
  project source for implementation facts.
- Distinguish the `std.Io` interface contract from behavior of a particular
  implementation such as `std.Io.Threaded`. Distinguish code present in the
  standard library from code that is feature-complete and production-ready.
- Never infer that `async` means an event loop, a new thread, or guaranteed
  parallel progress. State the implementation and resource limits involved.
- No unverified Zig snippets belong in `wiki/`. Executable examples live once
  under `proofs/` and wiki pages link to them. Fenced `zig` blocks in `wiki/`
  are rejected until a tangle-and-compile verifier exists.
- Run `zig build verify` after any content, proof, schema, or link change.

## Layers and ownership

- `sources/` contains pinned source records. Once a record is cited, do not
  rewrite its evidence or silently move its revision. Add a new record for a
  new revision. A record may point to an immutable remote revision or to a
  local artifact identified by repository commit and SHA-256.
- `wiki/` is the synthesis layer. Agents may refactor it freely while
  preserving meaning, citations, working links, and verification status.
- `proofs/` is executable evidence. Every `.zig` proof must be compiled or
  tested by `zig build verify`.
- `index.md` is the retrieval map. Keep its one-line descriptions useful; do
  not turn it into a duplicate encyclopedia.
- `log.md` is append-only. Record ingests, substantial queries saved as pages,
  lint passes that changed content, and version upgrades.
- `ROADMAP.md` owns planned work and completion criteria. Update it when work
  lands or scope changes.

## Page schema

Every file in `wiki/` starts with YAML frontmatter containing:

```yaml
---
id: stable-kebab-case-id
title: Human title
kind: concept | pattern | principle | platform | map
status: stub | draft | source-verified | runtime-verified | superseded
zig: "0.16.0" | "n/a"
summary: One retrieval-oriented sentence.
updated: YYYY-MM-DD
sources:
  - "[[source-record-filename]]"
proofs:
  - proofs/example.zig
platforms:
  - cross-platform | linux | macos | windows
---
```

`sources`, `proofs`, and `platforms` may be empty when the status permits it.
Use `source-verified` only when each factual claim is traceable to the exact
target release or another pinned primary source. Use `runtime-verified` only
when relevant proofs have run on every platform named by the claim; record the
environment and date in the page body. A compiling cross-target binary is not
runtime verification.

Each page should answer, in roughly this order:

1. What should an agent remember?
2. What is guaranteed, and by which layer?
3. What commonly goes wrong?
4. Which pattern should code use instead?
5. What evidence and runnable proofs support it?
6. Which nearby pages change or constrain the answer?

Use Obsidian wikilinks for durable conceptual links. Link claims to source records,
not merely to an unpinned moving URL. Label open questions and inferences; do
not promote them to facts through repetition.

## Operations

### Command layer and mutation boundary

`tools/wiki.py` exposes deterministic `query`, `ingest`, `lint`, `review`, and
`upgrade` wrappers. Use `--format json` for agents and automation; its schema is
versioned and every result declares `mutates_repository`.

- `query` is read-only and ranks relevant wiki pages together with their listed
  sources, proofs, Zig version, and platforms.
- `lint` is read-only. By default it runs `zig build verify` and returns stable
  issue codes, including broken evidence and stale-version findings.
- `ingest` is plan-only. It screens obvious moving revision names, reports
  whether the revision merely resembles a full content identifier, hashes
  local input, finds related pages, and proposes a record. It does not contact
  the origin or prove immutability; the agent must confirm the revision before
  performing the full ingest workflow below as reviewable edits.
- `upgrade` is plan-only. It inventories invalidation and verification work but
  never changes `.zig-version`; the explicit upgrade workflow remains the only
  authority to do that.
- `review` is read-only and networked. It reports coarse upstream-head
  differences and newer Zig release candidates; neither is permission to
  rewrite an immutable source record or change `.zig-version`.

Run `python3 tools/retrieval_benchmark.py --enforce-policy` after changing the
index or query ranking. Its reviewed cases are a regression set, not production
telemetry or proof that lexical retrieval will remain sufficient.

Read `docs/platform-testing.md` before adding or promoting macOS, Linux, or
Windows evidence. It owns the remote-run commands, host metadata requirements,
hosted artifact boundaries, and known cross-platform test traps.

Both `omarx1` (Linux) and `maxross` (the user's M3 Max Mac) are authoring hosts.
Prefer the Mac for resource-heavy portable work; from Linux, reach it with
`ssh maxross`. If the Mac is unavailable during travel, continue feasible work
on `omarx1` with parallelism suited to its resources. Follow the runbook's host
selection and checkout rules. Native platform gates still require their OS;
record unavailable gates as pending rather than substituting cross-compilation.

During the user-directed M4 performance-tuning phase (2026-09-05), use macOS
and Linux gates and defer repeated Windows measurements/publication runs for
HTTP-only changes. The current HTTP server has no Windows adapter. Preserve
existing Windows receipts; resume Windows verification for explicitly resumed
Windows work or new Windows evidence, following the runbook. Never relabel a
pending Windows claim as tested because older unrelated proofs passed.

Do not turn plan output into unattended content mutation. A wrapper can check
structure and state, but cannot establish that a synthesis follows its primary
evidence or that a platform behavior was runtime-verified.

### Query

Read `index.md`, search the vault, then open the smallest relevant page set and
its evidence. Answer with page citations and the exact Zig/platform scope. Do
not edit unless the user asks to preserve a useful synthesis. If preserved,
run the ingest workflow for that synthesis.

### Ingest

1. Identify and pin the source. Create a source record before synthesis.
2. Search for pages whose claims the source supports, narrows, or contradicts.
3. Update existing pages before creating overlapping ones. Add reciprocal
   conceptual links where they improve retrieval.
4. Move all runnable Zig into `proofs/`, register it in `build.zig`, and run
   `zig build verify` with the exact `.zig-version` compiler.
5. Update `index.md`, append `log.md`, and update `ROADMAP.md` when applicable.

Never paste an old Zig example into the wiki and call it historical. If its
idea remains useful, port it to the active release and prove it first. The old
form may remain only in the immutable source layer, clearly marked as source
material rather than guidance.

### Lint

Run `zig build verify`, then perform a semantic pass for:

- contradictions or backend assumptions presented as interface guarantees;
- pages verified against a different Zig version;
- stale moving-branch citations, broken links, duplicates, and orphans;
- platform claims without platform evidence;
- TigerStyle advice copied as slogans without its operational consequence;
- missing limits, cancellation ownership, allocation behavior, or failure
  handling in systems patterns.

### Upgrade Zig

Only change `.zig-version` when explicitly performing a release upgrade. Add
the new release sources without overwriting old evidence, inventory every page
and proof carrying the prior version, compile all proofs with the new compiler,
and remove `*-verified` status wherever evidence no longer holds. Migrate useful
examples, update cross-links and the index, then append one upgrade entry to the
log with the exact compiler version and remaining gaps.

### Shared measurement hosts

Before benchmarks, heavy builds or runtime suites on maxross or omarx1, acquire
the host-local `/tmp/zig-http-measurement.lock` directory atomically. Hold off
when another agent owns it or measurement processes predate the protocol.
Record owner metadata, retain the lock through child cleanup, and release only
your own reservation. See `docs/platform-testing.md` for the full protocol.

## TigerStyle integration

Treat TigerStyle as a design system, not a decorative checklist. Connect each
principle to concrete Zig and OS choices: explicit limits, assertion placement,
allocation lifetime, control/data-plane separation, batching, cancellation,
resource ownership, and failure behavior. Where strict TigerStyle conflicts
with a standard-library implementation, document the seam instead of hiding it.
