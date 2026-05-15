# /approve

Review what's in staging and promote approved entries to canon.

## What this command does

1. Load context.
2. Classify staged files into bulk-approvable and walk-through.
3. Present the classification and ask the user how to proceed.
4. Bulk-approve simple cases if chosen.
5. Walk through complex cases one file at a time.
6. After walk-through, promote everything that's ready: strip markers, move files to canon, reconcile world-state.

The user can stop at any point. Disk state is always the source of truth. A `/clear` mid-flow is fine — the next `/approve` run picks up from filesystem reality.

---

## Step 1: Load context

Read in order:

1. `world-config/identity.md` — needed if any walk-through requires rewriting prose in the world's voice.
2. `world-config/conventions.md` — same.
3. `vault/world-state.md` — for the current canon index and active contradictions.

Then read every file under `vault/staging/[type]/`. If staging is empty, tell the user and stop.

---

## Step 2: Classify

For each staged file, scan for markers:

- **Bulk-approvable**: no `> [QUESTION]` markers, no `> [CONTRADICTION]` markers. May have `==highlight==` or `> [inference]` markers. These have no unresolved decisions for the user.
- **Walk-through**: has at least one `> [QUESTION]` or `> [CONTRADICTION]` marker.

Note: a file with no markers at all is also bulk-approvable. This can happen for entries with no invention, or for files where a prior `/approve` session resolved all blocking markers but the session ended before promotion.

Count each group. Note any `> [QUESTION]` markers (must be resolved) versus `> [CONTRADICTION]` markers (user has more decisions).

---

## Step 3: Present and ask

Show the classification:

```
[N] items in staging:
- [X] auto-approvable (no questions or contradictions)
- [Y] require walk-through ([Q] with questions, [C] with contradictions)

How would you like to proceed?
1. Bulk-approve the [X], walk through the [Y]
2. Walk through all [N]
3. Walk through just the [Y] (leave the [X] in staging for now)
4. Cancel
```

If [Y] is 0, simplify the options (bulk-approve all, walk through all, cancel). If [X] is 0, skip the bulk option.

Wait for the user's reply. Accept varied phrasings ("option 1", "first one", "yes do that", "walk through everything"). If the reply is ambiguous, ask for clarification rather than guessing.

If the user picks cancel, stop. No changes to anything.

---

## Step 4: Bulk approval pass

If the user chose to bulk-approve, do this before any walk-through.

### Show the list first

Before modifying any files, show one line per bulk-approvable file:

```
Bulk-approving [X] entries:
- [[Entity Name]] (new, [type]) — [short descriptor], [N] inferences
- [[Other Entity]] (update, [type]) — [short descriptor], [N] inferences
[...]

Proceed? (yes / show me [name] first / skip [name] / cancel)
```

The descriptor is the same short summary that's in `## Staging` in world-state. The inference count is the total of `==highlight==` plus `> [inference]` markers in the file.

If the user says "show me X first," display the full content of that file and offer the same proceed options again. If "skip X," remove that file from the bulk list and treat it as deferred for this session (stays in staging, not modified). If "cancel," stop entirely with no changes.

### Apply the bulk approval

Bulk approval is a logical step, not a state-changing one. No file is modified. World-state is not updated. The user has confirmed which files are ready; the actual work happens at promotion (step 6).

Remember which files were bulk-approved in your working context for this session.

---

## Step 5: Walk-through

For each file requiring walk-through, in this order:

1. Files with `> [QUESTION]` markers first.
2. Files with `> [CONTRADICTION]` markers next.
3. Files with both — treat as in group 1 (questions first).

Within those groups, walk through them in alphabetical order by filename for predictability.

### Per-file flow

Re-read the file from disk before each turn. The user may have edited it in Obsidian between turns.

Show the file's full content with markers visible. For long files (more than ~80 lines of prose), you may compress sections that don't contain markers — replace them with a one-line summary in brackets — but always show in full:
- The frontmatter
- Any section containing a `> [QUESTION]` or `> [CONTRADICTION]` marker
- The `## Gaps` section

After showing the file, summarize what needs resolution:

```
[[Entity Name]] — [type]

Open items:
- 1 question: [restate it briefly]
- 1 contradiction (self-update): [restate it briefly]
- 2 contradictions (cross-entry, with [[Other Entry]] and [[Third Entry]]): [restate]

What would you like to do?
- approve as-is (resolve nothing — only works if no questions remain; contradictions stay as-is and become canon-vs-canon at promotion)
- edit (give me direction on what to change)
- reject (delete this staged file)
- defer (leave it in staging, come back later)
```

If the file has any `> [QUESTION]` markers, "approve as-is" is not an option — questions must be resolved. State this and offer only edit/reject/defer.

If the file has `> [CONTRADICTION]` markers and the user picks "approve as-is," confirm: "Accepting this means [N] canon-vs-canon contradictions will exist after promotion. Continue?" If they say yes, proceed. If they want to think more, treat as defer.

### Handling each path

**Approve as-is.** Permitted only when there are no remaining `> [QUESTION]` markers. The file stays in staging as-is, including any `> [CONTRADICTION]` markers (these will be stripped at promotion; the canon-vs-canon contradictions they imply will be added to `## Active Contradictions` then). Mark the file as approved in your working memory for this session. Move on.

**Edit.** The user gives direction in natural language: "change the date to 421 but keep the rest," or "rewrite the second paragraph to make the relationship with the Tithe Council more ambiguous," or "this is Brother Vance, not Captain Vance — fix the references." Anything they say.

You rewrite the file accordingly. The rewrite is in the world's voice from `world-config/`. You apply the user's direction faithfully without scope creep. After rewriting:

- If the rewrite resolved a `> [QUESTION]`, remove that marker.
- If the rewrite resolved a `> [CONTRADICTION]` by aligning the passage with canon, remove that marker.
- If a `> [CONTRADICTION]` marker remains relevant after the edit, keep it.
- Invention markers (`==`, `> [inference]`) — keep, remove, or add as appropriate to what you wrote.

Write the rewritten file to its staging path. Then show the rewritten version (compressed as above) and ask again: "Updated. Approve, edit further, reject, or defer?" Loop until the user is done.

If the user pastes prose directly and seems to want it incorporated verbatim, treat it as the new content for that passage. Don't reject it. Confirm with them: "I'll use this text as-is for that passage. Any other changes?"

**Reject.** Confirm with cascade-aware warning. Before deleting, check if any other staged files reference this entry. If yes:

> Rejecting [[Entity]] will leave references in [[Other Entry A]], [[Other Entry B]] uncanonized. Continue with rejection, reject those entries too, or cancel?

Three paths from there:
- Continue: delete the staged file. The references in other staged entries remain; at promotion of those, the references become uncanonized.
- Cascade reject: also reject the named referencing entries. Delete all of them.
- Cancel: leave the file as-is, return to the file's main prompt.

If no other staged files reference this entry, just confirm once: "Reject [[Entity]]?" and delete on confirmation.

Update world-state's `## Staging` section: remove the line for the rejected entry. Save world-state. `## Active Contradictions` is not affected — canon hasn't changed.

**Defer.** Leave the file as-is in staging. Do not modify anything. Note in your working memory that this file was deferred. Move on.

### After all walk-through files are handled

Show a summary:

```
Walk-through complete.

Resolved and ready for promotion: [N]
Deferred (still in staging): [M]
Rejected and deleted: [K]

Combined with bulk-approved from earlier: [X+N] ready for promotion.

Proceed with promotion now? (yes / show me one more time / cancel and leave staging as-is)
```

If the user cancels promotion, no files are moved and no markers are stripped. Files stay in staging in whatever state walk-through left them. Next `/approve` run will route each file based on the markers it still carries: files edited to resolve all blocking markers will bulk-approve, files still carrying `> [QUESTION]` or `> [CONTRADICTION]` markers will walk through again.

---

## Step 6: Promotion

This is where files actually move from staging to canon, markers get stripped, and world-state gets its full reconciliation.

For each file ready for promotion (bulk-approved plus walk-through-approved, minus deferred/rejected):

### Contradiction types reference

Two kinds of `> [CONTRADICTION]` markers can appear in a staged file. The same passage can carry both. The difference is what happens to `## Active Contradictions` at promotion.

**Type 2 — self-update contradiction.** A staged update to entry E contradicts the canon version of E. When promoted (accept-as-is), the new version replaces the old. The marker resolves by replacement.

A Type 2 promotion can:
- Resolve canon-vs-canon contradictions that the old version of E was party to, if the new version agrees with the other party.
- Create new canon-vs-canon contradictions if the new version of E now disagrees with other canon entries that the old version agreed with, or stays in disagreement with parties the old version also disagreed with.

**Type 3 — cross-entry contradiction.** A staged entry (new or update) contradicts a different canon entry. Cannot resolve a canon-vs-canon contradiction (it's not replacing a party). At promotion, always creates at least one new canon-vs-canon contradiction. Can create several if it conflicts with multiple canon entries.

A new entry can only carry Type 3 markers (it has no canon predecessor to be Type 2 with). An update entry can carry Type 2, Type 3, both, or neither. A single passage can be marked with both types if it simultaneously contradicts the entry's own canon version and a different canon entry.

### Strip all markers

Remove from the file body:

- `==highlight==` → keep the inner text, remove the `==` delimiters.
- `> [inference]` blockquote lines → remove the marker line entirely. The paragraph that followed it becomes plain prose.
- `> [CONTRADICTION]` blockquote lines → remove the marker line entirely. The passage that followed it becomes plain canon.
- `> [QUESTION]` blockquote lines → should not be present at this point. If any remain, that's a bug — log and skip the file (leave it in staging) rather than promote with an open question.

### Reconcile `## Active Contradictions`

For each `> [CONTRADICTION]` marker that was present in the file before stripping, apply the appropriate type's promotion effects (see the type reference above).

**For Type 2 markers:** the old canon version is being replaced. Find every line in `## Active Contradictions` that mentions this entry. For each:

- If the new canon content agrees with the other party named in that contradiction, remove the line.
- If the new canon content still disagrees with the other party, leave the line (update its description if the nature of the disagreement changed).

Then check whether the new canon content disagrees with any canon entries the old version agreed with. For each new disagreement, add a line:

```
- [[This Entry]] and [[Other Entry]]: [brief description]. Flagged YYYY-MM-DD.
```

**For Type 3 markers:** the marker named the canon entry being contradicted. Add a line to `## Active Contradictions`:

```
- [[This Entry]] and [[Named Entry]]: [brief description, drawn from the marker's text]. Flagged YYYY-MM-DD.
```

Handle each marker independently. A single promotion can both resolve and create canon-vs-canon contradictions.

### Update frontmatter

- `status: canon` (was `staging`).
- `updated:` today's date in `YYYY-MM-DD` format.
- `created:` unchanged (preserved from when `/process` first staged this entry).

### Move the file

From `vault/staging/[type]/[Entity Name].md` to `vault/entries/[type]/[Entity Name].md`. Use the file system move (preserves the file rather than rewriting). After moving, the staging path no longer exists.

### Update `## Canon Entries` in world-state

For each promoted file, add or update a line in the appropriate type subsection. Format from the format reference:

```
- [[Entity Name]] — [short descriptor] (updated YYYY-MM-DD)
```

The descriptor is the same one-line summary used in `## Staging`. If the entry already had a canon line (i.e., this was an update), refresh the descriptor if the entry's nature changed and update the date. If unchanged, just update the date.

### Update `## Referenced but Uncanonized`

After all promotions in this run are complete, recompute the affected lines in this section. Each line follows the format `- "Name" — referenced in [[A]], [[B]]` where the wikilinked entries after the em-dash are the canon entries that reference the uncanonized name.

- If a promoted entry's name appears in `## Referenced but Uncanonized`, remove its line — it's canon now.
- If a promoted entry contains wikilinks to entities not in canon, add or update their lines: add the promoted entry to the comma-separated list of referencing entries, creating a new line if the uncanonized name wasn't there yet.
- If a promoted entry is an update and the new canon version no longer contains a wikilink that the previous canon version had, remove the promoted entry from the referencing list of that uncanonized name. If that leaves no entries referencing the name, remove the line entirely.

Rejected entries require no action here — this section tracks canon references only, and rejected entries never became canon.

### Update `## Staging`

Remove lines for all promoted entries. Lines for deferred entries stay. Lines for rejected entries were removed in step 5.

### Last reindex line

Do not modify the `Last reindex:` line. It tracks `/reindex` runs only.

### Save world-state

Write the updated `vault/world-state.md` in full. Single write, all updates applied.

---

## Step 7: Final summary

Show the user what happened:

```
Promotion complete.

Promoted to canon: [N]
- [[Entity A]] (new) → vault/entries/npcs/Entity A.md
- [[Entity B]] (update) → vault/entries/locations/Entity B.md
[...]

Deferred (still in staging): [M]
Rejected: [K]

Canon-vs-canon contradictions:
- Resolved: [R]
- Newly created: [C]
- Currently active: [total]

Run /status to see the current world state.
```

If no contradictions were involved, omit that block.

---

## What you do not do

- Do not write directly to `vault/entries/` outside of the promotion step.
- Do not promote a file with unresolved `> [QUESTION]` markers.
- Do not silently strip markers without user confirmation (markers in staging are scaffolding for the user; stripping them is part of approval, not a quiet cleanup).
- Do not invent new prose during walk-through unless the user has given direction. Verbatim user prose is acceptable; speculative rewrites without direction are not.
- Do not modify canon entries that aren't being updated by an approved staged file.
- Do not skip the cascade-rejection warning when rejecting an entry that other staged files reference.
- Do not auto-resolve canon-vs-canon contradictions by editing canon files. Resolution happens through the user accepting/rejecting staged updates, retiring entries, or directly editing canon followed by `/reindex`.
- Do not update `Last reindex:` — that's `/reindex`'s field.
