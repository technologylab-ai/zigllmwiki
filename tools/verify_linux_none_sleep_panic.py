#!/usr/bin/env python3
"""Require the exact Zig 0.17 Linux Threaded infinite-sleep safety panic."""

from pathlib import Path
import os
import re
import resource
import signal
import subprocess
import sys


def signal_group(child: subprocess.Popen, sig: int) -> None:
    try:
        os.killpg(child.pid, sig)
    except ProcessLookupError:
        pass


def stop_child(child: subprocess.Popen) -> str:
    signal_group(child, signal.SIGTERM)
    try:
        output, _ = child.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        signal_group(child, signal.SIGKILL)
        output, _ = child.communicate()
    return output


def main() -> None:
    if sys.platform != "linux":
        raise SystemExit("This runtime witness requires native Linux")
    executable, = sys.argv[1:]
    # Keep the intentional panic from creating a large core dump on shared hosts.
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))

    def interrupted(signum: int, _frame: object) -> None:
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGHUP, interrupted)
    child = subprocess.Popen(
        [str(Path(executable).resolve())],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        start_new_session=True,
    )
    try:
        try:
            output, _ = child.communicate(timeout=30)
        except subprocess.TimeoutExpired:
            output = stop_child(child)
            print(output, end="")
            raise SystemExit("Infinite sleep did not produce the expected panic; requalify this backend")
    finally:
        if child.poll() is None:
            print(stop_child(child), end="")
    print(output, end="")
    print(f"Witness return code: {child.returncode}")
    normalized = output.replace("\\", "/")
    binary_name = re.escape(Path(executable).name)
    # Safe inlining removes sleepPosix and the fixture's main from the trace.
    # Bind the retained frames to the precise shipped conversion site and this
    # executable rather than requiring frames the optimizer does not preserve.
    required_frames = (
        rf"/lib/std/Io/Threaded\.zig:14634:16:.* in timestampToPosix \({binary_name}\)",
        rf"/lib/std/Io\.zig:1290:31:.* in sleep \({binary_name}\)",
    )
    if not (
        child.returncode == -signal.SIGABRT
        and "panic: integer does not fit in destination type" in output
        and ".sec = @intCast(@divFloor(nanoseconds, std.time.ns_per_s))," in output
        and all(re.search(frame, normalized) for frame in required_frames)
    ):
        raise SystemExit("Expected the exact Threaded time_t overflow panic; requalify this backend")
    print("Confirmed shipped Linux infinite-sleep defect; this does not qualify infinite sleep.")


if __name__ == "__main__":
    main()
