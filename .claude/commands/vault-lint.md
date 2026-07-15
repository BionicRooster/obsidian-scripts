Run a quality audit of the Synthesis layer and EWT wiki: flag thin pages, topic gaps, stale claims, contradictions, and orphaned synthesis pages.

## Parameters

No arguments. Always operates on `C:\Users\awt\Sync\Obsidian\30 - Synthesis\` and the EWT wiki index.

---

## Step 1 — Inventory Synthesis Pages

Read `C:\Users\awt\Sync\Obsidian\30 - Synthesis\index.md` to get the full list of synthesis pages.

For each page listed:
- Read the file and extract `source_count` from frontmatter
- Note the `updated:` date if present
- Note whether the page is linked from any MOC or synthesis index

Also read: `C:\Users\awt\Sync\Obsidian\02 - Working Projects\Elias White Talbot - Project\wiki-index.md`

---

## Step 2 — Run the Five Checks

### Check 1: Contradictions
Scan for synthesis pages that assert incompatible claims about the same entity or event. Look for:
- Date conflicts (two pages assert different dates for the same event)
- Factual opposites ("X caused Y" vs. "X did not cause Y")
- Attribution conflicts (same quote or action credited to different people)

Flag each contradiction with both page names and the conflicting claims.

### Check 2: Thin Pages
Flag any synthesis page with `source_count` ≤ 2 as a candidate for enrichment. These pages exist but are not yet well-supported.

List them with their current `source_count` and a note about what additional sources might strengthen them.

### Check 3: Topic Gaps
Grep the vault notes in `C:\Users\awt\Sync\Obsidian\01\` for recurring topics that appear in 5 or more notes but have no corresponding synthesis page. Common gap patterns to check:
- A concept or term that appears frequently across multiple MOC areas
- A named individual with 5+ vault references but no synthesis bio
- A recurring theme in Bahá'í, soccer, health, or PKM notes that is never synthesized

List gap topics with an estimated note count and recommended synthesis page title.

### Check 4: Stale Claims (EWT focus)
For EWT wiki pages (`02 - Working Projects\Elias White Talbot - Project\`): check whether any claim marked `not confirmed`, `Unknown`, or `unverified` has been superseded by a more recent vault note or box score. Cross-reference against:
- Dates on vault notes newer than the EWT page's `updated:` field
- Any `[RESOLVE]` entries in the Claude Action Log referencing EWT

Flag pages where newer evidence may contradict or update an existing claim.

### Check 5: Orphaned Synthesis Pages
For each synthesis page found in Step 1, check:
- Is it linked from `30 - Synthesis\index.md`? (it should be, by definition)
- Is it linked from at least one MOC or one content note?

Pages with zero inbound links from MOCs or content notes are orphans — they exist but are unreachable from the vault graph.

---

## Step 3 — Query-to-File Rule

While running the lint, if you answered any substantive vault questions during this session that produced a multi-paragraph answer synthesizing 3+ sources — and no synthesis page exists for that topic — flag it here as a `[QUERY→FILE]` candidate.

A good candidate: the answer would still be useful 6 months from now and is not derivable from a single note.

List each candidate with: topic name · recommended synthesis page title · key claims to include.

---

## Step 4 — Report

Output a four-section report:

**Section 1: Contradictions** — list each pair with the conflicting text
**Section 2: Thin Pages** — list with source_count and enrichment suggestions
**Section 3: Topic Gaps** — list with note count and recommended page title
**Section 4: Stale Claims / Orphans** — list files and specific claims to re-examine

End with a one-line summary:
`Lint complete: N contradictions · N thin pages · N topic gaps · N stale/orphaned pages`

---

## Step 5 — Log

Append to `C:\Users\awt\Sync\Obsidian\01\PKM\Claude Action Log.md` with `[LINT]` prefix:

```
[LINT] YYYY-MM-DD — N thin pages · N topic gaps · N contradictions · N orphans
```

---

## Step 6 — Offer to Create Gap Pages

After the report, offer: "Create synthesis stubs for the top-priority topic gaps?" If yes, create a stub page in `30 - Synthesis\` for each accepted topic with:
- Frontmatter: `source_count: 0`, `created: YYYY-MM-DD`, `updated: YYYY-MM-DD`
- A `## Summary` heading with a one-sentence placeholder
- A `## Sources` heading

Then add each new page to `30 - Synthesis\index.md`.
