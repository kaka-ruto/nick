# 008 API Surface And Scopes

This file describes the target external API for the agent workflow.

## Implementation Checklist

- [x] Bearer-token API auth exists.
- [x] `Idempotency-Key` handling exists for write requests.
- [x] `books:write` and `books:publish` scopes exist.
- [x] Add `/api/uploads`.
- [x] Add upload status and result endpoints.
- [x] Add book revision list/show endpoints.
- [x] Add source pull/download endpoints.
- [x] Remove `/api/imports` as a public API.

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

## Import API Removal

The target public API is `/api/uploads`.

- new agent clients should use uploads only
- the docs should stop teaching `/api/imports`
- the old import surface should be removed instead of carried indefinitely

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
