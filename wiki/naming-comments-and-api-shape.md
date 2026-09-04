---
id: naming-comments-and-api-shape
title: TigerStyle naming, comments, and API shape
kind: pattern
status: source-verified
zig: "0.16.0"
summary: Make Zig systems code auditable through domain names, explicit options, callback order, top-down files, intentional comments, and a declared TigerStyle naming profile.
updated: 2026-09-04
sources:
  - "[[source-tigerstyle]]"
  - "[[zig-0.16.0-style-guide]]"
  - "[[matklad-steering-zig-fmt]]"
proofs:
  - proofs/fmt_steering.zig
platforms:
  - cross-platform
---

# TigerStyle naming, comments, and API shape

## Remember

Names and signatures are part of the safety model. They should expose the
domain, units, ownership strategy, confusable choices, and callback flow at the
point where an agent reviews a call.

Declare which naming profile a project follows. A strict TigerStyle project
does not exactly follow every Zig 0.16 style-guide recommendation. Do not mix
the profiles accidentally, and do not rename standard-library or third-party
APIs at their call sites to disguise the seam.

## Which layer guarantees what?

| Layer | Guarantee or recommendation |
| --- | --- |
| Zig 0.16 compiler | Accepts identifiers and API shapes that obey the language grammar; it does not enforce the style guide. |
| `zig fmt` 0.16.0 | Produces canonical whitespace and preserves supported layout cues; it does not choose names, comments, file order, API dimensions, or a hard line-length policy. |
| Zig 0.16 style guide | Recommends namespace-aware, non-redundant names; casing by declaration kind; four-space indentation; and specific doc-comment vocabulary. |
| Pinned TigerStyle | Adds stricter project rules for naming, API shape, callbacks, file order, comments, line length, and explicit call-site options. |

### Resolve the naming conflicts explicitly

For code governed by strict TigerStyle, use the TigerStyle choice where its
rule conflicts with the more general Zig guide:

| Subject | Zig 0.16 guide | Strict TigerStyle profile |
| --- | --- | --- |
| Callable | `camelCase` ordinarily; `TitleCase` when it returns a type | `snake_case`, including type-producing functions |
| File representing a type | `TitleCase.zig` | `snake_case.zig` for every file |
| Acronym inside an identifier | Apply normal identifier casing, such as `XmlParser` | Preserve the acronym, such as `XMLParser` |
| Line length | Aim for 100 columns and use judgment | Hard maximum of 100 columns |

Use Zig's declaration-kind rules for choices TigerStyle does not override:
types remain `TitleCase`, variables remain `snake_case`, and namespaces remain
`snake_case`. Under the strict acronym rule, a type can therefore be named
`HTTPServer`. The compiler and formatter accept either profile; repository
policy and review enforce the choice.

## Make names carry the model

- Choose exact domain nouns and verbs. Read the fully qualified name and a
  representative call aloud; remove a segment that merely repeats its
  namespace.
- Avoid generic type names such as `Value`, `Data`, `Context`, `Manager`, or
  `State` when they communicate nothing specific. Do not hide privacy,
  reflection, or versioning semantics behind an underscore prefix; use the type
  system, a precise name, and documentation.
- Avoid abbreviations except for narrow integer variables in sorting or matrix
  work. Prefer long command-line flags in scripts; reserve short flags for
  interactive use.
- Put units and qualifiers last, from most significant to most specific. Names
  such as `latency_ms_max` group naturally with `latency_ms_min` and keep the
  measurement domain visible.
- Name allocator strategy and lifetime rather than only its interface type.
  `gpa`, `arena`, `static_pool`, and similarly precise names tell the reviewer
  which cleanup and reuse rules to expect.
- Prefer symmetric related names when meaning is preserved: `source` and
  `target` make derived names and calculations easier to compare than unrelated
  abbreviations.
- Give one domain term one meaning. Prefer nouns that also work in prose,
  headings, logs, metrics, and derived identifiers.

These rules optimize review and retrieval, not alignment for its own sake. Do
not choose equal-length names that blur a real distinction.

## Shape APIs for auditable call sites

Use an options struct when positional values can be exchanged without a type
error. Two arguments of the same integer type belong in named options. A
nullable argument belongs there too when a bare `null` would hide its meaning.

Thread singleton dependencies with unique types positionally, ordered from the
most general capability to the most specific. Keep the options value near the
operation-specific arguments. This keeps authority visible without turning
every dependency into a bag of unrelated fields; see
[[process-init-and-capabilities]].

At calls to library functions, write the options and relevant fields
explicitly instead of accepting invisible defaults. This records the current
decision and makes review easier. It does not freeze future semantics: a newly
added field with a default can still compile. A release upgrade must therefore
review option definitions as well as call sites.

An options struct names choices; it does not validate them. Assert relations
such as nonzero sizes, ordered limits, and mutually exclusive modes inside the
callee, and return operational errors for expected invalid external input.

## Make callback flow read in execution order

- Put the callback last in the parameter list; put its context or completion
  storage immediately before it when they form a pair.
- When a helper or callback belongs to exactly one caller, prefix it with that
  caller's name, such as `read_sector_callback`. The name exposes call history
  during search and review.
- Give a genuinely shared callback a domain name instead of inventing a false
  caller relationship.

Naming and argument order do not establish ownership. The caller still needs a
documented lifetime for callback context, buffers, and operation state, plus a
terminal path for success, failure, and cancellation. See
[[task-lifetimes-and-structured-concurrency]] and [[cancellation]].

## Order files for the first read

Put the important public entry point near the top, because readers discover a
file top-down. Within a struct, use fields, then nested types, then methods. An
alias made with `@This()` can visibly close the nested-type section. Move a
complex nested type to the top level. Where semantic order is weak, stable
alphabetical order is a reasonable fallback; putting significant words first
lets that order group related names before their less-significant qualifiers.

This is a navigation rule, not a dependency-order constraint: Zig declarations
can refer to declarations that occur later. Preserve a stronger local ordering
when generated code, foreign interfaces, or an established subsystem has a
documented reason for it.

## Comments preserve reasoning

- Explain why a decision exists and show the reasoning that produced it. Do
  not translate the adjacent statement into English.
- Start a substantial test with its goal and methodology so a reviewer can
  understand the experiment before reading mechanics.
- Write standalone comments as sentences: a space after the marker, an initial
  capital, and terminal punctuation. An end-of-line phrase may omit
  punctuation.
- For Zig doc comments, omit facts already obvious from the declaration name,
  but duplicate useful help across similar APIs when that improves tool output.
- Follow Zig's precise doc vocabulary: use `assume` for an invariant whose
  violation causes unchecked illegal behavior, and `assert` for one whose
  violation causes safety-checked illegal behavior.

Commit messages are another durable reasoning boundary; a pull-request
description is not a substitute for history reachable by `git blame`. See
[[source-archaeology]].

## Format, then check the rules the formatter cannot

Run `zig fmt`. Use four-space indentation, same-line opening braces, braces for
multi-line conditionals, and a single-line conditional only when its one
statement fits on that line. Use trailing commas and deliberate expression
boundaries to request readable wrapping; see [[steering-zig-fmt]].

This repository runs Zig 0.16.0 formatting checks and separately rejects lines
over 100 characters in maintained Zig sources. The separate check matters
because the formatter's canonical output is not a promise to satisfy
TigerStyle's hard limit.

## Common failures

- Treating a successful `zig fmt --check` as proof that naming, comments, API
  shape, or file order are good.
- Calling strict TigerStyle code complete while retaining upstream Zig casing
  in some new local functions or type files without documenting the exception.
- Passing two same-typed limits positionally, or passing a bare `null` whose
  meaning is visible only in the callee.
- Passing an empty options literal and silently accepting all defaults.
- Naming every callback `callback`, which erases call history from search
  results.
- Writing comments that say what the syntax already says while omitting the
  limit, ownership, or failure rationale.

## Evidence and proof boundary

The pinned TigerStyle revision is the authority for its project rules. The
versioned Zig 0.16 style guide is the authority for Zig's general conventions
and explicitly says those conventions are not compiler-enforced.

The [style fixture](../proofs/fmt_steering.zig) demonstrates a Zig 0.16.0 API
with same-typed and nullable choices in explicit options, positional unique
dependencies, caller-prefixed callback naming, and the callback last. Its tests
prove that the call preserves each named value and reaches the completion. The
repository formatting and line-length checks prove the checked-in syntax and
shape; they cannot prove that a name or explanation is the best one.

## Review checklist

- Is the active naming profile explicit, especially at Zig/TigerStyle seams?
- Does each noun, verb, acronym, unit, qualifier, and allocator name convey the
  domain and lifetime?
- Can same-typed or nullable arguments be understood and distinguished at the
  call site?
- Is every relevant option and its upgrade risk visible?
- Does callback order mirror execution, and are ownership and terminal paths
  documented separately?
- Can a first-time reader find the entry point, fields, types, methods, test
  goal, and decision rationale in one top-down pass?
- Do `zig fmt --check` and the separate 100-character check pass?

Related: [[tigerstyle]], [[tigerstyle-coverage]], [[steering-zig-fmt]],
[[process-init-and-capabilities]], [[invariants-and-assertions]],
[[task-lifetimes-and-structured-concurrency]], [[source-archaeology]], and
[[zig-0.16-baseline]].
