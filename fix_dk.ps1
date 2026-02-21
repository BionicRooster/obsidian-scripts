$f = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\Dunning*' | Select-Object -First 1
$content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
if ($content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

# This file has broken frontmatter. Extract the YAML fields buried in the middle:
# title, source, author, published, created, description, tags
# Then rebuild with proper frontmatter at top

# Find the title: line
$titleMatch = [regex]::Match($content, 'title: "([^"]*)"')
$sourceMatch = [regex]::Match($content, 'source: "([^"]*)"')
$authorMatch = [regex]::Match($content, 'author:\r?\n- "([^"]*)"')
$publishedMatch = [regex]::Match($content, 'published: (\S+)')
$createdMatch = [regex]::Match($content, 'created: (\S+)')

# Remove the old broken frontmatter sections and embedded YAML
# The file starts with ---\n## Related Notes\n---\n... then later has title:/source:/etc then ---
# We need to strip those and create a clean frontmatter

# Remove opening ---
$content = $content -replace '^---\r?\n', ''

# Remove the embedded YAML block (title: through ---)
$content = $content -replace 'title: "Dunning-Kruger effect - Wikipedia"\r?\nsource: "[^"]*"\r?\nauthor:\r?\n- "Contributors to Wikimedia projects"\r?\npublished: \S+\r?\ncreated: \S+\r?\ndescription:\r?\ntags:\r?\n- "clippings"\r?\n---\r?\n', ''

$newFm = @"
---
title: "Dunning-Kruger effect - Wikipedia"
source: "https://en.wikipedia.org/wiki/Dunning%E2%80%93Kruger_effect"
author:
- "Contributors to Wikimedia projects"
published: 2005-07-22
created: 2025-12-28
description:
tags:
  - Psychology
  - cognition
  - bias
  - Education
  - clippings
---

"@

$newContent = $newFm + $content
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($f.FullName, $newContent, $utf8NoBom)
Write-Host "Fixed Dunning-Kruger file"
