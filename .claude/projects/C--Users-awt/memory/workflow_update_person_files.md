---
name: update-person-files-workflow
description: How to scan and expand incomplete people files in 15 - People to the gold standard biography format
metadata: 
  node_type: memory
  type: project
  originSessionId: c8443fac-3c94-467b-b4a8-ac7a29d060bf
---

When the user says "update person files", "expand person files", "complete people stubs", or similar, follow this exact workflow:

## Standard to Match

The gold standard biography format is exemplified by `Helen Cordes.md` and `David Packard.md`. Key elements:
- Rich frontmatter: tags, created, modified, nav property pointing to MOC
- Header breadcrumb: `[[15 - People]] | [[MOC - relevant]]`
- **Biography** paragraph (summary of who the person is)
- **Career History** section with named subsections per role, bullet details
- **Books & Publications** as a markdown table (Title, Year, Publisher, Notes)
- **Community Involvement / Projects** section
- **Personal Life** section (birth, family, death if applicable)
- **Related Notes** organized by themed sub-headings
- For public figures: research from web sources before writing

## File Location
- People folder: `D:\Obsidian\Main\15 - People\`
- Index: `D:\Obsidian\Main\15 - People\15 - People.md`

## Step-by-Step Workflow

**Step 1 — List all files** using Glob on `D:/Obsidian/Main/15 - People/**/*.md`

**Step 2 — Read ALL files** in parallel batches of 10 to assess completeness

**Step 3 — Categorize each file:**
- **Complete** (no action): Helen Cordes, Richard Bandler, John Grinder, Julia Child, Mike Rowe, ReShonda Tate, Mark Pryor, Daniel Norris, David Packard — and all genealogy records and private contact cards
- **Contact cards** (appropriate format, no action): FOL board members, Bahá'í friends, library staff, Georgetown local contacts — these use a different format (Basic Info, Context, Interactions) which is correct for private individuals
- **NLP CompuServe forum participants** (appropriate forum-context format, minor expansion only if new info available)
- **Stubs needing expansion** (public figures with `*(Stub created automatically...)*` or near-empty Biography)
- **False positives** (not actually a person — flag and document, e.g. "Job Backer" was a bookbinding tool)

**Step 4 — For each stub that IS a public figure:**
- Use WebFetch on 2–3 sources (try Britannica, goodtherapy.org, ethw.org, author websites, sfwork.com, etc.)
- Wikipedia returns 403; skip it
- Write from training knowledge + whatever fetches succeed
- Keep fetches under 3 minutes each; skip if timeout/404

**Step 5 — Write the expanded file** using Write tool with full biography format

**Step 6 — Show verbose progress** as you go: state which file you're working on, what sources you tried, what succeeded

## Already-Processed Files (as of 2026-03-21; new files added since — see below)

These were expanded in the session on 2026-03-21 and should NOT be re-expanded unless the user requests it:
- Moshe Feldenkrais — physicist, judo pioneer, Feldenkrais Method
- Jay Haley — family therapy, Strategic Therapy, Milton Erickson
- Bradford Keeney — Batesonian cybernetics, shamanic healing
- Ross Jeffries — Speed Seduction, NLP-based pickup
- Rabbi Zelig Pliskin — 30+ books on Jewish psychology/happiness
- Anthony Flaccavento — Virginia farmer/politician/author
- Mark McKergow — Solutions Focus, Host Leadership
- Colin Marshall — journalist, Japan/cities essayist
- Jack Wallen — tech journalist, Linux/ZDNet
- Jonathan Rice — NLP trainer, Institute of NLP
- Sophia Bogle — book restorer, Save Your Books
- Carolyn Maiers — DHE article author, CompuServe NLP
- Shelle Rose Charvet — expanded (LAB Profile, career history added)
- John J. La Valle — expanded (Pure NLP career history added)

## Files Added Since 2026-03-21 (status unknown — check before expanding)

**Likely public figures needing biography expansion:**
- Stever Robbins (Get-It-Done Guy, productivity/NLP)
- Nelson Zink (NLP trainer)
- Rex Steven Sikes (NLP/success conditioning)
- Patrick E. Merlevede (NLP/talent management)
- Paul Kersten (NLP)
- Belle Steinberg (Ericksonian hypnosis)
- Bill Mollison (permaculture founder)
- Baldassare Forestiere (historical figure, underground gardens)
- Nick Lima (Austin FC player)

**Status unknown — verify before expanding:**
- Andrea Rice, Malinda Lloyd, Geri Tease, Bob Bradford, Christina McFillips
- Robert Weinberg, Jeff A. Weakley, Ronald C. Bieber, Bob Janes, Larry Kobrin, Chad Robertson

**EWT genealogy records (separate format, no biography expansion needed):**
- Col Mathew Talbot, Lee Etta Stanard, Alfred W. Talbot Sr., Vera Irene Talbot
- Dr. Alfred Carson Waldrep Jr., John Henry White, Thomas Talbot

## Known False Positives
- `Job Backer.md` — a bookbinding tool, not a person. File updated with explanation; can be deleted.
- `Many Things However` — could not locate on disk; likely already gone or mis-filed

## Private Individual Format (do NOT convert to biography format)
These use contact-card format which is CORRECT for them:
Joanne Burke, Karen O'Brien, Pat O'Brien, Farid Tafazzoli, Takane Hinds, Josie Talbot, Carson Wayne Talbot, Chuck Collins, Angela Bryant, Wayne Talbot, Diane Moukourie, Diane Sandlin, Kalena Powell, Sally Miculek, Mindy Klein, Ricki McMillian, Terrie Hahn, Derek Timourian, Jody Patterson, Karen Harrison

## WebFetch Tips (from experience)
- Britannica 404s on biography pages lately — skip
- Wikipedia returns 403 — skip
- goodtherapy.org/famous-psychologists/ works well
- ethw.org works well for engineers/scientists
- sfwork.com works for Mark McKergow
- Author .com/about pages frequently return 404 or ECONNREFUSED
- Packard Foundation, ETHW, GoodTherapy are reliable fallbacks
- Always try 2–3 sources in parallel; write from training knowledge if all fail
