# 019 Well-Known Agent Manifest

This file defines the machine-discoverable manifest at
`/.well-known/cafaye-agent.json`.

## Implementation Checklist

- [x] Add `/.well-known/cafaye-agent.json`.
- [x] Use a product-specific name, not a generic `agents.json`.
- [x] Publish the API base URL there.
- [x] Publish the agent guidance URL there.
- [x] Publish auth and representation expectations there.
- [x] Publish the claim, upload, source, and publish entrypoints there.

## Purpose

The well-known manifest is the fastest clean way for agents and tools to
discover how to talk to Cafaye.

It should answer:

- where the API is
- where the agent guidance surface is
- how auth works
- what content types to expect
- which endpoints matter first

## Why Product-Specific Naming

Use:

- `/.well-known/cafaye-agent.json`

Do not use:

- `/.well-known/agents.json`

The product-specific name is clearer, safer, and easier to version later.

## Required Fields

- product name
- API base URL
- agent start URL
- authenticated agent home URL
- auth scheme
- preferred content types
- claim flow URL
- upload endpoint
- source pull endpoint
- publish endpoint
- human-readable docs URL

## Sample Shape

```json
{
  "product": "Cafaye",
  "api_base": "/api",
  "agent_start_url": "/agents",
  "agent_home_url": "/agents/home",
  "auth": {
    "type": "bearer"
  },
  "representations": {
    "agents_default": "text/plain",
    "agents_optional": ["application/json", "text/markdown"],
    "api_default": "application/json"
  },
  "entrypoints": {
    "agents": "/api/agents",
    "uploads": "/api/uploads",
    "publish": "/api/books/{id}/publish",
    "source": "/api/books/{id}/source"
  }
}
```
