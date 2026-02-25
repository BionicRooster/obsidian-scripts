$vault = "D:\Obsidian\Main"
$enc   = [System.Text.Encoding]::UTF8
$link  = "[[MOC - Japan & Japanese Culture]]"

function Add-NavToFrontmatter($path, $navValue) {
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $lines  = $text -split "(?<=`n)"
    $result = [System.Collections.Generic.List[string]]::new()
    $fmStart = $false; $fmDone = $false; $inserted = $false; $i = 0
    foreach ($line in $lines) {
        $trim = $line.TrimEnd("`r","`n"," ")
        if ($i -eq 0 -and $trim -eq '---') { $fmStart = $true; $result.Add($line); $i++; continue }
        if ($fmStart -and -not $fmDone -and $trim -eq '---') {
            $result.Add("nav: `"$navValue`"`n"); $fmDone = $true; $inserted = $true
        }
        $result.Add($line); $i++
    }
    if ($inserted) {
        $out = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($result -join '') } else { $enc.GetBytes($result -join '') }
        [System.IO.File]::WriteAllBytes($path, $out)
        Write-Host "  [nav added] $path"
    }
}

function Add-ToRelatedNotes($path, $lnk) {
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $newText = if ($text -match '(?m)^## Related Notes') {
        $text -replace '(?m)(^## Related Notes[ \t]*\r?\n)', "`${1}- $lnk`n"
    } else {
        $text.TrimEnd() + "`n`n## Related Notes`n- $lnk`n"
    }
    $out = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($newText) } else { $enc.GetBytes($newText) }
    [System.IO.File]::WriteAllBytes($path, $out)
    Write-Host "  [related] $path"
}

# Broccoli Curry Udon — has nav: [[MOC - Recipes]], so add Japan to Related Notes
Add-ToRelatedNotes "$vault\01\Recipes\Broccoli Curry Udon.md" $link

# Fingering Charts for — no nav, add Japan as nav
Add-NavToFrontmatter "$vault\01\Music\Fingering Charts for.md" $link

Write-Host "Done."
