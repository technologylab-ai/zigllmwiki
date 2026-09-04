---
id: source-microsoft-windows-winsock-batched-file-io
title: Microsoft Winsock, batched IOCP dequeue, and file flush contracts
kind: source
status: captured
summary: Pinned public API evidence for overlapped TCP ownership and partial results, per-entry batched completion errors, and file flush boundaries.
captured: 2026-09-04
revision: 5f2625b6782d3e9c0df08756583c527a0a2872ca
url: https://github.com/MicrosoftDocs/sdk-api/tree/5f2625b6782d3e9c0df08756583c527a0a2872ca/sdk-api-src/content/winsock2
---

# Microsoft Winsock, batched IOCP dequeue, and file flush contracts

MicrosoftDocs/sdk-api commit `5f2625b6782d3e9c0df08756583c527a0a2872ca`
was resolved through GitHub's commit API on 2026-09-04; its tree is
`dfde8fe2c7e0b9aca036b727aa7b433c6352f4d5`. The focused files below were
retrieved from that exact commit. This additional source slice preserves
[[microsoft-windows-iocp-api]] unchanged.

Paths are relative to `sdk-api-src/content/`:

| Primary source paths | Supported claims and limits |
| --- | --- |
| `winsock2/nf-winsock2-{wsastartup,wsasocketw,bind,listen,getsockname,connect,accept,closesocket}.md` | Winsock initialization and negotiated version; explicit overlapped socket creation; loopback listener/connection setup; socket ownership and close behavior. Setup calls can block and belong outside the proof's measured transfer path. |
| `winsock2/nf-winsock2-wsarecv.md` | Stable operation/buffer ownership; immediate success versus pending versus failed initiation; TCP byte-stream partial results and zero-byte graceful EOF; provider capture of WSABUF descriptors does not expire payload lifetime. |
| `winsock2/nf-winsock2-wsasend.md` | Overlapped send lifetime and initiation outcomes; local completion does not establish application receipt by the peer. |
| `winsock2/nf-winsock2-wsagetoverlappedresult.md` | Nonwaiting per-operation result and receive flags; failure leaves the byte-count output unspecified by the successful-result contract; pending is not a terminal result. |
| `winsock2/nf-winsock2-shutdown.md` | Separate send/receive shutdown and close; a graceful byte-stream receive observes zero bytes after the peer shuts down sends. |
| `ioapiset/nf-ioapiset-getqueuedcompletionstatusex.md` | A fixed entry array bounds one dequeue batch; a successful dequeue can include failed operations, each requiring its own result classification. |
| `minwinbase/ns-minwinbase-overlapped_entry.md` | Completion key, operation pointer, and byte count identify each entry; `Internal` is reserved, so application code must not treat it as a documented Win32 error field. |
| `fileapi/nf-fileapi-flushfilebuffers.md` | File flush requires write access and requests buffered data be written to the device; the call itself does not constitute a destructive power-loss experiment or identify the physical persistence guarantees of a virtual disk. |

The pinned Zig release's bundled Windows headers additionally supply the
architecture-dependent `WSADATA` layout in
`lib/libc/include/any-windows-any/psdk_inc/_wsadata.h`. That declaration is
exact-release implementation evidence under [[zig-0.16-windows-io-source]],
not a new portable `std.Io` contract.

Relevant pages: [[windows-iocp-and-overlapped-io]],
[[platform-io-backend-decision-table]],
[[files-buffering-and-atomic-persistence]], and [[networking-and-dns-racing]].
