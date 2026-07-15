---
name: feedback-web-fetch-routing
description: "Web fetch tool priority order — Playwright MCP first, Firecrawl last resort only"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d19617d8-8a13-4cae-9402-bd0a201b2918
---

Use Playwright MCP for JS-heavy pages; Firecrawl is last resort only.

**Why:** User explicitly requested this on 2026-07-14 — Playwright is local, free, and more capable (can click/scroll). Firecrawl costs API credits.

**How to apply:**
Priority order for any web fetch in any skill or workflow:
1. `WebFetch` — plain articles, static pages
2. `WebSearch` (Exa) — topic/concept searches
3. **Playwright MCP** (`browser_navigate` + `browser_get_text`) — JS-heavy pages, SPAs, thin WebFetch results (< 200 words)
4. **Firecrawl** — ONLY if Playwright errors or times out after one retry

Always `browser_close` after Playwright use. Never reach for Firecrawl as the first JS-rendering tool.

**Known exception:** FBref (`fbref.com`) blocks Playwright too — Cloudflare "Just a moment..." challenge, HTTP 403, confirmed 2026-07-14 (see [[soccer_sources]]). Go straight to Firecrawl for FBref specifically; don't burn a Playwright attempt first.
