---
id: source-zig-http-arena-shards-2026-09-05
title: Output arena, constant-work request path and reuse-port shards
kind: source
status: captured
summary: Exact Zig0.16 Linux/macOS branch replacing fixed response cells with a per-connection arena, ready-ring scheduling, lane-scanning parsing, cell-addressed transport and shards; interleaved pairs reach0.85–1.05 of libreactor at the compared cells.
captured: 2026-09-05
revision: "ad424c7"
url: https://github.com/technologylab-ai/zig-http/tree/perf/arena-shards/reports/2026-09-05-arena-shards.md
snapshot: sources/snapshots/zig-http-arena-shards-2026-09-05.json.gz
sha256: "b126cb6bdec9df0339e50992cc0b913c5a2580aa997d661eca829378fd05f8ba"
---

# Pinned local artifact

At capture the branch `perf/arena-shards` existed only in the user's local
`zig-http` checkout (measured commit `ad424c7`, report commit `122e903`,
merge with main `d5b6d9b` on `perf/arena-shards-plus-main`); the URL above
resolves only once the branch is pushed. The snapshot preserves the report
`reports/2026-09-05-arena-shards.md` (SHA-256
`a06d912ebef8516abe10d78d4c9930e17679e42f8633646baea2743bb8375693`) and the
design `docs/PERF-ARCHITECTURE.md` (SHA-256
`18cd9ee6e19e3cfd223bc2909d707959006fbc0163413b329e6d58e9e0d7b665`);
uncompressed snapshot SHA-256
`dc07684b5963d02f83c2a9622c8e7a39d31771763d8f16b838ef7072d86045df`. The Linux
ReleaseSafe binary at `ad424c7` is
`643da6810ff6b8b2e0c557021d53abbc5de9a435a13c0b4a85a2f6227798250d`.

# What the branch changes

Inspected server, parser, writer, main, both transports and the wire suites.

- One contiguous output arena per connection (default 64 KiB) replaces sixteen
  4 KiB cells. `begin()` writes the response head at once from a per-second
  cached status/Server/Date prefix without `std.fmt`; generated bodies follow;
  borrowed spans of at most 256 bytes are copied and counted; larger borrows
  stay separate vectors. A cell is a 40-byte arena range plus optional borrow;
  the default batch limit is 128 (1–511). A batch of small responses is one
  span and one SEND.
- The loop services a FIFO ready ring rather than scanning every slot; the
  clock is sampled per turn and every 16 callbacks; deadlines are swept every
  100 ms; free slots are a stack; the callback budget is configured.
- The parser finds each line end with one 16-byte lane pass that validates
  CR/LF placement in the same pass, classifies octets with tables, dispatches
  interpreted field names by length, compares fixed names as masked integers
  and parses into the caller's request in place.
- Transport operations are addressed by fixed cells (receive, send, and their
  cancel cells per connection, plus accept/cancel-accept); admission and
  completion matching never search; gather vectors are caller-owned startup
  storage referenced without copying; the Linux ring requests COOP_TASKRUN.
- A cluster runs one complete server per allowed CPU on Linux, each with its
  own SO_REUSEPORT listener, ring, slots and arenas; every shard keeps full
  slot capacity and a shared atomic counter enforces the process ceiling.
  macOS keeps one shard: XNU delivered every connection to the last-bound
  listener in the branch's SHARDS counters.
- Pre-armed receives and eager submission are implemented and off by default.

# Measurements (direction, interleaved pairs, host in desktop use)

omarx1, performance profile, wrk 4 threads on CPUs 3–7, 128 connections,
each Zig run followed by a libreactor run under the same mask; one or two
repetitions per cell; libreactor itself varied 5.5–7.8M/s across sessions on
one cell, so only within-pair ratios are meaningful:

| Cell | Zig (CPU) | libreactor (CPU) |
| --- | ---: | ---: |
| CPUs 0–2, depth 16, 3 shards | 7.17M / 7.03M (162–166%) | 7.71M / 7.58M (122%) |
| CPU 0, depth 16 | 3.73M / 3.52M (71%) | 4.37M / 3.29M (62%) |
| CPU 0, depth 128 | 6.90M / 6.57M (89%) | 9.99M / 10.0M (82%) |
| CPUs 0–2, depth 128, 3 shards | 11.5M / 11.1M (202–204%) | 13.2M / 13.2M (122%) |
| CPUs 0–2, depth 1, 3 shards | 588k / 549k (177%) | 558k / 568k (142%) |

Mac M3 Max, one kqueue thread: depth 16 rose from 1.43M/s at the branch
point to 3.20M/s, depth 128 from 1.17M/s to 7.60M/s across the commits. The
pre-armed receive measured 6–16% slower on kqueue (a failed recv plus a
kevent registration per pipeline) and no change on io_uring at depths 1, 16
and 128 while raising CPU; smaller per-turn budgets did not help either.

# Native gates

Mac: Debug and ReleaseSafe unit tests (62 executions each), 26 generic, 10
inline, 11 gather and 25 batch wire cases including overlap variants. Linux
omarx1 (kernel 7.1.9, io_uring enabled): the same unit gates, 25 + 11 + 10 +
26 wire cases with eight auto shards and the shared ceiling in force, and the
30,000-response smoke. The merge with main adds four maximum-64-cell chunked
fixtures (29 batch cases) and passes both gates again. These are finite
witnesses; no qualified three-repetition shuffled comparison of this branch
exists yet.
