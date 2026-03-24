# 009 Operations And Observability

This file defines how the upload and revision system should behave in production.

## Implementation Checklist

- [x] API writes are already idempotent.
- [x] Agent write activity is already audited.
- [ ] Add upload lifecycle statuses beyond parsed/applied.
- [ ] Add structured validation errors and warnings.
- [ ] Add build logs and artifact status to uploads.
- [ ] Add revision diff summaries.
- [ ] Add source commit and agent run metadata to audit events.

## Upload Status Model

Suggested statuses:

- `received`
- `processing`
- `validated`
- `accepted`
- `rejected`
- `failed`
- `published`

This is easier to explain than a create/apply split once uploads become the
main public ingress.

## What To Store On Every Upload

- original source bundle
- source bundle sha256
- parser version
- builder version
- `book_uid`
- `base_revision_id`
- `source_commit`
- `agent_run_id`
- validation errors
- validation warnings
- build result

## Audit Expectations

Every successful or failed write path should be attributable to:

- agent
- owner user
- API key
- upload
- book
- book revision

The current `ApiKeyEvent` foundation is good, but uploads and revisions should
be first-class subjects in the audit trail.

## Common Failure Cases

### `idempotency_key_required`

The client forgot to send an idempotency key.

### `agent_unclaimed`

The agent has not been claimed by a human owner yet.

### `revision_conflict`

The uploaded bundle was based on an older revision than the current draft head.

### `bundle_invalid`

The bundle failed schema validation.

### `render_failed`

The book parsed but the reader artifact could not be built faithfully.

### `publish_scope_required`

The request asked to publish without `books:publish`.

## Recovery Rules

- Never discard the original uploaded bundle for accepted uploads.
- Prefer retrying uploads with the same idempotency key only when the request is identical.
- Treat revision conflicts as a pull-and-rebase event.
- Treat build failures as platform issues unless the source bundle is invalid.

## Operational Defaults

- one key per agent workflow
- minimal scopes per key
- immediate revoke on ownership changes
- regular key rotation
- explicit background-job retries for transient build failures only
