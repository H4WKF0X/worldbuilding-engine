# /retire [entry]

Soft-delete a canon entry. The entry's file is moved outside the vault to `retired/`, removing it from the world. The file is preserved so the user can read or recover it, but Obsidian no longer indexes it and wikilinks to it no longer resolve.

Use this when an entity is no longer part of the world at all — the user has decided it doesn't belong, was a draft they're discarding, or has been replaced by something else. For timeline events (an NPC dies, a faction dissolves), do not use retirement — update the entry through `/process` instead.

## What this command does

1. Resolve the entry argument.
2. Confirm with the user.
3. Move the file to `retired/`.
4. Update frontmatter.
5. Update world-state.
6. Tell the user to run `/reindex` for full consistency.

---

## Step 1: Resolve the entry argument

The user passes an entry name as argument. Accept it in any form: with or without `[[]]`, case-insensitive.

Search `vault/entries/[type]/` for a file whose name matches. Only canon entries can be retired.

If exactly one match: proceed.

If multiple matches across types: ask the user which one.

If no match in canon: tell the user and stop. Example messages:

```
No canon entry named "[name]" found.
```

If the entry is in staging or has already been retired:

```
"[name]" is not in canon. It is currently in [staging | already retired]. /retire only applies to canon entries.
```

---

## Step 2: Confirm

Show the user what will happen:

```
Retire [[Entry Name]]?

This will remove it from the world:
- The file moves to retired/[type]/Entry Name.md (outside the vault)
- Obsidian will no longer see it
- Wikilinks from other entries to [[Entry Name]] will no longer resolve — they become uncanonized references
```

If the entry is party to any line in `## Active Contradictions`, add:

```
This entry is party to [N] active contradiction(s):
- [contradiction line]

Retirement will resolve these — once the entry is no longer canon, canon can no longer disagree with it.
```

If the entry's prose contains wikilinks to other entities, note that briefly:

```
Wikilinks from this entry to other entities will be removed from world-state's reference tracking.
```

Wait for the user's reply. Accept yes/no/cancel.

---

## Step 3: Move the file

Move `vault/entries/[type]/[Entry Name].md` to `retired/[type]/[Entry Name].md`.

If `retired/` or `retired/[type]/` does not exist, create them.

The file is now outside the Obsidian vault. Wikilinks to this entry from canon entries no longer resolve.

---

## Step 4: Update frontmatter

In the moved file, set:

- `status: retired` (was `canon`).
- `updated:` today's date in `YYYY-MM-DD` format.
- `created:` unchanged.

---

## Step 5: Update world-state

Rewrite `vault/world-state.md` with these changes:

**`## Canon Entries`:** remove the line for the retired entry from its type subsection.

**`## Retired`:** add a line for the retired entry. Format:

```
- [[Entry Name]] — retired YYYY-MM-DD
```

Note: the wikilink in this line will not resolve in Obsidian. That is intentional — it preserves the entity's name in the index without making it canon-adjacent.

**`## Active Contradictions`:** remove any line that mentions the retired entry. The contradictions involved this entry; the entry is no longer canon; the contradictions are resolved.

**`## Referenced but Uncanonized`:** update based on wikilinks *from* the retired entry. Read the retired file's prose and identify the wikilinks it contained. For each:

- If the wikilink pointed to an uncanonized name (a name in `## Referenced but Uncanonized`), remove the retired entry from that name's "referenced in" list. If the retired entry was the only entry referencing the name, remove the line entirely.

Wikilinks *to* the retired entry from other canon entries are not handled here. Those are now uncanonized references but require scanning all canon entries to find. `/reindex` handles that. See step 6.

**`Last reindex:`:** no change.

Save world-state.

---

## Step 6: Tell the user

```
[[Entry Name]] retired.

File: retired/[type]/Entry Name.md
Active contradictions resolved: [N]

World-state's `## Referenced but Uncanonized` may not yet reflect wikilinks from other canon entries that pointed to [[Entry Name]]. Run /reindex to update.
```

If no contradictions were involved, omit that line.

If the entry had no wikilinks to other entities and no other canon entries referenced it, also omit the reindex suggestion — there's nothing for reindex to find.

---

## What you do not do

- Do not delete the retired file. Retirement preserves; manual deletion is a separate user action.
- Do not modify the prose of the retired entry.
- Do not retire entries from staging or already-retired. Only canon entries can be retired.
- Do not skip the active-contradictions cleanup. Retired entries are no longer canon, so their contradictions are no longer live.
- Do not attempt to find backlinks to the retired entry. That's `/reindex`'s job.
- Do not retire an entry for a timeline event (death, dissolution, destruction). Those are updates, not retirements.
