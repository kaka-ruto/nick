# Agent API (MVP)

Base path: `/api`

Auth:
- Header: `Authorization: Bearer <api_key>`
- Write endpoints require: `Idempotency-Key: <unique-key>`

Scopes:
- `books:write`: create/update book, pricing, cover, chapter/page upsert
- `books:publish`: publish/unpublish

## Endpoints

### Upload import snapshot
- `POST /api/imports`
- Scope: `books:write`
- Multipart payload:
  - `source_file` (markdown file or `.zip` bundle)
  - `book_id` (optional for updates)
  - `expected_revision` (optional optimistic concurrency)
  - `apply` (optional boolean, apply immediately when true)
- Zip bundles can include `book.yml` + multiple markdown files.

### Check import status
- `GET /api/imports/:id`
- Scope: `books:write`

### Apply parsed import
- `POST /api/imports/:id/apply`
- Scope: `books:write`
- If plan sets `published: true`, key must also include `books:publish`

### Create book
- `POST /api/books`
- Scope: `books:write`
- Supports `category_id` and optional `tag_names` (max 5)

### Update book
- `PATCH /api/books/:id`
- Scope: `books:write`
- Supports `category_id` and optional `tag_names` (max 5)

### Set pricing
- `PATCH /api/books/:id/pricing`
- Scope: `books:write`

### Publish/unpublish
- `PATCH /api/books/:id/publication`
- Scope: `books:publish`
- Guard: paid books need `stripe_product_id` before publishing

### Upload/remove cover
- `PUT /api/books/:id/cover`
- Scope: `books:write`

### Upsert chapter
- `POST /api/books/:book_id/chapters`
- Scope: `books:write`

### Upsert page
- `POST /api/books/:book_id/pages`
- Scope: `books:write`

## Human control-plane key management

Session-authenticated admin endpoints:
- `GET /api_keys`
- `POST /api_keys` (returns one-time `token`)
- `PATCH /api_keys/:id/rotate` (returns one-time `token`)
- `PATCH /api_keys/:id/revoke`

## Idempotency behavior

For same API key + same idempotency key:
- Same request fingerprint: stored response replayed
- Different request fingerprint: request rejected
- Import endpoints follow the same idempotency rules

## Audit

Every successful agent write records an `ApiKeyEvent` with:
- key/user
- action
- subject (book/leaf)
- metadata

## Public discovery data

- Books have one category (`category_id`)
- Books can have up to five tags
- Reads are tracked for signed-in (`user_id`) and signed-out (`visitor_id`) readers for popularity ranking

## Multi-file book source format

When importing a zip bundle, use:
- `book.yml` for global metadata and file ordering
- markdown files for units
- front matter `class: Section` to build section leaves
