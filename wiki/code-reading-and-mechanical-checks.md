---
id: code-reading-and-mechanical-checks
title: Code reading and mechanical checks
kind: workflow
status: source-verified
zig: "0.16.0"
summary: Review whole subsystems by tracing control flow and every state mutation, then turn stable discoveries into small automated repository invariants.
updated: 2026-09-04
sources:
  - "[[matklad-look-for-bugs]]"
  - "[[matklad-mechanical-habits]]"
  - "[[matklad-always-be-blaming]]"
  - "[[source-tigerstyle]]"
proofs: []
platforms:
  - cross-platform
---

# Code reading and mechanical checks

## Remember

Review is model reconstruction, not diff proofreading. Read enough of the
subsystem to know its owners, states, transitions, invariants, and historical
constraints. Then compare that model with the proposed code.

Use two complementary traversals:

- **follow control flow:** begin at the public entry point or event-loop root,
  then follow calls as an imaginary program counter would;
- **stare at state:** identify decisive fields and search every initializer,
  mutation, queue transition, reset, and reader.

A diff becomes meaningful only inside both views. Search names work best when
the code uses stable domain terms instead of aliases that hide the same state.

## Review workflow for an agent

1. State the subsystem's purpose and externally visible contract.
2. Inventory owners, capacity limits, mutable fields, operation states, and
   trust boundaries.
3. Follow one success path and every terminal failure/cancellation path.
4. Search all writes to each decisive field; account for initialization and
   reset as writes.
5. Read callers and callees around tricky interactions, not only the changed
   function.
6. Use pinned blame and history to recover why a surprising constraint exists;
   label recovered intent separately from current behavior.
7. Write the invariant that would make the implementation correct and look for
   a path that violates or bypasses it.
8. Turn a stable, cheap, objective discovery into a test or lint rule.

Be especially suspicious of interactions: allocation beside a fallible path,
check/use separated by suspension, state duplicated under two names, completion
without ownership transfer, cleanup conditional on the happy path, and a limit
enforced after the resource is consumed.

## Mechanical-check admission rule

Automation is a means of preserving a real invariant. Add a check only when all
of these are true:

- the protected property and failure message are understandable;
- the result is deterministic and cheap enough for its chosen cadence;
- the check reduces repeated human review rather than creating routine cleanup;
- suppressions or exceptions have an explicit owner and rationale;
- the check runs through an existing obvious entry point.

A small project-specific tidy program is valuable because adding the next check
is cheap. Candidate checks include forbidden APIs, missing limits or metadata,
oversized functions, dead markers, generated-file drift, source revisions,
broken links, and unregistered proofs. Scan the tracked repository set rather
than an accidental working-directory subset when history is the thing being
protected.

This wiki's `zig build verify` is such an entry point: it checks the pinned Zig
version, Markdown schema and links, proof registration, formatting, and all
executable proofs. `zig build graph` emits deterministic link-health scores,
and [the semantic lint procedure](../tools/semantic_lint.md) turns their review
into a dated report. Link counts are triage signals, never substitutes for
checking the meaning and evidence of a recommendation.

## Process effects worth transferring

- Frequent, low-cost releases keep each change small and force the release path
  to stay healthy; the appropriate cadence is project-specific.
- Test the exact merge candidate before advancing the protected branch. A green
  ancestor or source branch is weaker evidence.
- Keep benchmark and diagnostic artifacts on ordinary build/test paths so they
  cannot quietly bit-rot.
- A static, versioned project dashboard can expose fuzzing, benchmark, release,
  and triage state without requiring an elaborate service.

Related: [[source-archaeology]], [[invariants-and-assertions]],
[[trustworthy-microbenchmarks]], [[build-diagnostics-and-generated-code]],
[[design-revision-and-exception-policy]], [[tigerstyle]].
