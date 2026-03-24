# 004 Offline Agent Workflow

This file defines how agents should actually work day to day.

## Implementation Checklist

- [ ] Add a platform-owned starter bundle template for new books.
- [ ] Add source pull for existing books.
- [ ] Add a local state file for last-known remote revision.
- [ ] Document rebase flow after revision conflicts.
- [ ] Make hosted validation and preview the primary review loop after upload.

## Default Workflow

Agents should never draft directly in the web app.

They should:

1. create or pull a local source bundle
2. write locally
3. upload a complete bundle
4. review hosted validation and preview output
5. publish when ready

That keeps writing fast, reproducible, and easy to version in git when teams
choose to use git locally.

## New Book Workflow

For a brand new book:

1. Start from the standard platform-owned Chapterwan bundle template.
2. Fill out `book.yml`.
3. Write content files with stable unit ids.
4. Upload the full bundle to `/api/uploads`.
5. Review the hosted validation and preview result.

The platform should create the `Book` automatically from `book_uid` if it does
not already exist.

## Existing Book Workflow

For a later revision:

1. Pull the latest accepted source bundle for the book.
2. Keep the same `book_uid`.
3. Keep the same unit ids for unchanged logical units.
4. Change content locally.
5. Upload the full updated bundle with the last known `base_revision_id`.
6. Review the hosted validation and preview result.

The agent should think in full source snapshots, not patch instructions.

## Multi-Book Workflow

One agent can work on many books.

Recommended default:

- one local directory per book
- one git history per book
- one `.chapterwan/state.json` per book directory

That is simpler than forcing a multi-book monorepo as the default.

Git is recommended for local history and collaboration, but it is not required
by the platform.

## Local State

The local state file should not be part of the canonical book source.

It can store:

- base URL
- last uploaded `book_revision_id`
- last uploaded `upload_id`
- last known published revision

This avoids polluting `book.yml` with server-only state.

## Why Not Remote-First Authoring

Remote authoring can be a future feature, but it should not replace local-first
authoring for MVP.

- local files are simpler for agents
- local preview and upload keep the platform focused on distribution
- remote drafting adds collaboration, autosave, and trust/safety complexity

## Conflict Handling

If the remote head moved:

- the upload should fail with a revision conflict
- the agent should pull the latest source
- the agent should reapply its local changes offline
- the agent should upload a new complete bundle

The platform should reject stale writes, not merge them automatically.
