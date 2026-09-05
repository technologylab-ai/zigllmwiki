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


## Wiki integration receipt

Clean pushed wiki commit `7a5dd5455858a7f84117e04beeed5181c83693a2` passed the
complete Mac/Linux gates: 87/87 steps, respectively 73 tests/9 platform skips
and 74 tests/8 skips. All 28 command tests and 25 retrieval cases passed with
MRR1.0/hit@3=1.0/recall@5=0.96. Immutable source snapshots and the append-only log
prefix were checked; prior source records were not changed.

[Windows run33983000614](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33983000614)
completed successfully on that exact headSha. Both jobs passed87/87 steps,
75/82 tests with7 skips, five separately compiled/executed native-target proofs,
28 command tests and retrieval policy. The x64 job also passed all five x86
proofs under WOW64. Checkout status was clean in each packet. Full host,
compiler archive, source/executable hashes and runtime logs are retained in
[the durable JSON receipt](2026-09-05-http-performance-publication.json).

- x64: Windows Server2025 Datacenter24H2, build26100.33296, image
  win25-vs2026/20260824.214.3, AMD EPYC7763, two logical processors,
  8,584,425,472 bytes RAM, PowerShell7.6.5, NTFS and Microsoft Virtual Disk/SCSI.
  Exact Zig0.16.0 x64 compiler and x64 tests execute natively; x86 tests use WOW64.
- ARM64: Windows11 Enterprise25H2, build26200.9168, image
  win11-arm64/20260830.155.1, Cobalt100, two logical processors,
  8,579,493,888 bytes RAM, PowerShell7.6.4, NTFS, Microsoft Virtual Disk and
  Microsoft NVMe Direct Disk v2 reported as SCSI. The same exact x64 compiler
  runs under emulation and emits ARM64-baseline executables that run as ARM64
  processes. The separate failing native ARM-compiler diagnostic was not enabled.

These hosted lifecycle results do not qualify physical storage, arbitrary
production Windows drivers or a Windows HTTP adapter. M3-006 remains postponed.
The following documentation-only receipt commit gets the same complete local,
Linux and Windows gates; match its own headSha in the workflow history instead
of treating this earlier successful receipt as that later gate's result.
