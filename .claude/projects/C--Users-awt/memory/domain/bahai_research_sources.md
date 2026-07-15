---
name: bahai-research-sources
description: Bahá'í LLM/research resource page (bahai-library.com) — which linked tools are actually usable by agent tools vs. human-only
metadata:
  type: reference
  originSessionId: f5c35184-83b0-4ff9-b5e3-6c5592505b04
---

`https://bahai-library.com/llm_resources_bahai` catalogs Bahá'í LLM/research tools in 5 categories. Checked 2026-07-15 for usability by Claude's web tools (WebFetch/Playwright/Firecrawl) — most of it isn't.

**Not usable — Google NotebookLM notebooks (bulk of the page, ~17 links):**
- Categories 1–4 (Steven Phelps' Inventory v6, Violetta Zein's by-subject split, Adib Masumian's periodicals and Persian scholarship notebooks) are all `notebooklm.google.com/notebook/{id}` links.
- Confirmed: navigating one redirects straight to `accounts.google.com` sign-in — not accessible without a human's authenticated Google session, and even if signed in, NotebookLM is an interactive RAG chat interface, not static/crawlable content. Not usable in my workflow regardless of auth.
- If Wayne wants to use one of these notebooks, he'd need to open it himself and paste findings back for me to file — I can't query it directly.

**Usable — Category 5, Sifter search tool:**
- `bahai-education.org/sifter-star-of-the-west` (Chad Jones) — full-text search over Star of the West (25 volumes, 383 issues, 8,505 pages). Loads fine via Playwright, no auth wall. Good candidate for [[resolve-unknowns]]-style lookups or [[ingest-resource]] research when a topic touches early American Bahá'í periodical history (1910s–1920s).

**Usable — Category 1 PDF downloads:**
- `blog.loomofreality.org/?page_id=252` — 194-volume parallel-text series of Central Figures' writings in **provisional** (unofficial) English translation, downloadable PDFs. Loads fine via Playwright, no auth wall.
- Caution: "provisional translation" means not an authoritative Bahá'í World Centre translation — treat as supplementary/informal source, not citation-grade for [[bahai_publication_standards]] purposes. Cross-check against official texts before using wording from it in vault notes.

**Bottom line:** of the 5 categories on that page, only the Sifter tool and the loomofreality PDF inventory are directly fetchable by my tools. The NotebookLM links are dead ends for programmatic use.
