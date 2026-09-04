---
id: source-microsoft-windows-nt-fs-control
title: Microsoft NtFsControlFile APC and completion-context contract
kind: source
status: captured
summary: Pinned Microsoft NT filesystem-control documentation separating APC callbacks from completion-port contexts and preserving final IO_STATUS_BLOCK interpretation.
captured: 2026-09-04
revision: 7515063cea4c9e98db6a92986c5b4ddb0463fd16
url: https://github.com/MicrosoftDocs/windows-driver-docs-ddi/blob/7515063cea4c9e98db6a92986c5b4ddb0463fd16/wdk-ddi-src/content/ntifs/nf-ntifs-ntfscontrolfile.md
---

# Microsoft `NtFsControlFile` APC and completion-context contract

Pinned to MicrosoftDocs/windows-driver-docs-ddi commit
`7515063cea4c9e98db6a92986c5b4ddb0463fd16`. GitHub's commit API resolved
that exact commit and tree `c34b77f23db42b1d1a9de4e95082ebc9a4fbeab1` on
2026-09-04; the focused file was retrieved at that revision after the plan-only
ingest command.

The file is `wdk-ddi-src/content/ntifs/nf-ntifs-ntfscontrolfile.md`. Use its
parameter and remarks sections for:

- asynchronous-handle requirements for callback/completion contexts;
- the prohibition on supplying an APC routine for a handle already associated
  with an I/O completion object;
- the different interpretation of `ApcContext` as callback context or port
  completion identity;
- final status and output byte count in `IO_STATUS_BLOCK`;
- per-control-code input/output requirements and the caller's buffer ownership.

The pinned page contains a documentation inconsistency: its return discussion
mentions an `Asynchronous` parameter absent from this function's signature.
Do not synthesize that nonexistent parameter. Use the parameter/remarks
sections together with the exact installed Zig declarations and implementation
in [[zig-0.16-windows-io-source]]. This record establishes neither a universal
driver cancellation guarantee nor runtime evidence for a particular FSCTL.

Relevant pages: [[windows-iocp-and-overlapped-io]] and [[select-and-batch]].
