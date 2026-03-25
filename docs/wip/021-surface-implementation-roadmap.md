# 021 Surface Implementation Roadmap

This file turns the route and surface spec into an execution order.

## Phase 1: Route Ownership

- [x] Add `/home`.
- [x] Add `/library`.
- [x] Add `/agents` as the agent guidance namespace.
- [x] Move current JSON `/agents` endpoints to `/api/agents`.
- [x] Keep compatibility redirects or aliases only if needed for migration.

## Phase 2: Canonical Machine Surface

- [x] Keep `/api` strict and canonical.
- [x] Remove duplicate machine resource shapes from `/agents`.
- [x] Standardize JSON response links and status fields.
- [x] Add `/.well-known/cafaye-agent.json`.

## Phase 3: Public Discovery

- [x] Redesign `/` as the signed-out public homepage.
- [x] Build `/library` as the full browse/search experience.
- [x] Keep the public reader routes clearly connected from both.

## Phase 4: Human Workspace

- [x] Build `/home`.
- [x] Build `/home/books`.
- [x] Build `/home/books/:id`.
- [x] Build `/home/agents`.
- [x] Build `/home/agents/:id`.
- [x] Build `/home/billing`.
- [x] Build `/home/settings`.

## Phase 5: Agent Surface

- [x] Build `/agents` as the unauthenticated agent start page.
- [x] Build `/agents/home` as the authenticated agent landing page.
- [x] Add `/agents/capabilities`.
- [x] Add `/agents/quickstart` or `/agents/help` if still needed after the start page is designed.
- [x] Keep agent responses text-first and low-token.

## Phase 6: Testing And Acceptance

- [x] Add integration coverage for the new route ownership and redirects.
- [x] Add integration coverage for `/api/agents` after the move.
- [x] Add response-format tests for `/agents`.
- [x] Add acceptance coverage for `/home` and `/library`.
- [x] Prefer unit and integration tests over new controller or system tests.

## Phase 7: Cleanup

- [x] Remove legacy `/agents` JSON behavior once `/api/agents` is in place.
- [x] Update docs, examples, and onboarding to the new route model.
- [x] Ensure no page violates the audience contract defined in `012`.
