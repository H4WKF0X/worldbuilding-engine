# Worldbuilding Engine

A Claude Code tool for building and maintaining fictional worlds. Drop raw lore fragments into an inbox; Claude writes structured, interconnected entries, flags contradictions, and invents supporting detail — nothing enters canon without your approval.

Built around a strict two-layer architecture: a portable engine (this repo) and per-world config that you fill in.

## Requirements

- [Claude Code](https://claude.ai/code)
- Git
- curl or wget

## Getting started

```bash
curl -fsSL https://raw.githubusercontent.com/H4WKF0X/worldbuilding-engine/main/setup.sh | bash -s my-world
cd my-world
```

Then open `world-config/identity.md` and `world-config/conventions.md` and fill them in. After that, drop any lore notes into `vault/inbox/` and run `/process` in Claude Code.

## Commands

| Command | What it does |
|---|---|
| `/process` | Reads inbox fragments and writes full entries to staging |
| `/approve` | Reviews staged entries and promotes approved ones to canon |
| `/gaps` | Analyses the full vault and reports narrative gaps |
| `/status` | Quick read-only snapshot of world state |
| `/refresh-entry` | Re-evaluates a single entry's gaps against current world state |
| `/retire` | Soft-deletes a canon entry, moving it outside the vault |
| `/reindex` | Rebuilds world-state from the filesystem (safety net) |

## How it works

The vault is an Obsidian folder with a strict structure: `inbox/` for raw input, `staging/` for Claude's output pending review, `entries/` for canon. A `world-state.md` file tracks canon entries, active contradictions, and references.

`/process` reads everything in the inbox, decomposes it into affected entities, and writes prose entries to staging. Invented details are marked inline. Contradictions with canon are flagged rather than resolved. `/approve` walks you through staged files and promotes the ones you accept.

World configuration lives in `world-config/identity.md` (name, tone, premise) and `world-config/conventions.md` (naming, style, what Claude should and shouldn't invent). These are the only files you need to author yourself.

## Repo layout

```
engine/          prompts, templates, and the user-facing CLAUDE.md
docs/            format references for engine development
setup.sh         initialises a new world project
```
