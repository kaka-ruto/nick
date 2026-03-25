# 020 Visual Direction

This file defines the visual and interaction direction for the new surfaces.

Use the `frontend-skill` when building `/`, `/library`, and `/home`.

## Implementation Checklist

- [ ] Give `/`, `/library`, and `/home` distinct visual personalities.
- [ ] Keep `/agents` non-HTML and out of the visual system.
- [ ] Use expressive composition on `/`.
- [ ] Use browse-first editorial layout on `/library`.
- [ ] Use utility-first workspace layout on `/home`.
- [ ] Avoid generic card mosaics across all major surfaces.

## Surface Theses

### `/`

- mood: editorial, bold, memorable
- job: persuade and orient
- copy style: concise, brand-forward
- motion: visible but restrained
- thems: light and dark modes

### `/library`

- mood: calm, browseable, bookish
- job: search and discovery
- copy style: descriptive and utility-aware
- motion: minimal and supportive

### `/home`

- mood: operational, clear, trustworthy
- job: help humans decide and act
- copy style: utility copy, not marketing copy
- motion: subtle and state-oriented

### `/agents`

- not part of the HTML design language
- optimize for clarity, structure, and low token cost
- prioritize text hierarchy over visual styling

## Hard Rules

- do not design `/home` like a marketing landing page
- do not design `/library` like an admin dashboard
- do not design `/` like a SaaS card grid
- do not build HTML UI for `/agents`
- keep the first screen of `/` unmistakably branded

## Typography And Hierarchy

- `/` should have the loudest brand presence
- `/library` should prioritize scanning and browse order
- `/home` should prioritize labels, status, and actions

## Motion Guidance

- `/`: hero entrance and one meaningful reveal sequence
- `/library`: near-zero ornamental motion
- `/home`: quick, quiet motion for task flow only
