---
id: source-apple-libdispatch-io
title: Apple libdispatch I/O interface headers
kind: source
status: captured
summary: Revision-pinned Apple headers define Dispatch I/O channel, data, callback, batching-policy, descriptor-ownership, and best-effort stop semantics.
captured: 2026-09-04
revision: 2361ffb78a76f7ee488cd052eb0bc5c767118bf9
url: https://github.com/apple-oss-distributions/libdispatch/tree/2361ffb78a76f7ee488cd052eb0bc5c767118bf9
---

# Apple libdispatch I/O interface headers

Pinned to Apple libdispatch commit
`2361ffb78a76f7ee488cd052eb0bc5c767118bf9`. The focused primary-source paths
are `dispatch/io.h` and `dispatch/data.h`.

Use `dispatch/io.h` for these interface contracts:

- stream channels serialize operations of the same type at the channel's file
  position, while random-access channels accept offsets and may run operations
  concurrently;
- the system controls a descriptor associated with a channel and may change
  flags such as `O_NONBLOCK`; direct application mutation during that interval
  is an error;
- a read or write handler may run more than once, but is non-reentrant for its
  operation, and only `done` marks its terminal invocation;
- reads deliver `dispatch_data_t` objects whose automatic handler-scope
  lifetime requires retaining, concatenating, or copying for later use;
- writes retain their input dispatch-data object until completion;
- low-water, high-water, and interval policies shape partial-result delivery;
- `DISPATCH_IO_STOP` makes a best-effort interruption attempt, permits partial
  results, and terminates an interrupted operation with `ECANCELED`;
- a barrier orders operations across channels sharing a descriptor and is the
  documented place for direct operations such as `fsync` and `lseek`.

Use `dispatch/data.h` for copy-versus-borrow ownership at dispatch-data
creation and for the lifetime of mapped contiguous views.

These headers do not establish comparative performance, fairness, filesystem
behavior, or a bounded admission policy. Those require an application-specific
wrapper and runtime measurements.

Relevant page: [[macos-kqueue-and-aio]].
