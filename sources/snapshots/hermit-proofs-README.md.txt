# proofs/

Small, self-contained Zig programs that produced the numbers quoted in the
talk and in [`docs/zig-codebase.md`](../docs/zig-codebase.md). They exist so the
claims can be re-measured rather than believed.

Nothing here is part of the hermit build.

## `io-timeout.zig` — how to time out under a full runtime

Four ways to bound an operation, measured side by side.

```sh
zig build-exe proofs/io-timeout.zig -target aarch64-linux-gnu -O ReleaseSafe \
  -femit-bin=/tmp/io-timeout
scp /tmp/io-timeout hermit:/tmp/
ssh hermit '/tmp/io-timeout <busy-tasks> <work-ms> [async-limit]'
```

| variant | shape |
| --- | --- |
| A | `Select`, both branches dispatched with `async` |
| B | `Select`, both branches dispatched with `concurrent` |
| C | work spawned with `async`, deadline is `Event.waitTimeout` |
| D | work spawned with `concurrent`, deadline is `Event.waitTimeout` |
| E | `Select`, but only the *timeout* branch made `concurrent` |

### Measured on the Pi Zero 2 W (4 cores), 2026-08-27

Deadline is 3 s throughout.

| | idle | 4 busy, default limit | 4 busy, limit 64 | 10 s work, 32 busy |
| --- | ---: | ---: | ---: | ---: |
| A `Select` + `async` | 102 ms | **3100 ms** | 102 ms | **13000 ms** |
| B `Select` + `concurrent` | 100 ms | 102 ms | 100 ms | **3003 ms** |
| C `Event` + `async` | 100 ms | 100 ms | 100 ms | **10000 ms** |
| D `Event` + `concurrent` | 100 ms | 100 ms | 100 ms | **3000 ms** |
| E only the timeout | 100 ms | 102 ms | 100 ms | **10000 ms** |

Read it as four separate facts.

1. **`async` is not a promise of concurrency.** `std.Io.Threaded` caps async
   dispatch at `async_limit`, which defaults to one less than the core count:
   three on this Pi. Past that, `Io.async` documents that it "runs the task
   immediately" — inline, silently, with no error. Column two is a 3 s sleep
   being executed by the caller before `await` was ever reached.
2. **Raising `async_limit` moves the cliff, it does not remove it.** Column
   three fixes A at that load; at 64 busy tasks with a limit of 64 it fails
   again the same way.
3. **Both branches, or neither.** Variant E is the half fix, and it is the
   tempting one: the sleep was what ran inline, so making *it* concurrent looks
   sufficient. It is not. The work stays on `async`, so it is inlined instead,
   `await` returns only once it has already finished, and the deadline never
   fires. E is indistinguishable from a working timeout until the work hangs.
4. **`concurrent` is the promise.** `concurrent_limit` defaults to unlimited
   and the call returns `error.ConcurrencyUnavailable` rather than lying, so B
   and D hold at every load, with no tuning.

C and D exist only to show that the axis is `async` against `concurrent` rather
than one code shape against another; they are not a recommendation. The device
uses `Select` with `concurrent` on both branches
(`voice/recorder.waitForExit`, `gateway_http.awaitWithDeadline`) and tunes
nothing.

## `io-timeout-stages.zig` — where the time actually goes

Prints when each `Select.async` call returns, which is what showed that the
sleep runs inline *inside* `async` rather than the cleanup waiting for it.

```sh
ssh hermit '/tmp/io-timeout-stages 4 100'
#   async(work) returned at 100 ms | async(timeout) returned at 3100 ms | await at 3100 ms
```
