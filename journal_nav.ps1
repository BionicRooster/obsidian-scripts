$journal = 'C:\Users\awt\Sync\Obsidian\2026-04-22.md'
$text = [System.IO.File]::ReadAllText($journal, [System.Text.Encoding]::UTF8)
$entry = "`r`n- Nav backfill complete: added nav property to 453 notes across all 01\ subfolders (42 needed new frontmatter blocks). 1,807 files already had nav and were untouched. 0 errors."
$text = $text.TrimEnd() + $entry
[System.IO.File]::WriteAllText($journal, $text, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Journal updated'
