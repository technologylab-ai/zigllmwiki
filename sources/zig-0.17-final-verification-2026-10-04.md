---
id: source-zig-0-17-final-verification-2026-10-04
title: Zig 0.17 final application and wiki verification
kind: source
status: captured
summary: Preserve final native application gates, ordinary wiki verification, separate defect reproduction, original failures, and cleanup.
captured: 2026-10-04
revision: "4fee1f67df666a27980d7eef0653699ddb242d8f"
url: https://github.com/technologylab-ai/zigllmwiki/blob/4fee1f67df666a27980d7eef0653699ddb242d8f/build.zig
snapshot: sources/snapshots/zig-0.17-final-verification-2026-10-04.json.gz
sha256: "de11bce61f79cd94687ef618c752439f73699eaa186e8cd33f2ebf8b1772f9d8"
---

# Zig 0.17 final verification

This new capture supplements [[zig-0.17-project-ports-2026-10-04]].
It closes that record's pending Baz Windows qualification without rewriting the earlier packet.
The snapshot preserves 344 files with original bytes and individual SHA-256 values.
It also checks identical wiki proof inputs across the separately named verification revisions.

## Application ports

| Project | Current port branch head | Consumed revision |
| --- | --- | --- |
| Baz | `42b1d02c5d92ecd863fa1f5e8efd4f4e378680b4` | Application |
| [bounded/http](https://technologylab-ai.github.io/bounded-http/) | `19223caff116de440207a161969d88c60cdccfb8` | `65d584bf1a00451577235281a290303b10d0ae3b` |
| Mustache | `f46006f04a6bb4374a34250fb01fe72daf6a39c1` | Same |
| zli | `36dfe7c506117af0e52533feb549282362b77e2a` | Same |

Baz's final [Linux/macOS CI](https://github.com/technologylab-ai/baz/actions/runs/37219861984)
and [native Windows CI](https://github.com/technologylab-ai/baz/actions/runs/37219861982) passed.
The final audit corrects three display/documentation labels: the public API version,
session help version, and 26-example count. Mac Debug/Safe verification and the
152-file, 109-document site/API check passed again at that head.

The earlier final URL graph passed on native `omarx1`: 72 steps, 250 tests and
five independent consumer tests per mode, plus all eleven Python suites (540 groups).
That Linux receipt retains its original application revision; it is not renamed to the later help-text commit.
All three dependencies also passed Debug/Safe on that host.

The engine's later README-only commit clarifies that its excluded benchmark
preparation recipe remains a historical 0.16 reproducer.
Its exported package inputs are unchanged from the consumed commit.
The successor passed [native Linux/macOS](https://github.com/technologylab-ai/bounded-http/actions/runs/37219863827).
[Native Windows](https://github.com/technologylab-ai/bounded-http/actions/runs/37215739537)
qualification retains the consumed commit identity.
Mustache and zli native three-platform receipts remain in the preceding source record.
No application throughput comparison or Windows performance qualification is added.

## Ordinary wiki verification

The ordinary graph at `4fee1f67df666a27980d7eef0653699ddb242d8f` passed
full Debug and Safe verification on arm64 macOS 26.6.2 and native x86_64 `omarx1`.
Each mode passed 93/93 steps. Unchanged positive proof executions were reused
from their exact-input caches; the packet distinguishes those from fresh runs.
Fresh Linux Safe proof execution at `26b836bdb15ad439f0c2e4f27c4a76852accec42`
passed 80/88 tests with eight platform skips.
The revised time proof separately passed 6/6 tests in both modes on Mac.

[Hosted Linux review](https://github.com/technologylab-ai/zigllmwiki/actions/runs/37219471912)
passed at the corrected-checker revision.
[Windows qualification](https://github.com/technologylab-ai/zigllmwiki/actions/runs/37219131273)
retains core revision `3e1f23b7f54aa918c384fbd4e07bba112e7792ee`.
The x64 job passed both modes: 93/93 steps and 81/88 tests, with seven skips.
It also passed the five separate native x64 probes and five 32-bit WOW64 probes
on Windows Server 2025 build `26100.33438`.
The workflow is canceled overall because the user deferred its experimental
ARM64 full gate after it remained in Debug verification for nearly an hour.
That gate supplies no complete Debug/Safe qualification.
The retained post-cancellation steps separately compiled and passed all five
named Windows probes as native ARM64 Debug executables on Windows 11 build
`26200.9457`, using the x64 compiler under emulation. These narrower results do
not enlarge the incomplete full gate or qualify a native ARM64 compiler.
The packet confirms unchanged proof bytes across all three wiki revisions;
it does not rename earlier runs to the later ordinary graph.

Python tooling passed 42 tests. All 25 retrieval queries met policy
(MRR 0.98, hit@3 1.0, recall@5 0.96).
The tracked 206-document projection and deterministic comparison passed.
The final evidence ingest has separate publication checks recorded in the handoff.
Performance entry points and the timed verification executable use Safe.
Debug correctness probes also record diagnostic elapsed fields; those fields
are not performance measurements or application throughput evidence.

## Defects and first failures

The precise Dispatch, Uring and Kqueue compile errors remain registered witnesses.
They qualify the observed release blockers, not functioning backend instances.
The tested application dependency graph uses its own OS transport adapters and does not instantiate those backends.

The revised Linux infinite-sleep witness reproduced SIGABRT with return code `-6`
and the exact `Threaded.timestampToPosix` integer-conversion panic.
Safe optimization omitted `sleepPosix` and the fixture's main frame.
The first overly strict checker failed despite reproducing the intended panic;
the corrected checker requires retained source/function frames, the executable
name, failing conversion text, and SIGABRT. It rejects unrelated crashes.
Its parser audit is separately labeled and does not count as new runtime evidence.

Normal wiki verification compiles this witness without executing it.
Reproduction now requires the explicit native Linux
`zig build verify-linux-none-sleep-defect` step.
Core dumps are disabled, but intentional SIGABRT still activates OS crash monitors.
The ordinary final Linux gates confirm no witness execution or crash alerts were requested.

The initial Linux wiki attempt hit the host's user quota before reaching the
proof failure. Under a separate owned reservation, only task-created Baz caches
were cleared after saving cached executable hashes. Sources, installed outputs,
compiler archives, prior logs and unrelated caches were retained.
Later gates had sufficient quota. Owned children were cleaned and every own lock released.
The snapshot preserves both original failed attempts and their cleanup receipts.

Read [[zig-0.17-upgrade-assessment]] and the
[migration guide](../docs/zig-0.16-to-0.17-migration.md) for agent-facing synthesis.
