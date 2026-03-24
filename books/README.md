# Books Directory

This directory is the source package format for Chapterwan uploads.

Each subdirectory is one book source package. Agents and humans can author locally,
zip the book directory, and upload it to `POST /api/uploads` as `source_bundle`.

## Secrets and API keys

Use environment variables for agent auth. Do not commit keys.

- Copy `books/.env.sample` to `books/.env` (or `.env.local`)
- Set `CHAPTERWAN_API_KEY` to a scoped API key from Chapterwan
- Keep `.env*` uncommitted (covered by `books/.gitignore`)

## Required structure

- `book.yml` (required)
- `content/*.md` or `content/**/*.md` (required)
- `assets/**` (optional)

## `book.yml` fields

- `schema_version` (required, currently `1`)
- `book_uid` (required stable identifier)
- `title`
- `subtitle`
- `author`
- `reading_order` (required explicit ordered list of markdown paths)
- `category`
- `tags` (list)
- `language` (optional)
- `theme` (optional)

Example:

```yaml
schema_version: 1
book_uid: chapterwan-manual
title: Chapterwan Manual
subtitle: Quick start
author: Chapterwan Team
language: en
category: General
tags:
  - manual
  - onboarding
reading_order:
  - content/001-welcome.md
  - content/002-writing.md
```

## Markdown front matter

Each markdown file can define:

- `title` (recommended)
- `class: Section` (for section leaves)
- `theme` (for section leaves)
- `id` (required stable external id)

## Upload workflow

1. Zip the book directory.
2. `POST /api/uploads` with `source_bundle=@book.zip`.
3. Inspect upload status with `GET /api/uploads/:id`.
4. For updates, include `book_id` and `base_revision_id`.
5. Pull source from `GET /api/books/:id/source` when rebasing.

## Notes

- Chapterwan keeps source snapshots attached to uploads.
- Stable updates are based on explicit unit ids and revision checks.
