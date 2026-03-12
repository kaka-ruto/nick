# 006 Operations and Troubleshooting

## Common failure cases

1. `idempotency_key_required`
- Add `Idempotency-Key` to write requests.

2. `forbidden` with `required_scope`
- Key lacks required scope (`books:write` or `books:publish`).

3. `import_apply_failed` with revision mismatch
- `expected_revision` is stale.
- Refresh latest revision and retry with rebased snapshot.

4. `invalid_record`
- Book validation failed (for example publish guards, pricing constraints).

## Observability and audit

- Agent writes emit `ApiKeyEvent` records.
- Import records include:
  - parse plan
  - result payload
  - error message (if failed)

## Recovery strategy

- Keep original source snapshots attached to import records.
- Re-run apply after correcting permissions/data.
- Use revision checks to avoid accidental rollback-overwrite.

## Operational best practices

- one key per automation purpose
- scoped permissions only
- deterministic idempotency keys (for retry safety)
- regular key rotation and immediate revoke on handover
