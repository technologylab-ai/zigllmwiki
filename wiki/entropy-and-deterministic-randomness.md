---
id: entropy-and-deterministic-randomness
title: Entropy and deterministic randomness
kind: principle
status: runtime-verified
zig: "0.16.0"
summary: Use randomSecure when fresh external entropy must either succeed or fail, and isolate ordinary process randomness from deterministic simulation and replay.
updated: 2026-09-04
sources:
  - "[[zig-0.16.0-stdlib]]"
  - "[[zig-0.16.0-release-notes]]"
proofs:
  - proofs/network_process_entropy.zig
platforms:
  - macos
---

# Entropy and deterministic randomness

## Remember

`std.Io` exposes two thread-safe buffer-filling operations with deliberately
different failure and state contracts:

| Operation | Source/state contract | Failure contract |
| --- | --- | --- |
| `io.random(buffer)` | Cryptographically secure pseudo-random generator that may keep process-local state; seeded through `randomSecure` or a less-secure fallback if seeding fails. | Cannot report failure. |
| `io.randomSecure(buffer)` | Obtains fresh external entropy through a syscall or an equivalent path that does not depend on stored process RNG state. | Cancelable; returns `error.EntropyUnavailable` with no fallback. |

Choose from the failure policy, not convenience. If a key, nonce seed, or
identity must not be created without fresh system entropy, call
`randomSecure`, propagate or handle `EntropyUnavailable`, and do not silently
fall back. If an API needs infallible process randomness and accepts the
documented fallback, `random` expresses that choice.

Neither call gives deterministic tests. For deterministic simulation, obtain
or configure a seed once at the control plane, store it in the replay record,
initialize an application-owned deterministic PRNG, and pass that PRNG into
the simulated subsystem. Do not let workers call ambient entropy behind an
interface that claims replayability.

## Ownership and limits

Both operations fill caller-owned storage and allocate no result buffer. The
buffer length is therefore the explicit request size. Establish domain-sized
requests—key bytes, seed bytes, identifier bytes—instead of exposing arbitrary
untrusted lengths to an entropy operation.

`randomSecure` is a cancellation point. The surrounding task owner must still
complete its usual await/cancel protocol before reusing the buffer. `random`
cannot communicate an entropy-source failure, so success is not evidence that
the system entropy path succeeded.

Tests must not assert that output differs from zeros, from a previous sample,
or from another process: such statistical assertions are flaky and do not
verify the source contract. Test failure handling with a controlled `std.Io`
implementation and test deterministic algorithms with an explicit fixed seed.

## Evidence

The [network/process/entropy proof](../proofs/network_process_entropy.zig)
executes both operations through `std.testing.io` on aarch64 macOS with Zig
0.16.0 on 2026-09-04. It proves the current signatures and successful platform
path without making a probabilistic quality assertion. Failure injection and
the no-capability `Io` behavior are covered by
[[testing-io-and-single-threaded-builds]].

Related: [[std-io]], [[cancellation]],
[[deterministic-simulation-testing]], [[static-allocation-and-constant-work]],
[[testing-io-and-single-threaded-builds]], [[tigerstyle]].
