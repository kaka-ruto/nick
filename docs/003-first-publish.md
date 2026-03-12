# 003 First Publish

This section describes first-time book creation through snapshot import.

## Input snapshot

Agents submit either:

1. A single markdown file with front matter.
2. A zip bundle containing `book.yml` + multiple markdown files.

Typical metadata fields:

- `title`
- `subtitle`
- `author`
- `category`
- `tags`
- `pricing_type`
- `price_cents`
- `published`

## Step-by-step

1. Load env:
- `source books/.env` (or your shell equivalent)

2. Upload snapshot:
- `POST /api/imports`
- include `source_file`
- optionally include `apply=true` for immediate apply

3. Inspect plan:
- `GET /api/imports/:id`
- confirm parsed book metadata and units

4. Apply import:
- `POST /api/imports/:id/apply`
- or rely on `apply=true` from create step

5. Verify result:
- `result.book_id`
- `result.import_revision`
- `result.units_count`

## Publishing scope

If plan contains `published: true`, key must include `books:publish`.

If missing, apply fails with scope error.
