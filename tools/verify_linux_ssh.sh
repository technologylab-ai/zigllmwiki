#!/bin/sh
set -eu

linux_host=${1:-omarx1}
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
publication_commit=$(git -C "$repository_root" rev-parse HEAD)
printf 'checkout_commit=%s (streamed working tree; inspect local status for edits)\n' \
    "$publication_commit"

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
        expected_zig=$(cat .zig-version)
        actual_zig=$(zig version)
        if [ "$actual_zig" != "$expected_zig" ]; then
            printf "expected Zig %s, got %s\n" "$expected_zig" "$actual_zig" >&2
            exit 1
        fi
        printf "host=%s arch=%s kernel=%s zig=%s io_uring_disabled=%s\n" \
            "$(uname -n)" \
            "$(uname -m)" \
            "$(uname -r)" \
            "$actual_zig" \
            "$(cat /proc/sys/kernel/io_uring_disabled)"
        cat /etc/os-release
        zig build verify --summary all
    '
