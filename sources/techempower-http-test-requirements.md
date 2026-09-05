---
id: source-techempower-http-test-requirements
title: TechEmpower HTTP test requirements
kind: source
status: captured
summary: Revision-pinned plaintext and JSON requirements constrain meaningful HTTP framework comparisons.
captured: 2026-09-05
revision: "3be9618978e68b1a953f0c1a9cb642440c064fd8"
url: https://github.com/TechEmpower/FrameworkBenchmarks/wiki/Project-Information-Framework-Tests-Overview/3be9618978e68b1a953f0c1a9cb642440c064fd8
---

# TechEmpower HTTP test requirements

Origin: `https://github.com/TechEmpower/FrameworkBenchmarks.wiki.git`.
Verified the remote HEAD and fetched commit above on 2026-09-05. Inspected
`Project-Information-Framework-Tests-Overview.md`, general requirements and
the plaintext and JSON sections. The Git wiki commit is the revision authority.

Plaintext exercises routing and pipelining. Both tests require Server and Date
headers. A static plaintext body is allowed; a pre-rendered entire response
is not. JSON requires per-request serialization rather than cached output.

This record captures test semantics, not a leaderboard, current test hardware,
or a framework ranking. A Mac measurement must identify its own environment;
comparison with published runs on other hardware cannot establish rank.
