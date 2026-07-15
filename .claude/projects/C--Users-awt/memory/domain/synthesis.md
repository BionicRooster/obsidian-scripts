---
name: domain-synthesis
description: "Synthesis Layer rules — location, purpose, when to check/update, Query-to-File Rule, Vault Lint Workflow, current pages"
metadata:
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Synthesis Layer

**Location:** `C:\Users\awt\Sync\Obsidian\30 - Synthesis\`
**Index:** `C:\Users\awt\Sync\Obsidian\30 - Synthesis\index.md` — catalog of all synthesis pages with one-line summaries and source counts

**Purpose:** Synthesis pages compile what the vault currently knows about a topic into a single document, integrating evidence from multiple source notes. They get richer with every source ingested and every question answered. The MOC tells you *where* content lives; synthesis pages tell you *what the vault thinks* about a topic.

## When to Check
- Before answering a vault question on a topic that has a synthesis page — read the synthesis page first
- During the classify workflow: after classifying a new note, check `30 - Synthesis/index.md` and update any relevant page

## When to Update a Synthesis Page
1. A new source is classified that adds evidence, revises a claim, or introduces a contradiction
2. A good query answer reveals a connection not yet reflected in the page
3. Increment `source_count` in frontmatter when adding a source to the synthesis
4. Note contradictions explicitly rather than silently resolving them

## EWT Project Wiki
Synthesis pages for the Elias White Talbot project live inside the project folder at `02 - Working Projects/Elias White Talbot - Project/` with `wiki-index.md` as the project wiki index.

## Current Synthesis Pages
**Bahá'í:** Progressive Revelation, The Covenant, Bahai Administrative Order, Oneness of Humanity
**EWT:** Talbot Brothers in Texas, Underground Railroad Station - 209 Church Street, Talbot Family Origins - Ireland to Vermont

---

## Query-to-File Rule

When a substantive vault query produces a useful answer — a comparison, an analysis, a synthesis of evidence across sources, a cross-topic connection — offer to file the answer as a new synthesis page.

**Filing a query answer:**
1. Create the page in `30 - Synthesis/` with frontmatter: `tags: [synthesis]`, `nav` pointing to relevant MOC, `source_count: N`, `created: YYYY-MM-DD`
2. Add an entry in `30 - Synthesis/index.md` under the appropriate section
3. Ask at the end of any exploratory vault conversation: "Should I file this answer as a synthesis page?"

**Do not file:**
- Simple factual lookups ("when did X happen?")
- Workflow outputs (box scores, classifications, People Index updates)
- Administrative operations (MOC cleanup, orphan linking, file moves)

---

## Vault Lint Workflow

**Trigger:** "lint vault", "lint synthesis", or "run a lint"

**Purpose:** Health-check the synthesis layer for staleness, gaps, and contradictions.

**Scope:** All pages in `30 - Synthesis/` plus EWT project wiki at `02 - Working Projects/Elias White Talbot - Project/wiki-index.md`

**Checks to run:**
- **Contradictions** — claims on one synthesis page that conflict with another or with recent source notes; note explicitly rather than silently resolving
- **Thin pages** — synthesis pages with `source_count` ≤ 2; flag for enrichment and identify which vault notes could be added as sources
- **Topic gaps** — concepts mentioned in 5+ vault notes that lack their own synthesis page; search clippings and MOC subsections for recurring themes; suggest creating a page
- **Stale claims** — EWT pages where newer evidence (Find a Grave, Yale catalog) supersedes an older claim; flag and resolve in the page
- **Orphaned synthesis pages** — synthesis pages not linked from any MOC subsection or the synthesis index

**Output:** A report with four sections — Contradictions · Thin Pages · Topic Gaps · Stale Claims — with specific file references and recommended actions.

After lint: Offer to create synthesis pages for any high-priority topic gaps identified.
