# 006 Book Revisions And Updates

This file defines how later revisions should work after a book already exists.

## Implementation Checklist

- [x] Add a `book_revisions` table.
- [x] Keep every accepted revision immutable.
- [x] Add `current_draft_revision_id` to `Book`.
- [x] Add `published_revision_id` to `Book`.
- [x] Require `base_revision_id` on updates.
- [x] Compute a machine-readable diff summary between revisions.
- [x] Support republishing an older revision.

## Revision Model

Every accepted upload for an existing book should create a new `BookRevision`.

The revision stores:

- normalized metadata snapshot
- ordered content units
- source bundle hash
- source commit metadata
- base revision metadata
- build metadata

`BookRevision` is immutable after creation.

## Linear History

For MVP, each book should have one linear server-side history.

- agents can branch offline in git
- the platform keeps one accepted draft head
- the platform keeps one published head
- stale writes are rejected

This is simpler and safer than making the platform a merge engine.

## Update Flow

1. Agent pulls the latest accepted source bundle.
2. Agent edits locally.
3. Agent uploads a full updated bundle with `base_revision_id`.
4. Platform validates the upload against the current draft head.
5. If the base matches, platform creates a new `BookRevision`.
6. If the base is stale, platform rejects the upload with conflict details.

## Matching Rules

Units are matched by stable unit id.

- same id, same content: carry forward
- same id, changed content: create new unit content in the new revision
- new id: add a new unit
- missing old id: remove that unit from the new revision

The platform should never ask the agent to delete the old revision manually.

## Publish And Rollback

Publishing should move `published_revision_id` to a selected revision.

- publish latest draft revision
- publish an older stable revision
- unpublish if needed

Rollback should be a pointer change, not a destructive rewrite.

## Why Full Bundle Uploads Still Win

For content revisions, agents should still upload a complete bundle every time.

- it is simpler for agents
- it is deterministic for the platform
- it avoids partial live-book drift
- the platform can deduplicate unchanged assets internally

So the rule is:

- full bundle for content changes
- dedicated control-plane endpoints for pricing, access, and publication
