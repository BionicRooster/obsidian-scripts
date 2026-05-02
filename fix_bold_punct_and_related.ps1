param([string]$VaultPath = "D:\Obsidian\Main", [switch]$DryRun)

Write-Host "Building vault file index..." -ForegroundColor Cyan
$fileIndex = @{}
Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" | ForEach-Object {
    $stem = $_.BaseName
    $fileIndex[$stem.ToLower()] = $stem
}
Write-Host "  Indexed $($fileIndex.Count) files" -ForegroundColor Gray

$boldPunctFixed = [System.Collections.Generic.List[string]]::new()
$relatedFixed   = [System.Collections.Generic.List[string]]::new()
$relatedSkipped = [System.Collections.Generic.List[string]]::new()
$errFiles       = [System.Collections.Generic.List[string]]::new()

$allFiles = Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" |
    Where-Object {
        $_.FullName -notmatch "00 - Images" -and
        $_.FullName -notmatch "Templates"  -and
        $_.FullName -notmatch ".resources"
    }

$total = $allFiles.Count
$idx   = 0

foreach ($file in $allFiles) {
    $idx++
    if ($idx % 300 -eq 0) { Write-Host "  $idx / $total..." -ForegroundColor Gray }

    try {
        $raw      = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $original = $raw

        # Pass 1: strip bold-wrapped punctuation
        $pass1 = [System.Text.RegularExpressions.Regex]::Replace($raw, '\*\*([.!?;:,]+)\*\*', '$1')

        # Pass 2: wikify plain-text bullets in Related sections
        $lines     = $pass1 -split "`n"
        $inRelated = $false
        $changed   = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            if ($line -match '^\s*#+\s+Related') { $inRelated = $true;  continue }
            if ($inRelated -and $line -match '^\s*#+\s+') { $inRelated = $false; continue }
            if (-not $inRelated) { continue }

            if ($line -match '^(\s*- )(?!\[\[)(?!http)(.+)$') {
                $pfx  = $Matches[1]
                $txt  = $Matches[2].Trim()
                $look = ($txt -split '\|')[0].Trim()

                if ($look.Length -gt 80) { continue }
                if ($look -match '[,"]' -or $look -match '\s(and|or|but|the|a|an)\s') { continue }

                $key = $look.ToLower()
                if ($fileIndex.ContainsKey($key)) {
                    $disp      = $fileIndex[$key]
                    $lines[$i] = "$pfx[[$disp]]"
                    $changed   = $true
                    if (-not $relatedFixed.Contains($file.FullName)) { $relatedFixed.Add($file.FullName) }
                    Write-Host "  REL [$($file.Name)]: '$look' -> [[$disp]]" -ForegroundColor Green
                } else {
                    $sk = "$($file.Name): '$look'"
                    if (-not $relatedSkipped.Contains($sk)) { $relatedSkipped.Add($sk) }
                }
            }
        }

        $pass2 = if ($changed) { $lines -join "`n" } else { $pass1 }

        if ($pass2 -ne $original) {
            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($file.FullName, $pass2, [System.Text.Encoding]::UTF8)
            }
            if ($pass1 -ne $original) { $boldPunctFixed.Add($file.FullName) }
        }
    } catch {
        $errFiles.Add("$($file.FullName): $_")
    }
}

Write-Host ''
Write-Host 'BOLD PUNCT fixed:' $boldPunctFixed.Count -ForegroundColor Yellow
$boldPunctFixed | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ''
Write-Host 'RELATED BULLETS wikified:' $relatedFixed.Count -ForegroundColor Yellow
$relatedFixed | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ''
Write-Host 'RELATED BULLETS no vault match (skipped):' $relatedSkipped.Count -ForegroundColor DarkYellow
$relatedSkipped | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
if ($errFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'ERRORS:' $errFiles.Count -ForegroundColor Red
    $errFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green