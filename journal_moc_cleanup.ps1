$journal = 'C:\Users\awt\Sync\Obsidian\2026-04-22.md'
$text = [System.IO.File]::ReadAllText($journal, [System.Text.Encoding]::UTF8)
$entry = @'

- MOC Cleanup complete (9 changes): moved 2 Timothy 3 NLT and Titanic Forgotten Survivor within Bahai MOC (Central Figures to Clippings & Resources); removed HP Retiree Dave Packard from NLP (already in Tech); moved Art of the Apology from PKM to NLP Psychology & Behavior; moved Bettinger Genetic Genealogy and DNA from Home Practical Tips to Genealogy; moved IRS Wash Sale Rules from Home to Finance; removed IBM Research Thinks and Powdered Booze from Science Articles (already in Tech and Health MOCs respectively).
'@
$text = $text.TrimEnd() + $entry
[System.IO.File]::WriteAllText($journal, $text, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Journal updated'
