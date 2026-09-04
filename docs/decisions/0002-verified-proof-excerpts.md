# Verified proof excerpts

Status: accepted design, 2026-09-04. Implementation is not enabled.

## Decision

Keep runnable Zig exclusively in registered `proofs/`. If rendered excerpts are
needed later, generate them from marked regions of those files into disposable
render output. Do not maintain an independently editable Markdown copy or use
Markdown as a second source of executable code. The existing ban on fenced Zig
in `wiki/` remains in force.

This completes the roadmap's design investigation. It does not add a renderer,
change the vault format, or activate a web backend. The Obsidian-first decision
still governs publishing; ordinary proof links remain the supported interface.

## Proposed contract

A maintained proof may mark a region with a stable, unique excerpt identifier.
A page would reference the proof path and region identifier using a directive
whose exact syntax is reserved for implementation. The resolver must reject
unknown, duplicate, nested, overlapping, empty, or unterminated markers, paths
outside registered proofs, symlinks escaping the repository, and stale IDs.
Line numbers alone are not stable identifiers.

Export requires the complete registered proof to pass `zig build verify` with
the exact `.zig-version` compiler. The generated manifest records the proof's
SHA-256, region identifier, extracted-byte SHA-256, publication commit, compiler,
target, optimization mode, and whether the proof ran or only cross-compiled.
A clean source tree and unchanged hashes are required at publication.

An extracted function may depend on imports, declarations, setup, or other
regions. Present it explicitly as an excerpt with a link to the complete proof;
do not promise that a pasted region compiles alone. If a standalone example is
needed, make it a registered standalone proof and verify that actual artifact.

The generated display should include the exact version, proof link, and evidence
scope. It must not promote a source-verified page or cross-compiled binary to
runtime-verified merely because a code excerpt is visible. Raw Markdown and
Obsidian readers must retain a useful proof link even without a renderer.

## Implementation acceptance gates

Before enabling directives, add tests for marker resolution, traversal and
symlink rejection, stale IDs/hashes, deleted registrations, platform skips,
non-standalone excerpts, and reproducible exports. Link lint must resolve every
directive, and CI must compare generated output with the verified inputs.
Generated artifacts stay outside the maintained source vault and can be
recreated from the recorded commit. No handwritten Zig-fence exception is
allowed while these gates are absent.
