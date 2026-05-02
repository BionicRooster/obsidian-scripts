$journal = 'D:\Obsidian\Main\2026-04-22.md'
$text = [System.IO.File]::ReadAllText($journal, [System.Text.Encoding]::UTF8)
$entry = @'

- Verified Bahai Election Results for Georgetown LSA 2026-04-21 is correctly linked in MOC - Bahai Faith under Administrative Guidance. No action needed.
'@
$text = $text.TrimEnd() + $entry
[System.IO.File]::WriteAllText($journal, $text, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Journal updated'
