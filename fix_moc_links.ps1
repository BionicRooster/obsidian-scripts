# fix_moc_links.ps1
# For each broken MOC wikilink:
#   1. Try starts-with match (truncated filenames)
#   2. Try all-words-contained match (renamed files)
#   3. Replace with best match, or remove line if nothing found

$vaultPath = "D:\Obsidian\Main"                          # Vault root
$mocDir    = "$vaultPath\00 - Home Dashboard"            # Folder containing MOC files
$enc       = [System.Text.Encoding]::UTF8                # Encoding for all file I/O

# Build full file index: lowercase basename -> list of full paths
$allFiles   = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md"
$byBasename = @{}                                        # Lookup table keyed by lowercase basename
foreach ($f in $allFiles) {
    $key = $f.BaseName.ToLower()
    if (-not $byBasename.ContainsKey($key)) {
        $byBasename[$key] = [System.Collections.Generic.List[string]]::new()
    }
    $byBasename[$key].Add($f.FullName)
}

# Find vault files whose basename starts with a given prefix
function Find-StartsWith($prefix) {
    $p    = $prefix.ToLower()
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        if ($key.StartsWith($p)) { $hits.AddRange($byBasename[$key]) }
    }
    return $hits
}

# Find vault files whose basename contains all significant words from the target
function Find-AllWords($target) {
    $words = ($target -split '[\s\-_,\.]+') | Where-Object { $_.Length -ge 4 } |
             ForEach-Object { $_.ToLower() }
    if ($words.Count -eq 0) { return @() }
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        $match = $true
        foreach ($w in $words) {
            if (-not $key.Contains($w)) { $match = $false; break }
        }
        if ($match) { $hits.AddRange($byBasename[$key]) }
    }
    return $hits
}

$report = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem $mocDir -Filter "MOC - *.md" | Sort-Object Name | ForEach-Object {
    $mocFile  = $_
    $bytes    = [System.IO.File]::ReadAllBytes($mocFile.FullName)
    $hasBom   = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text     = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $changed  = $false

    $allMatches = [regex]::Matches($text, '\[\[([^\]]+)\]\]')

    foreach ($m in $allMatches) {
        $raw      = $m.Groups[1].Value
        $target   = ($raw -split '\|')[0].Trim()
        $alias    = if ($raw -match '\|') { ($raw -split '\|', 2)[1] } else { $null }
        $basename = (Split-Path $target -Leaf)
        $key      = $basename.ToLower()

        if ($byBasename.ContainsKey($key)) { continue }   # Exists - skip

        $action      = ""
        $replacement = $null

        # Strategy 1: starts-with (truncated filenames)
        # IMPORTANT: wrap in @() to prevent PowerShell from unwrapping a single-element
        # List[string] into a plain string (which would make $sw[0] return a char, not path)
        $sw = @(Find-StartsWith $basename)
        if ($sw.Count -eq 1) {
            $newBase     = [System.IO.Path]::GetFileNameWithoutExtension($sw[0])
            $replacement = if ($alias) { "[[${newBase}|${alias}]]" } else { "[[${newBase}]]" }
            $action      = "Updated -> $newBase"
        } elseif ($sw.Count -gt 1) {
            $aw = @(Find-AllWords $basename)
            if ($aw.Count -eq 1) {
                $newBase     = [System.IO.Path]::GetFileNameWithoutExtension($aw[0])
                $replacement = if ($alias) { "[[${newBase}|${alias}]]" } else { "[[${newBase}]]" }
                $action      = "Updated -> $newBase"
            } else {
                $action = "Removed (ambiguous: $($sw.Count) candidates)"
            }
        } else {
            # Strategy 2: all words present
            $aw = @(Find-AllWords $basename)
            if ($aw.Count -eq 1) {
                $newBase     = [System.IO.Path]::GetFileNameWithoutExtension($aw[0])
                $replacement = if ($alias) { "[[${newBase}|${alias}]]" } else { "[[${newBase}]]" }
                $action      = "Updated -> $newBase"
            } elseif ($aw.Count -gt 1) {
                $action = "Removed (ambiguous: $($aw.Count) word-match candidates)"
            } else {
                $action = "Removed (not found in vault)"
            }
        }

        $oldWikilink = "[[${raw}]]"
        if ($replacement) {
            $text    = $text.Replace($oldWikilink, $replacement)
            $changed = $true
        } else {
            $escapedRaw  = [regex]::Escape($raw)
            $linePattern = "(?m)^- \[\[$escapedRaw\]\][^\r\n]*\r?\n?"
            $newText     = [regex]::Replace($text, $linePattern, '')
            if ($newText -ne $text) { $text = $newText; $changed = $true }
        }

        $mocName = ($mocFile.Name -replace '\.md$', '')
        $entry   = New-Object PSCustomObject -Property ([ordered]@{
            MOC        = $mocName
            BrokenLink = $basename
            Action     = $action
        })
        $report.Add($entry)
    }

    if ($changed) {
        $text = [regex]::Replace($text, "(\r?\n){3,}", "`n`n")
        $out  = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($text) } else { $enc.GetBytes($text) }
        [System.IO.File]::WriteAllBytes($mocFile.FullName, $out)
    }
}

Write-Host "`n=== MOC LINK FIX REPORT ===`n"
$report | Group-Object MOC | ForEach-Object {
    Write-Host "[$($_.Name)]"
    $_.Group | ForEach-Object {
        Write-Host "  $($_.BrokenLink)"
        Write-Host "    -> $($_.Action)"
    }
    Write-Host ""
}

$updated = ($report | Where-Object { $_.Action -like "Updated*" }).Count
$removed = ($report | Where-Object { $_.Action -notlike "Updated*" }).Count
Write-Host "Total: $updated links updated, $removed links removed."
