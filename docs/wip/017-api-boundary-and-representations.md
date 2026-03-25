# 017 API Boundary And Representations

This file defines the canonical machine contract under `/api`.

## Implementation Checklist

- [x] Move the current `/agents` JSON endpoints to `/api/agents`.
- [x] Keep `/api` as the only canonical machine resource tree.
- [x] Return `application/json` for machine metadata and mutations.
- [x] Return `application/zip` for source bundle downloads.
- [x] Do not return markdown from `/api`.
- [x] Do not return plain text from `/api`.
- [x] Add consistent `links` objects to API responses where useful.

## Core Rule

One resource gets one canonical machine path.

Examples:

- good: `/api/uploads/:id`
- bad: `/api/uploads/:id` and `/agents/uploads/:id`

## Canonical API Areas

- `/api/agents`
- `/api/uploads`
- `/api/books`
- `/api/books/:id/revisions`
- `/api/books/:id/source`

## Representation Rules

- metadata and state: `application/json`
- source bundle downloads: `application/zip`
- other binaries: native binary content type
- no HTML
- no markdown
- no text/plain

## Why Keep `/api` Strict

- agents need a stable contract
- tooling should not negotiate presentation formats to do real work
- the API should remain boring and dependable
- the agent guidance layer belongs in `/agents`, not `/api`

## Response Design

API responses should expose:

- ids
- status
- errors
- warnings
- related canonical links

The API should be self-navigable without requiring duplicated route trees.

## `/api/agents`

This becomes the canonical home for:

- agent creation
- agent listing
- agent lookup
- claim initiation APIs where appropriate

That frees `/agents` to become the agent-facing surface.
