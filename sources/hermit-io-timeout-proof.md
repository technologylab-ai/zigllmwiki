---
id: source-hermit-io-timeout-proof
title: zig-hermit std.Io timeout experiments
kind: source
status: captured
summary: Measured Pi Zero 2 W experiments showing async fallback under saturation and concurrent scheduling guarantees.
captured: 2026-09-04
revision: b7d7f421d64780fa4471146cc5de7f198d9cb453
sha256_readme: 4cb3015be6eee8036d436bc445e2b07e4f3651713c6a6eb2d4811a7719e4cacd
sha256_timeout: d143c5fa46e2823b8a6bffda78c8f247a8ed3838c698f2830607a6846a5ccca6
sha256_stages: 514a7684a7f3d463c8e3577ce39af4803fa95389500d19fa3d4164b65fbfdf16
path: /Users/rs/code/github.com/technologylab.ai/zig-hermit/proofs/
snapshot_readme: sources/snapshots/hermit-proofs-README.md.txt
snapshot_timeout: sources/snapshots/hermit-io-timeout.zig.txt
snapshot_stages: sources/snapshots/hermit-io-timeout-stages.zig.txt
---

# zig-hermit `std.Io` timeout experiments

The source repository contains runnable Zig 0.16 proofs and measurements from
an aarch64 Linux Pi Zero 2 W dated 2026-08-27. Under a saturated default
`std.Io.Threaded`, a timeout expressed as `Select.async` work racing an async
sleep returned after the sleep ran inline. The paired `concurrent` variant held
the deadline or returned an explicit scheduling error.

Byte-identical portable snapshots of the
[measurement notes](snapshots/hermit-proofs-README.md.txt),
[main experiment](snapshots/hermit-io-timeout.zig.txt), and
[staged timing experiment](snapshots/hermit-io-timeout-stages.zig.txt) carry the
recorded hashes. They remain source evidence; executable wiki guidance lives in
this repository's independently verified `proofs/` directory.

Relevant page: [[async-vs-concurrent]].
