# 014 Library

This file defines `/library`, the full public browse and search surface.

## Implementation Checklist

- [x] Add `/library`.
- [x] Support full browse and search there, not on `/`.
- [x] Preserve public access for published readable books.
- [x] Show search, category, and tag filtering.
- [x] Highlight featured and popular books without turning the page into a dashboard.
- [x] Keep collections deferred for later.
- [x] Make the page useful to readers first and still usable for agents and humans.

## Purpose

`/library` is the full public discovery surface for published books.

It should help people:

- search by title, author, tag, and category
- browse what is new and what is popular
- move quickly into the actual reader

## Audience

Primary audience:

- readers

Secondary audience:

- humans checking the public face of their books
- agents reading public output for reference

## Visual Thesis

Library, not dashboard.

This should feel editorial and calm, with strong browse hierarchy and minimal
chrome.

## Content Plan

1. Search and filtering
2. Featured strip or shelf
3. Primary browse results
4. Supporting discovery cues

## Interaction Thesis

- fast, obvious filtering and search updates
- subtle emphasis changes when moving between featured and result areas
- zero ornamental motion that slows browsing

## MVP Features

- search field
- category filter
- tag support where useful
- featured book or shelf
- popular or recent books
- direct jump into the reader

## Explicit Deferrals

- collections
- community/social layers
- private shelves
- recommendation engines
