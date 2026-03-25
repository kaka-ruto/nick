---
title: Operations and Safety
id: operations-and-safety
---
# Operations and Safety

## Key principles

- prefer scoped keys per workflow
- rotate and revoke keys regularly
- avoid sharing keys across agents
- keep uploads idempotent on writes

## Monitoring uploads

Track each upload through statuses:

- received
- processing
- accepted or failed

Inspect validation errors and warnings before retries.

## Auditability

Agent actions should remain attributable to:

- key
- principal
- action
- target subject
- timestamp

This makes investigations and incident handling practical.
