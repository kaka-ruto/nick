# 008 API Surface And Scopes

This file describes the target external API for the agent workflow.

## Implementation Checklist

- [x] Bearer-token API auth exists.
- [x] `Idempotency-Key` handling exists for write requests.
- [x] `books:write` and `books:publish` scopes exist.
- [ ] Add `/api/uploads`.
- [ ] Add upload status and result endpoints.
- [ ] Add book revision list/show endpoints.
- [ ] Add source pull/download endpoints.
- [ ] Deprecate `/api/imports` after compatibility window.

## Auth

- Header: `Authorization: Bearer <api_key>`
- Write requests require: `Idempotency-Key: <key>`

## Scopes

### `books:write`

Allows:

- upload new book bundles
- upload updates to existing books
- inspect upload status
- inspect revision metadata
- pull source bundles for books the principal can edit

### `books:publish`

Allows:

- publish a revision
- unpublish a book
- request upload-and-publish in one step

## Target Endpoints

### Agent Identity

- `POST /agents`
- `POST /agents/:id/claim`
- `GET /claims/:token`
- `POST /claims/:token/start/:provider`

### Uploads

- `POST /api/uploads`
- `GET /api/uploads/:id`

### Books And Revisions

- `GET /api/books/:id`
- `GET /api/books/:id/revisions`
- `GET /api/books/:id/revisions/:revision_id`
- `GET /api/books/:id/revisions/:revision_id/source`
- `GET /api/books/:id/source`

### Publication And Commerce

- `POST /api/books/:id/publish`
- `POST /api/books/:id/unpublish`
- `PATCH /api/books/:id/pricing`
- `PUT /api/books/:id/cover`

## Compatibility Plan

The current `/api/imports` surface can stay briefly as a compatibility layer.

Target behavior:

- old import requests map internally to uploads
- response payloads begin exposing revision terminology
- clients migrate to `/api/uploads`
- import naming is removed after the migration window

## Response Design

Responses should consistently expose:

- `upload_id`
- `book_id`
- `book_uid`
- `book_revision_id`
- `published_revision_id`
- `status`
- `errors`
- `warnings`

That gives agents enough information to retry, rebase, or publish cleanly.
