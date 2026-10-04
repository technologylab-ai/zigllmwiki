---
id: zig-0-17-upgrade-assessment
title: Zig 0.16 to 0.17 migration findings
kind: map
status: draft
zig: "0.17.0"
summary: Route explicit 0.17 upgrades through cast audits, dependency ports, native gates, and recorded migration traps.
updated: 2026-10-05
sources:
  - "[[zig-0.17.0-release-notes]]"
  - "[[zig-0.17.0-stdlib]]"
  - "[[zig-0.17-project-ports-2026-10-04]]"
  - "[[zig-0.17-final-verification-2026-10-04]]"
  - "[[omajot-zig-0.17-2026-10-04]]"
  - "[[omagma-zig-0.17-stdlib-followup-2026-10-05]]"
proofs:
  - proofs/zig_017_semantics.zig
platforms:
  - cross-platform
---

# Zig 0.16 to 0.17 migration findings

## Remember

Read the [migration guide](../docs/zig-0.16-to-0.17-migration.md) before porting a complete dependency graph.
The guide incorporates the Baz, [bounded/http](https://technologylab-ai.github.io/bounded-http/), Mustache, zli, and Omajot ports.
The wiki's active baseline is [[zig-0.17-baseline]].
The upgrade invalidates prior labels before requalifying current pages and proofs.

## Main review routes

- Audit each `@bitCast` by logical bits, native memory bytes, or protocol byte order.
- Preserve reflection column indices, optional defaults, and public cleanup hooks.
- Preserve string and sentinel behavior when replacing removed array repetition.
- Update build APIs, final dependency pins, and machine-readable optimization tags.
- Recheck corrected `CLOSE_RANGE` flags against literal values and kernel behavior; nearby comments can remain stale.
- Retain checked `privileged_headers` workarounds and explicit authorization redirect controls.
- Separate request deadlines from idle limits and test watchdogs.
- Recheck infinite-sleep semantics and distinguish experimental std.Io backend blockers from OS adapters.
- Fetch current main before qualifying consumers, and preserve embedded package assets.
- Run direct dependency suites; inspect Unicode changes, fixture skips, and escaped borrowed slices.
- Record native verification and excluded historical dependency samples.

[[zig-0.17.0-stdlib]] provides exact compiler and library semantics.
[[zig-0.17.0-release-notes]] provides release context.
[[zig-0.17-project-ports-2026-10-04]] provides project revisions and verification limits.
[[zig-0.17-final-verification-2026-10-04]] closes final application and ordinary wiki gates.
The experimental full ARM64 Windows gate is deferred; its narrower standalone probes remain separate.

[[omajot-zig-0.17-2026-10-04]] adds final Baz integration and Omajot native qualification.
Its separate helper diagnosis records an optional casing lifetime defect outside the consumed scalar table.

[[omagma-zig-0.17-stdlib-followup-2026-10-05]] adds corrected Linux descriptor flags and unchanged HTTP header behavior.
The record separates source conclusions from the probes' native Linux scope.
[[networking-and-dns-racing]] explains authorization overrides and explicit redirect controls.

## Related active guidance

Use [[build-diagnostics-and-generated-code]] for build and evidence boundaries.
Use [[io-time-clocks-and-deadlines]] for clock domains and deadline ownership.
Use [[task-lifetimes-and-structured-concurrency]] for cleanup and borrowed storage.
Use [[trustworthy-microbenchmarks]] for measurement limits.
Read the [platform testing runbook](../docs/platform-testing.md) before using shared hosts.
