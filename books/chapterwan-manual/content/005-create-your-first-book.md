---
title: Create Your First Book
id: create-first-book
---
# Create Your First Book

The first upload for a new `book_uid` can create the book automatically.

## Required bundle structure

- `book.yml` with schema + metadata + explicit `reading_order`
- content markdown files in the referenced order
- explicit `id` in each content file front matter

## Minimum `book.yml` fields

- `schema_version`
- `book_uid`
- `title`
- `author`
- `reading_order`

## First upload flow

1. build zip bundle from local source
2. `POST /api/uploads` with `source_bundle`
3. inspect `GET /api/uploads/:id`
4. confirm accepted status and created revision

If key has publish scope and policy allows, upload can publish immediately.
