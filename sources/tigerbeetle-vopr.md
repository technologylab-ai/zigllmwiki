---
id: source-tigerbeetle-vopr
title: TigerBeetle deterministic simulation testing
kind: source
status: captured
summary: Primary overview of VOPR's deterministic clock, network and disk simulation, fault injection, reproduction, assertions, and checkers.
captured: 2026-09-04
revision: 47aeb2212a255273dda508288412e537d11e4b7c
url: https://github.com/tigerbeetle/tigerbeetle/blob/47aeb2212a255273dda508288412e537d11e4b7c/docs/internals/vopr.md
---

# TigerBeetle deterministic simulation testing

Pinned to the TigerBeetle commit recorded above. VOPR replaces the clock,
network, and disk nondeterminism, drives faults from a seed, runs production
code, and records the Git revision so failures can be replayed. Assertions and
external state checkers turn unusual schedules and faults into precise stops.

Relevant page: [[deterministic-simulation-testing]].
