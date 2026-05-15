# /process

The main authoring command. Take what's in the inbox and turn it into staged entries.

## What this command does

1. Load context (world-config, world-state, relevant existing entries).
2. Read inbox files.
3. Plan: identify what entities each inbox file affects.
4. Write entries to `vault/staging/`, marking invention and flagging contradictions.
5. Update `vault/world-state.md` to reflect staging.
6. Archive processed inbox files.

Two invocation modes:
- `/process` — handle every file in `vault/inbox/` (except `_processed/` and `_notes-archive.md`).
- `/process [filename]` — handle only the named file in `vault/inbox/`.

---

## Step 1: Load context

Read in order:

1. `world-config/identity.md` — tone, themes, narrator voice, what kinds of gaps matter, mystery-vs-explanation stance.
2. `world-config/conventions.md` — naming, dates, titles, cross-reference style, POV/tense, in-world terms, forbidden devices.
3. `vault/world-state.md` — the index of everything that exists.

Do not load entry files yet. You will load only the entries the planning step identifies as relevant.

---

## Step 2: Read inbox

List files in `vault/inbox/`. Skip:
- `_processed/` directory contents (already archived).
- `_notes-archive.md` if present (meta-notes archive).
- Any file beginning with `_` or `.` (reserved/hidden).

For each remaining file, read its full content.

Inbox files can be any format: paragraphs, scattered sentences, bullet lists, dialogue, half-finished thoughts. Do not reject malformed input. The user dumps fragments; you make sense of them.

---

## Step 3: Plan and load

Decompose each inbox file into a plan and load the canon entries you need to classify each operation correctly. Planning and loading interleave — you cannot reliably classify an operation as `update` vs `contradiction` vs `duplicate` without having read the existing canon entry.

For each inbox file, identify:

- **What entities does this fragment touch?** A single fragment often touches multiple entities — an NPC, the faction they belong to, the location of an event, the event itself. List them all.
- **What entities does this fragment reference but not focus on?** Names mentioned in passing. These need wikilinks in the eventual prose; some may also need to be loaded for transitive contradiction checking (see below).

For each touched entity, check `vault/world-state.md`:

- If it's in `## Canon Entries`, load its file from `vault/entries/[type]/`.
- If it's in `## Staging`, load its file from `vault/staging/[type]/`. Treat the staged version as current state for the rest of this run.
- If it's in neither, it's a new entity.

With the canon entries loaded, classify each operation:

- `new` — entity doesn't exist in canon or in staging.
- `update` — entity exists; this fragment adds detail compatible with what's there.
- `contradiction` — entity exists; this fragment conflicts with what's recorded.
- `duplicate` — entity exists; this fragment adds nothing new.
- `meta-note` — the fragment isn't world content (see Meta-notes below).

Coalesce across files. If two inbox files both touch `[[Greybridge]]`, produce one staged entry for Greybridge drawing from both.

**Transitive contradiction check.** For each operation that's not just a new entity in isolation, also load any canon entry that the fragment *references* (even if it's not being modified). Read those entries enough to confirm the new content doesn't contradict them. Example: if the fragment is about Aelthorn but says he rode to Greybridge, load Greybridge to confirm nothing in its entry conflicts with that visit. Do not chase references transitively beyond one hop — if Greybridge mentions another entity, you don't need to load that entity unless the current fragment also mentions it.

Present the plan in your chat response before producing entries. Format:

```
Processing N inbox files. Plan:

- [[Entity A]] (type: npcs) — new, from frag_01.md
- [[Entity B]] (type: locations) — update, from frag_01.md and frag_03.md
- [[Entity C]] (type: factions) — contradiction, from frag_02.md
- frag_04.md — meta-note, archiving to _notes-archive.md
- [[Entity D]] (type: history) — duplicate of existing canon, no entry produced
```

Then proceed.

---

## Step 4: Write entries

For each entity in the plan that needs an entry (new, update, or contradiction):

### Load the template

Read `engine/templates/entries/[type].md`. The template's section headings define the entry's structure. Follow them. The HTML comments under each heading are guidance for you — do not preserve them in the staged file.

If during writing you realize you need to load an additional canon entry that wasn't loaded during planning, you may do so. This should be rare — planning is meant to cover loading needs — but the prompt does not forbid it.

### Write prose

Write the entry in the world's voice as defined by `world-config/identity.md` and `world-config/conventions.md`. The narrator voice from identity.md is who is writing this entry. The tone, mystery stance, and forbidden devices from those files apply throughout.

For each section, write actual prose. Not bullets. Not stubs. Not "TBD." If you have nothing to write in a section, leave the heading and write one short paragraph acknowledging what's not known — or omit the section entirely if the world hasn't given you anything to put there.

### Invention rules

The user gave you a seed. Invent the supporting detail that makes the seed into a real entry.

**Implied invention — not marked.** Anything straightforwardly implied by the source or by canon. Subordinates of a named leader. Plausible waypoints on a described journey. Customs consistent with a described culture. Write as natural prose.

**Beyond-implied invention — marked.** Anything a reasonable user would read and say "I didn't say that." Named characters not implied by the source. Specific dates not given. Attributed motives. Backstory beats. Mark these:

- `==highlighted text==` for sentence-level invention.
- `> [inference]` blockquote, on its own line immediately before the passage, for paragraph-scale invention.

When in doubt, mark. Over-marking is recoverable during approval. Under-marking turns invention into canon.

### Cross-references

Every first mention of another entity in this entry must be a wikilink: `[[Entity Name]]`. Subsequent mentions follow the cross-reference style from `conventions.md`.

Wikilinks to entities without entries are required — they get logged to `## Referenced but Uncanonized` in world-state. Do not skip the wikilink just because the entity doesn't have a file.

### Frontmatter

Fill in:
- `type`: the entity type, lowercase.
- `tags`: relevant tags. Leave empty if none apply.
- `status`: `staging`.
- `aliases`: any alternate names this entity is referred to by. Leave empty if none.
- `created`: today's date in `YYYY-MM-DD` format. For updates, preserve the original.
- `updated`: today's date in `YYYY-MM-DD` format.

### The `## Gaps` section

Every entry ends with `## Gaps`. Use bullets here — this is one of the exceptions to the prose-only rule. List what is genuinely undefined for this specific entity. Honest incompleteness, not a task list.

Examples of good gap entries:
- Origin of the family name unknown
- Relationship with the Tithe Council unspecified
- No named successor identified

Examples of bad gap entries (too generic to be useful):
- More backstory needed
- Could use more detail

---

## Step 5: Handle special cases

### Contradictions

When a fragment contradicts existing canon:

1. Write the new content faithfully. Do not hedge to make it fit.
2. Mark the conflicting passage with `> [CONTRADICTION]` on its own line immediately before the passage. Briefly state what it contradicts.
3. Log to `## Active Contradictions` in `vault/world-state.md` per the format in `world-state-format.md`: `- [[Entry A]] and [[Entry B]]: brief description. Flagged YYYY-MM-DD.`
4. Do not modify the existing canon entry. The user resolves contradictions during approval or by direct edit.

Important: an update and a contradiction are not the same thing. If a fragment seems to *correct* existing canon ("actually the Compact was signed in 421"), treat it as a contradiction, not as an update. You cannot reliably tell whether the user is correcting a forgotten earlier note or asserting incompatible canon. Flag it; let the user resolve.

### Ambiguous references

When a fragment refers to an entity ambiguously — "the king" when two kings exist in canon, "Vance" when there's both Brother Vance and Captain Vance — do not guess. Stage the entry with a `> [QUESTION]` block immediately before the ambiguous passage naming the ambiguity:

```
> [QUESTION] "The king" — could refer to [[King Aldric]] or [[King Borren]]. Please clarify.
```

### Uncanonized references

When a fragment mentions an entity that has no entry and isn't worth creating one for right now — a passing mention, a family name, a minor reference — wikilink it and let the link dangle. Add the name to `## Referenced but Uncanonized` in world-state if it isn't already there. Do not create a stub entry. Stub entries pollute the vault and create false signals of completeness.

### Meta-notes

If an inbox file is clearly a note-to-self rather than world content, log it and don't stage anything.

Signals that something is a meta-note:
- Talks about the world from outside it ("I need to figure out how the faerie compact works")
- Addresses the writer directly ("remember to add detail about Greybridge")
- Lists todos or questions for the writer ("what's the Compact's third article?")
- Discusses the writing process rather than the content

Action: append the file's content to `vault/inbox/_notes-archive.md` with a datetime header, then archive the original to `_processed/` per the normal flow. Do not stage anything.

If uncertain whether something is a meta-note or genuine fragmentary content, treat it as content. Better to stage something the user rejects than to bury a real fragment.

### Duplicates

If an inbox file's content is already covered by existing canon, do not stage a no-op. Archive the inbox file and note the duplicate in the plan output. Example chat note: `frag_04.md duplicates existing canon at [[The Greybridge Compact]]. Archiving without staging.`

### Short fragments

A three-paragraph location entry is fine if that's what the source supports. Do not pad to length. Some entities are genuinely small — a tavern, a passing figure, a minor settlement. Write what fits, mark what you invented, stop.

### Multiple entity types in one fragment

A typical ramble touches multiple entity types. Produce one staged entry per affected entity, cross-linked with wikilinks. Do not bloat a single entry by stuffing in detail that belongs in a sibling entry.

---

## Step 6: Stage the files

Write each entry to `vault/staging/[type]/[Entity Name].md`. Create subdirectories as needed.

Filenames match entity names exactly. Spaces preserved. `Lord Aelthorn.md`, not `lord-aelthorn.md`.

If the entity already exists in staging from a prior `/process` run, overwrite the staged file. The user is expected to run `/approve` between process runs; if they haven't, the newer process replaces the staged version.

If the entity is canon and you're staging an update, write the full updated entry to `vault/staging/[type]/[Entity Name].md`. The canon file is untouched. `/approve` will handle the diff and promotion.

---

## Step 7: Update world-state

Rewrite `vault/world-state.md` in full. Do not patch lines.

Updates required:
- `## Staging`: add an entry per staged file with `(type: new | update | contradiction)` and a short note on what changed.
- `## Referenced but Uncanonized`: add any new dangling references created during this process. Remove names that now have staged entries (they will be in `## Staging` instead).
- `## Active Contradictions`: add any new contradictions flagged this run.
- `Last reindex:` — do not update. This line tracks `/reindex` runs, not `/process` runs.

Do not add to `## Canon Entries` — entries only become canon during `/approve`.

---

## Step 8: Archive inbox

For each processed inbox file (including meta-notes and duplicates, but not files you couldn't categorize):

Move from `vault/inbox/[filename].md` to `vault/inbox/_processed/YYYY-MM-DD-HHmm-[filename].md` using the current datetime.

If for some reason a file couldn't be processed at all (unreadable, somehow empty after content check, etc.), leave it in `vault/inbox/` and note it in the chat response. Do not archive files you didn't actually handle.

---

## Step 9: Final chat response

After the work is done, summarize:

```
Processed N inbox files.

Staged:
- [[Entity A]] (new) — vault/staging/npcs/Entity A.md
- [[Entity B]] (update) — vault/staging/locations/Entity B.md
- [[Entity C]] (contradiction, conflict with [[Entity D]]) — vault/staging/factions/Entity C.md

Archived without staging:
- frag_04.md (duplicate)
- frag_05.md (meta-note)

New contradictions: 1
New uncanonized references: 3

Run /approve to review staged entries.
```

Keep it factual. The user will see the entries during `/approve`; they don't need previews here.

---

## What you do not do

- Do not write to `vault/entries/` directly. Ever.
- Do not modify existing canon entries. Updates go to staging.
- Do not invent content that contradicts canon. Flag instead.
- Do not resolve contradictions on your own.
- Do not create stub entries for uncanonized references.
- Do not skip wikilinks because the target doesn't have an entry yet.
- Do not pad entries beyond what the source supports.
- Do not silently merge ambiguous references — ask via `> [QUESTION]`.
- Do not preserve the HTML guidance comments from templates in staged files.
