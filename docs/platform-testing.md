# Platform testing runbook

This runbook is the durable operational record for validating the Zig LLM Wiki
on macOS, Linux, and Windows. Read it before changing platform claims or
promoting a page to `runtime-verified`.

## Evidence rule

Cross-compiling a test proves that declarations, types, target branches, and
link inputs compile. It does not prove syscall behavior, cancellation,
completion ordering, timing, filesystem semantics, driver support, or load
behavior.

A runtime claim must record:

- the proof path and exact Zig version from `.zig-version`;
- architecture, OS version, kernel/build, and relevant feature state;
- the date and command or workflow run;
- what behavior was observed and what was not exercised;
- watchdog, resource limit, workload, filesystem/device, and queue depth when
  those affect the claim.

Actions artifacts expire. Preserve the important environment and conclusion in
the affected wiki page and append `log.md`; use the artifact/run URL as
supporting detail, not the only durable record.

## Execution hosts and availability

The user works from either host. These are the user's execution preferences,
recorded on 2026-09-04, rather than a guarantee of SSH availability:

| Host | Access from the other host | Role |
| --- | --- | --- |
| `maxross`, the user's M3 Max Mac | `ssh maxross` from `omarx1` | Preferred for resource-heavy portable builds, cross-compilation, analysis, and macOS runtime gates. |
| `omarx1`, Linux | `ssh omarx1` from the Mac | Linux runtime gates and continued authoring/builds when the Mac is unavailable. |
| GitHub-hosted Windows runner | Manual GitHub Actions dispatch below | Windows x86_64 and ARM64 native gates, plus x86 processes under WOW64. |

When working on `omarx1`, prefer offloading expensive portable work to
`maxross` when reachable. A bounded availability probe is:

```text
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 maxross 'uname -sm'
```

The Mac may be offline during travel or loss of signal. If it is unreachable,
continue all feasible work on `omarx1`, size build/agent parallelism to its
available CPU and memory, and leave only macOS-native evidence pending. Do not
stall portable or Linux work on repeated Mac connection attempts. Lightweight
editing and checks can stay on the current host.

Before offloading, identify the actual host, exact compiler, working directory,
and checkout state. Do not assume the Mac's `/Users/rs/...` checkout path exists
on Linux or that a remote clone contains the current tree. Use an isolated
checkout at the intended pushed commit for publication gates, or a validated
temporary copy of the current tree for development checks; preserve any active
remote checkout and its edits. Record the source commit and whether the input
tree was dirty. A successful SSH probe alone does not validate that setup.

Execution placement never changes evidence scope: Linux runtime tests run on
Linux, macOS tests on macOS, and Windows tests on Windows. Cross-compiling on
the faster Mac does not satisfy another OS's runtime gate. Report any required
unavailable native gate and its exact blocker explicitly.

## Cooperative host measurement lock

On both `maxross` and `omarx1`, use the host-local directory
`/tmp/zig-http-measurement.lock`. Acquire it with one atomic `mkdir` before a
benchmark, heavy build, or runtime test suite. If `mkdir` fails because the path
exists, hold off on that host and inspect `owner.json`; checking for absence and
then starting work without acquiring is racy. A lock on one host does not reserve
the other. Keep lightweight editing and remote orchestration available.
The HTTP rename preserves this shared reservation path for compatibility.

The acquiring agent writes `owner.json` with its identity, purpose, host, UTC
start, owner PID, unique ownership token and any working directory. For Linux,
record `/proc/PID/stat` start ticks as well so PID reuse is distinguishable.
Keep the lock for the entire workload, including warmups and child cleanup.
Only the owner removes its metadata and uses `rmdir` to release the directory,
after confirming all owned server/client/build processes have stopped. Use an
exact path and ownership token; never recursively delete a lock or remove one
merely because it is old. A missing or incomplete metadata file still means busy.
An interrupted owner may leave a stale lock: inspect the process identity and
children, coordinate recovery, and fail closed while ownership is uncertain.

Check existing measurement processes before acquiring too: work that started
before this protocol, or another tool that ignores it, is not protected. This is
a cooperative exclusion rule, not CPU isolation or proof of a quiet host. The
user requested it on 2026-09-05 because another agent also measures on the Mac.
Never stop that agent's work to make a gate run. Acquire both host-local locks
only if a workload actually needs both machines; otherwise reserve its execution
host alone. Recheck and acquire before later builds rather than assuming an
earlier empty process list still applies.

## Windows HTTP resumed — user decision 2026-09-06

The user resumed Windows HTTP implementation and verification.
The [captured follow-up](../sources/bounded-http-followup-2026-09-06.md) records that instruction.
The earlier tuning cadence below does not defer the resumed Windows scope.
M4-005 now includes a native x64 HTTP IOCP implementation and its finite runtime gates.
[[bounded-http-windows-shards-2026-09-06]] pins the qualified acceptor handoff and its identical-tree merge.
Native HTTP fixtures cover one through four IOCP owners.
[[bounded-http-windows-iocp-2026-09-06]] preserves the earlier single-owner candidate and hosted packet.
Four POSIX suspension fixtures remain excluded from the Windows HTTP suite.
This documentation-only ingest changes no wiki proof and requires no unrelated Windows wiki dispatch.
Changed Windows HTTP code still requires its relevant native gate.
M3-006 physical deployment qualification remains postponed.

## Earlier M4 performance cadence — user decision 2026-09-05

While the HTTP implementation is still being tuned, focus on macOS correctness
and Linux runtime/performance. The user explicitly deferred further Windows
measurements and repeated Windows publication gates because they slow this loop
without validating the then Linux/macOS-only HTTP server. A wiki update that
records these HTTP experiments does not require a new Windows dispatch.

Keep the manual Windows workflow and all existing receipts. Resume its gates
when Windows portability/work is explicitly resumed or a change needs new
Windows-specific evidence; never apply an old successful run to changed Windows
code. Any affected but unexecuted Windows claim remains pending. This is a
measurement-cadence decision, separate from M3-006's postponed physical deployment
qualification and from the then-absent M4 Windows HTTP adapter.

Use ReleaseSafe for every timing experiment, record power profile and CPU policy,
and preserve changes of environment as separate measurement conditions. Do not
silently mix results taken before and after a power-profile change. Mac/Linux
correctness, ownership, source and retrieval gates remain in force.

## Release gates

From a clean checkout on each runtime host required by the current scope:

```text
zig version
zig build verify --summary all
```

On the exact publication revision, also run the target-independent command and
retrieval regression tests on at least one host:

```text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tools.test_wiki_commands tools.test_retrieval_benchmark tools.test_curate_review tools.test_curate_scheduled -v
PYTHONDONTWRITEBYTECODE=1 python3 tools/retrieval_benchmark.py --format text --enforce-policy
```

`zig version` must exactly match `.zig-version`. Do not accept a master build or
nearby release. `zig build verify` runs structural/source lint, formatting,
generated-code inspection, every registered native proof, platform skips, and
Windows cross-target compilation.

After a run, require `git status --short` to be empty except for intentional
reviewed edits. Generated assembly and caches belong under ignored
`.zig-cache/`; Python bytecode is disabled or ignored.

## macOS

On `maxross`, run the common gate in the intended checkout, whether working
locally or over SSH from `omarx1`.
The verifier additionally compiles the C Blocks shim and runs the Dispatch I/O
and experimental Zig Dispatch mapping proofs only when the host target is
macOS.

Record the exact macOS build and architecture for new runtime evidence. A
Dispatch proof is not a kqueue reactor proof; hot-cache file measurements are
not evidence about cold storage, durability, cancellation, or production load.

## Linux on `omarx1`

When already working on `omarx1`, run the common gate locally and record the
architecture, `/etc/os-release`, kernel, and `io_uring_disabled` state. From
the Mac or another authoring host, run the complete current tree with:

```text
tools/verify_linux_ssh.sh omarx1
```

The wrapper:

1. validates a newly created remote temporary directory;
2. streams the current checkout rather than relying on a possibly stale remote
   clone;
3. disables macOS AppleDouble/xattr sidecars while archiving;
4. prints the local publication commit, remote architecture/OS/kernel, Zig version, and
   `/proc/sys/kernel/io_uring_disabled` value;
5. requires the remote Zig version to match `.zig-version`;
6. runs `zig build verify --summary all`; and
7. removes only the validated temporary directory through its cleanup trap.

It does not modify the remote user's checkout. Do not replace its validated
temporary path with `$HOME`, `~`, a workspace root, a glob, or another broad
deletion target.

This wrapper is Linux-specific; do not point it at `maxross` as a reverse
macOS runner. Use the macOS common gate in an isolated checkout there.

The archive contains the current working tree. The printed commit identifies
that tree only when the local checkout is clean. Require a clean checkout and
matching pushed commit for a publication gate; label earlier dirty-tree runs
as development checks.

The 2026-09-04 reference host was x86_64 Omarchy 4.0.2 / Arch Linux, kernel
`7.1.9-arch1-2`, Zig 0.16.0, with `io_uring_disabled=0`. That run proved the
registered low-level `io_uring` lifecycle tests and Threaded blocked pipe-read
cancellation. It does not generalize to older kernels, other filesystems or
devices, multishot/resource-tag support, security policy, or product load.

If `io_uring` setup or an opcode is unavailable, retain the exact errno and
feature/probe result. Do not turn a skip on one host into a portable support
claim.

## Windows through GitHub Actions

Windows runtime evidence currently comes from GitHub-hosted Windows VMs via
a matrix of `windows-latest` (x64) and `windows-11-arm` (ARM64). No local Windows VM on `maxross` or `omarx1`, or
self-hosted Windows runner, is part of this repository's testing setup.
The common verifier also cross-compiles Windows proofs on macOS and Linux;
those builds provide compile-only evidence. The most recently recorded hosted
image is Windows Server 2025 x86_64; `windows-latest` can change, so record the
actual image and build for every new runtime claim.

The public repository exposes the manual workflow `Windows runtime
verification` in `.github/workflows/windows-runtime-verify.yml`. Dispatch it
with:

```text
gh workflow run windows-runtime-verify.yml --ref main
gh run list --workflow windows-runtime-verify.yml --limit 1
gh run watch RUN_ID --exit-status
```

The workflow has `contents: read` only. Its standard path downloads the
`x86_64-windows` archive named by `.zig-version` from Zig's official index and
verifies SHA-256. On x64 the compiler and tests run natively. On ARM64 that
**x64 compiler runs under Windows emulation**, while all project tests target
`aarch64-windows` with CPU `baseline` and execute as **ARM64 processes** on the
ARM64 OS. Compiler and emitted-test PE machines and actual OS architecture are
checked separately. Host JSON records those distinctions alongside image,
Windows build/UBR, CPU, RAM, logical filesystems and reported disk models.

The x64 common gate is `zig build verify --summary all`; the ARM64 common gate
is `zig build verify -Dtarget=aarch64-windows -Dcpu=baseline --summary all`.
The ARM64 job additionally inspects generated code with explicit ARM64 target
and baseline CPU, since the ordinary inspector inherits its compiler's x64
host default. This path uses the same unmodified exact compiler release; it
does not count emulated x64 test execution as ARM64 evidence.

Each job separately compiles the five Windows proofs with `--test-no-exec`,
checks emitted PE architecture, then executes each and records phase-specific
exit codes, binary SHA-256 and logs: `windows_io_mapping.zig`,
`threaded_blocked_read_cancel_windows.zig`, `windows_apc_batch.zig`,
`windows_iocp_lifecycle.zig`, and `windows_iocp_tcp_file.zig`. Command/retrieval
gates and a clean-checkout check follow. Artifacts named
`zig-wiki-windows-runtime-ARCH-RUN-ATTEMPT` retain logs and host metadata for
30 days, including failures. Keep compiler success and actual executable
runtime distinct when interpreting their phase records.

The x64 job additionally builds all five proofs for `x86-windows`, validates
PE32/I386 headers, executes them under WOW64 and records SHA-256/exit status.
This proves 32-bit processes on the named 64-bit OS, not a native 32-bit OS.

The native ARM64 Zig 0.16.0 compiler crashed during compilation on the hosted
Cobalt 100 image. In
[diagnostic run 33921810785](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921810785)
all five default `--test-no-exec` commands failed with -1073741819 before test
execution; seven of eight CPU/LLVM variants also failed. The root cause is
unknown. That run remains failed overall, even though its explicit x64-compiler
ARM64-runtime path and full target gate passed. Do not silently patch Zig or
claim the standard path validates the native ARM compiler.

To repeat that separate diagnostic deliberately, dispatch:

```text
gh workflow run windows-runtime-verify.yml --ref main -f native_arm64_diagnostics=true
```

The optional diagnostic installs the exact checksum-verified ARM compiler and
keeps its compile/execution failure fatal. Default publication gates use the
proven explicit compiler/target path; diagnostics are not run silently or
turned green with `continue-on-error`.

The [January 2026 GitHub runner announcement](https://github.blog/changelog/2026-01-29-arm64-standard-runners-are-now-available-in-private-repositories/)
establishes standard ARM64 runner availability for private repositories. An
older public-only restriction must not be used to skip an available gate.
Actual allocation, image/build, and success still require a completed run.

Use `gh run download RUN_ID -D TEMPORARY_DIRECTORY` to inspect the packet. The
first reference host was x86_64 Windows Server 2025 Datacenter 24H2, build
26100.33296, with Zig 0.16.0. On 2026-09-04, commit
`4a641706696830a92611c20ab09a91ea3e9a2e50` in
[run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858)
passed the full verifier with 70/70 build steps, 67 passing tests, and 7
intentional platform skips, then passed the native mapping and synchronous
named-pipe cancellation proofs explicitly. At that historical checkpoint,
x86 and aarch64 had only compile evidence; subsequent WOW64/ARM64 results
and the precise compiler boundary are recorded in the Windows page.

The M3-004 expansion's native gate at commit
`959a93ac690abbde9f9ea55cf5f06437fedcec30` in
[run 33915530939](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33915530939)
passed 82/82 Zig steps, 70 tests and 7 skips, plus all four explicit native
proofs. Its later Python gate failed because a Windows drive letter was parsed
as a URL scheme; that command bug is fixed with a regression test. Keep the
native result distinct from that run's overall failure. Full environment,
fixtures, observed paths and metrics are in [[windows-iocp-and-overlapped-io]].

Before interpreting a run, check `headSha` with `gh run view RUN_ID --json
headSha,status,conclusion,url` and match it to the intended pushed commit.
A queued workflow has not executed any proof. An in-progress workflow has not
passed until its conclusion and packet confirm that result.

Windows lessons that must not regress:

- `.gitattributes` enforces LF. Git's Windows CRLF conversion otherwise changes
  byte-identical captured-source hashes and makes `zig fmt --check` fail.
- Process fixtures select `cmd.exe` on Windows and `/bin/sh` on POSIX. `cmd`
  emits CRLF and redirection whitespace can become output; limits and expected
  bytes must describe the actual platform command.
- A Windows Server 2025 run observed a 2 ms `.awake` deadline wait return just
  before the following timestamp comparison reached the deadline. The proof
  now rechecks and reuses the same absolute deadline with a bounded attempt
  count. Never replace that with fresh relative sleeps, which would extend the
  budget.
- Passing the synchronous cancellation harness does not prove asynchronous APC
  races, every device/driver, `Batch.cancel`, or a custom IOCP adapter.
- Zig 0.16.0 `Threaded.batchCancel` waits for an APC/alert before sending
  cancellation requests for a pending batch. A watchdog-backed witness must
  distinguish an explicit wake used to release that wait from unassisted
  cancellation progress. See [[windows-iocp-and-overlapped-io]].
- New native harnesses must keep control blocks and buffers live until terminal
  reconciliation even on a failed assertion. A process watchdog may terminate
  a stuck proof; it must not unwind a stack still borrowed by the kernel.
- Zig 0.16.0 `dirOpenFileWtf16` requests asynchronous mode when not following
  symlinks but returns `File.flags.nonblocking = false`. Use explicit NT/Win32
  opens for a custom overlapped fixture instead of inferring mode from this
  wrapper metadata. The first M3-004 run caught that mismatch.
- PowerShell `Tee-Object` does not create a file when a clean `git status`
  emits nothing. Capture status as an array and explicitly write the packet
  file before checking it; a missing file is not a dirty checkout.
- `urlparse` treats a Windows drive letter as a URI scheme. Local source
  ingestion must identify drive paths before enforcing the remote HTTPS rule;
  the native Windows command gate protects this distinction.

## Scheduled source/retrieval review

`Zig wiki read-only review` in `.github/workflows/wiki-review.yml` runs weekly
and by manual dispatch. It installs the exact checksum-verified Linux compiler,
runs verification and command tests, performs the bounded source/Zig-release
review, enforces retrieval thresholds, asserts that the checkout did not
change, and uploads a 30-day packet.

The repository-scoped Actions token can query repositories but has no public
Gist API scope. `tools/wiki.py review` therefore obtains a public Gist HEAD
with read-only `git ls-remote`; do not reintroduce the scoped API call. A remote
HEAD difference is a coarse inspection prompt, not proof that a pinned record
or synthesized claim is stale.

Neither hosted workflow writes content or opens pull requests. The separate
local consumer in [agent curation](agent-curation.md) uses Codex for semantic
review and `gh` for packet retrieval and draft-PR publication. Its operational
validation and scheduler status are tracked in the handoff; read-only hosted
review remains independent of write authority.

## Recording a new platform result

1. Keep the executable claim in one registered file under `proofs/`.
2. Run the full gate, not only the new test.
3. Update the affected page's Evidence section with the exact environment,
   date, observed behavior, and remaining limits.
4. Change frontmatter status only when every platform named by the claim has
   the required runtime evidence.
5. Update `CURATION.md` and `ROADMAP.md` without calling queued work “running.”
6. Append `log.md`; never rewrite an earlier historical entry to hide a failed
   or narrower run.
7. Commit and push the complete evidence/doc change, then run the hosted gate
   against that exact commit.


## Standalone M4 HTTP gates

The public sibling `bounded-http` contains the runnable bounded/http application.
The application registers its modules through its own `zig build verify`.
The [naming decision](../sources/bounded-http-naming-2026-09-06.md) defines the project names.
The HTTP project's first source-hashed packet is
[[zig-http-mvp-2026-09-05]], separate from this wiki's registered lifecycle proofs.
Run its Debug and ReleaseSafe verifiers, build ReleaseSafe, then its Python
generic, inline, gather, batch and arena lifecycle integration suites, the comparator receipt
tests, and `tools/smoke.py`. The smoke orchestrator rejects a binary
whose READY marker does not report ReleaseSafe. Its Linux SSH wrapper follows
this runbook's validated temporary-directory, exact compiler and clean-input
rules, and adds finite build/integration/process watchdogs.

On omarx1, the default Zig 0.16.0 x86 Debug/libc path failed on R_X86_64_PC64 in
GCC 16's crt1.o:.sframe. The user's first workaround, ReleaseSafe without linker
overrides, passed. Debug with explicit LLVM/LLD passed too. Preserve the target,
CRT and compiler evidence; see [[build-diagnostics-and-generated-code]]. This
is unrelated to Windows compiler diagnostics or a Zig version upgrade.

The HTTP server now has Linux, macOS, and native x64 Windows runtime evidence.
[[bounded-http-windows-shards-2026-09-06]] pins the Windows acceptor handoff and its explicit limits.
The maintained Windows shard suite supplements the common wire suites on Windows.
Runtime fixtures cover one through four owners; configuration acceptance through 64 owners does not prove that wider range.
The wiki's Windows workflow validates the existing wiki proofs.
Those proofs do not supply runtime or compile evidence for the separate HTTP executable.
A documentation-only HTTP evidence ingest does not require that unrelated dispatch.
M3-006 physical deployment qualification remains postponed.

Performance experiments belong in the sibling project's maintained comparison
harness. Keep assertion-enabled ReleaseSafe, pinned contender/source/binary
identities and exact CPU assignments; finish builds before timed runs. Separate
client pipeline depth from the startup server batch limit. A deeper client
pipeline must not silently enlarge response storage. Check distinct-body wire
ordering and retained-cell cancellation separately from wrk throughput counts.
One I/O thread and three contender processes may share an allowed CPU budget
without using equal parallelism; compare actual one-core runs before making
per-core claims. Raw corrected wrk percentiles have a pinned validity defect
and do not establish request tail latency. [[techempower-r23-comparison-inputs]]
