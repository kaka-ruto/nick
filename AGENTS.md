# AGENTS.md

Common agent instructions for this repository.

## Scope

- This repository is a platform product codebase.
- Follow the rules in this file for product and platform engineering work.

## Core Rules

- Keep executing in a continuous loop; do not stop unless a hard blocker exists.

## Product Direction (MVP)

- Cafaye is agent-first for publishing and distribution.
- Humans can still use the UI where supported; the system should remain usable for both.
- Agent-first writing is out of scope for MVP ingestion: agents submit already-written work.
- Prioritize fast, lovable, usable MVP delivery over hardening work not explicitly requested.

## Frontend Styling Rules

- For every new view, use Tailwind utility classes for styling.
- When updating an existing view, prefer Tailwind classes for any new or changed styling.
- Do not add new raw CSS files or selectors for view styling unless the user explicitly asks for it.
- Existing legacy CSS can remain in place until the related view is updated.

## Backend/Infra Rules

- Database support is Postgres only. Do not add or restore SQLite behavior.
- Never route `solid_events` writes to the `primary` database.
- Keep multi-database separation:
  - `primary` for app data
  - `errors` for `solid_errors`
  - `events` for `solid_events`
- Do not introduce `POSTGRES_*` environment variable fallback patterns in app DB config.
- Local Postgres should work without password defaults unless the user asks otherwise.

## Payments + Commerce Rules

- Use the `pay` gem for payments.
- Stripe is the processor for MVP.
- Keep purchase and free-distribution flows simple and explicit for demand validation.

## Priority

- If there is any conflict, instructions from the user in the current thread take precedence.
- Otherwise, this `AGENTS.md` is the source of truth for repository-level behavior.

## Commits

**Commit related changes when they are done.**

- Commit when a feature is completed
- Do NOT use `git add .` by any means
- Commit messages must be one direct sentence
- Do not use commit prefixes like `feat:`, `fix:`, `chore:`, etc.
- One logical change per commit

# Rails Core Team Development & Testing Guidelines

## Rails Core Team Style Guide

We follow the Rails core team's approach to writing clean, maintainable code and tests.

### Code Philosophy

**Simplicity Over Complexity**

- Write the simplest code that solves the problem
- Don't over-engineer for hypothetical future needs
- If you need complex abstractions, your design might be wrong
- Prefer boring, obvious solutions over clever ones

**Convention Over Configuration**

- Trust Rails conventions - they exist for a reason
- Don't fight the framework
- Use standard Rails patterns unless you have a compelling reason not to
- When in doubt, check how Rails itself does it

**Separation of Concerns**

- Jobs call services, services contain business logic
- Jobs should be 5-10 lines: call the service, maybe log a summary
- Services should be focused: one clear responsibility
- Don't mix HTTP concerns with business logic
- Extract to separate classes when a method needs more than one level of conditionals

### DDD Service Objects (Operations)

**Structure:**

```
class MyOperation
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  def call
    # Business logic here
    # Return a result (hash, object, or raise exception)
  end

  private

  # Small, focused private methods
end
```

**Guidelines:**

- Keep `call` method under 10 lines
- Extract complex logic into private methods with descriptive names
- Return consistent result format (hash with status/data/errors)
- Let exceptions bubble up for unexpected errors
- Only rescue specific, expected exceptions
- No logging in services (jobs handle that)
- No file I/O without injectable paths
- Pass dependencies as parameters, not hardcoded

### Background Jobs

**Keep Jobs Simple:**

- Just call the DDD object
- Let exceptions bubble up to `retry_on`/`discard_on`
- Minimal logging (one line summary at most)
- No business logic in jobs
- No complex error handling (service handles it)

**Retry Configuration:**

- Be specific about which errors to retry
- Use `retry_on` for transient errors (timeouts, deadlocks)
- Use `discard_on` for permanent errors (validation failures)
- Don't retry everything with `StandardError`

**Example:**

```
class MyJob < ApplicationJob
  retry_on TimeoutError, ApiError, wait: :exponentially_longer, attempts: 3
  discard_on ValidationError, ParseError

  def perform(params)
    MyOperation.call(params: params)
  end
end
```
