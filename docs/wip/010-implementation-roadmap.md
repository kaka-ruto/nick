# 010 Implementation Roadmap

This file turns the spec into an execution sequence.

## Phase 1: Naming And Data Model

- [ ] Rename the public ingest concept from `Import` to `Upload`.
- [ ] Add `BookRevision`.
- [ ] Add `current_draft_revision_id` to `Book`.
- [ ] Add `published_revision_id` to `Book`.
- [ ] Add source metadata fields: `book_uid`, `base_revision_id`, `source_commit`, `agent_run_id`.

## Phase 2: Bundle Contract

- [ ] Add `schema_version` to `book.yml`.
- [ ] Require `book_uid`.
- [ ] Require explicit `reading_order`.
- [ ] Require explicit unit ids in all markdown files.
- [ ] Add asset and cover support in the parser and builder.
- [ ] Remove `published` from bundle metadata.
- [ ] Remove pricing flags from bundle metadata.

## Phase 3: Upload Processing

- [ ] Add `POST /api/uploads`.
- [ ] Add `GET /api/uploads/:id`.
- [ ] Store the raw uploaded bundle.
- [ ] Parse and validate uploads in the background.
- [ ] Create `Book` automatically when `book_uid` is new.
- [ ] Create a `BookRevision` from each accepted upload.

## Phase 4: Reader Build And Publication

- [ ] Build canonical HTML output from `BookRevision`.
- [ ] Attach assets and generate navigation.
- [ ] Add publish and unpublish endpoints for revisions.
- [ ] Support upload-and-publish when scope allows.
- [ ] Support rollback by republishing an older revision.

## Phase 5: Agent Workflow

- [ ] Add bundle template tooling for new books.
- [ ] Add source pull for existing books.
- [ ] Add local `validate`, `preview`, `pull`, and `upload` commands.
- [ ] Add clear conflict/rebase guidance for stale updates.

## Phase 6: Migration And Cleanup

- [ ] Keep `/api/imports` as a compatibility layer temporarily.
- [ ] Update docs and examples to `/api/uploads`.
- [ ] Update tests to revision terminology.
- [ ] Remove import-first naming after migration is complete.

## Already In Place

- [x] Agent self-registration
- [x] Human claim flow
- [x] Scoped API keys
- [x] Idempotent write handling
- [x] Snapshot upload foundation
- [x] Revision mismatch protection at the current import layer
