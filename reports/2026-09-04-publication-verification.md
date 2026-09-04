# Publication verification — 2026-09-04

Clean pushed source revision: **a92ec380adaad914a304021d1502a77e93dd549c**.
Exact compiler on every path: **Zig 0.16.0**, unchanged `.zig-version`.
This receipt records completed gates on that revision. Later documentation
publication must match its own workflow headSha; this report does not predict
future runner results or retroactively expand historical proof coverage.

## Completed gates

| Environment | Build steps | Passed / total tests | Platform skips | Other gates |
| --- | --- | --- | --- | --- |
| maxross, M3 Max arm64 macOS 26.6.2 build 25G83 | 87/87 | 73/82 | 9 | 28 Python tests, 25-query retrieval policy, lint with no issues, clean tree |
| ssh omarx1, x86_64 Omarchy 4.0.2, kernel 7.1.9-arch1-2, io_uring_disabled=0 | 87/87 | 74/82 | 8 | Exact clean input streamed by tools/verify_linux_ssh.sh; temporary directory cleaned |
| Windows Server 2025 x64, native x64 compiler and executables | 87/87 | 75/82 | 7 | Five standalone proofs, five x86 PEs executed under WOW64, 28 Python tests, retrieval and clean status |
| Windows 11 ARM64, emulated x64 compiler, native ARM64 executables | 87/87 | 75/82 | 7 | Five standalone ARM64 PEs, explicit ARM64 assembly, 28 Python tests, retrieval and clean status |

[Windows matrix run 33922946389](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946389)
concluded **success** at the stated source revision, with both jobs successful.
[Read-only review run 33922946096](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33922946096)
also concluded **success** at that revision. It retained a clean, versioned
review packet; no curation agent was started for this publication-only check.

The four new ownership tests ran in all four environments: synchronization now
has nine tests and Select/Batch three. They cover zero-minimum contention,
partial cancellation/fast progress/checkCancel, close/join with blocked callers,
and owned partial awaitMany delivery. The existing Batch test now actually
asserts completion indexes. The finite private-state witnesses are exact-release
implementation evidence; no arbitrary-backend progress guarantee is inferred.

Mac commands were `zig build verify --summary all`, the four Python unittest
modules listed in the runbook, and retrieval with `--enforce-policy`. Linux
used `tools/verify_linux_ssh.sh omarx1` from the clean matching source revision.
ARM64 used `zig build verify -Dtarget=aarch64-windows -Dcpu=baseline --summary all`
and separately checked each executable's PE architecture before execution.

Retrieval: 25 cases, MRR **1.0**, hit@3 **1.0**, recall@5 **0.98**, policy met.
Machine lint: **ok=true**, zero issues, mutates_repository=false; graph has
49 wiki pages, 475 directed edges, all 49 strong and zero orphans. Those counts
are mechanical checks, not an additional full-vault semantic audit.

## Exact Windows hosts and scope

The x64 job used image **win25-vs2026 / 20260824.214.3**, Windows Server 2025
Datacenter 24H2 build **26100.33296**, PowerShell **7.6.5**, reported
**Intel Xeon 6973P-C**, one core/two logical processors, **8,584,425,472 bytes
RAM**. Fixture volume D: was NTFS, **118,093,770,752 bytes** capacity. Reported
devices: **Virtual_Disk NVME Premium** and **Microsoft NVMe Direct Disk v2**,
both SCSI interfaces. This differs from earlier AMD/virtual-disk runs; a shared
image version does not establish identical CPU or storage hardware.

The ARM64 job used image **win11-arm64 / 20260830.155.1**, Windows 11 Enterprise
25H2 build **26200.9168**, ARM64 PowerShell **7.6.4**, **Cobalt 100**, two
cores/two logical processors, **8,579,493,888 bytes RAM**. Fixture volume C:
was NTFS, **274,284,392,448 bytes** capacity. Devices reported **Microsoft
Virtual Disk** and **Microsoft NVMe Direct Disk v2**, both SCSI interfaces.

Both jobs downloaded and SHA-256 checked the official **x86_64-windows 0.16.0**
compiler archive. The ARM64 compiler process ran under Windows emulation;
test target was aarch64-windows, baseline CPU, and checked ARM64 PE executables
ran on the ARM64 OS. Native ARM64 compiler diagnostics were explicitly disabled
for this qualification run; their recorded failures remain in
[diagnostic run 33921810785](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921810785).
The exact native compiler root cause remains unknown. No compiler was patched.

The standalone TCP/file x64 sample completed 32 KiB in **3.3047 ms**,
9,915,574 bytes/s, cycle p50/p99/max **94.5/275.3/275.3 microseconds**.
ARM64 completed it in **200.5617 ms**, 163,381 bytes/s, cycle p50/p99/max
**6002.9/9888.4/9888.4 microseconds**. Both checksum values were **4,090,822**.
Each observed 453 data submissions/packets, 449 successes, three canceled
receives, one EOF error, one separately rejected write initiation, peak owned
two of four slots, largest dequeue batch three, and zero short OS receives.
All 32 read and 32 write cancellation races succeeded; none produced canceled
file results. x64 writes were immediate (64), ARM64 writes pending (64); all
65 reads were pending in each. No watchdog expired. These small VM fixtures
are correctness observations, not a hardware or architecture ranking.

## Proof identities and remaining limits

| Proof | SHA-256 at the verified revision |
| --- | --- |
| `proofs/io_sync_primitives.zig` | `f69358d87a013418d7764d2b89d45926f3da3b94b4345298435d67876900f191` |
| `proofs/select_and_batch.zig` | `bd85f1ecd3094b049124b1d066639df328dc7770bb53d3dbbffa370441779893` |
| `proofs/windows_apc_batch.zig` | `89f47e526bef84f0a1f17d470e41a6643223cbd54574b6fafb8cce768c387f2b` |
| `proofs/windows_iocp_lifecycle.zig` | `41ffa8d75437373af19671c71a74ed3bcfbc2c8542e8b234671fc6df21cfebea` |
| `proofs/windows_iocp_tcp_file.zig` | `3cb79ef2a25695750ef07f3f95d26e33977374aad82a5bb3aea4a78da574dfa6` |

The selected storage/recovery source synthesis, full semantic audit, excerpt
design, and installed curator are complete. The curator's successful draft PR
and separate root merge are recorded in the
[operational receipt](2026-09-04-curation-operations.md). All subagents finished;
the curator service is inactive and its enabled weekly timer is waiting.

M3-006's safe available fixture work is complete. Its broad deployment exit
remains **blocked** on physical power-loss and controlled cold-storage evidence,
a named production filesystem/device/driver/error matrix, and workload-specific
throughput/tail criteria. Immediate regular-file reads and canceled file
terminal results remain unobserved. Custom public IOCP shutdown was tested;
that does not repair shipped Threaded.batchCancel or qualify arbitrary drivers.
No named deployment or physical storage fault runner is available in this
session. M4 remains user-reserved; backend work remains deferred under its ADR.
