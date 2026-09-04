---
id: tigerstyle-coverage
title: TigerStyle principle coverage
kind: map
status: source-verified
zig: "0.16.0"
summary: Rule-by-rule inventory showing which TigerStyle principles have focused Zig 0.16 guidance and which still need synthesis or proof.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[matklad-size-matters]]"
proofs: []
platforms:
  - cross-platform
---

# TigerStyle principle coverage

## Status meaning

- **Covered:** focused guidance exists and any code claim has an executable
  Zig 0.16 proof.
- **Partial:** the rule is represented, but an applied page, counterexample, or
  proof named in the target column is still required.
- **Missing:** only the pinned source currently explains the rule. The target
  is planned, not an existing wikilink.

This inventory is complete for TigerStyle at commit
`47aeb2212a255273dda508288412e537d11e4b7c`. “Inventory complete” does not mean
"all guidance complete." The current tally is 71 covered, 0 partial, and 0
missing principles.

## Design stance

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Order goals as safety, performance, then developer experience. | covered | [[tigerstyle]] |
| Treat simplicity as a disciplined revision that advances all three goals. | covered | [[design-revision-and-exception-policy]] requires explicit ownership, failure, bounds, arithmetic, alternatives, and falsification passes before implementation. |
| Spend design effort before implementation and operations make change expensive. | covered | [[design-revision-and-exception-policy]] supplies a one-page design-sketch template and replaceable revision sequence; [[source-archaeology]] preserves the accepted why. |
| Do not knowingly carry technical debt that violates the design goals. | covered | [[design-revision-and-exception-policy]] makes known correctness/safety debt a release blocker and gives non-strict seams an owned bounded-exception record. |

## Safety

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Use simple explicit control flow, avoid recursion, and keep abstractions few and domain-shaped. | covered | [[function-shape-and-control-flow]] and its fixed-stack/visit-budget traversal proof. |
| Put a fixed upper bound on loops, queues, and real resources; assert intentionally infinite loops. | covered | [[static-allocation-and-constant-work]] and the bounded-progress proof in [[invariants-and-assertions]]. |
| Prefer explicitly sized domain integers and avoid automatic `usize` modeling. | covered | [[integer-widths-and-boundaries]] and its checked-conversion proof; [[newtype-indexes]] for typed handles. |
| Separate expected operational errors from programmer defects; stop on corrupt invariants. | covered | [[error-handling-and-diagnostics]]. |
| Assert arguments, returns, preconditions, postconditions, and invariants; maintain high assertion density. | covered | [[invariants-and-assertions]] and its Zig 0.16 proof. |
| Pair one property's assertions on independent paths, such as before write and after read. | covered | [[invariants-and-assertions]] and its persistence-boundary proof. |
| Use a blatantly true assertion as executable documentation only for a critical surprising fact. | covered | [[invariants-and-assertions]]. |
| Split compound assertions for simpler reasoning and precise failure location. | covered | [[invariants-and-assertions]]. |
| Express implication as a single-line conditional assertion. | covered | [[invariants-and-assertions]]. |
| Assert relationships among compile-time constants and important type sizes. | covered | [[newtype-indexes]] and its Zig 0.16 size proof. |
| Assert positive and negative spaces; test valid, invalid, and valid-to-invalid transitions. | covered | [[invariants-and-assertions]] proves a unique valid result and every invalid candidate; [[deterministic-simulation-testing]] scales the technique. |
| Build the mental model first; assertions and fuzzing test understanding but cannot prove absence of bugs. | covered | [[deterministic-simulation-testing]]. |
| Allocate all memory at startup; do not allocate, free, and reuse dynamically afterward. | covered | [[static-allocation-and-constant-work]]. |
| Declare variables in the smallest scope and minimize simultaneous live names. | covered | [[state-scope-and-in-place-initialization]] makes derived values short-lived and keeps distinct domains explicit. |
| Limit functions to 70 lines and prefer an inverse-hourglass shape. | covered | [[function-shape-and-control-flow]] combines the hard review bound, architectural-size caveat, applied decomposition, and review checklist. |
| Centralize branches and push repetitive mechanics into non-branching leaves. | covered | [[function-shape-and-control-flow]] and its parent/leaf batch transition proof. |
| Centralize state mutation; keep parent state local and leaf computations pure where practical. | covered | [[function-shape-and-control-flow]] keeps mutation in the controller after a narrow leaf computes its candidate delta. |
| Enable and respect the strictest compiler warnings from day one. | covered | [[build-diagnostics-and-generated-code]] records that Zig 0.16 has no general Zig-source warning level, then maps the rule to compile errors, safety modes, explicit foreign-source flags, sanitizers, target/mode matrices, and repository checks. |
| Decouple external event arrival from internal work cadence to preserve batching and work bounds. | covered | [[performance-sketches-and-batching]] gives external callbacks an eligibility role while a bounded control plane owns cadence and flush triggers. |
| Replace compound conditions and long `else if` chains with explicit nested cases. | covered | [[function-shape-and-control-flow]] and its exhaustively tested nested admission tree. |
| State invariants positively; prefer `index < count` over reasoning through negation. | covered | [[invariants-and-assertions]]. |
| Handle every error path and test non-fatal errors explicitly. | covered | [[error-path-catalogs-and-fault-injection]] defines producer/state/ownership/retry/bound/observation rows and proves exhaustive Zig 0.16 fault-tag traversal across four non-fatal paths. |
| Always record why a decision exists. | covered | [[source-archaeology]] and the source-record contract. |
| Pass library options explicitly rather than inheriting defaults that may change. | covered | [[naming-comments-and-api-shape]] and its Zig 0.16 explicit-options fixture. |

## Performance

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Consider architecture-level performance before profiling can exist. | covered | [[performance-sketches-and-batching]] supplies a falsifiable pre-implementation worksheet and worked server sketch. |
| Sketch network, disk, memory, and CPU bandwidth and latency. | covered | [[performance-sketches-and-batching]] keeps bandwidth, serialized latency, queue memory, CPU cycles, and tail latency as separate constraints. |
| Optimize slow resources first after weighting access frequency. | covered | [[performance-sketches-and-batching]] demonstrates that durability-call frequency dominates comfortable disk bandwidth. |
| Separate control and data planes so expensive assertions stay off regular hot loops. | covered | [[performance-sketches-and-batching]] defines the ownership split while retaining entry, local, and return-path invariants; its Zig 0.16 proof separates the loops. |
| Batch network, disk, memory, and CPU work to amortize overhead. | covered | [[performance-sketches-and-batching]] models each resource, finite queues, backpressure, and size/deadline/shutdown flush triggers. |
| Give CPUs predictable, sufficiently large, branch-light chunks of work. | covered | [[performance-sketches-and-batching]] and its proof feed dense bounded slices to a stand-alone data-plane loop. |
| Make machine-code intent explicit rather than depending blindly on optimization. | covered | [[build-diagnostics-and-generated-code]] provides an exact-version/target/CPU/mode inspection workflow and a reporting tool against a proved stand-alone symbol; [[trustworthy-microbenchmarks]] retains correctness and measurement boundaries. |
| Extract hot loops into functions with primitive arguments and no broad `self` dependency. | covered | The data-plane function proved by [[performance-sketches-and-batching]] accepts only dense key/value slices and has no server pointer, allocator, I/O, or callbacks. |

## Developer experience — naming and documentation

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Choose precise domain nouns and verbs. | covered | [[naming-comments-and-api-shape]] provides the domain and fully qualified name review. |
| Use `snake_case` for functions, variables, and filenames. | covered | [[naming-comments-and-api-shape]] records the strict TigerStyle overrides to Zig's callable and type-file casing. |
| Avoid abbreviations; reserve short forms for narrow mathematical contexts and interactive flags. | covered | [[naming-comments-and-api-shape]]. |
| Preserve acronym capitalization. | covered | [[naming-comments-and-api-shape]] records the explicit seam with Zig's normal acronym recasing. |
| Follow Zig's style guide for the remaining choices. | covered | [[naming-comments-and-api-shape]] uses the pinned Zig 0.16 guide and separates its overridden rules; [[steering-zig-fmt]] covers layout. |
| Put units and qualifiers last, ordered from significant to specific. | covered | [[naming-comments-and-api-shape]] and its options fixture use unit-bearing names. |
| Name allocator strategy and lifetime, such as `gpa` or `arena`, not merely its interface type. | covered | [[naming-comments-and-api-shape]] gives the naming rule; [[static-allocation-and-constant-work]] gives the lifetime consequence. |
| Prefer symmetrical related names that align visually when meaning is preserved. | covered | [[naming-comments-and-api-shape]] makes semantic precision the constraint on symmetry. |
| Prefix a unique helper/callback with its caller's name to expose call history. | covered | [[naming-comments-and-api-shape]] and the `read_sector_callback` style fixture. |
| Put callback parameters last to mirror invocation order. | covered | [[naming-comments-and-api-shape]] and the Zig 0.16 style fixture. |
| Order files top-down; put important entry points first and struct fields before nested types and methods. | covered | [[naming-comments-and-api-shape]] states the navigation rule and the style fixture follows it. |
| Do not overload one term with multiple domain meanings. | covered | [[naming-comments-and-api-shape]] gives the naming rule; [[cancellation]] applies it to cancellation, shutdown, and crash recovery. |
| Prefer names that compose naturally in documentation and derived identifiers. | covered | [[naming-comments-and-api-shape]]. |
| Use an options struct for confusable same-typed arguments and nullable literals; thread unique dependencies positionally. | covered | [[naming-comments-and-api-shape]] and the executable Zig 0.16 style fixture. |
| Write descriptive commit messages; a PR description is not durable Git history. | covered | [[source-archaeology]]. |
| Comments explain why and show the reasoning. | covered | [[naming-comments-and-api-shape]] gives the convention; [[source-archaeology]] preserves longer-lived rationale. |
| Tests explain their goal and methodology. | covered | [[naming-comments-and-api-shape]] gives the convention and its style fixture applies it. |
| Write comments as intentional prose with consistent punctuation. | covered | [[naming-comments-and-api-shape]]. |

## Developer experience — cache invalidation and state

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Avoid duplicate variables and aliases that can diverge. | covered | [[state-scope-and-in-place-initialization]] defines one-authority and derived-value rules. |
| Pass values larger than 16 bytes by `*const` when copies are not intended. | covered | [[state-scope-and-in-place-initialization]] and its proof apply the threshold while rejecting an ABI overclaim. |
| Initialize large or immovable structs in place; recognize that in-place initialization is viral. | covered | [[state-scope-and-in-place-initialization]] propagates final-address initialization through a containing object and proves pointer identity. |
| Shrink scope and the number of variables in play. | covered | [[state-scope-and-in-place-initialization]] gives boundary and loop rules without collapsing distinct domains. |
| Calculate and check values near use to reduce place-of-check/place-of-use gaps. | covered | [[state-scope-and-in-place-initialization]] applies conversion, validation, generation, and suspension rules. |
| Prefer lower-dimensional signatures and return types when they preserve the contract. | covered | [[lower-dimensional-api-contracts]] maps caller obligations to truthful result shapes and its proof uses `PipelineError!void` without erasing terminal failure or ownership state. |
| Keep functions run-to-completion so preconditions remain true; suspension changes the invariant model. | covered | [[state-scope-and-in-place-initialization]] requires task ownership, serialization, locking, or generation revalidation across suspension. |
| Zero unused buffer bytes and padding to prevent disclosure and nondeterministic representations. | covered | [[buffer-hygiene-and-division-intent]] and its proof cover full initialization, reused storage, native padding, and the secure-erasure boundary. |
| Visually group acquisition with its corresponding `defer` cleanup. | covered | [[bounded-retries-and-cleanup]] places cleanup at acquisition and treats ownership transfer as an explicit state change. |

## Developer experience — arithmetic and formatting

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Treat index, count, and byte size as distinct domains with explicit conversions. | covered | [[integer-widths-and-boundaries]] and its Zig 0.16 checked-arithmetic proof; [[newtype-indexes]] for compact handle types. |
| Express division rounding intent with exact, floor, or ceiling operations. | covered | [[buffer-hygiene-and-division-intent]] and its Zig 0.16 proof distinguish rounding, remainders, zero, signed values, and overflow. |
| Run `zig fmt`. | covered | [[steering-zig-fmt]], [[naming-comments-and-api-shape]], and repository format verification. |
| Use four-space indentation. | covered | [[naming-comments-and-api-shape]] and Zig 0.16 formatting enforce canonical indentation. |
| Limit code to 100 columns and use trailing commas to request canonical wrapping. | covered | [[steering-zig-fmt]] covers layout steering; repository lint separately enforces TigerStyle's hard 100-character ceiling for maintained Zig sources. |
| Use braces for multi-line conditionals; omit only for a single-line statement. | covered | [[naming-comments-and-api-shape]] states the strict rule and its style fixture demonstrates the braced form. |

## Dependencies and tooling

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Treat dependencies as supply-chain, safety, performance, installation, and longevity costs. | covered | [[design-revision-and-exception-policy]] defines a project acceptance gate for transitive trust, bounds, platform/install behavior, hot-path evidence, isolation, upgrades, rollback, and removal. |
| Keep the toolset small and standardize on Zig for project tooling where it reduces platform and type-system variance. | covered | [[design-revision-and-exception-policy]] records `TOOL-001`: Zig owns executable/runtime evidence while standard-library-only Python 3.10+ owns development-time Markdown and reporting, with explicit review triggers. |

## Closure and continuing audit

All 71 principles in the pinned TigerStyle revision now have focused guidance
and every local Zig code claim has Zig 0.16 evidence. This closes inventory coverage,
not automatic conformance: each concrete subsystem must still apply the design
sketch, exception/dependency gates, error catalog, platform runtime matrix, and
review checklist to its own workload and fault model.

Related: [[tigerstyle]], [[tigerbeetle-engineering-corpus]],
[[static-allocation-and-constant-work]], [[deterministic-simulation-testing]],
[[integer-widths-and-boundaries]], [[code-reading-and-mechanical-checks]],
[[trustworthy-microbenchmarks]], [[performance-sketches-and-batching]],
[[function-shape-and-control-flow]], [[naming-comments-and-api-shape]],
[[bounded-retries-and-cleanup]], [[state-scope-and-in-place-initialization]],
[[buffer-hygiene-and-division-intent]], [[tigerstyle-seams-with-zig-and-os]],
[[design-revision-and-exception-policy]],
[[build-diagnostics-and-generated-code]],
[[error-path-catalogs-and-fault-injection]],
[[lower-dimensional-api-contracts]].
