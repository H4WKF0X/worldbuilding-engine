# /reindex

Rebuild `vault/world-state.md` from filesystem reality. The safety net for when world-state and the actual files have diverged.

Two modes:

- **Cheap mode (default).** Uses file modification times against the `Last reindex:` timestamp in world-state. Only re-reads files newer than that timestamp. Cheap; suitable for routine use.
- **Full mode (`/reindex --full`).** Re-reads every file regardless of mtimes. Authoritative; use when world-state seems corrupted, after many manual edits, or on first run.

## What this command does

1. Determine mode.
2. Confirm with user (full mode only).
3. Scan filesystem.
4. Load relevant content into context.
5. Reconcile world-state.
6. Write the updated file.
7. Report what changed.

This command never modifies entries. It only modifies `vault/world-state.md`.

---

## Step 1: Determine mode

If the user passed `--full`, use full mode. Otherwise cheap mode.

In cheap mode, read the `Last reindex:` timestamp from `vault/world-state.md`. This is the cutoff for which files count as "changed." Files with mtime newer than `Last reindex:` are changed; older ones are assumed unchanged.

If `Last reindex:` is "never" (first run on this world), fall back to full mode and tell the user:

> No prior reindex on record. Running full reindex instead.

In full mode, the cutoff is ignored — every file is re-read.

Note: do not use world-state.md's filesystem mtime as the cutoff. Other commands rewrite world-state regularly, which would bump that mtime past manual edits made before the rewrite. Only `Last reindex:` accurately tracks when the index was last reconciled with filesystem reality.

---

## Step 2: Confirm (full mode only)

For full mode, tell the user what's about to happen:

```
Full reindex will re-read every file under:
- vault/entries/[type]/ ([N] files)
- vault/staging/[type]/ ([N] files)
- retired/[type]/ ([N] files)

This is expensive. Cheap mode (the default) only re-reads files newer than world-state's last update.

Proceed?
```

Wait for confirmation. Cheap mode does not confirm — it's expected to be cheap and routine.

---

## Step 3: Scan filesystem

List every file under:

- `vault/entries/[type]/` for each known type subfolder
- `vault/staging/[type]/` for each known type subfolder
- `retired/[type]/` for each known type subfolder (note: `retired/` is at the project root, outside `vault/`)

Build a set of all files that should be reflected in world-state.

Compare against `vault/world-state.md`'s current contents:

- Files in the filesystem but not in world-state: **new**.
- Files in world-state but not in the filesystem: **missing**.
- Files in both: in cheap mode, compare the file's mtime against the `Last reindex:` cutoff from step 1 — newer means **changed**, older means **unchanged**. In full mode, treat as **changed** regardless.

Also note any files in unexpected locations:

- Files directly under `vault/entries/` (not in a type subfolder).
- Files directly under `vault/`.
- Files in `vault/entries/_retired/` (this folder shouldn't exist anymore — retirement now uses `retired/` outside the vault).
- Files with malformed or missing frontmatter.

These get reported as warnings at the end. Reindex does not move or modify them.

---

## Step 4: Load content into context

For every file classified as **new** or **changed**, read its full content. You need the content for:

- Generating descriptors (new files).
- Re-checking for contradictions (changed files).
- Updating wikilink tracking (both).

In cheap mode, skip unchanged files. Their descriptors and reference tracking in world-state are assumed valid — preserve them in the rewritten world-state.

In full mode, read every file. Existing descriptors in world-state are not assumed valid; regenerate them.

---

## Step 5: Reconcile world-state

Rewrite `vault/world-state.md` section by section, drawing from loaded content and from the existing world-state for unchanged data.

### `## Canon Entries`

For each `.md` file under `vault/entries/[type]/`:

- If in cheap mode and the file is unchanged: keep the existing line from world-state. Same descriptor, same date.
- If new or changed: derive a one-line descriptor from the entry's content (overview section, role, what the entity is). Set the date from the file's frontmatter `updated:` field.

Format per format reference:

```
- [[Entity Name]] — [short descriptor] (updated YYYY-MM-DD)
```

Remove lines for files that no longer exist in `vault/entries/[type]/`.

### `## Retired`

For each file under `retired/[type]/`:

- Add a line with the file's `updated:` date from frontmatter (this is the retirement date).

Format:

```
- [[Entity Name]] — retired YYYY-MM-DD
```

Remove lines for files no longer in `retired/`.

### `## Staging`

For each file under `vault/staging/[type]/`:

- Determine the operation type by scanning for markers and checking if a canon counterpart exists:
  - `new` — no canon file with this name.
  - `update` — canon file exists, no `> [CONTRADICTION]` markers in the staged file.
  - `contradiction` — canon file exists and the staged file has at least one `> [CONTRADICTION]` marker.
- Derive a short note on what the staged change is (one line, drawn from the file's content).

Format:

```
- [[Entity Name]] (type: new | update | contradiction) — [short note]
```

Remove lines for files no longer in staging.

### `## Referenced but Uncanonized`

In cheap mode: take the existing section as a starting point. For each new or changed file, recompute its wikinks and update the relevant lines:

- Wikilinks to entities that have canon entries (anywhere in canon): no entry in this section needed.
- Wikilinks to entities without canon entries: ensure the line for that name lists the current entry in the "referenced in" list.

For each missing file (file deleted or moved out): remove it from any "referenced in" lists. If a line's list becomes empty, remove the line.

In full mode: ignore the existing section. Scan every canon entry's wikilinks and rebuild from scratch.

Format per format reference:

```
- "Name" — referenced in [[A]], [[B]]
```

Note: wikilinks *from* retired entries do not count. Retired entries are out of canon; their references are not canonical references.

### `## Active Contradictions`

Start with the existing section. Then:

**Removal pass.** For each line, check whether both named entries still exist as canon. If either has been retired, deleted, or doesn't exist: remove the line.

**Update pass (cheap mode).** For each changed file, re-check any contradictions it's party to. If the changed content no longer disagrees with the other party, remove the line. If the disagreement shifted, update the description.

**Detection pass (cheap mode).** For each changed file, check its content against the canon entries it references for new contradictions. Add new lines for any new disagreements.

**Detection pass (full mode).** With all canon entries in context, check for canon-vs-canon contradictions across the loaded content. Add lines for any not already in the section.

Note: full mode's detection is opportunistic, not exhaustive. You're looking for contradictions where the content makes them visible — clearly stated facts that disagree. You are not expected to derive contradictions from subtle implications across many entries.

### `Last reindex:`

Set to the current datetime in `YYYY-MM-DD HH:mm` format.

---

## Step 6: Write world-state

Write the fully reconstructed `vault/world-state.md`. Single write, all changes applied.

---

## Step 7: Report to user

Tell the user what reindex did:

```
Reindex complete (cheap | full mode).

Examined: [N] files
  - New: [X]
  - Changed: [Y]
  - Removed: [Z]

Reconciled:
  - Canon entries: [count change, e.g. +3, -1, no change]
  - Staging: [count change]
  - Retired: [count change]
  - Uncanonized references: [count change]
  - Active contradictions: [+X new, -Y resolved]

Warnings:
  - [Any unexpected files or malformed frontmatter, listed]
```

If there are no warnings, omit that section.

If nothing changed at all (clean state, no drift), say so plainly:

```
Reindex complete. No changes — world-state was already in sync with filesystem.
```

---

## What you do not do

- Do not modify any entry files. Reindex only writes world-state.
- Do not move files. Files in unexpected locations are reported as warnings, not corrected.
- Do not auto-fix malformed frontmatter. Report and leave alone.
- Do not delete files. Missing files are removed from world-state but their absence on disk is not the engine's concern.
- Do not retry expensive operations across mode boundaries. Cheap mode trusts mtimes; if you don't trust them, the user should run `/reindex --full`.
- Do not update the `Last reindex:` field anywhere else. This is the only command that touches it.
- Do not use world-state.md's filesystem mtime as a cutoff. Other commands write world-state regularly; only `Last reindex:` tracks the actual reindex moment.
