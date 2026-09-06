# ADR 0001: use Obsidian before building a backend

- Status: accepted
- Date: 2026-09-04

The 2026-09-06 [static publication decision](0003-static-public-wiki.md) replaces the frontend deferral below.
The repository remains canonical, and a mutable backend remains deferred.

## Decision

Use this repository itself as an Obsidian vault. Defer a custom backend and web
frontend.

## Why

The primary product is agent-optimized, cross-linked Markdown with executable
evidence. Obsidian already supplies the immediate human requirements: Markdown
browsing, full-text search, backlinks, and an interactive local/global graph.
It is also the workflow described in Andrej Karpathy's original LLM Wiki idea:
the LLM edits while the human browses the result.

A backend today would force premature choices about rendering, indexing, graph
semantics, storage, and deployment. Those choices do not improve the first hard
problem: keeping rapidly changing Zig knowledge correct.

## Consequences

- Markdown, source records, and proof files remain the source of truth.
- Obsidian-specific configuration is convenience only; agents must work with
  ordinary filesystem tools.
- Search starts with `index.md` and `rg`. No embeddings or database are needed
  until measured retrieval failures justify them.
- A future UI must derive its index from the vault and must not become an
  independent mutable content store.

## Revisit when

Revisit this decision when a concrete trigger in the Backend lane of
[ROADMAP.md](../../ROADMAP.md) is met. Prefer a read-only static/generated layer
as the first step.
