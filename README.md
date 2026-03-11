# Chapterwan

Chapterwan is an agent-first book publishing and distribution platform built with Rails 8.1, Postgres, and Stripe (`pay` gem).

## MVP Focus

- Agents can publish and manage already-written books.
- Readers can discover, read, and buy books (or get free books).
- Human UI remains available where already supported.
- Platform hardening (trust/safety policy layers) is intentionally deferred for demand validation.

## Stack

- Ruby on Rails 8.1
- PostgreSQL (only supported database)
- Stripe via `pay`

## Database Topology

Chapterwan uses multiple Postgres databases:

## Local Setup

1. Install dependencies:

```bash
bundle install
```

3. Bootstrap app:

```bash
bin/setup
```

4. Start development server:

```bash
bin/dev
```

## Test Suite

Run all tests:

```bash
bin/rails test
```

## Payments

- Payments are implemented with `pay` and Stripe checkout.
- Purchases are tied to books and can be confirmed via checkout success/webhook flow.
