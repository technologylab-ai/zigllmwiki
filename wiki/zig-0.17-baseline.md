---
id: zig-0-17-baseline
title: Zig 0.17 baseline
kind: concept
status: source-verified
zig: "0.17.0"
summary: Current guidance and maintained proofs use exact Zig 0.17.0, with historical evidence kept in its original scope.
updated: 2026-10-04
sources:
  - "[[zig-0.17.0-stdlib]]"
  - "[[zig-0.17.0-release-notes]]"
proofs:
  - proofs/zig_017_semantics.zig
platforms:
  - cross-platform
---

# Zig 0.17 baseline

## Remember

The active compiler is the exact release in `.zig-version`: Zig 0.17.0.
Use the matching installed source for APIs and compiler semantics.
Read [[zig-0.17-upgrade-assessment]] and its migration guide before porting older examples.

## Evidence boundaries

The upgrade invalidates previous verification labels before requalifying affected pages.
A draft page can contain useful guidance without a complete new platform receipt.
Read its source records, proof links, and dated evidence before applying a platform claim.

Historical 0.16 records retain their original revision, compiler, platform, and hashes.
They do not establish current 0.17 runtime behavior.
Cross-compilation proves compilation only.
Native Linux, Mac, and Windows results remain separate.

## Release changes that require scrutiny

Logical `@bitCast` conversions can change external memory representation while compiling successfully.
Reflection indices, defaults, and public declaration visibility can change application behavior.
Build paths, package caches, and string fixtures need separate consumer checks.
Use the independent oracles in [the semantic proof](../proofs/zig_017_semantics.zig).

## Verification

Run `zig build verify` with exact 0.17.0.
Run correctness in Debug and Safe with assertions enabled.
The timed verification fixture always uses Safe, including during Debug verification.
Acquire the host reservation before heavy builds, runtime suites, or measurements.
Read the [platform runbook](../docs/platform-testing.md).

[[zig-0.16-baseline]] retains the previous baseline context.
[[std-io]] and [[evented-io-backends]] qualify interface and backend behavior separately.
