#!/usr/bin/env python3
"""Route one scheduled curation pass to an available, current Mac or run locally."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
MAC_PATH = '/Users/rs/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mac-host', default='maxross')
    parser.add_argument('--mac-root', default='/Users/rs/code/github.com/technologylab.ai/zigllmwiki')
    parser.add_argument('--local-only', action='store_true')
    args = parser.parse_args()
    environment = os.environ.copy()
    environment['PYTHONDONTWRITEBYTECODE'] = '1'
    # The local script may run from an isolated deployment clone. It never
    # resets either authoring checkout. The consumer makes its own work clone.
    if sys.platform == 'linux' and not args.local_only:
        ssh = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5',
               '-o', 'ConnectionAttempts=1', '-o', 'ServerAliveInterval=15',
               '-o', 'ServerAliveCountMax=3', args.mac_host]
        probe = (f'export PATH={shlex.quote(MAC_PATH)}; '
                 f'cd {shlex.quote(args.mac_root)} && '
                 'test -z "$(git status --porcelain)" && '
                 'git fetch origin main --quiet && '
                 'test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" && '
                 'command -v codex >/dev/null && command -v zig >/dev/null && '
                 'command -v gh >/dev/null && test -f tools/curate_review.py')
        try:
            result = subprocess.run([*ssh, probe], capture_output=True, timeout=30, env=environment)
            available = result.returncode == 0
        except (subprocess.TimeoutExpired, OSError):
            available = False
        if available:
            print(f'Curator host selected: {args.mac_host}', flush=True)
            command = (f'export PATH={shlex.quote(MAC_PATH)}; '
                       f'cd {shlex.quote(args.mac_root)} && '
                       'python3 tools/curate_review.py --latest --publish')
            # If a started remote pass fails, do not silently run a second
            # agent locally. The remote state directory retains its proposal.
            return subprocess.call([*ssh, command], env=environment)
        print('Mac unavailable, busy, stale, or missing tools; curation continues locally', flush=True)
    else:
        print('Curator host selected: local', flush=True)
    return subprocess.call([sys.executable, str(ROOT / 'tools/curate_review.py'),
                            '--latest', '--publish'], cwd=ROOT, env=environment)


if __name__ == '__main__':
    raise SystemExit(main())
