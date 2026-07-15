Fetch web content using Exa for semantic search, Playwright MCP for JavaScript-heavy pages, and Firecrawl only as a last resort.

## Parameters

`$ARGUMENTS` — specify what to fetch and how:
- `/web-scraping search "query here"` — semantic search via Exa; returns ranked results with snippets
- `/web-scraping scrape https://example.com` — full-page scrape via Firecrawl; handles JS-rendered content
- `/web-scraping search "query" scrape` — semantic search then scrape the top result
- `/web-scraping search "query" top 5` — return top N results (default: 3)
- `/web-scraping` with no args → prompt: "What do you want to search or scrape?"

Parse from `$ARGUMENTS`:
- **Mode** — `search` (Exa) or `scrape` (Firecrawl); default is `search`
- **Query or URL** — required; a quoted search string or a bare URL
- **top N** — optional result count for search mode (default 3)
- **scrape** — if added after a search query, automatically scrape the top result

---

## Tool Selection Rules

| Situation | Tool | Reason |
|---|---|---|
| Finding relevant pages on a topic | Exa (WebSearch) | Semantic ranking surfaces conceptually related results, not just keyword matches |
| Static HTML page or plain article | WebFetch directly | Fastest; no JS render needed |
| Page uses heavy JavaScript / SPA | **Playwright MCP** (`browser_navigate` + `browser_get_text`) | Runs real Chromium headless; handles React, Vue, Angular, infinite scroll, tabs |
| Playwright fails or unavailable | Firecrawl (last resort) | API fallback; costs credits; only when Playwright errors or times out |
| Unclear which to use | Default to Exa search first | Find the right URL, then decide whether to scrape |

**When to escalate from WebFetch → Playwright:**
- URL is from a known JS-heavy domain (ESPN, FBref stats tabs, Twitter/X, LinkedIn, GitHub Actions UI)
- WebFetch returns < 200 words of body text
- Page content requires scroll or click to load (infinite scroll, tabs, accordions)

**When to use Firecrawl (last resort only):**
- Playwright MCP returns an error or times out after one retry
- Playwright is not available in the current session

---

## Step 1 — Interpret the Request

1. Parse mode, query/URL, and result count from `$ARGUMENTS`
2. If mode is ambiguous and input looks like a URL (`http://` or `https://`), set mode to `scrape`
3. If mode is ambiguous and input looks like a phrase, set mode to `search`
4. If no arguments: ask "Search for a topic (give me a query) or scrape a specific URL?"

---

## Step 2 — Execute

### Search mode (Exa)

Use `WebSearch` with the query string.

- Request at least `top N` results (default 3, max 10)
- Collect: title, URL, snippet/summary, published date if available
- Rank by relevance to the original query intent, not just keyword overlap

### Scrape mode (Playwright MCP → WebFetch → Firecrawl)

1. Try `WebFetch` first on the target URL.
2. If content is < 200 words or clearly incomplete, escalate to **Playwright MCP**:
   - `browser_navigate` to the URL
   - `browser_get_text` (or `browser_snapshot`) to extract content
   - `browser_close` when done
3. Only if Playwright errors or times out → fall back to Firecrawl as last resort.

For all paths:
- Strip nav, footer, cookie banners, and sidebar ads from the extracted text
- Preserve: headings, tables, ordered/unordered lists, and code blocks
- Return the cleaned Markdown representation of the page body

### Search-then-scrape mode

1. Run Exa search, collect top results
2. Pick the highest-ranked result that matches the user's intent
3. Scrape that URL using Firecrawl/WebFetch
4. Report which URL was selected and why

---

## Step 3 — Format Output

### Search results

```
## Search Results for: "{query}"
Source: Exa · {timestamp}

1. **{Title}** — {URL}
   {snippet, 1–3 sentences}
   Published: {date if known}

2. ...
```

### Scraped page

```
## Scraped: {URL}
Source: {Playwright MCP | WebFetch | Firecrawl} · {timestamp}

{Cleaned Markdown body}
```

### Search-then-scrape

Show both the search result list and the full scraped content of the chosen URL, separated by a horizontal rule.

---

## Step 4 — Vault Save (optional)

If the user says "save to vault" or "save as a clipping":
- Save to `C:\Users\awt\Sync\Obsidian\10 - Clippings\` as `YYYY-MM-DD - {Page Title}.md`
- Frontmatter:

```yaml
---
title: {Page Title}
url: {source URL}
date_clipped: {YYYY-MM-DD}
tags:
  - Clipping
source: {Exa | Firecrawl | WebFetch}
---
```

- Body: the cleaned Markdown from Step 3
- Log to `C:\Users\awt\Sync\Obsidian\01\PKM\Claude Action Log.md` with `[INGEST]` prefix:
  ```
  [INGEST] {filename} ← web-scraping skill ({mode}) — {query or URL}
  ```

---

## Key Rules

- **Never hardcode API keys.** Exa and Firecrawl authenticate via MCP server configuration; no keys appear in skill code or prompts.
- If WebFetch returns a 403/429/bot-block response, escalate to Playwright MCP — do not retry WebFetch.
- If the scraped content is behind a login wall, report "Login required — content not accessible" rather than returning the login page HTML.
- **Priority order: WebFetch → Playwright MCP → Firecrawl.** Firecrawl is last resort only.
- Always `browser_close` after a Playwright session to avoid leaked browser processes.
- For Obsidian vault saves, follow UTF-8 encoding rules and preserve diacritical characters unchanged.
