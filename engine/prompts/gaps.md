# /gaps

Produce a prioritized report of narrative gaps in the world. Written for the user to read when they want direction on where to continue building.

This is the most expensive command in the engine. It reads every canon entry. Run it deliberately, not routinely.

## What this command does

1. Load context.
2. Confirm the scan with the user, accept any overrides.
3. Read the full vault.
4. Identify candidate gaps and prioritize them.
5. Write a dated report to `vault/reports/`.
6. Tell the user where the report is.

This command does not modify any vault content. It only reads, and writes one new file to `reports/`.

---

## Step 1: Load context

Read:

1. `world-config/identity.md` — the "what kinds of gaps matter most" field is the primary input for prioritization. Tone and themes also matter.
2. `world-config/conventions.md` — for understanding the world's writing conventions when judging entries.
3. `vault/world-state.md` — for the entry count, the uncanonized references, and active contradictions.

Do not load entry files yet. That happens after confirmation.

---

## Step 2: Confirm with the user

Tell the user what the scan will cover and ask for confirmation. Format:

```
Gap analysis will scan:
- [N] canon entries across [types listed]
- world-config files
- world-state for uncanonized references and active contradictions

Default output: up to 15 prioritized gaps, fewer if fewer warrant attention.
This is the most expensive command — full vault read.

Proceed? You can also override the cap (e.g. "list everything you find").
```

Wait for the user's reply. Accept natural language: "yes," "go ahead," "proceed but list up to 30," "list everything," "cancel," etc.

If cancel, stop. No report written.

If proceed with an override on the cap, remember the override for step 5.

If the world has too few entries for meaningful analysis (say, fewer than 5 canon entries), tell the user upfront:

```
The world currently has [N] canon entries. Gap analysis at this scale is premature — most "gaps" would just be content yet to be written. I can still produce a report, but it will mostly tell you to add more entries first. Proceed anyway?
```

Let them choose.

---

## Step 3: Full vault read

Read every canon entry under `vault/entries/[type]/`. Include the `## Gaps` section of each entry — these are seed data, not authoritative.

Do not read staging or processed inbox files. The scan is about canon coverage, not work in progress.

For each entry, build a mental picture of:
- What this entity is and what role it plays
- What other entities it references via wikilinks
- What the entry's per-entry `## Gaps` section already names as undefined
- What the entry implies but does not deliver (a named successor expected but missing, a faction's purpose unstated, an event's consequences unspecified)

---

## Step 4: Identify and prioritize candidate gaps

A gap is *worth surfacing* when it meets all of these:

1. **It is specific.** It names what is missing about which entity. Not "needs more detail" but "no named leadership for a faction referenced as a political force in 4 entries."

2. **It has evidence.** The gap matters because of how the world is built around it. Cite the entries that make the gap visible — entries that reference the entity, entries that imply something the entry doesn't deliver.

3. **It would affect actual use.** A DM running this world, or a player exploring it, would hit this gap. A reader of the entries would notice. Not "this field is empty" but "this absence would weaken the world."

4. **It matches the world's priorities.** The "what kinds of gaps matter most" field in `identity.md` is the strongest signal. Gaps that match that guidance are higher priority. Gaps that don't match it are lower priority even if otherwise visible.

### Weighting factors

- **Reference count.** An entity referenced by many other entries has more weight than an entity referenced by few. The `## Referenced but Uncanonized` section is a strong signal — every name there has at least one canon entry pointing to it. Names there with multiple referencing entries are prime candidates.
- **Centrality of the missing piece.** Gaps in agency (who acts, why, with what stake) matter more than gaps in description (what something looks like). A faction without named leadership cannot act. An NPC without motivation has nothing to do. A location without inhabitants has no story. These are agency gaps and rank high.
- **Identity.md match.** Gaps the user has explicitly flagged as important to this world (succession questions, power vacuums, religious contradictions, whatever they've named) get prioritized above generic gaps.

### Anti-patterns — do not list these as gaps

- "X needs more detail." (Generic.)
- "X could be expanded." (Generic.)
- "X is underdeveloped." (Generic.)
- "The description in section Y is short." (Length is not a gap.)
- "Field Z is empty." (Empty fields are not automatically gaps; only when the absence affects the world.)
- "This entry has no `## Gaps` section." (Structural — handled by `/refresh-entry`, not the gap report.)

### Examples

**Bad gap item:**

> Greybridge needs more description.

Why bad: generic, no evidence, no stakes. Doesn't name a specific gap or cite why it matters.

**Good gap item:**

> The Tithe Council is referenced as a political force by [[Brother Vance]], [[Lord Aelthorn]], and [[The Tithe Refusals]], but the entry names only Vance and no other council members. With the tithe crisis active (per [[The Tithe Refusals]]), the absence of a council head means scenes of council decision-making can't be written. `identity.md` flags political legitimacy as a central theme; this gap directly affects that.

Why good: specific entity, specific missing piece, cites evidence, ties to identity.md guidance, names a concrete consequence.

**Bad gap item:**

> The Long Mire entry is short.

Why bad: length is not a gap. If the entry is short because there's nothing more the world needs from it, that's fine.

**Good gap item:**

> [[The Long Mire]] is referenced as the contested territory at the heart of [[The Greybridge Compact]] and is described as disputed, but no faction is named as the rival claimant to [[Lord Aelthorn]]'s holding. The dispute drives the Compact's political weight, but no one is named as disputing it. This is the kind of gap `identity.md` calls out — power vacuums and unstated factional motivations.

Why good: identifies a specific unnamed party, cites where this matters, ties to world guidance.

---

## Step 5: Compile the report

Soft cap: 15 prioritized gaps. Aim for 5-10 in most cases. Use fewer if fewer are warranted — a small world might yield 2 findings. Do not pad. If the user overrode the cap at confirmation, respect their override.

Order: highest-priority first. Priority is your judgment based on the weighting factors above. Reference count, centrality of missing piece, identity.md match.

Report format:

```markdown
# Gap Analysis — YYYY-MM-DD HHmm

Scanned: [N] canon entries, [M] uncanonized references, [K] active contradictions.

## Prioritized Gaps

### 1. [Short title naming the gap]

[The gap item, written as in the "good gap item" examples — specific, evidence-cited, with stakes.]

### 2. [Next title]

[...]

[Continue for each prioritized gap.]

## Active Contradictions

[For each line in world-state's `## Active Contradictions`, include it here with any additional context that didn't fit in the world-state line. If world-state's brief description was sufficient, just restate it. Format:]

- [[Entry A]] and [[Entry B]]: [description]. Flagged [date]. [Any additional context worth adding.]

[If there are no active contradictions, omit this section entirely.]

## Notable Uncanonized References

[Only include uncanonized names with multiple referencing entries — those are the high-signal candidates for canonization. Format:]

- "Name" — referenced in [[A]], [[B]], [[C]]. [One-line note on what this entity appears to be from how it's referenced.]

[If no uncanonized names have multiple referencing entries, omit this section entirely.]
```

If the world is too small for meaningful analysis (the case from step 2), produce a short report:

```markdown
# Gap Analysis — YYYY-MM-DD HHmm

The world currently has [N] canon entries. Gap analysis at this scale is not meaningful — most absences are content yet to be written, not narrative gaps.

Add more entries before running `/gaps` again. The command becomes useful once there's enough canon for entries to reference each other and for absences to affect the world's coherence.
```

---

## Step 6: Save the report

Write the report to `vault/reports/YYYY-MM-DD-HHmm-gaps.md` using the current datetime. Do not overwrite existing reports — the filename includes the time precisely to avoid collisions.

Do not modify world-state. Do not modify any entries. The report file is the only output.

---

## Step 7: Tell the user

Short confirmation in chat:

```
Gap analysis complete. Report saved to vault/reports/YYYY-MM-DD-HHmm-gaps.md.

[N] prioritized gaps identified. [K] active contradictions noted. [M] uncanonized references flagged.
```

Keep it brief. The user reads the report file for the content.

---

## What you do not do

- Do not modify any entry files.
- Do not modify world-state.
- Do not produce a report without user confirmation in step 2.
- Do not pad the report to hit a target length. A report of 3 strong findings beats one of 15 weak findings.
- Do not list generic gaps ("needs more detail," "underdeveloped").
- Do not include gaps without evidence (cited entries showing why the gap matters).
- Do not include a "what's well-developed" section.
- Do not auto-include every uncanonized reference — only those with multiple sources.
- Do not read the previous gap report. Each run is fresh.
- Do not read staging files or processed inbox files. Canon only.
