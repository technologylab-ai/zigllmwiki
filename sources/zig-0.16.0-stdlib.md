---
id: source-zig-0-16-stdlib
title: Zig 0.16.0 standard-library source
kind: source
status: captured
summary: Exact API contracts and implementation behavior from the installed Zig 0.16.0 distribution.
captured: 2026-09-04
revision: "zig tag 0.16.0; 44d9672fed001115e674fd5ddb32747ef43a7af4"
url: https://ziglang.org/documentation/0.16.0/std/
---

# Zig 0.16.0 standard-library source

The local compiler reported `0.16.0` through `zig version`. `std/Io.zig` is the
interface-contract source; `std/Io/Threaded.zig` is the source for the default
threaded implementation, including `async_limit`, `concurrent_limit`, eager
fallback, allocation, and thread growth.

Do not carry file line numbers into wiki claims: paths and declarations are
stable enough for retrieval, while line numbers create copied state.

Relevant pages: [[process-init-and-capabilities]], [[std-io]],
[[async-vs-concurrent]], [[select-and-batch]], and [[evented-io-backends]].
