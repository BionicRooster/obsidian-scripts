$vault = "D:\Obsidian\Main"
$enc   = [System.Text.Encoding]::UTF8

function Remove-LineContaining($path, $pattern) {
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $lines  = $text -split "(?<=`n)"
    $new    = $lines | Where-Object { $_ -notmatch $pattern }
    $newText = $new -join ''
    $out    = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($newText) } else { $enc.GetBytes($newText) }
    [System.IO.File]::WriteAllBytes($path, $out)
    Write-Host "  Cleaned: $(Split-Path $path -Leaf)"
}

function Remove-Tag($path, $tag) {
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $lines  = $text -split "(?<=`n)"
    # Remove only the exact tag line (e.g. "  - NLP" or "  - NLP_Psy")
    $new    = $lines | Where-Object { $_.TrimEnd() -notmatch "^\s+- $([regex]::Escape($tag))$" }
    $newText = $new -join ''
    $out    = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($newText) } else { $enc.GetBytes($newText) }
    [System.IO.File]::WriteAllBytes($path, $out)
    Write-Host "  Removed tag '$tag': $(Split-Path $path -Leaf)"
}

# 1. Remove erroneous "- MOC - NLP & Psychology" lines from unrelated notes
Write-Host "`n=== Removing erroneous NLP MOC crosslinks ==="
$badCrosslinks = @(
    "$vault\01\Home\Clean Air Floor Remodeling.md",
    "$vault\01\Technology\Hardware.md",
    "$vault\01\Technology\Life Behind the Stacks.md",
    "$vault\01\Technology\9 Steps to Take If You Download Malware.md",
    "$vault\01\Music\15 Tips to Becoming a Skilled Choral Singer.md",
    "$vault\01\Music\Background of  Lift.md",
    "$vault\01\Music\Modern vs Baroque vs.md",
    "$vault\01\Music\Recorder Instrument Types.md"
)
foreach ($f in $badCrosslinks) {
    if (Test-Path -LiteralPath $f) {
        Remove-LineContaining $f 'MOC - NLP & Psychology'
    }
}

# 2. Remove wrong NLP tag from xkcd note
Write-Host "`n=== Removing wrong NLP tag from xkcd note ==="
Remove-Tag "$vault\01\Home\xkcd- Sandwich Helix.md" "NLP"

# 3. Remove wrong NLP_Psy tag from ecology note
Write-Host "`n=== Removing wrong NLP_Psy tag from ecology note ==="
Remove-Tag "$vault\01\Science\What Ecologists Are Learning from Indigenous People.md" "NLP_Psy"

Write-Host "`nDone."
