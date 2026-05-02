# Second cleanup pass — removes remaining false-positive People Index entries
# These are NLP procedure steps, park labels, forum usernames, etc.

$enc = New-Object System.Text.UTF8Encoding($false)
$filePath = 'D:\Obsidian\Main\People Index.md'

$bytes  = [System.IO.File]::ReadAllBytes($filePath)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$text   = if ($hasBom) { $enc.GetString($bytes[3..($bytes.Length-1)]) } else { $enc.GetString($bytes) }
$lines  = [System.Collections.Generic.List[string]]($text -split '\r?\n')
$eol    = if ($text -match '\r\n') { "`r`n" } else { "`n" }

# Headings to remove (without ### prefix, without ★ suffix — matched with -match)
$falseHeadings = @(
    'FEE, DAY USE',
    'FEE:, DAY USE',
    'feedback, Appropriate',
    'feedback, Having the sensory',
    'feelings, discovering how',
    'Hmmm, my assumption',
    'Hmmm, my assumption\.',
    'NUMBER, PARK PHONE',
    'NUMBER:, PARK PHONE',
    'NZN, me',
    'NZN, me\.',
    'Outcomes, I',
    'Outcomes, I\.',
    'Outcomes, NLP Well-Formed',
    'outcomes, Well-formed',
    'outcomes\., Flexibility governs',
    'reader, General',
    'reader:, General',
    'rule, Key',
    'rule:, Key',
    'saved, Stan is',
    'saved\., Stan is',
    'state, ANCHOR the non-reactive',
    'state\., ANCHOR the non-reactive',
    'state\., Elicit the problem',
    'state:, Identify excellent',
    'State:, Separator',
    'statements, the',
    'subject, Tell the',
    'subject:, Ask the',
    'subject:, Tell the',
    'Technology, Deep Woods',
    'Technology\., Deep Woods'
)

$removed = 0
foreach ($heading in $falseHeadings) {
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^### $heading") { $idx = $i; break }
    }
    if ($idx -eq -1) { Write-Host "Not found: ### $heading"; continue }

    # Find end of this entry (next ### or ## or ---)
    $end = $idx + 1
    while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') {
        $end++
    }
    $count = $end - $idx
    $lines.RemoveRange($idx, $count)
    $removed++
    Write-Host "Removed: ### $heading ($count lines)"
}

$newText  = $lines -join $eol
$outBytes = if ($hasBom) {
    (New-Object System.Text.UTF8Encoding($true)).GetPreamble() + $enc.GetBytes($newText)
} else { $enc.GetBytes($newText) }
[System.IO.File]::WriteAllBytes($filePath, $outBytes)
Write-Host "`nSaved People Index. Total entries removed: $removed"
