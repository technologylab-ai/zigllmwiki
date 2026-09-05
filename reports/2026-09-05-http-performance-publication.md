# HTTP performance iteration publication

The standalone HTTP implementation and complete measured packet are published at
`e07766e4f1a3bf1cd5dc772e8da48f63d085e5ad`. The worktree was clean and matched
origin/main before the publication gates. See [[zig-http-response-batching-2026-09-05]]
for immutable implementation/harness checkpoints, exact workload differences and
all measured distributions; this receipt does not replace those identities.

## Exact standalone publication gate

On 2026-09-05, both native hosts ran exact Zig 0.16.0 against that clean pushed
revision, retaining assertions. Each passed:

- Debug and ReleaseSafe: 14/14 build steps, 52/52 unit executions per mode.
- ReleaseSafe wire suites: 26 generic, 10 inline, 11 gather and 22 batching cases.
- Four comparator receipt tests and three finite smoke workloads totaling
  30,000 checked plaintext/preloaded-HTML responses.
- Zero live connection/operation owners after each checked shutdown; no late
  framework allocation in the checked server sessions.

Mac maxross: M3 Max arm64, macOS 26.6.2 build 25G83, 16 logical CPUs, 128 GiB RAM.
Commands: both `zig build verify --summary all` modes, ReleaseSafe build,
`tests/test_compare.py`, all four Python wire suites, and `tools/smoke.py`.

Linux omarx1: x86_64 Omarchy 4.0.2, kernel 7.1.9-arch1-2, Intel Core Ultra 7
258V, eight CPUs, glibc 2.44, GCC 16.2.1 20260810, io_uring_disabled=0.
Command: the standalone project's `tools/verify_linux_ssh.sh omarx1`, with its
validated temporary directory, exact compiler check and finite watchdogs.
The wrapper printed the publication hash above and removed its owned directory.

Local ignored receipts are `.zig-cache/batch-publication-*` in the sibling
project. The published packet already preserves the same runtime implementation's
native gate JSON and raw logs; final documentation publication did not change
its Zig source. These are Linux/macOS HTTP results. This wiki's Windows workflow
runs existing registered lifecycle proofs; it provides no Windows HTTP evidence.

## Results and remaining limits

Header/body gather and bounded response cells are implemented and measured,
with inline callbacks and zero workers by default. Deep client pipeline tests
are complete through 128 while response cells remain capped at 16. Increasing
client depth did not unlock the contender's throughput growth; the plateau,
increased compaction and substantial same-binary variation remain documented.
No reliable wrk tail, general capacity, arbitrary application preemption or
kernel network zero-copy claim is made.

All timed runners and implementation agents finished. The benchmark directory
`/tmp/zig-http-compare.qHiBFl` was removed after validating its canonical path,
caller ownership and absence of live owned processes/containers. Original
container-owned build files required ownership repair through the same pinned
Python image with only that directory mounted, network disabled and finite
resource/time bounds; the repair and cleanup succeeded. Raw measurement logs
and JSON were preserved before cleanup. Shared image caches remain untouched.

The wiki publication uses its complete local verifier, 28 command tests and
25-query policy, followed by clean-pushed Linux and manual hosted Windows gates.
Match each hosted run's headSha to the intended final wiki revision; an older
successful run is not evidence that a new publication has passed.
