---
id: source-archaeology
title: Source archaeology for maintained guidance
kind: pattern
status: source-verified
zig: "n/a"
summary: Anchor code and documentation to a repository revision, inspect their historical motivation and surrounding snapshot, and distinguish recovered intent from current guarantees.
updated: 2026-09-04
sources:
  - "[[matklad-always-be-blaming]]"
  - "[[karpathy-llm-wiki]]"
proofs: []
platforms:
  - cross-platform
---

# Source archaeology for maintained guidance

## Remember

Reading the current line explains only the present shape. Before turning an
implementation detail into durable guidance, recover when it appeared, what
problem its change addressed, and which surrounding files and assumptions were
true at that same revision.

Pin the whole repository snapshot, not merely a moving branch URL or copied line
number. A commit-qualified path lets an agent inspect declarations, callers,
tests, build options, and documentation as one coherent state.

## Workflow

1. Form a prediction from the problem and public contract before reading the
   implementation.
2. Compare the code with that prediction; investigate every meaningful
   difference rather than normalizing it away.
3. Pin the repository commit and inspect all relevant files at that revision.
4. Use blame and history for the logical snippet, following moves and adjacent
   changes instead of treating the current filename as the unit of history.
5. Read the introducing change, tests, issue/PR discussion when available, and
   the parent revision when the reason is unclear.
6. Record source fact, recovered rationale, inference, and current
   recommendation separately.
7. Recheck the current target version before synthesizing; historical intent is
   not a current API guarantee.

## Wiki consequence

Source records in this repository carry an immutable revision. Mutable wiki
pages cite those records and may be rewritten as understanding improves. A new
upstream revision gets a new record so an agent can compare snapshots instead
of silently changing the evidence beneath an old claim.

Code-review comments may contain essential rationale but live outside Git.
Capture the exact URL and enough locally summarized evidence to survive search
and access changes; do not imply that a commit alone contains discussion that it
does not.

Line anchors are useful for navigation inside a pinned source record, but the
wiki should name declarations and paths in its prose so harmless line movement
does not make guidance appear stale.

## Agent traps

- Blame identifies a commit, not necessarily the original motivation.
- The latest edit to a line may be formatting or movement; inspect parents.
- A historical workaround may no longer be required by Zig 0.16 or the current
  kernel.
- An author's rationale is evidence of intent, not proof that the design works.
- A current behavior observed in one backend is not an interface guarantee.

Related project documents: [agent contract](../AGENTS.md),
[curation ledger](../CURATION.md), and [[zig-0.16-baseline]].
