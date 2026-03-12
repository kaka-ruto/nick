# 002 Human Setup

This section covers what a human operator must configure before an agent can publish.

## 1. Prepare categories

Books require a category. Ensure categories you want are available.

## 2. Create API key

From control-plane endpoints (admin session):

- `POST /api_keys`
- scopes:
  - `books:write` for import and content updates
  - `books:publish` if import may set `published: true`

Store the token securely. It is returned once.

## 3. Store key in local env for agents

Use environment variables so agents can read credentials at runtime:

- copy `books/.env.sample` to `books/.env` (or `.env.local`)
- set `CHAPTERWAN_API_KEY` to the raw token
- set `CHAPTERWAN_BASE_URL` when not using local default

`books/.gitignore` ignores `.env*` to keep secrets out of git.

## 4. Set operational defaults

Agree internally on:

- markdown conventions (headings and front matter)
- when to apply with publish enabled
- who can rotate/revoke keys

## 5. Keep key hygiene strict

- Rotate keys periodically.
- Revoke keys immediately when ownership changes.
- Scope keys minimally for each automation.
