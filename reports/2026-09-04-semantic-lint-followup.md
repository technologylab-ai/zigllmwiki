---
kind: semantic-lint-report
date: 2026-09-04
zig: "0.16.0"
scope: all 49 baseline navigable pages plus the storage and Windows qualification additions inspected below
verifier: pass
disposition: pass-with-findings
---

# Semantic lint follow-up — 2026-09-04

## Scope and verification

This is a second, independent pass under [the semantic lint
procedure](../tools/semantic_lint.md). It preserves the earlier
[historical report](2026-09-04-semantic-lint.md); its smaller inventory and
then-open roadmap items describe that earlier checkout, not current work.

The starting commit was
`000989dcbaaf548a68fefc943c88c4e19a6a6153`. Before semantic review,
`zig build verify --summary all` passed with exact Zig **0.16.0** on arm64
macOS **26.6.2 (25G83)**: **82/82 steps, 69/77 tests passed, eight skipped**.
The baseline contained the index plus 48 wiki pages, 53 source records, 30 Zig
proof files, and one C proof shim. All baseline pages, source records, proof
files, the shim, and their `build.zig` registrations were read. Platform skips
were not counted as native evidence.

The initial `zig build graph` result was **48 wiki pages, 449 directed wiki
edges, 48 strong, zero connected, zero weak, zero orphans**. A later graph run
after storage integration found **49 wiki pages, 470 directed wiki edges,
49 strong, zero connected, zero weak, zero orphans**. These are observations
of the two inspected working-tree states, not promises about later edits.

During the audit, other agents added [[durable-storage-and-recovery]], five
TigerBeetle source records, a Winsock/batched-dequeue source record, and
[the TCP/file proof](../proofs/windows_iocp_tcp_file.zig). Those additions
were also read, giving an inspected content total of **50 navigable pages,
59 source records, 31 Zig proofs, and one C shim**. The qualification proof's
source review is distinct from its subsequent native Windows gate.

After the report and registered additions were present, the local integration
gate passed **87/87 steps, 69/78 tests passed, nine skipped**, with the same
exact compiler and macOS environment. A first sandboxed attempt could not read
the external compiler source for generated-code inspection; the authorized
retry passed. The nine skips include Windows and Linux behavior that this Mac
cannot execute. Windows x86/x86_64/aarch64 linking is compile evidence only.

## Findings and resolutions

No critical or high finding was identified. Medium and low findings below
were sent to the owning agent for separate, reviewable edits. A resolution
means the indicated edit was reread; it does not certify uninspected future
changes or close an external evidence gap.

| ID | Status | Severity | Exact page / heading | Category | Evidence, consequence, and bounded correction |
| --- | --- | --- | --- | --- | --- |
| SL-20260904-001 | resolved; retained | medium | [[zig-0.16-release-inventory]] / release tables | evidence scope | The earlier report corrected prematurely integrated rows. Current OS-minimum and local-address watches remain explicit; `Thread.Pool` removal now routes to completed synchronization guidance. No old completion claim was restored. |
| SL-20260904-002 | resolved; retained | low | [[zig-0.16-baseline]] / release inventory link | retrieval | The natural baseline-to-inventory backlink remains present. |
| SL-20260904-003 | accepted; updated | note | [[steering-zig-fmt]] / whole page | graph quality | The narrow leaf has useful naming/style and proof routes. It is now strong; the earlier connected classification was accurate for its historical graph. |
| SL-20260904-004 | narrowed; external gaps retained | note | [[cancellation]] and the three platform I/O pages / evidence sections | runtime scope | Initial M1 cancellation and M3 lifecycle work now have named native evidence. Those runs do not establish arbitrary devices, power-loss behavior, cold-storage performance, or every native architecture. Keep those requirements in M3-006 and the runbook; do not perpetuate the old claim that all Linux/Windows runtime work is still outstanding. |
| SL-20260904-005 | resolved | low | [[code-reading-and-mechanical-checks]], [[trustworthy-microbenchmarks]] / frontmatter | schema | Both used `kind: workflow`, outside the `AGENTS.md` enumeration, while lint accepted it. Both now use `pattern`; `tools/lint_wiki.py` rejects unsupported wiki kinds. |
| SL-20260904-006 | resolved | low | [[deterministic-simulation-testing]] / Limits; [[io-threaded]] and [[process-init-and-capabilities]] / Evidence | stale roadmap/evidence | DST still said M1 must first inventory test I/O; the other pages still said Linux/Windows runners had not supplied evidence. They now link the completed testing inventory and actual native evidence while retaining the absence of a custom DST harness and untested startup/device cases. |
| SL-20260904-007 | resolved | medium | [[static-allocation-and-constant-work]] / The `std.Io.Threaded` seam | allocation | Exact `Threaded.async`/`concurrent` call `Future.create`, group dispatch calls `Group.Task.create`, and terminal cleanup frees records. Prewarmed workers therefore do not establish strict allocation-free dispatch. The corrected page distinguishes worker growth, per-dispatch allocator calls, bounded backing storage, and the single-threaded path. |
| SL-20260904-008 | resolved | medium | [[cancellation]] / Zig 0.16 `std.Io` contract | interface contract | `Group.await` had an ambiguous unconditional propagation statement. Exact `Io.Group.await` propagates cancellation received by the waiting caller; `Group.cancel` initiates it immediately. The page now states that condition and still requires joining members. |
| SL-20260904-009 | resolved | low | [[io-synchronization-primitives]] / `RwLock` | implementation wording | Writers were described as being kept from admission “as readers.” Exact `RwLock.lockShared` checks the writer state before its reader fast path and falls back to the internal mutex. The replacement describes that mechanism without promising fairness. |
| SL-20260904-010 | resolved | medium | [[macos-kqueue-and-aio]] / Apple Dispatch I/O lifecycle | cancellation outcome | The page said the terminal handler reports `ECANCELED` after best-effort stop without qualifying interruption. Pinned Apple `dispatch/io.h` limits that result to an interrupted operation (and submission on a closed channel). The correction preserves successful races and terminal ownership. |
| SL-20260904-011 | resolved during integration | medium | [[windows-iocp-and-overlapped-io]] / M3-006 acceptance criteria | proof/claim agreement | The draft claimed a five-second full-cycle criterion while the first inspected proof only enforced individual drain deadlines; it also claimed a printed rate that was then only derivable from elapsed time. The updated proof adds a maximum-cycle elapsed assertion and an explicit byte-rate field. The cycle assertion is diagnostic after completion: only the process/job watchdog can stop a blocked flush. Native results still require their own gate. |

## Graph review

| Graph band requiring individual review | Result | Semantic assessment |
| --- | --- | --- |
| Orphan | none | No unindexed, unlinked decision page was found. |
| Weak | none | No weak page needs an invented backlink. |
| Connected | none | All inspected pages are strong; counts alone do not prove relevance. |

The index routes capability, lifetime, synchronization, clocks, files,
networking, platform, and engineering decisions to separate pages. The
platform comparison links detailed platform evidence rather than duplicating
every lifecycle. The new storage page adds recovery authority and block reuse
to the existing file-API page; its reciprocal links preserve that distinction.
No overlapping page was identified that should be merged merely to improve
graph counts.

## Explicit checks that passed

- **Version and source layers:** `.zig-version` remains 0.16.0; no executable
  Zig was copied into wiki fences. Existing cited source records were not
  rewritten by this integration. New records retain exact revisions and
  distinguish upstream implementation evidence from current Zig examples.
  Baseline verification checked the four portable snapshot hashes.
- **Capability and scheduling:** [[std-io]], [[async-vs-concurrent]],
  [[io-threaded]], and [[task-lifetimes-and-structured-concurrency]] keep
  interface contracts, eager fallback, fallible independent progress,
  owned results, and concrete runtime resource limits separate.
- **Cancellation and fixed storage:** cancellation, Select/Batch, and
  synchronization guidance preserves request versus terminal acknowledgement,
  storage lifetime, result draining, cancellation propagation, queue close/drain,
  permit balance, predicate loops, and the absence of a universal fairness
  guarantee. `Batch.init` already explicitly requires at least one slot;
  exact `Operation.OptionalIndex` also constrains representable capacity.
- **Time, retries, testing, entropy:** clock domains and one-deadline budgets
  remain explicit; the retry fixture is a controlled script rather than a
  claim to bound arbitrary blocking attempts. `Io.failing` is a fixed hostile
  profile, not a deterministic scheduler. Randomness fallback, fresh-entropy
  failure, strict-clock overflow/synchronization, and test-runner scope remain
  visible.
- **Files, processes, networking:** atomic namespace publication is separate
  from directory and physical persistence. Buffered flush is separate from
  truncation. Child-process output limits, resource cleanup, stream partial
  results, and DNS/race admission remain qualified by the exact implementation
  and proof scope. No loopback fixture was promoted to a DNS or remote-network
  qualification campaign.
- **TigerStyle:** the complete pinned style source was reread against the
  coverage map and focused pages. The 71-rule inventory is guidance coverage,
  not automatic project conformance. Allocation, integer widths, assertions,
  control flow, state lifetime, encoding, diagnostics, naming, dependency
  admission, and tooling exceptions have concrete consequences. Ordinary
  zeroing is not called secure erasure, and native layout is not called a
  portable serialization format.
- **Linux:** the `io_uring` fixture has finite submission storage, runtime
  opcode/feature checks, registered-file reference ownership, and separate
  target/cancel CQEs. Its exact success case is not evidence that every
  cancellation wins or every kernel/device is supported.
- **macOS:** the Dispatch C shim copies callback data before releasing its
  handler lifetime and joins before exposing the caller buffer. The page
  distinguishes readiness, Dispatch I/O channels, POSIX AIO, and Zig's own
  experimental Dispatch implementation; synchronous positional syscalls,
  60 MiB fibers, unavailable paths, and broken backend teardown are retained.
- **Windows baseline:** APC and IOCP remain different mechanisms. The
  test-only alert workaround does not repair `Threaded.batchCancel`.
  Stable operation records, both immediate-success notification policies,
  canceled side-effect ambiguity, non-null failed completion handling,
  control-packet identity, and cancel-before-drain shutdown remain explicit.
- **New Windows fixture:** all TCP/file proof code was reviewed for buffer,
  operation, socket, file, port, and Winsock lifetime. Per-entry result calls
  happen after batched dequeue; reserved `OVERLAPPED_ENTRY.Internal` is not
  treated as a public error field. Failed result byte counts are not trusted.
  Cleanup runs before handle closes; a failed drain ends the test process
  rather than unwinding live kernel-owned records. The observed batch size,
  immediate/pending counts, and cancellation outcomes must be reported as
  measured, including when an expected race outcome is not observed.
- **New storage synthesis:** primary `Grid.cancel`/`cancel_join_callback`,
  `FreeSet.mark_checkpoint_durable`, superblock quorum selection, and forest
  reservation paths support the distinctions between logical queue clearing,
  outstanding-I/O drain, delayed reuse, local-copy quorums, and per-beat
  compaction admission. Fatal storage/node exhaustion is preserved rather
  than redescribed as graceful overload. No TigerBeetle engine or power-loss
  test was run as part of this source ingest.

## Primary-material scope and limits

Exact installed Zig source was checked for material scheduling, allocation,
group cancellation, Batch storage, reader/writer synchronization, clock,
entropy, and file-publication claims. The Apple cancellation qualification was
checked against `dispatch/io.h` at
`2361ffb78a76f7ee488cd052eb0bc5c767118bf9`. Existing Windows SDK/NT contracts
and the new Winsock source record were reviewed with the proofs. The local
TigerBeetle and matklad checkouts report their recorded immutable commits,
`47aeb2212a255273dda508288412e537d11e4b7c` and
`ff6734c93ac8b41677dee016af6bb67c39420101`.

Reading every source record is not the same as refetching every remote byte or
auditing all of the upstream projects. This pass used focused primary material
for the material claims, and did not repeat the entire TigerBeetle engine
audit, inspect arbitrary Windows drivers, or independently rerun every
historical performance sample. Local verification is not the final pushed
Linux/Windows gate; those publication receipts belong in the handoff and
platform evidence sections.

## Roadmap effects and excerpt design

The old M0/M1/M2 completion records survive this audit. M3-006 still needs its
explicit external qualification criteria; a green small hosted fixture does
not close physical persistence, controlled cold storage, native-architecture,
arbitrary-driver, or unspecified production-SLO gaps. M4 remains reserved for
the user's separate implementation session. Reviewing these boundaries does
not itself complete them.

The snippet-tangling research item has a bounded design in
[ADR 0002](../docs/decisions/0002-verified-proof-excerpts.md): registered proofs
stay canonical, stable marked regions produce disposable output, and a
manifest binds full-proof/excerpt hashes to exact compiler, target,
publication revision, and runtime-versus-compile evidence. The design rejects
missing/ambiguous markers and escaped paths, preserves full-proof links, and
does not pretend an excerpt compiles independently. Implementation and fence
permission remain disabled until the resolver and verification gates exist.

The audit does not approve future content mutation or silently expand the
read-only maintenance workflow's authority. Integration and final publication
checks remain the responsibility of the owning session.
