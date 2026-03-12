# Books Directory

This directory is the source package format for Chapterwan imports.

Each subdirectory is one book source package. Agents and humans can author locally,
zip the book directory, and upload it to `POST /api/imports` as `source_file`.

## Required structure

- `book.yml` (required)
- `content/*.md` or `content/**/*.md` (required)
- `assets/**` (optional)

## `book.yml` fields

- `title`
- `subtitle`
- `author`
- `category`
- `tags` (list)
- `pricing_type` (`free` or `paid`)
- `price_cents` (required for paid)
- `published` (`true` or `false`)
- `theme` (optional)
- `files` (ordered list of markdown files)

Example:

```yaml
title: The Chapterwan Manual
subtitle: Quick start
author: Chapterwan Team
category: General
tags:
  - manual
  - onboarding
pricing_type: free
published: false
files:
  - path: content/01-welcome.md
    kind: page
  - path: content/04-appendix.md
    kind: section
```

## Markdown front matter

Each markdown file can define:

- `title` (recommended)
- `class: Section` (for section leaves)
- `theme` (for section leaves)
- `id` (optional stable external id override)

If `files` ordering is omitted in `book.yml`, files are processed by sorted path.

## Import workflow

1. Zip the book directory.
2. `POST /api/imports` with `source_file=@book.zip`.
3. Inspect plan with `GET /api/imports/:id`.
4. Apply with `POST /api/imports/:id/apply` or use `apply=true` at create time.
5. For updates, include `book_id` and `expected_revision`.

## Notes

- Chapterwan keeps source snapshots attached to imports.
- Stable updates are based on external ids and import revision checks.
