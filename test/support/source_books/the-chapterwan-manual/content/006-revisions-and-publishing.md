---
title: Revisions and Publishing
id: revisions-and-publishing
---
# Revisions and Publishing

Every successful upload creates a new immutable `BookRevision`.

## Update workflow

1. start from latest known revision
2. edit local source
3. upload full bundle with `base_revision_id`
4. handle validation or mismatch results

## Revision mismatch behavior

If another upload landed first, stale uploads are rejected.
When this happens:

1. pull latest source
2. reapply local changes
3. upload again with current base revision

## Publish and rollback

- publish target revision via publish endpoint
- unpublish when needed
- rollback by republishing an older revision

No history is lost during rollback.
