---
id: source-omagma-zig-0-17-stdlib-followup-2026-10-05
title: Zig 0.17 descriptor flags and HTTP header follow-up
kind: source
status: captured
summary: Pin corrected Linux descriptor flags, stale comments, and unchanged HTTP header emission and redirect behavior.
captured: 2026-10-05
revision: "b37873f128b705681fa33c950697de712edade1f"
url: https://github.com/technologylab-ai/omagma/blob/b37873f128b705681fa33c950697de712edade1f/docs/ZIG017-WIKI-FOLLOWUP.md
snapshot: sources/snapshots/omagma-zig-0.17-stdlib-followup-2026-10-05.json.gz
sha256: "ceac7386ba2614175ccd6b5478470fdd4f57178758a27a13d88628633f4aca09"
---

# Descriptor flags and HTTP headers

The curator selected two general standard-library findings from Omagma's migration handoff.
The snapshot preserves 14 files, with original bytes and individual SHA-256 values.
The capture excludes private receipts and application bug histories.
Earlier source records and historical measurements retain their original bytes.

## Pinned inputs

| Input | Revision | Captured files |
| --- | --- | --- |
| Zig 0.16.0 | `44d9672fed001115e674fd5ddb32747ef43a7af4` | Installed `lib/std/os/linux.zig` and `lib/std/http/Client.zig`. |
| Zig 0.17.0 | `7647adab80dd088f4de3610fd245915a912eb6ad` | The same exact-release standard-library files. |
| Linux v6.12 | `adc218676eef25575469234709c2d87185ca223a` | `include/uapi/linux/close_range.h`, fetched from the upstream Git object. |
| Omagma follow-up | `b37873f128b705681fa33c950697de712edade1f` | Four Zig source files, two transport fixtures, and the release workflow. |
| Omagma branch CI | `b9dfde6acd84dc32f74490890f45764067c64659` | Hosted run `37238990205` metadata. |
| Omagma release CI | `9fbe044fe43d456c99b652960a9b0902671e28d4` | Hosted run `37240727720` metadata. |

The curator resolved Linux's annotated v6.12 tag to the full commit above.
Omagma's source, probe, build, and tool bytes match across its source port, release, and final follow-up.
The five standard-library digests in Omagma's evidence document match the installed exact Zig 0.17 release.
The packet captures only the two standard-library files needed for these findings.

## Corrected Linux flag layout

Zig 0.16 places `CLOSE_RANGE.UNSHARE` and `CLOEXEC` at bits zero and one.
Zig 0.17 adds a leading reserved bit in `std/os/linux.zig:2034`.
The fields therefore have backing values two and four, matching Linux UAPI.
The adjacent comments still show the older values one and two.
The `close_range` wrapper accepts typed flags and returns a raw Linux syscall result.

Omagma's `src/platform.zig` checks literal values four and six independently.
Its descriptor probe marks one duplicated descriptor with `CLOEXEC`, without closing the descriptor immediately.
The probe checks `F_GETFD == 1` and successful byte I/O before exec.
After exec, the marked descriptor reports `EBADF`; an unflagged descriptor survives as a positive control.
The probe keeps `UNSHARE = false`.
The literal combined value does not qualify runtime `UNSHARE` behavior.

## HTTP header emission and redirects

Exact Zig 0.17 `std/http/Client.zig:985` defines `sendHead`.
The function emits `headers.authorization` overrides and `extra_headers`.
The function does not emit `privileged_headers`.
Zig 0.16 has the same omission.
Header validation and request storage do not establish wire emission.

The redirect path can clear `privileged_headers`, but leaves `headers.authorization` unchanged.
An authorization override therefore remains available when the redirected request sends its headers.
Privileged-header stripping does not protect that override.
These are source conclusions, without a new cross-host credential-forwarding test.
The caller retains borrowed override storage through every send or resend.

Omagma's client uses the standard authorization override, restricts destination hosts, and rejects automatic redirects.
Its loopback peer checks the literal synthetic bearer on the wire.
Its redirect fixture checks rejection and the absence of a followed request.
The fixture does not directly reproduce privileged-header omission or test cross-host stripping.
The credential-free Google TLS/401 check supplies separate reachability evidence, not bearer-transmission evidence.

## Hosted evidence and scope

Both captured runs completed successfully at their recorded commits.
The pinned workflow uses native Ubuntu 24.04 x86_64 and ARM64 jobs with exact Zig 0.17.
Both jobs execute the descriptor and transport fixtures in Debug and Safe.
The branch run skips publication; the release run completes publication.
The captured workflow and job metadata identify the executed gates.
The curator did not download private desktop receipts or rerun Omagma's runtime tests.
The packet makes no big-endian, Windows, macOS, desktop ARM64, or arbitrary-kernel qualification claim.

Read [[zig-0.17-upgrade-assessment]] and [[networking-and-dns-racing]] for the selected guidance.
