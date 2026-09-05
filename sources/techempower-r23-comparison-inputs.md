---
id: source-techempower-r23-comparison-inputs
title: TechEmpower Round 23 plaintext results and comparison inputs
kind: source
status: captured
summary: Round 23 result bytes, exact libreactor and mrhttp submissions, and pinned wrk distinguish published rankings from a local Linux comparison.
captured: 2026-09-05
revision: "523534bb61450e3522d775a749ad060753e26e3a"
url: https://github.com/TechEmpower/FrameworkBenchmarks/tree/523534bb61450e3522d775a749ad060753e26e3a
snapshot: sources/snapshots/techempower-r23-results.json.gz
sha256: "347b402e3afd83fde507cba72d56842614652fabbb6734808b72eb59b36c1c1a"
---

# Pinned comparison inputs

The official results site identified Round 23 (2025-02-24) as the latest
published round when inspected on 2026-09-05. Its
[results JSON](https://www.techempower.com/benchmarks/results/round23/ph.json)
was captured before synthesis: 5,027,231 uncompressed bytes, SHA-256
`9300a12950f64852af228556e342896e971122cf821433382d7f8b6d432c1023`.
The deterministic gzip snapshot above preserves those exact bytes. The JSON
names repository commit `523534bb61450e3522d775a749ad060753e26e3a`, also resolved
by the R23 tag. Its internal run began 2025-01-30; do not confuse that with the
round's display date or the later publication announcement.

`rawData.plaintext` contains four 15-second samples per submission, at
256/1024/4096/16384 connections. Ranking by maximum `totalRequests / 15` gives
mrhttp 28,384,305.73, faf 28,034,705.07, libreactor 28,025,992.53, pico.v
28,025,837.87, silverlining-prefork 27,997,694.93, and uwebsockets.js
27,991,649.07 responses/s. These best samples report no errors. These are
published plaintext rankings, not overall framework rankings. The official
ProLiant/40GbE environment differs from omarx1 and maxross; ratios between
these published numbers and our local measurements would not isolate servers.

## libreactor, plaintext rank 3

Inspected the exact
[submission and Docker recipe](https://github.com/TechEmpower/FrameworkBenchmarks/tree/523534bb61450e3522d775a749ad060753e26e3a/frameworks/C/libreactor),
including `src/libreactor.c`, `src/helpers.c`, `Makefile`, and
`libreactor.dockerfile`. Dependency revisions are libreactor
`63fa717a8047b1b5c38bc1d69ad193050e4f0ef7`, libdynamic
`5aacfb1bc8aee9468041313a38a15b086c9d0ee2` (v2.2.0), and libclo
`cc815bded704919246685093d0574bcf8cafd561` (v1.0.0).

The [server loop](https://github.com/fredrikwidlund/libreactor/blob/63fa717a8047b1b5c38bc1d69ad193050e4f0ef7/src/reactor/server.c)
parses complete requests from a read chunk, invokes callbacks inline and
flushes accumulated output once after that loop. Response construction copies
headers and body into extensible output storage. Date is cached per worker and
updated by a timer. The submission forks once per CPU in sched_getaffinity and
uses a CPU-number SO_ATTACH_REUSEPORT_CBPF selector. Its worker distribution
must be observed in loopback experiments with disjoint client CPUs.

The original recipe uses GCC 10 and optimized native/LTO compilation. Native
GCC 16 on omarx1 is a recorded toolchain deviation, not a reconstruction of
the original compiler. The local app changes only its bind to loopback;
private library installation and libclo's unused include removal follow the
build recipe. Pinned build/binary receipts belong with the measurement packet.

## mrhttp, plaintext rank 1

Inspected the exact
[Python submission](https://github.com/TechEmpower/FrameworkBenchmarks/tree/523534bb61450e3522d775a749ad060753e26e3a/frameworks/Python/mrhttp).
Its Python 3.8.12 recipe pins mrhttp 0.12, uvloop 0.19.0, mrjson 1.4, ujson
5.4.0, mrpacker 1.5 and asyncpg 0.25.0. The route has `options=['cache']` and
returns `Hello, world!` with lowercase w. Preserve that exact upstream body
and disclose its difference from our canonical `Hello, World!`; both are 13
bytes and accepted by the TFB validator.

The mrhttp 0.12
[source artifact](https://files.pythonhosted.org/packages/c7/02/5a2cc7b0a80a7d696799a300f20e4e165c15f3fca7bc6de5b45884834741/mrhttp-0.12.tar.gz)
has SHA-256 `7fd86c70e1af6f741287df8c01740e46dbb9ef33b5caba250e73c7b90094e68d`.
In that archive, `src/mrhttp/internals/router.c:110` calls the cached
Python route during router construction; `protocol.c:543` serves its cached body
before the ordinary per-request Python handler branch. `protocol.c:670` still
copies headers/body, creates Python bytes and invokes transport.write.
`src/mrhttp/app.py:311` schedules Date refresh every second. It does not call arbitrary Python application code per request.
The x86-64 native extension is not a native M3 Mac comparison candidate.

Local execution uses the exact official Python 3.8.12 image pinned by digest,
hashed CPython 3.8 wheels, and a source-built mrpacker. Debian 11 container
userland shares the host Linux kernel and loopback network. Explicit cores=3
replaces cpu_count(), which otherwise ignores this affinity budget; address
and worker count are the only app adaptations. This preserves the cached route
but does not establish original wheel compiler flags or equal resource policies.

## Load generator and excluded reconstruction

[wrk 4.2.0](https://github.com/wg/wrk/tree/a211dd5a7050b1f9e8a9870b95513060e72ac4a0)
is pinned at `a211dd5a7050b1f9e8a9870b95513060e72ac4a0`. Its `src/wrk.c`
counts each complete response, so do not multiply its RPS by pipeline depth.
Latency is sampled when the whole pending pipeline batch completes, followed
by histogram correction before the script's `done` callback. It is not
per-response tail latency or an open-loop arrival/SLO experiment. A custom Lua
request callback retains per-batch Lua/buffer overhead even when formatting
and request bytes are cached. Record client CPU and sensitivity to client
thread count before interpreting a plateau as server capacity.

The pinned `src/stats.c:33` correction adds synthetic counts below the original
`stats.min` without lowering that minimum. `stats_percentile()` scans from the
unchanged minimum while ranking against the enlarged count, and can return its
zero fallback. For example, a single 100-microsecond sample corrected with
expected=10 adds eight synthetic samples (90 through 20); rank 9 for p99 sees
only the original sample in the scan starting at 100 and returns zero. Local
pipeline runs observed positive means/maxima with p99=0. Preserve raw values
for audit; do not interpret zero as zero-latency service. This is independent
of `summary.requests`/elapsed throughput, and merely checking percentile order
does not establish validity of all other corrected histograms.

faf's R23 manifest has an unpinned git dependency plus cargo update. A nearby
commit does not identify the dependency used for the published result. This
comparison excludes it rather than claiming an exact R23 reconstruction.

These inputs support [[bounded-http-server-design]] and
[[trustworthy-microbenchmarks]]. Local execution/results require a separate
source-hashed packet; this record alone proves no measured throughput.
