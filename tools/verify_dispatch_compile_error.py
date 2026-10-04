#!/usr/bin/env python3
"""Verify a specific exact-release evented-backend compile blocker."""
from pathlib import Path
import subprocess
import sys
import re

compiler, source, target, diagnostic = sys.argv[1:]
baseline = (Path(__file__).resolve().parents[1] / ".zig-version").read_text().strip()
actual = subprocess.check_output([compiler, "version"], text=True).strip()
if actual != baseline:
    raise SystemExit(f"Compiler mismatch: {actual}, expected {baseline}")
result = subprocess.run(
    [compiler, "build-obj", source, "-target", target, "-lc", "-fno-emit-bin"],
    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
print(result.stdout, end="")
normalized = result.stdout.replace("\\", "/")
backend = Path(source).name.split("_")[0].title()
errors = [line for line in normalized.splitlines() if re.search(r"(^|:) error:", line)]
if (result.returncode != 1 or not errors or
        any(diagnostic not in line or f"Io/{backend}.zig:" not in line for line in errors)):
    raise SystemExit("Expected the exact shipped backend error; requalify this backend if the result changed")
print(f"Confirmed {source} compile blocker; this is not runtime backend evidence.")
