# 005 Uploads And First Publication

This file defines the new-book path.

## Implementation Checklist

- [x] Add `POST /api/uploads` as the public ingress endpoint.
- [x] Store the original uploaded bundle on every upload.
- [x] Parse and validate uploads asynchronously.
- [x] Create a `Book` automatically from `book_uid` when needed.
- [x] Create `BookRevision 1` from the first successful upload.
- [x] Project `BookRevision 1` into the existing web reader.
- [x] Allow upload-and-publish with `books:publish` scope.
- [x] Remove the current `/api/imports` public workflow.

## Why `Upload` Instead Of `Import`

`Upload` is the right product term.

- Agents understand "upload your bundle".
- The platform can do more than import raw rows.
- An upload can parse, validate, build, and produce a revision.
- The public API becomes easier to explain.

## Endpoint Shape

The target ingress endpoint should be:

- `POST /api/uploads`

Multipart fields:

- `source_bundle`
- `publish` optional
- `idempotency_key` header required
- `source_commit` optional but recommended
- `agent_run_id` optional but recommended

The bundle itself carries `book_uid`, so a separate `book_id` parameter should
not be required for the happy path.

## First Upload Flow

1. Agent uploads a full source bundle.
2. Platform stores the raw upload.
3. Platform parses and validates the bundle.
4. Platform creates the `Book` if `book_uid` is new.
5. Platform creates immutable `BookRevision 1`.
6. Platform projects the accepted revision into the existing reader.
7. Platform publishes the revision if `publish=true` and scope allows it.

## Target Response Shape

The create response should point at the upload record, not pretend the work is
already finished:

```json
{
  "upload": {
    "id": 42,
    "status": "processing",
    "book_uid": "bk_field-guide-to-mars"
  }
}
```

Then `GET /api/uploads/:id` should eventually show:

- accepted or rejected status
- created `book_id`
- created `book_revision_id`
- build status
- validation warnings
- published status

## First Publication Rules

- Publishing should be controlled by request scope, not by a `published` flag in the bundle.
- If `publish=true` is absent, the first accepted revision becomes the draft head only.
- If `publish=true` is present without `books:publish`, the upload should fail clearly.

## Reader Copy Requirements

The first successful upload must produce an online reader that is:

- correctly ordered
- visually clean
- faithful to the supported markdown dialect
- backed by the same renderer used in preview

If the platform cannot render the book faithfully, the upload should fail or
warn clearly before publication.
