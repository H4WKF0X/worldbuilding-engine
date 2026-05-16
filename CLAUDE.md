# CLAUDE.md

You are working on the **worldbuilding engine** itself — the tool, not a world built with it.

This is not a CLAUDE.md for a user operating a world. That file is `engine/CLAUDE.md` and gets copied into generated world projects by `setup.sh`. This file is for development of the engine.

---

## What this project is

A Claude Code-powered worldbuilding tool. The user drops raw lore fragments into an inbox; Claude transforms them into full lore entries in an Obsidian vault. The engine is generic across worlds, distributed as a single GitHub-released setup script that initializes a fresh world project on the user's machine.

The project brief lives at `docs/project-brief.md` if present. Read it for the original design intent.

---

## Two-layer architecture

The deepest rule of this project, repeated everywhere:

**Engine** — portable across worlds. Lives in this repo. Includes:
- `engine/CLAUDE.md` — the user-facing instruction set (gets copied to world root).
- `engine/prompts/` — one prompt file per slash command.
- `engine/templates/entries/` — blank entry templates per entity type.
- `engine/templates/world-config/` — stubs for `identity.md` and `conventions.md`.
- `engine/templates/vault/` — the empty `world-state.md` skeleton.

**World config** — per-world, filled in by the user. Defined by the stubs in `engine/templates/world-config/`.

When a rule could plausibly differ between two worlds, it belongs in world config. Otherwise it belongs in the engine.

---

## Repo structure

```
/
├── CLAUDE.md                       ← this file (engine development)
├── README.md                       ← public-facing; stub right now
├── LICENSE
├── .gitignore
├── .vscode/                        ← workspace config
├── engine/
│   ├── CLAUDE.md                   ← user-facing, copied to world projects
│   ├── prompts/
│   │   ├── process.md              ← the main authoring command
│   │   ├── approve.md              ← review and promote staged entries
│   │   ├── gaps.md                 ← world-level narrative gap analysis
│   │   ├── status.md               ← quick snapshot
│   │   ├── refresh-entry.md        ← single-entry gaps refresh
│   │   ├── retire.md               ← soft-delete canon entry
│   │   └── reindex.md              ← world-state safety net
│   ├── templates/
│   │   ├── entries/                ← seven entity templates
│   │   ├── world-config/           ← identity.md, conventions.md stubs
│   │   └── vault/                  ← world-state.md skeleton
│   └── scripts/                    ← currently empty (.gitkeep only)
├── docs/                           ← format references and human docs
│   └── world-state-format.md
├── setup.sh                        ← release artifact (currently empty)
└── .github/                        ← reserved for issue templates, CI
```

`docs/` is for humans and for prompt-file authors. Engine prompts at runtime never load from `docs/`. The format reference for `world-state.md` lives there; engine prompts that need format details inline them.

---

## The seven slash commands

The full command surface, in writing order:

1. **`/process`** — the main authoring command. Reads inbox fragments, decomposes them into affected entities, writes full prose entries to `vault/staging/`, marks invention, flags contradictions, archives processed inbox files.

2. **`/approve`** — interactive review of staged entries. Classifies as bulk-approvable or walk-through. Bulk path is no-op until promotion. Walk-through resolves blocking markers per file. Final promotion strips markers, moves files to canon, reconciles world-state.

3. **`/gaps`** — deliberate world-level narrative gap analysis. Full vault read with user confirmation. Produces dated report in `vault/reports/`. Soft cap of 15 prioritized findings; user can override.

4. **`/status`** — read-only snapshot. Reads world-state, lists inbox and reports directories. No content reads, no state changes. Intentionally cheap.

5. **`/refresh-entry [entry]`** — re-evaluates a single entry's `## Gaps` section against current world-state. Only modifies that one section plus the `updated:` frontmatter field.

6. **`/retire [entry]`** — soft-delete. Moves a canon entry from `vault/entries/` to `retired/` at the project root (outside the vault). Wikilinks to retired entries no longer resolve. Reconciles `## Active Contradictions` and outgoing references; defers incoming-reference cleanup to `/reindex`.

7. **`/reindex`** — world-state safety net. Cheap mode (default) uses `Last reindex:` timestamp as cutoff; only re-reads newer files. Full mode (`--full`) re-reads everything. Updates world-state from filesystem reality. Reports warnings for files in unexpected locations but doesn't move them.

---

## Key design decisions

These were settled in the design phase and shape the entire engine. Future work should respect them unless explicitly revisited.

### Stateless operation

Every command does its own context loading. Claude has no session memory between commands. The user can `/clear` at any point and resume. Disk state is the source of truth.

### Staging gate

Nothing enters canon without `/approve`. `/process` writes only to `vault/staging/`. Updates to existing canon stage a new version of the file rather than modifying the canon file. Approval at promotion is what moves files and rewrites world-state's canon sections.

### Four marker types

Staging files use exactly four marker types as scaffolding for review:

- `==highlight==` — sentence-level invention.
- `> [inference]` — paragraph-scale invention.
- `> [QUESTION]` — ambiguity needing user resolution.
- `> [CONTRADICTION]` — conflict with canon (two sub-types, below).

All four are stripped at promotion. Questions must be resolved by walk-through before promotion; contradictions can be approved as-is and become canon-vs-canon contradictions at promotion.

### Three contradiction types

Settled after iteration:

- **Type 1: Canon-vs-canon.** Two canon entries disagree. Lives in `## Active Contradictions` in world-state.
- **Type 2: Self-update.** A staged update to entry E disagrees with E's own canon version. Marker text: "contradicts the existing canon version of this entry." Resolved by replacement at promotion. Can resolve or create Type 1 contradictions depending on the new content.
- **Type 3: Cross-entry.** A staged entry disagrees with a *different* canon entry. Marker text names that other entry. Always creates at least one Type 1 contradiction at promotion.

A new entry can only carry Type 3. An update entry can carry Type 2, Type 3, both, or neither. A single passage can carry both types.

### World-state is canon-only

`## Canon Entries`, `## Active Contradictions`, and `## Referenced but Uncanonized` track only canon-level facts. Staged entries appear separately in `## Staging` with a type tag. Retired entries appear separately in `## Retired`. Process does not write to canon-level sections — that's `/approve`'s job at promotion.

### Approval-vs-promotion distinction

These are separate phases of `/approve`. Approval is the user's per-file decision. Promotion is the actual file move from staging to canon plus world-state rewrite. They were briefly conflated during design; the clean separation matters because world-state updates and marker stripping happen only at promotion, allowing approval to be interruptible.

### `Last reindex:` cutoff

Cheap-mode `/reindex` uses the `Last reindex:` timestamp from world-state, not world-state's filesystem mtime. Reason: world-state.md is rewritten by many commands, which would push its mtime past any manual edits made before the rewrite. Only `Last reindex:` tracks the actual reindex moment.

### Retirement is soft-delete

A retired entry is no longer canon. Its file moves outside the vault (`retired/` at project root, not `vault/entries/_retired/`). Wikilinks to it from canon entries no longer resolve and become uncanonized references. Active contradictions involving it are resolved.

For timeline events ("Aelthorn dies"), do not retire — that's an update to the entry via `/process`, not removal.

---

## Editorial conventions for engine files

These conventions apply when writing engine files (prompts, templates, docs). They are not user-facing.

### Entity vs entry

These are distinct:

- **Entity** — the in-world thing. Lord Aelthorn the character. Greybridge the place.
- **Entry** — the markdown file documenting an entity. `Lord Aelthorn.md`.

Default to **entry** when talking about files, frontmatter, vault operations. Use **entity** only when explicitly talking about the in-world thing or about a name that may or may not have a file yet.

### No working notes in final files

Engine files are delivered clean. If a draft has "Wait, that's wrong, actually..." or "Hmm, but on the other hand..." or "Option A vs Option B" indecision, that's draft material and gets edited out before delivery. Final files state the decision, not the deliberation.

### Be opinionated, not exhaustive

Prompts are for Claude to follow at runtime. Listing every conceivable edge case bloats the prompt and makes the core path harder to find. State the principle, give examples of right and wrong behavior, name the anti-patterns to avoid. Leave the long tail to judgment.

### Examples over abstract criteria

Concrete good-vs-bad examples in prompts (as in `gaps.md`) work better than abstract quality criteria. Use them when the task requires judgment.

### Format reference patterns

When a section in a prompt produces or consumes a particular format (e.g., world-state's section headings, the marker types), keep the format reference close to the work that uses it. Don't cross-reference into `docs/` at runtime — engine prompts must be self-contained.

---

## Writing order used to build the engine

Files were written in this order. The order matters because each file builds on conventions established by the ones before it.

1. `engine/CLAUDE.md` — defines markers, hard rules, load order, file conventions.
2. `engine/templates/vault/world-state.md` + `docs/world-state-format.md` — the shared data structure.
3. `engine/templates/world-config/identity.md` and `conventions.md` — world-config stubs.
4. `engine/templates/entries/*.md` — seven entity templates.
5. `engine/prompts/process.md` — the main authoring command.
6. `engine/prompts/approve.md` — review and promotion.
7. `engine/prompts/gaps.md` — narrative gap analysis.
8. `engine/prompts/status.md`, `refresh-entry.md`, `retire.md`, `reindex.md` — the four smaller prompts.
9. (Not yet) `setup.sh` — the release artifact.
10. (Not yet) `README.md` proper.
11. (Not yet) `LICENSE` is in place but not chosen if it's still a placeholder.

If you're picking up work on the engine, check the writing order to see what's stable and what's still in flux. Anything from step 9 onwards is incomplete.

---

## What's still to build

- **`setup.sh`** — the script users download and run to initialize a new world. Takes a project name, downloads the engine release tarball, extracts only the relevant files into a new folder, runs `git init`, creates the empty vault and `retired/` directories, drops in world-config stubs.

- **`README.md`** — currently a stub. Needs proper public-facing documentation once `setup.sh` exists.

- **Release process** — GitHub release workflow for tagging versions and publishing tarballs. Will live in `.github/workflows/`.

---

## How to audit the project

When a session needs to confirm the state of the project (e.g., after gaps in development, or to verify that delivered files match decisions), read in this order:

1. This file, for the overview.
2. `engine/CLAUDE.md`, for the user-facing rules and what's promised to the user.
3. `docs/world-state-format.md`, for the shared data structure.
4. `engine/prompts/process.md` and `engine/prompts/approve.md`, for the core flow.
5. The remaining prompt files in any order.
6. The templates if checking entry shape questions.

Look for inconsistencies — places where one file says something different from another, places where a decision documented above isn't reflected in the prompt that should implement it. Surface these as questions rather than fixing silently; design decisions during fixes can drift further from intent.

---

## What this engine is not

- Not a session prep tool — Obsidian handles retrieval.
- Not a writing assistant — the user doesn't sit down to write entries with help.
- Not a paraphraser — the user doesn't pre-write; Claude authors from seeds.
- Not a tool requiring the user to write prompts — the slash command interface is the entire surface.
- Not stateful across sessions — context comes from files, every time.
- Not customizable per world beyond what `world-config/` provides — there are no per-world prompts or commands.
