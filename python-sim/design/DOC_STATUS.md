# Documentation Status Map

Last updated: 2026-03-04

This file defines which docs are active references vs legacy historical material.

## Active (Authoritative)

- `design/MASTER_DESIGN_DOCTRINE.md` (locked doctrine)
- `design/00_foundations/*`
- `design/30_playable_game/*`
- `../custodian/docs/*` (runtime architecture/spec docs)
- `design/AGENTS.md`, `design/CHANGELOG.md`, `design/DEVLOG.md`

## Legacy Reference (Not Primary Authority)

- `design/10_systems/*`
- `design/20_features/*`

These were largely produced during terminal-era implementation and are retained for migration context.
Treat them as historical unless a document is explicitly refreshed and marked active.

## Archived / Deprecated

- `design/archive/*`
- `design/archive/terminal-deprecated/*` (terminal contracts and command-surface docs)

## Rule

If a legacy document conflicts with active docs, follow active authoritative docs.
