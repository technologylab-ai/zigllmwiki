# Curation consumer and scheduler validation — 2026-09-04

The consumer and installed service completed their first successful publication
at reviewed base `0e82e97e6eb9314c4dd70cecdedd3449556bdd81`.
[Read-only packet 33921176578](https://github.com/technologylab-ai/zigllmwiki/actions/runs/33921176578)
passed on that exact main revision. The service on Linux selected maxross;
Codex CLI 0.153.2 performed the bounded semantic pass there using Zig 0.16.0.
The caller independently verified and published commit
`42811430c2ed3db9d9a6e83c0ad41af225779eef` as
[draft PR #1](https://github.com/technologylab-ai/zigllmwiki/pull/1).

## Observed phases

| Phase | Actual result and boundary |
| --- | --- |
| First consumer trial, packet 33919880936 at 0bdca5a | Failed caller verification and retained the unpushed proposal. An outer `.zig-cache` path excluded all Markdown candidates. Relative-root filtering and a regression corrected the defect in 0e82e97. The [first report](curation-review-33919880936-1.md) remains a failure record. |
| Installed service, 21:27 UTC | Fast-forwarded its dedicated runner clone to 0e82e97, selected maxross, found no successful current packet, returned waiting-for-current-review and agent_started=false. |
| Failed-Mac probe | An explicit unreachable probe address exercised Linux fallback; it also returned the idle result without starting an agent. No real Mac outage was simulated beyond the failed SSH probe. |
| Installed service, 21:29–21:37 UTC | Selected maxross and invoked one real Codex process. The isolated clone proposed seven Markdown files. Sandbox verification passed structure and failed the loopback bind with errno 1; the [agent's report](curation-review-33921176578-1.md) preserves that local failure. |
| Independent caller gates | On arm64 macOS 26.6.2 build 25G83, exact Zig 0.16.0 passed 87/87 build steps, 69/78 tests, 9 platform skips; 28 Python tests passed; 25-query retrieval MRR=1.0, hit@3=1.0, recall@5=0.98, policy met. Source/log/path/byte/index checks passed before publication. |
| Publication | The caller pushed a unique branch and opened draft PR #1. It did not merge. The systemd service exited with Result=success and ExecMainStatus=0. |
| Repeat installed service, 21:38 UTC | The Mac authoring checkout was busy with reviewed workflow edits. Linux fallback found the existing PR and returned already-published; no second agent or duplicate PR was created. |
| Root review and merge | The interactive owning agent separately checked the source-based diff and caller receipts, marked the PR ready, and merged it under the user's completion authorization. Merge commit: e3fccc362e8b4504b3660916e4bde277fe104667. Consumer auto-merge remains disabled. |

The agent report's sandbox failure and the caller's successful gate are
separate observations, not a rewritten historical result. This trial proves
one bounded curation/publication path and explicit idle/idempotence cases; it
does not prove every future model output is sound or that network access will
always be available. Existing publication-boundary tests cover refused paths,
source rewrites, log truncation, staged-file mismatch and interrupted execution.

## Installed operational state

- Host: omarx1, x86_64 Omarchy 4.0.2, kernel 7.1.9-arch1-2.
- User units: `~/.config/systemd/user/zig-wiki-curation.service` and `.timer`.
- Dedicated runner clone: `~/.local/state/zigllmwiki-curator/runner`.
- Timer enabled, Mondays at 05:17 UTC, Persistent=true; next observed firing
  2026-09-07 07:17 CEST. The preexisting user manager has Linger=yes.
- Service inactive after successful completion; timer waiting, no continuous
  agent. Existing local gh and Codex logins are used, without copying secrets.
- Preferred compute host: maxross, reached over SSH; unavailable/busy/stale Mac
  falls back to Linux before an agent starts. A started remote failure never
  triggers a duplicate local pass.

The Mac's actual Python was 3.9.6; this passing compatibility observation does
not change the documented Python 3.10+ tooling policy. Logs and JSON receipts
are retained locally under `.zig-cache/curation/review-RUN-ATTEMPT/`; the durable
findings and repository-visible PR/run references are above.
Commands, bounds and recovery behavior remain in
[agent curation](../docs/agent-curation.md).
