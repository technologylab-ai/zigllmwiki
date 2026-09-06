# The public wiki

Read the wiki at [Zig LLM Wiki](https://technologylab-ai.github.io/zigllmwiki/).
The website provides browser access to the same files that agents and Obsidian use.

## Reading and discovery

Search across guidance, source records, proofs, and project documentation.
Filters narrow results by document layer, platform, or verification status.
Press `/` to reach search.
Browser search serves human navigation.
The command-line retrieval benchmark continues to evaluate the agent query tool separately.

A backlink identifies another document that references the current document.
Each reader page exposes nearby documents, source records, and registered proofs.
The contents list links to individual headings.

The note graph displays document relationships with an animated layout.
Wiki, Sources, Proofs, and Project layers start enabled.
Click a node to center the graph on that document.
The neighboring nodes rearrange around the selected node.
Open the selected document from its details panel.
Use the layer controls to narrow the graph.
Use the local graph to inspect one document's neighborhood.
The list view provides an alternative to graphical navigation.
The note list starts expanded and shows matching documents during search.
The graph honors the browser's reduced-motion preference.

Status labels reproduce the recorded evidence status.
Read each page's evidence section for environments, dates, and remaining limits.
A displayed proof has not run in the browser.
A graph edge does not establish that a claim is correct.

## Stable links

Use the `page` query parameter with a repository-relative path.
For example, [the I/O page](https://technologylab-ai.github.io/zigllmwiki/?page=wiki/std-io.md) opens the rendered document.
Append a heading fragment when a specific section matters.
The reader resolves Obsidian links and ordinary Markdown links within the published corpus.
Unpublished repository attachments open at the publication commit on GitHub.

The [HTTP whitepaper](https://technologylab-ai.github.io/zig-http/) links to this reader.
Keep immutable source citations unchanged when adding viewing links.

## Build and preview

The build needs Git and Python 3.9 or later.
The browser uses vendored JavaScript without runtime CDN requests.

From a clean checkout, run:

```text
python3 -m unittest tools.test_build_site -v
python3 tools/build_site.py
python3 -m http.server 8767 --directory .zig-cache/site
```

Open `http://localhost:8767/`.
Use `python3 tools/build_site.py --allow-dirty` only for development previews.
The development manifest identifies modified inputs.
GitHub Pages uses the clean build command.

Browser checks need Node.js 22 or later and an installed Chrome or Chromium executable.
Acquire the shared host reservation before browser checks.
With the preview server running, use:

```text
node tools/check_site_browser.mjs http://localhost:8767/ .zig-cache/browser-check
```

Set `BROWSER` when the executable uses a different path.
The checker writes screenshots and a JSON receipt under the selected output directory.
The checker uses an isolated browser profile and closes its browser after completion.

The builder selects tracked Markdown, source records, and registered proof files.
The builder emits disposable JSON and website assets under `.zig-cache/site`.
The artifact contains no repository database or local cache.
Document hashes identify the original bytes before frontmatter removal.
Source metadata retains pinned revisions, URLs, and snapshot hashes.

## Maintenance and publication

Agents curate canonical files through the existing [ingestion contract](../AGENTS.md).
Agents inspect source changes, revise synthesis, add reciprocal links, and run evidence checks.
The website does not perform semantic curation.

The [Pages workflow](../.github/workflows/pages.yml) publishes updates after changes reach `main`.
Manual dispatch can republish the current revision.
Confirm the workflow's commit and successful deployment before reporting a publication.

Run `zig build verify` with the exact compiler from `.zig-version` after content or link changes.
Run the retrieval policy after index changes.
Follow the [platform runbook](platform-testing.md) for native evidence and shared host reservations.
The publication workflow validates the site artifact; the workflow does not replace native proof verification.

Update the reader in `site/app.js` and its styling in `site/styles.css`.
Update the graph in `site/graph.js`.
Update artifact selection and link resolution in `tools/build_site.py`.
Keep dependency versions, licenses, and checksums together in `site/vendor/`.

The [publication decision](decisions/0003-static-public-wiki.md) records the scope.
The roadmap retains unfinished systems work independently of website delivery.
