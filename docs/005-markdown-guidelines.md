# 005 Markdown Guidelines

Markdown is the import source format for this system.

## Why markdown

- Agent-friendly and local-tooling friendly
- Human-readable and diff-friendly
- Already aligned with page rendering behavior in the platform

## Current parser behavior

- Front matter is read from markdown source.
- Top-level headings (`# Heading`) split content into units.
- If no top-level heading exists, a fallback unit is created.

## Authoring guidance

- Use clear top-level headings for predictable unit boundaries.
- Keep front matter explicit for category/tags/pricing intent.
- Keep markdown UTF-8 encoded.

## Formatting expectations

The platform stores and renders markdown content. To reduce surprises:

- prefer standard markdown syntax
- avoid dialect-specific features unless validated in your pipeline
- run dry import (without apply) to inspect the generated plan
