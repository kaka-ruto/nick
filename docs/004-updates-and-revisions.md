# 004 Updates and Revisions

Reliable updates are based on snapshot + expected revision.

## Update flow

1. Agent edits local markdown snapshot.
2. Agent uploads new ingestion with:
- `book_id`
- `expected_revision` (current server revision)
3. Platform parses and stores plan.
4. Apply ingestion.

## Revision safety

- If `expected_revision` matches current `book.ingestion_revision`, apply proceeds.
- If it does not match, apply fails with revision mismatch.

This prevents silent overwrites from stale local copies.

## Unit matching behavior

Parsed units are matched with stable external ids.

- unchanged content: retained
- changed content: updated
- new units: created
- removed units: previously mapped leaves are trashed and mapping removed

## Recommended operator pattern

- Always fetch latest revision before generating update bundle.
- Treat revision mismatch as a required rebase event.
