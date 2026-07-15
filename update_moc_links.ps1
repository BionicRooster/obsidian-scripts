# Update MOC files to add newly classified notes
$vault = 'C:\Users\awt\Sync\Obsidian'

# ── MOC - Social Issues ────────────────────────────────────────────────────
$socialMoc = Join-Path $vault '00 - Home Dashboard\MOC - Social Issues.md'
$social = [System.IO.File]::ReadAllText($socialMoc, [System.Text.Encoding]::UTF8)

$oldSocial = '- [[The Signaling of Donald Trump and Adolf Hitler]]'
$newSocial = "- [[The Signaling of Donald Trump and Adolf Hitler]]`r`n- [[Bernie Sanders signaling]]`r`n- [[Bernie Sanders and Donald Trump Signaling Compaired]]"
$social = $social.Replace($oldSocial, $newSocial)

[System.IO.File]::WriteAllText($socialMoc, $social, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Updated: MOC - Social Issues.md'

# ── MOC - Technology & Computers ──────────────────────────────────────────
$techMoc = Join-Path $vault '00 - Home Dashboard\MOC - Technology & Computers.md'
$tech = [System.IO.File]::ReadAllText($techMoc, [System.Text.Encoding]::UTF8)

# Find the ## Digital Privacy & Security section header inline pattern and insert after it
# The header appears as suffix on a bullet line, followed by newline then entries
# Add Computer Security Tips. as a new entry right after the section header line
$oldTech = '## Digital Privacy & Security'
$newTech = "## Digital Privacy & Security`r`n- [[Computer Security Tips.]]"
$tech = $tech.Replace($oldTech, $newTech)

[System.IO.File]::WriteAllText($techMoc, $tech, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Updated: MOC - Technology & Computers.md'
