# 010 Implementation Roadmap

This file turns the spec into an execution sequence.

## Phase 1: Naming And Data Model

- [x] Rename the public ingest concept from `Import` to `Upload`.
- [x] Add `BookRevision`.
- [x] Add `current_draft_revision_id` to `Book`.
- [x] Add `published_revision_id` to `Book`.
- [x] Add source metadata fields: `book_uid`, `base_revision_id`, `source_commit`, `agent_run_id`.

## Phase 2: Bundle Contract

- [x] Add `schema_version` to `book.yml`.
- [x] Require `book_uid`.
- [x] Require explicit `reading_order`.
- [x] Require explicit unit ids in all markdown files.
- [x] Add asset and cover support in the parser and builder.
- [x] Remove `published` from bundle metadata.
- [x] Remove pricing flags from bundle metadata.

## Phase 3: Upload Processing

- [x] Add `POST /api/uploads`.
- [x] Add `GET /api/uploads/:id`.
- [x] Store the raw uploaded bundle.
- [x] Parse and validate uploads in the background.
- [x] Create `Book` automatically when `book_uid` is new.
- [x] Create a `BookRevision` from each accepted upload.

## Phase 4: Reader Build And Publication

- [x] Make the existing reader render from `BookRevision`.
- [x] Attach assets and generate navigation.
- [x] Add publish and unpublish endpoints for revisions.
- [x] Support upload-and-publish when scope allows.
- [x] Support rollback by republishing an older revision.

## Phase 5: Agent Workflow

- [x] Add a platform-owned starter bundle template for new books.
- [x] Add source pull for existing books.
- [x] Add clear conflict/rebase guidance for stale updates.
- [x] Make hosted validation and preview the normal post-upload review path.

## Phase 6: Testing And Acceptance

- [x] Prove the end-to-end flow by uploading the bundled Chapterwan Manual as a new book.
- [x] Prove the revision flow by revising and re-uploading that same manual as an existing book.
- [x] Add comprehensive unit and integration coverage around uploads, revisions, publication, and source pull.
- [x] Prefer minitest fixtures for setup and shared source data.
- [x] Prefer unit and integration tests for this work.
- [x] Do not add new controller tests or system tests for this area.

## Phase 7: Cleanup

- [x] Update docs and examples to `/api/uploads`.
- [x] Update tests to revision terminology.
- [x] Remove `/api/imports` and import-first naming completely.

## Already In Place

- [x] Agent self-registration
- [x] Human claim flow
- [x] Scoped API keys
- [x] Idempotent write handling
- [x] Snapshot upload foundation
- [x] Revision mismatch protection at the current import layer
