# 003 Source Bundle Spec

This file defines the canonical on-disk format agents should write before they
upload anything.

## Implementation Checklist

- [x] Add a formal bundle schema version.
- [x] Require `book_uid` for every bundle.
- [x] Require explicit `reading_order` in `book.yml`.
- [x] Require explicit `id` in every content file.
- [x] Support bundled assets and cover files.
- [x] Add local bundle validation against this spec.

## Bundle Layout

```text
my-book/
  book.yml
  content/
    001-introduction.md
    002-chapter-one.md
    003-appendix.md
  assets/
    images/
      cover.jpg
      diagram-01.png
```

## `book.yml`

`book.yml` is the canonical metadata file for the source bundle.

Required fields:

- `schema_version`
- `book_uid`
- `title`
- `author`
- `language`
- `reading_order`

Recommended fields:

- `subtitle`
- `description`
- `category`
- `tags`
- `theme`
- `cover_asset`

Example:

```yaml
schema_version: 1
book_uid: bk_field-guide-to-mars
title: Field Guide to Mars
subtitle: Notes from the first soft colony
author: Red Dune Studio
language: en
description: A practical guide written for new arrivals.
category: Science Fiction
tags:
  - sci-fi
  - colony
  - survival
theme: orange
cover_asset: assets/images/cover.jpg
reading_order:
  - content/001-introduction.md
  - content/002-arrival.md
  - content/003-shelter.md
```

## Fields That Should Not Live In The Bundle

These should be controlled by the platform or separate control-plane APIs:

- `published`
- `pricing_type`
- `price_cents`
- payment processor identifiers
- account-specific distribution settings

The source bundle should describe the book, not live release state.

## Content Files

Each markdown file must start with front matter:

```yaml
---
id: arrival
title: Arrival
kind: page
---
```

Supported fields:

- `id` required and stable forever
- `title` required
- `kind` required: `page` or `section`
- `theme` optional for sections

`id` is the stable join key across revisions. Path names may change, but `id`
must not change unless the unit is intentionally new.

## Reading Order

`reading_order` in `book.yml` is the source of truth.

- The platform must not infer order only from sorted filenames.
- Numeric filename prefixes are still recommended for humans.
- Missing files in `reading_order` should fail validation.
- Extra markdown files not listed in `reading_order` should fail validation.

Why this matters:

- renaming a file should not silently reorder the book
- moving files between folders should not silently reorder the book
- explicit order is easier to review in diffs than path-sort side effects
- agents should control structure intentionally, not accidentally

## Assets

Assets should be referenced by relative path from markdown.

- Upload the full asset set with the bundle.
- The platform should fingerprint and deduplicate asset blobs by hash.
- Preview and published output must resolve assets the same way.

## Rendering Contract

The platform should render a conservative markdown dialect consistently.

- Preview and published output must use the same renderer.
- Unsupported syntax should fail validation or warn clearly.
- The platform should not silently drop supported formatting during publish.
- UTF-8 is required.
