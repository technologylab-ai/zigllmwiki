# ADR 0003: publish a static wiki

- Status: accepted
- Date: 2026-09-06

## Decision

Publish a read-only browser interface on GitHub Pages.
The user requested public browsing, search, backlinks, and an interactive note graph.
The user also authorized public visibility for the wiki and HTTP repositories.

The site derives every document from the repository.
Markdown, pinned source records, and registered proofs remain canonical.
The interface does not store independent edits.
Obsidian and filesystem-based agent tools keep their existing workflows.

This decision replaces the frontend deferral in [ADR 0001](0001-obsidian-first.md).
The mutable backend and database remain deferred.

## Evidence and links

The reader preserves page status and platform labels.
The reader displays source revisions and links to complete proof files.
Code highlighting does not execute a proof or establish runtime evidence.
Graph edges represent document links, source citations, or proof references.
Graph proximity does not express evidence strength.

The public artifact records its repository commit and document hashes.
The site displays complete proofs generated from canonical files.
The site does not implement excerpt directives from [ADR 0002](0002-verified-proof-excerpts.md).

The HTTP whitepaper uses stable wiki viewing links.
Pinned source citations keep their immutable revision links.
New publications update navigation without rewriting existing source records.

## Operation

The [site guide](../wiki-site.md) defines building, publishing, and maintenance.
GitHub Actions publishes an explicit artifact from a clean checkout.
Publication checks validate rendering inputs and vendored dependencies.
The existing Zig verifier and curation gates continue to validate repository evidence.
