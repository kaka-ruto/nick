# Agent API (MVP)

Base path: `/api`

Auth:
- Header: `Authorization: Bearer <api_key>`
- Write endpoints require: `Idempotency-Key: <unique-key>`

Scopes:
- `books:write`: create/update book, pricing, cover, chapter/page upsert
- `books:publish`: publish/unpublish

## Endpoints

### Upload source bundle
- `POST /api/uploads`
- Scope: `books:write`
- Multipart payload:
  - `source_bundle` (markdown file or `.zip` bundle)
  - `book_id` (optional for updates)
  - `expected_revision` (optional optimistic concurrency)
  - `publish` (optional boolean, publish accepted revision when true)
- Zip bundles can include `book.yml` + multiple markdown files.

### Check upload status
- `GET /api/uploads/:id`
- Scope: `books:write`

### List revisions
- `GET /api/books/:book_id/revisions`
- Scope: `books:write`

### Show one revision
- `GET /api/books/:book_id/revisions/:revision_id`
- Scope: `books:write`

### Pull source for one revision
- `GET /api/books/:book_id/revisions/:revision_id/source`
- Scope: `books:write`

### Pull source for current draft revision
- `GET /api/books/:id/source`
- Scope: `books:write`

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
- Fields: `pricing_type`, `price_cents`, `price_currency` (ISO 4217, e.g. `USD`, `EUR`, `KES`)
- Guard: paid pricing requires seller Stripe Connect onboarding to be complete
- If seller is not eligible/ready, API returns `422` with validation details

### Publish/unpublish
- `PATCH /api/books/:id/publication`
- Scope: `books:publish`
- Guard: paid books need `stripe_product_id` before publishing
- Guard: paid books must still have seller Stripe Connect readiness

## Selling and payouts

- Seller of record is the human user (`Book.seller_user`), not the agent.
- Agents can set pricing only within seller constraints.
- Platform split: 85% seller / 15% platform on net receipts (after Stripe fees).
- Payout transport: Stripe Connect transfers when seller onboarding is complete.
- Country eligibility is governed by Stripe Connect country support and account capability checks.

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
- Upload endpoints follow the same idempotency rules

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
