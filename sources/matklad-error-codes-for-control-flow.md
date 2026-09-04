---
id: source-matklad-error-codes-for-control-flow
title: matklad — Error Codes for Control Flow
kind: source
status: captured
summary: Separates branching and recovery from human-facing reporting, interpreting Zig error sets as typed control-flow codes rather than payload unions.
captured: 2026-09-04
revision: ff6734c93ac8b41677dee016af6bb67c39420101
url: https://matklad.github.io/2025/11/06/error-codes-for-control-flow.html
---

# matklad — Error Codes for Control Flow

Pinned to the `matklad.github.io` repository commit recorded above. The essay
explains why a Zig error name can remain small and branchable while a separate
optional diagnostics sink carries source locations, paths, and presentation
state.

Relevant pages: [[error-handling-and-diagnostics]], [[error-context]].
