# Append activity log to today's journal

$journal = 'D:\Obsidian\Main\2026-04-28.md'

# Read existing content
$content = Get-Content -LiteralPath $journal -Encoding UTF8 -Raw

# Check if ## My Notes section exists; if not, append it
$entry = @"

## My Notes

- Added **Donath** and **Davidson** to the surname false-positive blocklist in `obsidian_maintenance.ps1`
- **Classify All Unclassified Notes** — linked ~186 vault notes across 14 MOC files:
  - `MOC - Bah$(([char]0x00e1))'$(([char]0x00ed)) Faith` — Community & Service, Ridv$(([char]0x00e1))n Messages sections; removed garbled link; renamed double-space Bah$(([char]0x00e1))'$(([char]0x00ed)) Names file
  - `MOC - Finance & Investment`, `MOC - FOL`, `MOC - Health & Nutrition`, `MOC - Home & Practical Life`, `MOC - Music & Record`
  - `MOC - NLP & Psychology` — 39 links across 6 subsections
  - `MOC - Reading & Literature`, `MOC - Recipes` — 20 links
  - `MOC - Science & Nature`, `MOC - Social Issues`, `MOC - Genealogy`
  - `MOC - Technology & Computers` — 50+ links across 14 sections; fixed run-together lines
  - `MOC - Travel & Exploration`
- Moved `Adults who apologize.md` → `01\Psychology`; `The Ninth Day of Ridvan...md` → `01\Baha'i`
- Fixed Brian K. White filename (non-breaking space → regular space)
- Fixed IFTTT MOC link (curly apostrophe → straight)
- Fixed Recipes MOC run-together entries; renamed 2 garbled recipe files (Windows-1252 smart quotes → clean ASCII)
- Deleted generated report `Link Recommendations for 10 Additional Obsidian Notes Batch 2.md`
- Added `[[16 - Organizations]]` to Bah$(([char]0x00e1))'$(([char]0x00ed)) Faith MOC — Community & Service
- Final unclassified content notes: **0** (7 remaining items are journal/plugin/trash files)
"@

if ($content -match '## My Notes') {
    # Append bullet points after the ## My Notes heading
    $notesIdx = $content.IndexOf('## My Notes')
    # Find end of My Notes section (next ## heading or end of file)
    $afterNotes = $notesIdx + '## My Notes'.Length
    $nextSection = [regex]::Match($content.Substring($afterNotes), '(?m)^## ')
    if ($nextSection.Success) {
        $insertPos = $afterNotes + $nextSection.Index
        $newText = "`n- Added **Donath** and **Davidson** to surname blocklist in `obsidian_maintenance.ps1``n- **Classify All Unclassified Notes** complete: 186 notes linked across 14 MOCs; 0 content notes unclassified"
        $content = $content.Substring(0, $insertPos) + $newText + $content.Substring($insertPos)
    } else {
        # Append at end
        $content = $content.TrimEnd() + "`n- Added **Donath** and **Davidson** to surname blocklist in ``obsidian_maintenance.ps1```n- **Classify All Unclassified Notes** complete: 186 notes linked across 14 MOCs; 0 content notes unclassified`n"
    }
    Set-Content -LiteralPath $journal -Value $content -Encoding UTF8 -NoNewline
    Write-Output "Appended to existing ## My Notes section"
} else {
    # Append the whole section
    $content = $content.TrimEnd() + $entry
    Set-Content -LiteralPath $journal -Value $content -Encoding UTF8 -NoNewline
    Write-Output "Appended new ## My Notes section"
}
