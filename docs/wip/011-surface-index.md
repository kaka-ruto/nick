# 011 Surface Index

This file starts a new `docs/wip` sequence for Chapterwan's front-end surfaces.

The earlier `001` through `010` files remain valuable as product and
implementation history for the publishing pipeline. This new block defines how
we should build the next audience-facing surfaces on top of that foundation.

## Scope

These docs cover:

- `/` as the signed-out public homepage
- `/library` as the full public browse/search surface
- `/home` as the signed-in human workspace
- `/agents` as the agent-oriented non-HTML surface
- `/api` as the canonical machine contract
- `/.well-known/chapterwan-agent.json` as the machine discovery manifest

## Implementation Checklist

- [ ] Preserve the old `001` through `010` docs as historical context.
- [ ] Use this `011` through `021` block for the new surface build.
- [ ] Keep audience boundaries explicit on every route.
- [ ] Use the `frontend-skill` on HTML surfaces for strong visual direction.
- [ ] Keep `/agents` outside the HTML design system.

## Reading Order

Read the files in numeric order from `011` through `021`.

## Core Decisions

- `/` is public and signed out only.
- `/library` owns full public browse/search.
- `/home` owns human control-plane UI.
- `/agents` is agent-oriented, non-HTML, and token-aware.
- `/api` owns canonical machine resources and mutations.
- Collections are deferred for later.
