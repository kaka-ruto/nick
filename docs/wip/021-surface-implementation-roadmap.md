# 021 Surface Implementation Roadmap

This file turns the route and surface spec into an execution order.

## Phase 1: Route Ownership

- [ ] Add `/home`.
- [ ] Add `/library`.
- [ ] Add `/agents` as the agent guidance namespace.
- [ ] Move current JSON `/agents` endpoints to `/api/agents`.
- [ ] Keep compatibility redirects or aliases only if needed for migration.

## Phase 2: Canonical Machine Surface

- [ ] Keep `/api` strict and canonical.
- [ ] Remove duplicate machine resource shapes from `/agents`.
- [ ] Standardize JSON response links and status fields.
- [ ] Add `/.well-known/chapterwan-agent.json`.

## Phase 3: Public Discovery

- [ ] Redesign `/` as the signed-out public homepage.
- [ ] Build `/library` as the full browse/search experience.
- [ ] Keep the public reader routes clearly connected from both.

## Phase 4: Human Workspace

- [ ] Build `/home`.
- [ ] Build `/home/books`.
- [ ] Build `/home/books/:id`.
- [ ] Build `/home/agents`.
- [ ] Build `/home/agents/:id`.
- [ ] Build `/home/billing`.
- [ ] Build `/home/settings`.

## Phase 5: Agent Surface

- [ ] Build `/agents` as the unauthenticated agent start page.
- [ ] Build `/agents/home` as the authenticated agent landing page.
- [ ] Add `/agents/capabilities`.
- [ ] Add `/agents/quickstart` or `/agents/help` if still needed after the start page is designed.
- [ ] Keep agent responses text-first and low-token.

## Phase 6: Testing And Acceptance

- [ ] Add integration coverage for the new route ownership and redirects.
- [ ] Add integration coverage for `/api/agents` after the move.
- [ ] Add response-format tests for `/agents`.
- [ ] Add acceptance coverage for `/home` and `/library`.
- [ ] Prefer unit and integration tests over new controller or system tests.

## Phase 7: Cleanup

- [ ] Remove legacy `/agents` JSON behavior once `/api/agents` is in place.
- [ ] Update docs, examples, and onboarding to the new route model.
- [ ] Ensure no page violates the audience contract defined in `012`.
