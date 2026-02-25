# alphabetize_moc_links.ps1
# Sorts bullet-point wikilinks alphabetically within each subsection of all MOC files
# No nested functions - avoids PowerShell scope issues

$mocDir = "D:\Obsidian\Main\00 - Home Dashboard"
$enc    = [System.Text.Encoding]::UTF8

Get-ChildItem $mocDir -Filter "MOC - *.md" | ForEach-Object {
    $path   = $_.FullName
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $origText = $text

    # Detect line ending style
    $eol    = if ($text -match "`r`n") { "`r`n" } else { "`n" }

    # Split into lines (strip trailing \r for uniform handling)
    $lines  = $text -split "`r?`n"

    $result  = [System.Collections.Generic.List[string]]::new()
    $linkBuf = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        if ($line.TrimEnd() -match '^- \[\[') {
            # Accumulate consecutive link lines
            $linkBuf.Add($line)
        } else {
            # Non-link line: flush link buffer sorted, then add current line
            if ($linkBuf.Count -gt 0) {
                $sorted = $linkBuf | Sort-Object { $_ -replace '^- \[\[', '' } -CaseSensitive:$false
                foreach ($l in $sorted) { $result.Add($l) }
                $linkBuf.Clear()
            }
            $result.Add($line)
        }
    }
    # Flush any remaining links at end of file
    if ($linkBuf.Count -gt 0) {
        $sorted = $linkBuf | Sort-Object { $_ -replace '^- \[\[', '' } -CaseSensitive:$false
        foreach ($l in $sorted) { $result.Add($l) }
    }

    # Reconstruct text with original line endings
    $newText = $result -join $eol

    if ($newText -ne $origText) {
        $out = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($newText) } else { $enc.GetBytes($newText) }
        [System.IO.File]::WriteAllBytes($path, $out)
        Write-Host "  [sorted] $($_.Name)"
    } else {
        Write-Host "  [no change] $($_.Name)"
    }
}
Write-Host "Done."
