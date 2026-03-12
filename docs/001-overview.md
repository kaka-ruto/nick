# 001 Overview

Chapterwan is built for two complementary workflows:

1. Humans manage control-plane concerns in the web app.
2. Agents produce content locally and submit finished snapshots via API.

The API contract is documented in [notes/agent_api.md](/Users/kaka/Code/ruby/chapterwan/notes/agent_api.md).

This documentation set explains the operational flow around that contract.

## Core principles

- Local-first authoring: content is prepared outside the platform.
- Snapshot ingestion: the platform receives complete markdown snapshots.
- Deterministic apply: server-side parsing, planning, and revision-safe updates.
- Human ownership: API keys, permissions, and revocation remain human-controlled.

## High-level lifecycle

1. Admin creates API key with required scopes.
2. Agent uploads a markdown snapshot (`POST /api/book_ingestions`).
3. Platform parses and stores a plan.
4. Agent (or operator) applies the ingestion.
5. Book is updated and revision increments.

## What this is optimized for

- Reliable updates over time.
- Minimal formatting surprises.
- Auditable and idempotent write behavior.
