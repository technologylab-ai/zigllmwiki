# Agent curation from a review packet

The weekly `wiki-review.yml` workflow remains read-only. It supplies test logs,
source-head/release signals and retrieval results. `tools/curate_review.py`
connects that packet to a separately invoked local Codex agent and uses `gh`
for GitHub access and draft-PR publication. It never merges a PR.

## Run one pass

Use a host with exact `.zig-version` Zig, Python 3.10+, Git, authenticated `gh`,
and an authenticated Codex CLI. Prefer `maxross` for this compute work; use
`omarx1` when it is unavailable, following [the platform runbook](platform-testing.md).
The implementation uses existing local logins; it does not copy credentials to
GitHub or between hosts. Codex CLI 0.153.2 was the inspected command surface.

First obtain a successful packet for the current `origin/main`:

```text
gh workflow run wiki-review.yml --ref main
gh run list --workflow wiki-review.yml --limit 1
gh run watch RUN_ID --exit-status
python3 tools/curate_review.py --run-id RUN_ID --publish
```

Or use `--latest` to select a successful packet for the current publication
revision. Without `--publish`, the tool still invokes the agent and verifies
its proposal, but retains the staged edits locally. The invocation is the
agent's curation authorization; `--publish` additionally authorizes the branch
push and draft PR. These flags do not grant source upgrades, proof changes,
new runtime claims or automatic merging.

## Scope and ownership

The consumer checks the exact workflow, repository, main branch, allowed event,
successful conclusion, run attempt, and current commit. It checks the packet's
file set, size bounds, compiler versions, clean status and JSON schema versions,
and records SHA-256 values. It rejects a stale packet rather than applying old
findings to an unreviewed head.

The agent works in a separate clone under `.zig-cache/curation/`, preserving the
authoring checkout. It gets the packet as evidence to investigate, not as
executable instructions. It reads the contract, curation ledger and relevant
notes and primary sources, adds useful links, and records its actual audit
scope. A source-head difference alone never establishes a stale claim.

The publication boundary allows at most 24 Markdown files and 1 MiB total:
existing wiki notes and the five index/ledger/handoff files, plus new source
records and reports. It rejects source-record rewrites, historical-report
rewrites, deletions, escaped paths, symlinks, executable/tool/workflow/policy
changes, and changes to HEAD or branch. `log.md` must retain its existing byte
content as a prefix. Broader findings become follow-up work in the report.

The caller reruns the full exact-Zig verifier, Python command/consumer tests,
and retrieval policy after checking the diff. It checks content again after
verification, then commits and pushes a unique `curation/review-RUN-ATTEMPT`
branch. `main` must still match the reviewed commit. Existing PRs make repeat
invocations idempotent, and no force-push is used. A draft PR is the reviewable
result, not a declaration of new platform evidence.

## Limits and recovery

The agent has a default 30-minute process budget (configurable from one minute
to two hours); each verifier gate has 15 minutes. On POSIX, agent timeout kills
its process group. Logs, the input prompt, packet hashes, proposal and failure
reason stay in the state directory for inspection. A failure before publication leaves the proposal unpushed. If the push
succeeds but PR creation fails, the result records that partial publication
and the exact recovery command; do not rerun the agent merely to create the PR. An interrupted run is not automatically retried in the same directory;
inspect it before using a new `--state-dir` to retry. Simultaneous calls on one
host cannot create the same state directory; across hosts, unique branch/PR
identity and non-forced publication expose conflicts.

These permissions constrain the wrapper's publication, not arbitrary behavior
of a hostile model. Codex runs in its workspace-write sandbox; preserve the
local CLI's authentication and sandbox controls. Do not grant the curation agent
unrestricted access merely to bypass a failed check.

## Scheduled operation on omarx1

The user-systemd templates in `docs/automation/` schedule a pass on Mondays at
05:17 UTC, after the 04:17 UTC GitHub review. `Persistent=true` catches a missed
timer when the user manager next runs. The service has a 100-minute outer
budget and serializes its own activations. It uses a dedicated clone at
`~/.local/state/zigllmwiki-curator/runner`, fetched and fast-forwarded before
execution, preserving the user's authoring clone.

`tools/curate_scheduled.py` prefers `ssh maxross` when the Mac's checkout is
clean/current and its tools are available. A bounded probe and SSH keepalives
prevent an unavailable Mac from stalling host selection. If that probe fails,
it runs locally on `omarx1`. Once a remote agent starts, a failure is reported
without launching a second local agent; inspect the retained remote state.
A successful connection was observed from omarx1 to maxross on 2026-09-04;
future connectivity and identical shell PATHs must not be assumed.

No successful review for the current main commit means an explicit idle result
and no agent start. Existing PRs are skipped. The timer does not dispatch a new
GitHub workflow or retry a failed proposal automatically.

Operational commands on omarx1:

```text
systemctl --user status zig-wiki-curation.timer
systemctl --user list-timers zig-wiki-curation.timer
journalctl --user -u zig-wiki-curation.service
systemctl --user start zig-wiki-curation.service
systemctl --user disable --now zig-wiki-curation.timer
```

Template presence alone is not evidence of installation or a successful run.
The handoff records actual installation and validation results. The user
manager and authenticated tools must be available; local credentials never
become GitHub Actions secrets.

The CLI behavior is documented in [OpenAI's non-interactive-mode guide](https://learn.chatgpt.com/docs/non-interactive-mode).

## Observed installation and publication

The omarx1 timer was installed and enabled on 2026-09-04. Its service selected
maxross, completed one bounded agent pass and opened
[draft PR #1](https://github.com/technologylab-ai/zigllmwiki/pull/1) after the
independent caller gates passed. A separate root review merged it. Idle and
Linux-fallback/idempotence checks also passed; the service then stopped and
the timer remained waiting. See the [operational receipt](../reports/2026-09-04-curation-operations.md)
for exact revisions, environments, failed first trial and validation limits.
