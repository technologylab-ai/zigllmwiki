#!/bin/sh
set -eu

linux_host=${1:-omarx1}
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

COPYFILE_DISABLE=1 tar \
    --no-xattrs \
    --exclude=.git \
    --exclude=.zig-cache \
    --exclude='__pycache__' \
    -C "$repository_root" \
    -czf - \
    . | ssh "$linux_host" 'set -eu
        run_directory=$(mktemp -d /tmp/zigllmwiki.XXXXXX)
        cleanup() {
            case "$run_directory" in
                /tmp/zigllmwiki.*) rm -rf -- "$run_directory" ;;
                *) printf "%s\n" "refusing unsafe cleanup target: $run_directory" >&2 ;;
            esac
        }
        trap cleanup EXIT HUP INT TERM
        tar -xzf - -C "$run_directory"
        cd "$run_directory"
        printf "host=%s kernel=%s zig=%s io_uring_disabled=%s\n" \
            "$(uname -n)" \
            "$(uname -r)" \
            "$(zig version)" \
            "$(cat /proc/sys/kernel/io_uring_disabled)"
        zig build verify
    '
