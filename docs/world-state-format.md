# `world-state.md` Format Reference

This document describes the exact format of `vault/world-state.md`. The starting template is at `engine/templates/vault/world-state.md`. Prompt files that read or write world-state should treat this document as the format specification.

The file is markdown. It is read by Claude on every command and rewritten by `/process`, `/approve`, `/retire`, and `/reindex`. The user does not edit it manually — direct edits to canon entries are reconciled via `/reindex`.

---

## Section structure

The file has these top-level sections, in this order:

1. `## Canon Entries` — with seven `###` subsections, one per entity type
2. `## Referenced but Uncanonized` — entities wikilinked but lacking entries
3. `## Active Contradictions` — flagged conflicts awaiting user resolution
4. `## Staging` — entries awaiting approval
5. `## Retired` — entries moved to `_retired/`
6. `Last reindex:` line at the bottom

Section headings are fixed. Do not rename them. Prompt files match against these exact strings.

The seven `###` subsections under Canon Entries are also fixed: `Locations`, `Factions`, `NPCs`, `History`, `Religion`, `Economy`, `Magic`. Always present even when empty.

---

## Entry format within sections

### Canon entries

One bullet per entry. Format:

```
- [[Entity Name]] — short descriptor (updated YYYY-MM-DD)
```

The wikilink is the entity name. The descriptor is one line, written by Claude during `/process` or `/approve`, summarizing what the entity is. The date is when the entry's canon file was last updated.

The descriptor exists so Claude can pick relevant entries to load for a given operation without opening every file. Keep it informative and short.

### Referenced but Uncanonized

One bullet per uncanonized entity. Format:

```
- "Entity Name" — referenced in [[Source Entry]], [[Other Source]]
```

Quoted name (not wikilinked — wikilinking here would create a dangling reference that pollutes Obsidian's graph). The sources are the canon entries that mention it. When an uncanonized entity gets its first entry, this bullet is removed and a Canon Entries bullet is added.

### Active Contradictions

This section tracks **canon-vs-canon contradictions only** — places where two canon entries disagree. Staged entries that conflict with canon are not tracked here; they appear via their `> [CONTRADICTION]` marker inside the staged file and their `(type: contradiction)` tag in `## Staging`.

One bullet per active canon-vs-canon contradiction. Format:

```
- [[Entry A]] and [[Entry B]]: brief description of the conflict. Flagged YYYY-MM-DD.
```

Resolution paths:

- A staged self-update to one of the entries (Type 2 contradiction marker) can resolve the contradiction at promotion if the new canon version agrees with the other party.
- A user editing one of the canon entries directly, followed by `/reindex`.
- Retirement of one of the entries (removes one party from canon).

Promotion of a cross-entry staged contradiction (Type 3 marker) *adds* a new canon-vs-canon contradiction at promotion. A self-update may also add a new one if the new canon version disagrees with entries the old version agreed with.

### Staging

One bullet per staged entry. Format:

```
- [[Entity Name]] (type: new | update | contradiction) — short note on what changed
```

The type tag tells `/approve` how to triage. `new` is a fresh entry. `update` modifies existing canon. `contradiction` means the entry conflicts with canon. Cleared by `/approve` as items are promoted or rejected.

### Retired

One bullet per retired entry. Format:

```
- [[Entity Name]] — retired YYYY-MM-DD
```

Wikilinks still resolve; the file lives in `vault/entries/_retired/`. Retirement is reversible by moving the file back and running `/reindex`.

---

## Annotated example

What the file looks like for a small world with a handful of entries:

```markdown
# World State

Index of canon, references, contradictions, and staging for this world.
This file is maintained by the engine. Do not edit manually — use `/reindex` if it drifts.

## Canon Entries

### Locations
- [[Greybridge]] — frontier town, garrison post on the Mire road (updated 2026-04-12)
- [[The Long Mire]] — disputed marshland east of Greybridge (updated 2026-04-09)

### Factions
- [[The Stormwardens]] — mounted order of the eastern reach (updated 2026-04-14)
- [[The Tithe Council]] — clerical taxation body of the Quiet Faith (updated 2026-04-12)

### NPCs
- [[Lord Aelthorn]] — regional warden, seat at Greybridge (updated 2026-04-14)
- [[Stormwarden Mirelle]] — commander of the Stormwardens (updated 2026-04-14)
- [[Brother Vance]] — tithe collector, currently posted to Greybridge (updated 2026-04-11)

### History
- [[The Long Winter]] — three-decade-past famine and migration event (updated 2026-04-10)
- [[The Greybridge Compact]] — agreement settling the Mire claims, contested (updated 2026-04-12)

### Religion
- [[The Quiet Faith]] — dominant clerical tradition, hierarchical (updated 2026-04-11)

### Economy

### Magic

## Referenced but Uncanonized
- "The Marshreave family" — referenced in [[Greybridge]], [[Lord Aelthorn]]
- "The Compact's third article" — referenced in [[The Greybridge Compact]]
- "Old Coller" — referenced in [[The Long Winter]]

## Active Contradictions
- [[The Greybridge Compact]] and [[The Long Winter]]: Compact entry dates the signing to year 412; Long Winter entry places the signing after the winter, which ended 419. Flagged 2026-04-12.

## Staging
- [[Captain Reyne]] (type: new) — first appearance, garrison officer at Greybridge
- [[The Stormwardens]] (type: update) — adds detail on recruitment from frontier holds
- [[The Greybridge Compact]] (type: contradiction) — new fragment dates Compact to 421, conflicts with both existing date claims

## Retired
- [[Old Hess]] — retired 2026-03-30

---

Last reindex: 2026-04-14 09:22
```

---

## Notes for prompt-file authors

The `Last reindex:` line is human-readable diagnostic information. The **authoritative** timestamp for `/reindex`'s cheap-mode logic is the file's `mtime` on disk, not this string. The string exists for `/status` to display and for the user to glance at.

When updating the file: rewrite it whole. Do not try to patch individual lines. The file is small enough that whole-file rewrites are cheap and parsing/patching introduces bugs.

When the file is well-formed but a section is empty, leave the heading and the blank line after it. Do not delete empty section headings — the structure must be stable so other prompts can rely on it.

Entity names in wikilinks must match the entry filename exactly (case-sensitive, spaces preserved). `[[Lord Aelthorn]]` resolves to `vault/entries/npcs/Lord Aelthorn.md`.
