# /retire [entry]

Move a canon entry to retired status. The entry's file is moved to `vault/entries/_retired/`, the entry's wikilinks from other entries still resolve to it, and world-state is updated to reflect the retirement.

Use this when an entity should be preserved but is no longer current: a faction that has dissolved, an NPC that has died, a place that has been destroyed. Retirement does not delete; it archives.

## What this command does

1. Resolve the entry argument.
2. Confirm with the user.
3. Move the file to `vault/entries/_retired/`.
4. Update frontmatter.
5. Update world-state.

---

## Step 1: Resolve the entry argument

The user passes an entry name as argument. Accept it in any form: with or without `[[]]`, case-insensitive.

Search `vault/entries/[type]/` for a file whose name matches. Only canon entries can be retired — not staging, not already-retired.

If exactly one match: proceed.

If multiple matches across types (e.g., a canon location and a canon faction with the same name): ask the user which one.

If no match in canon: tell the user and stop. Example messages:

```
No canon entry named "[name]" found.
```

Or, if the entry exists in staging or retired:

```
"[name]" is not in canon. It is currently in [staging | already retired]. /retire only applies to canon entries.
```

---

## Step 2: Confirm

Show the user what will happen and confirm:

```
Retire [[Entry Name]]?

This will:
- Move the file to vault/entries/_retired/
- Mark its status as retired in frontmatter
- Update world-state: remove from canon, add to retired

Wikilinks pointing to this entry will continue to resolve.
```

If the entry is party to any line in `## Active Contradictions`, add to the confirmation message:

```
This entry is party to [N] active contradiction(s):
- [contradiction line as it appears in world-state]
- [...]

Retirement will remove these contradictions from the active list — the retired entry is no longer current canon, so the conflict is no longer pressing.
```

Wait for the user's reply. Accept yes/no/cancel. Anything ambiguous: ask again.

---

## Step 3: Move the file

Move `vault/entries/[type]/[Entry Name].md` to `vault/entries/_retired/[Entry Name].md`.

If `vault/entries/_retired/` does not exist, create it.

Use a filesystem move (preserves the file rather than rewriting). Wikilinks of the form `[[Entry Name]]` still resolve correctly because Obsidian searches the vault for a matching filename regardless of directory.

---

## Step 4: Update frontmatter

In the moved file, set:

- `status: retired` (was `canon`).
- `updated:` today's date in `YYYY-MM-DD` format.
- `created:` unchanged.

---

## Step 5: Update world-state

Rewrite `vault/world-state.md` in full with these changes:

**`## Canon Entries`:** remove the line for the retired entry from its type subsection.

**`## Retired`:** add a line for the retired entry. Format from the format reference:

```
- [[Entry Name]] — retired YYYY-MM-DD
```

**`## Active Contradictions`:** remove any line that mentions the retired entry. Retirement resolves these contradictions — the entry is no longer current canon, so disagreements with it are no longer active.

**`## Referenced but Uncanonized`:** no change. The retired entry's wikilinks still exist; they just point to a file in `_retired/` now. Uncanonized names referenced by the retired entry are still referenced by it.

**`Last reindex:`:** no change. This line tracks `/reindex`, not `/retire`.

Save world-state.

---

## Step 6: Tell the user

Short confirmation:

```
[[Entry Name]] retired.

File: vault/entries/_retired/Entry Name.md
Active contradictions resolved by retirement: [N]
```

If no contradictions were involved, omit the second line.

---

## What you do not do

- Do not delete the entry file. Retirement preserves; only manual deletion plus `/reindex` removes an entry entirely.
- Do not modify the prose of the retired entry.
- Do not modify other entries that reference the retired entry. Their wikilinks still resolve.
- Do not retire entries from staging or `_retired/`. Only canon entries can be retired.
- Do not skip the contradiction reconciliation step. Retirement resolves any active contradictions the retired entry was party to.
