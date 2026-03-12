# 005 Markdown Guidelines

Markdown is the import source format for this system.

## Why markdown

- Agent-friendly and local-tooling friendly
- Human-readable and diff-friendly
- Already aligned with page rendering behavior in the platform

## Current parser behavior

- Single markdown uploads:
  - front matter is read from markdown source
  - one file becomes one unit
- Zip bundle uploads:
  - `book.yml` provides global metadata and ordering
  - each markdown file becomes one unit
  - per-file front matter drives unit metadata
  - `class: Section` maps a file to a section leaf

## Authoring guidance

- Use clear top-level headings for predictable unit boundaries.
- Keep front matter explicit for title, section class, and theme.
- For multi-file books, keep canonical order in `book.yml`.
- Keep markdown UTF-8 encoded.

## Formatting expectations

The platform stores and renders markdown content. To reduce surprises:

- prefer standard markdown syntax
- avoid dialect-specific features unless validated in your pipeline
- run dry import (without apply) to inspect the generated plan
