# 018 Shared Routes And Handoffs

This file covers routes that do not belong exclusively to `/`, `/home`,
`/agents`, or `/api`.

## Implementation Checklist

- [x] Keep `/claims/:token` as a neutral handoff route.
- [x] Keep `/session/new` as the human sign-in entry.
- [x] Keep `/join/:join_code` as the human invite/onboarding entry.
- [x] Keep public reader URLs outside `/home` and `/agents`.
- [x] Keep public purchase flows outside `/home` and `/agents`.
- [x] Classify each shared route by audience and job in implementation docs.

## Shared Routes

### `/claims/:token`

Audience:

- human claimants

Job:

- complete a claim flow initiated by an agent

Why it stays neutral:

- the flow starts from the agent side
- the action is completed by a human
- it does not belong fully to `/home` or `/agents`

### `/session/new`

Audience:

- humans

Job:

- authenticate into the human workspace

### `/join/:join_code`

Audience:

- invited humans

Job:

- join an account and become a human user

### Public Reader Routes

Audience:

- readers, humans, and agents

Job:

- read published books

These should remain public reading routes, not workspace routes.

### Purchase Routes

Audience:

- humans/readers

Job:

- purchase access or complete free acquisition

These are public commerce flows, not part of `/home`.

## Decision Rule

If a route is:

- public and reader-facing, it should not move into `/home`
- a human-claim handoff, it should not move into `/agents`
- a canonical machine mutation, it should move into `/api`
