Fetch web content using Exa for semantic search and Firecrawl for JavaScript-heavy pages.

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
| Page uses heavy JavaScript / SPA | Firecrawl (WebFetch with JS) | Renders the DOM before extracting; handles React, Vue, Angular pages |
| Static HTML page or plain article | WebFetch directly | Fastest; no JS render needed |
| Unclear which to use | Default to Exa search first | Find the right URL, then decide whether to scrape |

**When to prefer Firecrawl over plain WebFetch:**
- URL is from a known JS-heavy domain (e.g., ESPN, FBref stats tabs, Twitter/X, LinkedIn, GitHub Actions UI)
- Initial WebFetch returns near-empty body or only nav/footer text
- Page content requires scroll or click to load (infinite scroll, tabs, accordions)

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

### Scrape mode (Firecrawl / WebFetch)

Use `WebFetch` on the target URL.

- If the page returns empty or thin content (< 200 words of body text), retry with a note that JS rendering may be required
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
Source: Firecrawl · {timestamp}

{Cleaned Markdown body}
```

### Search-then-scrape

Show both the search result list and the full scraped content of the chosen URL, separated by a horizontal rule.

---

## Step 4 — Vault Save (optional)

If the user says "save to vault" or "save as a clipping":
- Save to `D:\Obsidian\Main\10 - Clippings\` as `YYYY-MM-DD - {Page Title}.md`
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
- Log to `D:\Obsidian\Main\01\PKM\Claude Action Log.md` with `[INGEST]` prefix:
  ```
  [INGEST] {filename} ← web-scraping skill ({mode}) — {query or URL}
  ```

---

## Key Rules

- **Never hardcode API keys.** Both Exa and Firecrawl authenticate via MCP server configuration; no keys appear in skill code or prompts.
- If WebFetch returns a 403/429/bot-block response, report it clearly — do not silently retry more than once.
- If the scraped content is behind a login wall, report "Login required — content not accessible" rather than returning the login page HTML.
- Firecrawl is the fallback for JS-heavy pages, not the default — use plain WebFetch first when the URL is a simple article or static page.
- For Obsidian vault saves, follow UTF-8 encoding rules and preserve diacritical characters unchanged.
