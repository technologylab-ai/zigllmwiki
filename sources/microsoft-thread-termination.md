---
id: source-microsoft-thread-termination
title: Microsoft thread termination and shared-state hazards
kind: source
status: captured
summary: Pinned TerminateThread contract explains why forcibly ending arbitrary callbacks is not a safe worker-pool reclamation policy.
captured: 2026-09-05
revision: "5f2625b6782d3e9c0df08756583c527a0a2872ca"
url: https://github.com/MicrosoftDocs/sdk-api/blob/5f2625b6782d3e9c0df08756583c527a0a2872ca/sdk-api-src/content/processthreadsapi/nf-processthreadsapi-terminatethread.md
---

# Thread termination boundary

Read the complete pinned `TerminateThread` record. The target executes no
user-mode cleanup. Critical sections or heap locks can remain held, and shared
process/library state can be damaged. This Windows API is therefore not a
generic way to enforce callback deadlines while preserving a healthy server.

This is vendor documentation, not a termination experiment or a claim about
POSIX cancellation semantics. M4's proposed worker model instead retains
borrowed memory until acknowledged return. Stronger isolation needs a separate
process/sandbox design and platform evidence; it is not supplied by this record.
