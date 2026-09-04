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

## Release gates

From a clean checkout on every runtime host:

```text
zig version
zig build verify --summary all
```

On the exact publication revision, also run the target-independent command and
retrieval regression tests on at least one host:

```text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tools.test_wiki_commands tools.test_retrieval_benchmark -v
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

The local macOS checkout is the ordinary authoring host. Run the common gate.
The verifier additionally compiles the C Blocks shim and runs the Dispatch I/O
and experimental Zig Dispatch mapping proofs only when the host target is
macOS.

Record the exact macOS build and architecture for new runtime evidence. A
Dispatch proof is not a kqueue reactor proof; hot-cache file measurements are
not evidence about cold storage, durability, cancellation, or production load.

## Linux on `omarx1`

Run the complete current tree with:

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

The private repository exposes the manual workflow `Windows runtime
verification` in `.github/workflows/windows-runtime-verify.yml`. Dispatch it
with:

```text
gh workflow run windows-runtime-verify.yml --ref main
gh run list --workflow windows-runtime-verify.yml --limit 1
gh run watch RUN_ID --exit-status
```

The workflow has `contents: read` only. It downloads the `x86_64-windows`
archive named by `.zig-version` from Zig's official release index, verifies the
published SHA-256, records the runner image, exact Windows build/UBR, CPU, RAM,
logical filesystems and reported disk models, runs the common Zig verifier,
then explicitly runs `windows_io_mapping.zig`,
`threaded_blocked_read_cancel_windows.zig`, `windows_apc_batch.zig`, and
`windows_iocp_lifecycle.zig` natively. It also runs the command/retrieval gates
and fails if verification changes the checkout. Logs and host metadata are
uploaded for 30 days even when an earlier step fails.

Use `gh run download RUN_ID -D TEMPORARY_DIRECTORY` to inspect the packet. The
first reference host was x86_64 Windows Server 2025 Datacenter 24H2, build
26100.33296, with Zig 0.16.0. On 2026-09-04, commit
`4a641706696830a92611c20ab09a91ea3e9a2e50` in
[run 33911991858](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33911991858)
passed the full verifier with 70/70 build steps, 67 passing tests, and 7
intentional platform skips, then passed the native mapping and synchronous
named-pipe cancellation proofs explicitly. x86 and aarch64 remain compile-only
until native runners execute them.

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

Neither hosted workflow writes content or opens pull requests. L-009 in
`ROADMAP.md` deliberately reserves review-packet consumption for a separately
authorized coding agent.

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
