#!/usr/bin/env python3
"""Emit reproducible assembly metadata for one Zig generated-code review."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OPTIMIZE_MODES = ("Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        while chunk := file.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, help="repository-relative Zig source")
    parser.add_argument("--symbol", required=True, help="symbol expected in emitted assembly")
    parser.add_argument("--output-dir", required=True, help="explicit artifact directory")
    parser.add_argument("--optimize", choices=OPTIMIZE_MODES, default="ReleaseSafe")
    parser.add_argument("--target", help="explicit Zig target triple")
    parser.add_argument("--cpu", help="explicit Zig CPU/features string")
    parser.add_argument("--zig", default="zig", help="exact Zig executable")
    args = parser.parse_args()

    source = (ROOT / args.source).resolve()
    try:
        source.relative_to(ROOT)
    except ValueError:
        parser.error("--source must resolve inside the repository")
    if source.suffix != ".zig" or not source.is_file():
        parser.error("--source must name an existing .zig file")

    baseline = (ROOT / ".zig-version").read_text(encoding="utf-8").strip()
    actual = subprocess.run(
        [args.zig, "version"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if actual != baseline:
        print(
            f"zig version is {actual}, expected exact baseline {baseline}",
            file=sys.stderr,
        )
        return 1

    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    assembly = output_dir / f"{source.stem}-{args.optimize}.s"
    command = [
        args.zig,
        "build-obj",
        str(source),
        f"-O{args.optimize}",
        f"-femit-asm={assembly}",
        "-fno-emit-bin",
    ]
    if args.target:
        command.extend(("-target", args.target))
    if args.cpu:
        command.extend(("-mcpu", args.cpu))
    subprocess.run(command, cwd=ROOT, check=True)

    assembly_text = assembly.read_text(encoding="utf-8", errors="replace")
    symbol_found = args.symbol in assembly_text
    report = {
        "schema_version": 1,
        "zig": actual,
        "source": source.relative_to(ROOT).as_posix(),
        "source_sha256": sha256(source),
        "symbol": args.symbol,
        "symbol_found": symbol_found,
        "optimize": args.optimize,
        "target": args.target or "host",
        "cpu": args.cpu or "compiler-default",
        "assembly": str(assembly),
        "assembly_sha256": sha256(assembly),
        "command": command,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if symbol_found else 1


if __name__ == "__main__":
    raise SystemExit(main())
