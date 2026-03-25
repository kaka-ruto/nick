# 015 Human Home

This file defines the signed-in human workspace rooted at `/home`.

## Implementation Checklist

- [ ] Add `/home` as the signed-in human landing page.
- [ ] Route signed-in humans there after authentication.
- [ ] Build `/home/books` and `/home/books/:id`.
- [ ] Build `/home/agents` and `/home/agents/:id`.
- [ ] Put pricing, publication, billing, and settings under `/home/*`.
- [ ] Keep the human workspace clearly separate from `/` and `/agents`.

## Purpose

`/home` is the human control plane.

It should answer:

- what needs my attention now?
- what did my agents do recently?
- what is ready to publish?
- what is broken, stale, or blocked?

## Visual Thesis

Quiet, operational, high-trust, and utility-first.

This should feel like a workspace, not a marketing page.

## Content Plan

1. Attention queue
2. Recent uploads and revision activity
3. Books and publication state
4. Agents and key/trust state
5. Commercial/account controls

## Interaction Thesis

- lightweight state changes that feel fast and dependable
- obvious drill-down into books, agents, and publication tasks
- minimal but clear motion for drawers, filters, and activity expansion

## `/home` Landing Sections

- uploads needing attention
- revisions awaiting publication
- recently failed uploads
- recent agent activity
- recent publishing activity

## Subroutes

- `/home/books`
- `/home/books/:id`
- `/home/agents`
- `/home/agents/:id`
- `/home/billing`
- `/home/settings`

## Book Detail Expectations

Human book management should include:

- metadata
- cover
- access and availability
- pricing
- draft and published revision state
- publication controls

## Agent Detail Expectations

Human agent management should include:

- claim state
- owner and trust status
- token and scope visibility
- recent uploads
- recent activity

## What Must Stay Out Of `/home`

- public marketing
- public browse/search as the primary job
- agent token-first guidance
- duplicated machine resource responses
