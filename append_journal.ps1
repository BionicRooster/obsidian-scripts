$journal = 'D:\Obsidian\Main\2026-04-22.md'
$text = [System.IO.File]::ReadAllText($journal, [System.Text.Encoding]::UTF8)

# Remove the incomplete entry we just added
$badEntry = "- Classified 3 vault notes created today: added YAML frontmatter + nav to  (linked to MOC - Technology & Computers > Digital Privacy & Security; left in vault root),  and  (both linked to MOC - Social Issues > Justice & Politics; moved to 01\Social\)."
$text = $text.Replace($badEntry, '')

# Add correct entry
$entry = @"

- Classified 3 vault notes created today: added YAML frontmatter + nav to Computer Security Tips (linked to MOC - Technology & Computers > Digital Privacy & Security; left in vault root), Bernie Sanders signaling and Bernie Sanders and Donald Trump Signaling Compared (both linked to MOC - Social Issues > Justice & Politics; moved to 01\Social\).
"@

$text = $text.TrimEnd() + $entry
[System.IO.File]::WriteAllText($journal, $text, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Journal fixed'
