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
“all guidance complete.” The current tally is 17 covered, 30 partial, and 24
missing principles.

## Design stance

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Order goals as safety, performance, then developer experience. | covered | [[tigerstyle]] |
| Treat simplicity as a disciplined revision that advances all three goals. | partial | [[tigerstyle]]; add design-review examples. |
| Spend design effort before implementation and operations make change expensive. | partial | [[tigerstyle]], [[source-archaeology]]; add design-sketch template. |
| Do not knowingly carry technical debt that violates the design goals. | partial | [[tigerstyle]]; define exception and review policy for this wiki's projects. |

## Safety

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Use simple explicit control flow, avoid recursion, and keep abstractions few and domain-shaped. | partial | [[tigerstyle]]; add bounded traversal counterexamples. |
| Put a fixed upper bound on loops, queues, and real resources; assert intentionally infinite loops. | covered | [[static-allocation-and-constant-work]] and the bounded-progress proof in [[invariants-and-assertions]]. |
| Prefer explicitly sized domain integers and avoid automatic `usize` modeling. | partial | [[newtype-indexes]]; add integer-width and boundary-conversion page. |
| Separate expected operational errors from programmer defects; stop on corrupt invariants. | covered | [[error-handling-and-diagnostics]]. |
| Assert arguments, returns, preconditions, postconditions, and invariants; maintain high assertion density. | covered | [[invariants-and-assertions]] and its Zig 0.16 proof. |
| Pair one property's assertions on independent paths, such as before write and after read. | partial | [[tigerstyle]], [[deterministic-simulation-testing]]; add persistence-boundary proof. |
| Use a blatantly true assertion as executable documentation only for a critical surprising fact. | covered | [[invariants-and-assertions]]. |
| Split compound assertions for simpler reasoning and precise failure location. | covered | [[invariants-and-assertions]]. |
| Express implication as a single-line conditional assertion. | covered | [[invariants-and-assertions]]. |
| Assert relationships among compile-time constants and important type sizes. | covered | [[newtype-indexes]] and its Zig 0.16 size proof. |
| Assert positive and negative spaces; test valid, invalid, and valid-to-invalid transitions. | covered | [[invariants-and-assertions]] proves a unique valid result and every invalid candidate; [[deterministic-simulation-testing]] scales the technique. |
| Build the mental model first; assertions and fuzzing test understanding but cannot prove absence of bugs. | covered | [[deterministic-simulation-testing]]. |
| Allocate all memory at startup; do not allocate, free, and reuse dynamically afterward. | covered | [[static-allocation-and-constant-work]]. |
| Declare variables in the smallest scope and minimize simultaneous live names. | missing | Planned scope/cache-invalidation page. |
| Limit functions to 70 lines and prefer an inverse-hourglass shape. | partial | [[tigerstyle]]; add repository lint and refactoring examples. |
| Centralize branches and push repetitive mechanics into non-branching leaves. | partial | [[tigerstyle]] with [[matklad-push-ifs-up-fors-down]]; add applied examples. |
| Centralize state mutation; keep parent state local and leaf computations pure where practical. | partial | [[task-lifetimes-and-structured-concurrency]]; add state-transition proof. |
| Enable and respect the strictest compiler warnings from day one. | missing | Planned build-policy page; determine exact Zig 0.16 applicability. |
| Decouple external event arrival from internal work cadence to preserve batching and work bounds. | partial | [[tigerstyle]], [[io-uring]]; add bounded admission/dispatch page. |
| Replace compound conditions and long `else if` chains with explicit nested cases. | missing | Planned control-flow style page. |
| State invariants positively; prefer `index < count` over reasoning through negation. | covered | [[invariants-and-assertions]]. |
| Handle every error path and test non-fatal errors explicitly. | partial | [[error-handling-and-diagnostics]], [[cancellation]]; add fault-injection proof catalog. |
| Always record why a decision exists. | covered | [[source-archaeology]] and the source-record contract. |
| Pass library options explicitly rather than inheriting defaults that may change. | missing | Planned explicit-options page with Zig 0.16 API examples. |

## Performance

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Consider architecture-level performance before profiling can exist. | partial | [[tigerstyle]], [[tigerbeetle-engineering-corpus]]; add sketch template. |
| Sketch network, disk, memory, and CPU bandwidth and latency. | partial | [[tigerstyle]]; add quantified worksheet and worked server example. |
| Optimize slow resources first after weighting access frequency. | partial | [[tigerstyle]]; add worked hierarchy example. |
| Separate control and data planes so expensive assertions stay off regular hot loops. | partial | [[tigerbeetle-engineering-corpus]]; add focused control/data-plane page. |
| Batch network, disk, memory, and CPU work to amortize overhead. | partial | [[io-uring]], [[tigerbeetle-engineering-corpus]]; add batching/backpressure model. |
| Give CPUs predictable, sufficiently large, branch-light chunks of work. | partial | [[static-allocation-and-constant-work]]; measurement proof remains. |
| Make machine-code intent explicit rather than depending blindly on optimization. | partial | [[trustworthy-microbenchmarks]] covers runtime inputs and correctness witnesses; add generated-code inspection and a reproducible harness. |
| Extract hot loops into functions with primitive arguments and no broad `self` dependency. | missing | Planned hot-loop review pattern. |

## Developer experience — naming and documentation

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Choose precise domain nouns and verbs. | missing | Planned naming/comments page. |
| Use `snake_case` for functions, variables, and filenames. | partial | Zig formatter/build conventions; document repository policy. |
| Avoid abbreviations; reserve short forms for narrow mathematical contexts and interactive flags. | missing | Planned naming/comments page. |
| Preserve acronym capitalization. | missing | Planned naming/comments page. |
| Follow Zig's style guide for the remaining choices. | partial | [[steering-zig-fmt]]; pin the Zig 0.16 style guide. |
| Put units and qualifiers last, ordered from significant to specific. | missing | Planned naming/comments page. |
| Name allocator strategy and lifetime, such as `gpa` or `arena`, not merely its interface type. | partial | [[static-allocation-and-constant-work]]; add ownership examples. |
| Prefer symmetrical related names that align visually when meaning is preserved. | missing | Planned naming/comments page. |
| Prefix a unique helper/callback with its caller's name to expose call history. | missing | Planned callback naming page. |
| Put callback parameters last to mirror invocation order. | missing | Planned callback naming page. |
| Order files top-down; put important entry points first and struct fields before nested types and methods. | partial | [[newtype-indexes]], [[steering-zig-fmt]]; add file-shape page. |
| Do not overload one term with multiple domain meanings. | covered | [[cancellation]] establishes separate vocabulary for cancellation, shutdown, and crash recovery. |
| Prefer names that compose naturally in documentation and derived identifiers. | missing | Planned naming/comments page. |
| Use an options struct for confusable same-typed arguments and nullable literals; thread unique dependencies positionally. | missing | Planned API-shape page. |
| Write descriptive commit messages; a PR description is not durable Git history. | covered | [[source-archaeology]]. |
| Comments explain why and show the reasoning. | partial | [[source-archaeology]]; add naming/comments page. |
| Tests explain their goal and methodology. | partial | [[invariants-and-assertions]] documents its proof shape; add a repository-wide test-documentation convention. |
| Write comments as intentional prose with consistent punctuation. | missing | Planned naming/comments page. |

## Developer experience — cache invalidation and state

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Avoid duplicate variables and aliases that can diverge. | missing | Planned scope/cache-invalidation page. |
| Pass values larger than 16 bytes by `*const` when copies are not intended. | missing | Planned Zig 0.16 ABI/copy-semantics proof. |
| Initialize large or immovable structs in place; recognize that in-place initialization is viral. | missing | Planned pointer-stability page and proof. |
| Shrink scope and the number of variables in play. | missing | Planned scope/cache-invalidation page. |
| Calculate and check values near use to reduce place-of-check/place-of-use gaps. | missing | Planned scope/cache-invalidation page. |
| Prefer lower-dimensional signatures and return types when they preserve the contract. | partial | [[error-handling-and-diagnostics]] covers error-set dimensionality; general API page remains. |
| Keep functions run-to-completion so preconditions remain true; suspension changes the invariant model. | partial | [[task-lifetimes-and-structured-concurrency]] serialized-callback rules. |
| Zero unused buffer bytes and padding to prevent disclosure and nondeterministic representations. | missing | Planned buffer-boundary and serialization proof. |
| Visually group acquisition with its corresponding `defer` cleanup. | missing | Planned resource-lifetime style page. |

## Developer experience — arithmetic and formatting

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Treat index, count, and byte size as distinct domains with explicit conversions. | partial | [[newtype-indexes]]; add count/size types and checked arithmetic. |
| Express division rounding intent with exact, floor, or ceiling operations. | missing | Planned integer-arithmetic proof. |
| Run `zig fmt`. | covered | [[steering-zig-fmt]] and repository format verification. |
| Use four-space indentation. | covered | Enforced by Zig 0.16 formatting. |
| Limit code to 100 columns and use trailing commas to request canonical wrapping. | partial | [[steering-zig-fmt]]; add a line-length lint rule. |
| Use braces for multi-line conditionals; omit only for a single-line statement. | missing | Planned control-flow style page/lint. |

## Dependencies and tooling

| Principle | Coverage | Current guidance / target |
| --- | --- | --- |
| Treat dependencies as supply-chain, safety, performance, installation, and longevity costs. | partial | [[tigerbeetle-engineering-corpus]]; define project-specific acceptance criteria rather than blindly copying zero-dependency policy. |
| Keep the toolset small and standardize on Zig for project tooling where it reduces platform and type-system variance. | partial | This repository uses Zig for proof orchestration but still uses Python for Markdown linting; record this as a deliberate seam, not strict compliance. |

## Next closure order

The highest-value gaps for systems work are assertions/negative space,
integer-width and index/count/size boundaries, resource lifetime and in-place
initialization, explicit options, and the performance-sketch/control-data-plane
pair. M2 tracks these as separate deliverables; this page prevents the remaining
naming and formatting rules from disappearing behind the larger themes.

Related: [[tigerstyle]], [[tigerbeetle-engineering-corpus]],
[[static-allocation-and-constant-work]], [[deterministic-simulation-testing]],
[[code-reading-and-mechanical-checks]], [[trustworthy-microbenchmarks]].
