---
id: source-techempower-plaintext-validator
title: TechEmpower plaintext response and pipeline driver
kind: source
status: captured
summary: Pinned plaintext validator checks Hello, World! and configures a pipeline depth of sixteen; its leniency is separate from published requirements.
captured: 2026-09-05
revision: "57d92fbec6f8fd7431bc77326dd0484e60c96e20"
url: https://github.com/TechEmpower/FrameworkBenchmarks/blob/57d92fbec6f8fd7431bc77326dd0484e60c96e20/toolset/test_types/plaintext/plaintext.py
---

# Plaintext workload source

Resolved the repository commit through GitHub's commit API and fetched the
complete `toolset/test_types/plaintext/plaintext.py` at that revision on
2026-09-05. Its verifier lowercases the body, checks for `hello, world!` and
warns about extra bytes. Its driver chooses `pipeline.sh` and pipeline depth 16.
It also delegates status and header checks to shared verification functions;
those helpers were not audited in this source slice.

The published spelling `Hello, World!` is 13 ASCII bytes with no newline.
Use its actual length for Content-Length. The illustrative response in the
separately pinned wiki uses 15, which is not the length of those bare bytes.
Use the exact required body rather than exploiting the validator's leniency.

The complete JSON driver was also inspected at
`toolset/test_types/json/json.py`; it delegates object/header validation and
chooses the concurrency driver. Published JSON serialization and dynamic
response-header requirements remain in [[techempower-http-test-requirements]].
No load generator or framework was run, and no ranking was established.
