# Check why suspicious "outside" notes contain "MOC - NLP & Psychology"
$vault = "D:\Obsidian\Main"
$enc   = [System.Text.Encoding]::UTF8

$suspicious = @(
    "$vault\01\Home\Clean Air Floor Remodeling.md",
    "$vault\01\Technology\Hardware.md",
    "$vault\01\Technology\Life Behind the Stacks.md",
    "$vault\01\Technology\9 Steps to Take If You Download Malware.md",
    "$vault\01\Music\15 Tips to Becoming a Skilled Choral Singer.md",
    "$vault\01\Music\Background of  Lift.md",
    "$vault\01\Music\Modern vs Baroque vs.md",
    "$vault\01\Music\Recorder Instrument Types.md",
    "$vault\01\Travel\Going to Moscow.md",
    "$vault\01\Home\xkcd- Sandwich Helix.md",
    "$vault\01\Science\What Ecologists Are Learning from Indigenous People.md"
)

foreach ($f in $suspicious) {
    if (Test-Path -LiteralPath $f) {
        $bytes = [System.IO.File]::ReadAllBytes($f)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $text = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
        $lines = $text -split "`n"
        # Show lines containing NLP
        $nlpLines = $lines | Where-Object { $_ -match 'NLP|psychology' }
        Write-Host "=== $(Split-Path $f -Leaf) ==="
        $nlpLines | ForEach-Object { Write-Host "  $_" }
    }
}
