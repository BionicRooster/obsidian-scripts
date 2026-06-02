---
name: Transcript Formatting Rules
description: How to reformat video/audio transcripts with inline timestamps into readable paragraphs
type: feedback
originSessionId: f2c229e5-bd10-4e40-b472-28911306b580
---
**Why:** Transcripts with mechanical per-line timestamps produce unreadable walls of single-sentence fragments. Grouping by topic shift and keeping only the lead timestamp produces a scannable, readable document while preserving navigability.

**How to apply:** Any time a transcript note has inline timestamps (`{ts:N}`) or auto-caption line breaks, apply these rules before saving or linking.

When reformatting a video/audio transcript with inline timestamps (e.g., `{ts:0}`, `{ts:6}`, etc.):

1. **Keep only the first timestamp** of each paragraph; remove all timestamps within a paragraph
2. **Group text into natural paragraphs** based on topic shifts and sentence flow — do not follow the original line breaks (which are arbitrary auto-generated splits)
3. **Preserve all footnotes** (inline `[^n]` references, hidden `<span>` blocks, and the footnote definitions at the bottom)
4. **Preserve frontmatter, summary sections, and any other non-transcript content** unchanged

**Paragraph break cues:** topic shifts, rhetorical section headings, transition phrases, and natural narrative beats.
