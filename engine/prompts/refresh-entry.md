# /refresh-entry [entry]

Re-evaluate the `## Gaps` section of a single entry against current world-state. Useful when an entry has been edited, or when the world has grown around the entry and its gap section has drifted.

This command modifies only the `## Gaps` section of the named entry. It does not touch the rest of the entry. It does not modify world-state.

## What this command does

1. Resolve the entry argument to a specific file.
2. Load context.
3. Re-evaluate gaps for the entry.
4. Rewrite only the `## Gaps` section.

---

## Step 1: Resolve the entry argument

The user passes an entry name as argument. Accept it in any form: with or without `[[]]`, case-insensitive, with or without titles.

Search `vault/entries/[type]/` and `vault/entries/_retired/` for a file whose name matches. Also check `vault/staging/[type]/` — refresh is valid for staged entries too.

If exactly one match: proceed.

If multiple matches across types or states (e.g., a canon `Greybridge` location and a staged `Greybridge` faction): ask the user which one. Example:

```
Multiple entries match "Greybridge":
1. vault/entries/locations/Greybridge.md (canon)
2. vault/staging/factions/Greybridge.md (staged)

Which one?
```

If no match: tell the user and stop.

```
No entry named "[name]" found in canon, staging, or retired.
```

---

## Step 2: Load context

Read in order:

1. `world-config/identity.md` — tone, themes, what kinds of gaps matter most.
2. `world-config/conventions.md` — for voice consistency on the rewritten section.
3. `vault/world-state.md` — to know what canon exists around this entry.
4. The entry file itself.

Optionally read entries that reference this entry — check world-state's `## Canon Entries` for entries you suspect link here, or scan for backlinks. Reading these helps you judge what the entry implies but doesn't deliver. Limit to one hop; do not load the whole vault.

---

## Step 3: Re-evaluate gaps

Look at the entry as it currently stands. Identify what is genuinely undefined for this entity in light of:

- What the entry's prose implies but doesn't state (named relationships hinted at but not specified, motivations gestured at but not given).
- What other entries reference this entry as having or being — and what the entry itself doesn't yet cover.
- What `identity.md`'s "what kinds of gaps matter most" field flags.

Gap items in the per-entry `## Gaps` section should be:

- **Specific.** Name what is missing. "Cousin's name unrecorded" is fine. "More family detail needed" is not.
- **Honest.** Don't list a gap just because a template section is short. If the entity genuinely has nothing more to say in that area, no gap.

Per-entry gaps can be smaller in stakes than the world-level gap report. "His preferred wine is unspecified" is a fine per-entry gap if the entry implies he's a connoisseur but doesn't say what he drinks. The world-level report would never flag this; the per-entry section can.

Avoid the same anti-patterns the world-level gap report avoids:

- "Needs more detail."
- "Could be expanded."
- "Underdeveloped."
- "This section is short."

---

## Step 4: Rewrite the `## Gaps` section

Replace the existing `## Gaps` section in the entry file with the re-evaluated list. Use bullets (this is one of the exceptions to the prose-only rule).

Do not touch any other section of the entry. Do not modify frontmatter except `updated:` — set it to today's date.

If the entry has no gaps after re-evaluation, leave the heading and write one line: "No gaps identified at this time." Do not remove the section heading.

Write the updated file.

---

## Step 5: Tell the user

Short confirmation:

```
Refreshed gaps for [[Entry Name]].

[N] gaps identified. [Or: No gaps identified at this time.]
Updated: vault/entries/[type]/Entry Name.md
```

If the refresh found significantly different gaps than were there before, mention that briefly. Otherwise just the bare confirmation.

---

## What you do not do

- Do not modify any section of the entry other than `## Gaps` and the `updated:` frontmatter field.
- Do not modify world-state.
- Do not rewrite the entry's prose.
- Do not read every entry in the vault — only one-hop references.
- Do not list generic gaps. Specificity is required.
- Do not invent content for the entry itself. This command only updates the gap section.
