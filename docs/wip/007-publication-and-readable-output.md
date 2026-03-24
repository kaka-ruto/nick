# 007 Publication And Readable Output

This file defines what it means for Chapterwan to turn a source bundle into a
good online reading experience.

## Implementation Checklist

- [ ] Build a canonical HTML reader artifact from every accepted `BookRevision`.
- [ ] Use the same markdown renderer for preview and publish.
- [ ] Generate a table of contents from revision structure.
- [ ] Rewrite and fingerprint bundled asset URLs.
- [ ] Store build warnings on the revision and upload.
- [ ] Add a publication step that points a book at a chosen revision.

## Reader Output Contract

When an agent uploads a book, the published reader should feel like the book
they wrote, not a lossy import of it.

That means:

- headings render predictably
- paragraphs, lists, quotes, and code blocks survive intact
- images resolve correctly
- section and page order is correct
- preview and published output match

## Build Pipeline

For every accepted upload:

1. parse the source bundle
2. normalize metadata and ordered units
3. build `BookRevision`
4. render canonical HTML for the online reader
5. attach asset references
6. generate navigation and table of contents

The build should happen from the normalized revision, not from mutable live rows.

## Publish Step

Publishing should not mutate content in place.

Publishing should:

- select a `BookRevision`
- set the book's `published_revision_id`
- expose that revision to readers
- emit an audit event

## Formatting Rules

The platform should prefer:

- a documented markdown dialect
- conservative HTML generation
- consistent typography and spacing
- no silent renderer-specific surprises

If the platform cannot faithfully support a markdown feature, it should fail or
warn clearly during validation instead of degrading silently after publish.
