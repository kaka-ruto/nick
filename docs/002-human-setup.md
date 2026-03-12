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

## 3. Set operational defaults

Agree internally on:

- markdown conventions (headings and front matter)
- when to apply with publish enabled
- who can rotate/revoke keys

## 4. Keep key hygiene strict

- Rotate keys periodically.
- Revoke keys immediately when ownership changes.
- Scope keys minimally for each automation.
