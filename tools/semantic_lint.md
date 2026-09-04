# Semantic wiki lint

Use this audit after the deterministic `zig build verify` pass. It is designed
for an unsupervised coding agent, but its output is a review artifact, not
permission to silently rewrite guidance.

## Inputs

Read completely:

1. `AGENTS.md`, `.zig-version`, `ROADMAP.md`, and `CURATION.md`;
2. `index.md` and every in-scope page under `wiki/`;
3. each cited source record and only the primary material needed to check the
   page's material claims;
4. linked proofs and their registration in `build.zig`.

Run `zig build verify --summary all` and `zig build graph` first. Record the
exact compiler version, verification totals, and graph summary. Treat graph
scores as triage signals only: counts cannot establish that a link is useful.

## Audit questions

For every page, actively try to falsify the guidance:

- Does a current claim actually follow from its pinned primary source or
  executable proof?
- Does wording distinguish Zig's `std.Io` interface from the properties of
  `std.Io.Threaded` and from experimental/evented implementations?
- Are `async`, `concurrent`, sleeping, cancellation request, acknowledgement,
  terminal ownership, and cleanup kept distinct?
- Are platform and resource-kind claims qualified? In particular, do not
  generalize socket readiness to regular-file completion.
- Are finite limits, allocation sites, queue pressure, overload behavior,
  timeouts, integer widths, and resource ownership explicit where they affect
  correctness?
- Does a proof exercise the advertised behavior on the named Zig and OS, or
  does it only compile? Is a source inspection being mislabeled as runtime
  evidence?
- Do summaries and links help an agent reach the right decision page without
  implying that queued work is complete?
- Has an older source contributed a timeless principle only, with any Zig code
  ported into `proofs/` before publication?
- Are important disagreement, failure, unsupported-case, and negative-space
  findings preserved rather than smoothed away?
- Do source and page statuses match the curation vocabulary and actual state?

## Finding severity

- **critical** — likely to generate unsafe or uncompilable current guidance.
- **high** — materially wrong ownership, concurrency, platform, or evidence
  claim.
- **medium** — ambiguity or missing boundary likely to mislead an agent.
- **low** — retrieval, crosslink, terminology, or maintenance weakness.
- **note** — a validated limitation or future opportunity, not a defect.

## Required report format

Write `reports/YYYY-MM-DD-semantic-lint.md` with:

1. YAML frontmatter: `kind: semantic-lint-report`, date, Zig version, scope,
   verifier result, and disposition (`pass`, `pass-with-findings`, or `fail`);
2. a summary with page/source/proof totals and graph bands;
3. a findings table with stable IDs, severity, exact page/heading, category,
   evidence, consequence, and bounded corrective action;
4. a graph-review table for every orphan, weak page, and connected page,
   stating whether its links are semantically adequate;
5. explicit checks that passed, so absence of a finding is reviewable;
6. open roadmap effects, without marking work complete merely because it was
   inspected.

Use IDs `SL-YYYYMMDD-NNN`. A rerun keeps resolved findings with a resolution
note and creates new IDs for new findings. Critical/high findings make the
report `fail`; medium/low findings make it `pass-with-findings`. A clean report
may use `pass`. Never lower page verification status, change guidance, or close
roadmap work without a separate reviewable edit.
