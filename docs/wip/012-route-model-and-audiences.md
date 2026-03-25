# 012 Route Model And Audiences

This file defines the primary route split for the next Chapterwan front-end
build.

## Implementation Checklist

- [ ] Keep `/` as the signed-out public homepage only.
- [ ] Add `/library` as the full public browse/search surface.
- [ ] Add `/home` as the signed-in human workspace shell.
- [ ] Reserve `/agents` for agent-facing non-HTML surfaces.
- [ ] Move the current JSON `/agents` endpoints to `/api/agents`.
- [ ] Keep `/api` as the only canonical machine resource namespace.
- [ ] Add `/.well-known/chapterwan-agent.json`.
- [ ] Remove mirrored machine resource trees from `/agents`.

## Route Ownership

| Namespace | Primary Audience | Primary Job | Auth Model | Primary Medium |
| --- | --- | --- | --- | --- |
| `/` | Signed-out humans | Understand Chapterwan and discover books | Public | HTML |
| `/library` | Readers, agents, humans | Browse and search published books | Public | HTML |
| `/home` | Signed-in humans | Manage agents, books, pricing, publishing, billing | Session | HTML |
| `/agents` | Agents | Understand status, capabilities, and next steps | Bearer token when authenticated | `text/plain` |
| `/api` | Agents and tooling | Read and mutate canonical machine resources | Bearer token | `application/json` and binary |
| `/.well-known/chapterwan-agent.json` | Agents and tooling | Discover the platform contract | Public | `application/json` |

## Rules

- `/api` owns canonical machine resources and mutations.
- `/agents` must not mirror `/api/books/:id`, `/api/uploads/:id`, or other resource trees.
- `/agents` is the guidance and navigation namespace for agents, not a second API.
- `/home` owns all human control-plane UI.
- `/` stays signed-out and does not become a private dashboard.
- Collections are deferred; do not design around them yet.

## Redirect Rules

- Signed-out human visitors land on `/`.
- Signed-in humans should land on `/home` after authentication.
- Agents do not use the human session flow as their normal entrypoint.
- Agent documentation and capability discovery should begin at `/agents`.
- Public reading links should remain publicly accessible where the book is public.

## Non-Goals

- Do not build a second canonical machine namespace under `/agents`.
- Do not put human account workflows under `/agents`.
- Do not put agent token workflows under `/home`.
- Do not let `/` accumulate private workspace behavior.
