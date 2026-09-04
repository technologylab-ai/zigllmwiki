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

## TigerStyle integration

Treat TigerStyle as a design system, not a decorative checklist. Connect each
principle to concrete Zig and OS choices: explicit limits, assertion placement,
allocation lifetime, control/data-plane separation, batching, cancellation,
resource ownership, and failure behavior. Where strict TigerStyle conflicts
with a standard-library implementation, document the seam instead of hiding it.
