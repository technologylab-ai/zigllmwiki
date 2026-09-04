---
id: source-microsoft-windows-iocp-api
title: Microsoft Windows IOCP, named-pipe, and watchdog API contracts
kind: source
status: captured
summary: Pinned Win32 API contracts for terminal IOCP packets, skip-on-success, named-pipe fixtures, bounded timing, and process watchdog failure behavior.
captured: 2026-09-04
revision: 5f2625b6782d3e9c0df08756583c527a0a2872ca
url: https://github.com/MicrosoftDocs/sdk-api/tree/5f2625b6782d3e9c0df08756583c527a0a2872ca/sdk-api-src/content
---

# Microsoft Windows IOCP, named-pipe, and watchdog API contracts

Pinned to MicrosoftDocs/sdk-api commit
`5f2625b6782d3e9c0df08756583c527a0a2872ca`, resolved and independently
retrieved through GitHub's commit API on 2026-09-04. The returned tree was
`dfde8fe2c7e0b9aca036b727aa7b433c6352f4d5`. Focused files were retrieved
from that exact commit; no moving branch is evidence for this record.

All paths below are relative to `sdk-api-src/content/`:

| Paths | Evidence boundary |
| --- | --- |
| `ioapiset/nf-ioapiset-createiocompletionport.md` | Overlapped handle association, completion keys, port concurrency, and association lifetime. |
| `ioapiset/nf-ioapiset-getqueuedcompletionstatus.md` | A failed call with a non-null operation pointer dequeued a failed terminal packet; a null pointer on failure means no packet and leaves byte/key outputs indeterminate. |
| `ioapiset/nf-ioapiset-postqueuedcompletionstatus.md` | Caller-selected control packets; the system does not validate their key, byte count, or operation pointer. |
| `ioapiset/nf-ioapiset-cancelioex.md` | Cancellation requests return before completion; success, abort, another failure, and a no-matching-request race remain distinct. |
| `ioapiset/nf-ioapiset-getoverlappedresult.md` | Nonblocking terminal-result inspection and returned byte counts. |
| `winbase/nf-winbase-setfilecompletionnotificationmodes.md` | Skip-on-success suppresses a port entry only for immediate success; a mode cannot be removed after setting it on a handle. |
| `minwinbase/ns-minwinbase-overlapped.md` | Per-request stable records, initialized unused members, explicit offsets, and buffer/control-record reuse boundaries. |
| `fileapi/nf-fileapi-{createfilew,readfile,writefile}.md` | Asynchronous handles, immediate versus pending results, referenced-buffer ownership, and potentially synchronous execution even for an asynchronous handle. |
| `namedpipeapi/nf-namedpipeapi-{createnamedpipew,connectnamedpipe,setnamedpipehandlestate,transactnamedpipe,peeknamedpipe}.md` | Duplex/message fixtures, client default byte-read mode, connected-before-connect races, transaction completion, non-consuming inspection, and advisory kernel buffer reservations. |
| `profileapi/nf-profileapi-{queryperformancecounter,queryperformancefrequency}.md` | Counter ticks and frequency for elapsed-time measurements. |
| `sysinfoapi/nf-sysinfoapi-gettickcount64.md` and `synchapi/nf-synchapi-sleep.md` | Coarse elapsed-time checks and scheduler-dependent sleep behavior; these do not create a hard real-time deadline. |
| `processthreadsapi/nf-processthreadsapi-{exitprocess,terminateprocess}.md` | `ExitProcess` may deadlock during DLL detach; `TerminateProcess` avoids that callback path but process exit still depends on pending I/O becoming completed or canceled. |

This record extends [[microsoft-windows-iocp]] without changing its pinned
evidence. API contracts do not prove that a fixture ran, that cancellation won
a particular race, or that an arbitrary driver meets a latency bound. The
named-pipe transaction contract also does not make private AFD or other device
protocols public application APIs.

Relevant pages: [[windows-iocp-and-overlapped-io]], [[select-and-batch]],
[[platform-io-backend-decision-table]], and [[cancellation]].
