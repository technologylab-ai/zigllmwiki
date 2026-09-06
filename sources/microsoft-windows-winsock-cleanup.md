---
id: source-microsoft-windows-winsock-cleanup
title: Microsoft Winsock startup references and final process cleanup
kind: source
status: captured
summary: Final Winsock cleanup affects every process thread, so independent socket owners must retain startup references until terminal reconciliation.
captured: 2026-09-06
revision: 5f2625b6782d3e9c0df08756583c527a0a2872ca
url: https://github.com/MicrosoftDocs/sdk-api/blob/5f2625b6782d3e9c0df08756583c527a0a2872ca/sdk-api-src/content/winsock/nf-winsock-wsacleanup.md
snapshot: sources/snapshots/microsoft-windows-winsock-cleanup.json
sha256: "a05a99fba950b5ba2d727e68b68084d66a9a10ec8c76b24863d6eeb953179150"
---

# Winsock startup references and cleanup

The curator retrieved the complete `WSACleanup` documentation from the pinned Microsoft SDK API tree on 2026-09-06.
The Git blob is `67d9c20fcb918f9a26c12d4266a3a881e6115f38`.
The original 7,093 bytes have SHA-256 `5dfdd86ff5e568ae2c1b564897c5b7808909122bb550e5644dc5e5e9bc7e76a3`.
The curator checked both identifiers before creating this record.
The snapshot preserves the raw document and retrieval metadata.

A startup reference records one successful `WSAStartup` call.
The application must balance each successful call with `WSACleanup`.
Only the final cleanup call performs actual cleanup; earlier calls decrement the internal reference count.
Final cleanup affects Winsock operations from every thread in the process.
Pending asynchronous operations can be canceled without notification messages, event signals, or completion routines.
Cleanup can also reset open sockets and discard pending data.
These contracts describe Windows APIs, rather than a Zig `std.Io` implementation.

Design inference: independent socket owners must preserve startup references until every owner finishes terminal reconciliation.
Final cleanup cannot replace an adapter's ordinary cancellation-and-drain protocol.
The documentation supplies no provider-progress deadline or production qualification.

[[microsoft-windows-acceptex-provider]] retains the separate accepted-socket and background-close contracts.
[[microsoft-windows-iocp-api]] retains the association and cancellation contracts.
Application: [[bounded-http-server-design]] and [[windows-iocp-and-overlapped-io]].
