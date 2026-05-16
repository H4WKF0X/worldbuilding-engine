# /status

A quick read-only snapshot of the world.

This command does not modify anything. It does not reconcile world-state against filesystem reality — if the user suspects drift, that's what `/reindex` is for.

## What this command does

1. Read `vault/world-state.md`.
2. List `vault/inbox/` (excluding `_processed/` and `_notes-archive.md`).
3. List `vault/reports/` to find the most recent gap report.
4. Format and display a summary.

No other files are read. The command is intentionally cheap.

---

## Step 1: Read world-state

Read `vault/world-state.md`. Extract:

- Canon entry counts per type, from each subsection under `## Canon Entries`.
- Staging contents — count and the operation type breakdown (new / update / contradiction) from `## Staging`.
- Active contradictions count from `## Active Contradictions`.
- Retired entry count from `## Retired`.
- Uncanonized references count from `## Referenced but Uncanonized`.
- Last reindex timestamp from the `Last reindex:` line.

---

## Step 2: List inbox

List files directly under `vault/inbox/`. Exclude:
- The `_processed/` subdirectory.
- The `_notes-archive.md` file.
- Any file beginning with `_` or `.`.

Count the remaining files. These are unprocessed inbox items.

---

## Step 3: List reports

List files under `vault/reports/`. If any exist, find the most recent by filename (filenames are `YYYY-MM-DD-HHmm-gaps.md`, so lexicographic sort works).

---

## Step 4: Display the summary

Format:

```
World status

Canon entries: [total]
- Locations: [N]
- Factions: [N]
- NPCs: [N]
- History: [N]
- Religion: [N]
- Economy: [N]
- Magic: [N]

Staging: [N] item(s) — [X new, Y update, Z contradiction]
Inbox: [N] unprocessed file(s)

Active contradictions: [N]
Uncanonized references: [N]
Retired entries: [N]

Last reindex: [timestamp from world-state]
Last gap report: [timestamp from filename, or "never"]
```

Omit lines that are zero where it would feel cleaner. For example, if there are no active contradictions, no retired entries, and no uncanonized references, those lines can be folded into a single "No contradictions, retirements, or uncanonized references." line. Use judgment — keep it readable.

If the world is empty (no canon entries, no staging, no inbox), say so plainly:

```
World status

The world is empty. Drop fragments in vault/inbox/ and run /process.
```

---

## What you do not do

- Do not read entry files.
- Do not read staging files.
- Do not reconcile world-state against the filesystem. If something looks off, suggest the user run `/reindex`.
- Do not modify any files.
