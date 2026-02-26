# check_moc_links.ps1
# Scans all MOC files for broken wikilinks, attempts to find renamed/moved targets,
# reports action taken for each broken link.

$vaultPath = "D:\Obsidian\Main"
$mocDir    = "$vaultPath\00 - Home Dashboard"
$enc       = [System.Text.Encoding]::UTF8

# Build a lookup: basename (no extension, lowercase) -> array of full paths
Write-Host "Building vault file index..."
$fileIndex = @{}
Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | ForEach-Object {
    $key = $_.BaseName.ToLower()
    if (-not $fileIndex.ContainsKey($key)) { $fileIndex[$key] = @() }
    $fileIndex[$key] += $_.FullName
}
Write-Host "  Indexed $($fileIndex.Count) unique basenames."

# Helper: resolve a wikilink target to a vault file path
# Wikilinks can be [[Note]], [[path/Note]], [[Note|alias]]
function Resolve-WikiLink($raw) {
    # Strip alias portion
    $target = ($raw -split '\|')[0].Trim()
    # Strip leading path components for simple basename lookup
    $basename = (Split-Path $target -Leaf)
    $key = $basename.ToLower()
    if ($fileIndex.ContainsKey($key)) {
        return $fileIndex[$key]   # may be multiple matches
    }
    return @()
}

$report = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem $mocDir -Filter "MOC - *.md" | Sort-Object Name | ForEach-Object {
    $mocFile = $_
    $bytes   = [System.IO.File]::ReadAllBytes($mocFile.FullName)
    $hasBom  = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text    = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    # Extract all wikilinks
    $wikilinks = [regex]::Matches($text, '\[\[([^\]]+)\]\]') | ForEach-Object { $_.Groups[1].Value }

    foreach ($raw in $wikilinks) {
        $target  = ($raw -split '\|')[0].Trim()
        $basename = (Split-Path $target -Leaf)
        $key     = $basename.ToLower()

        $matches = Resolve-WikiLink $raw

        if ($matches.Count -eq 0) {
            # Broken link - file not found anywhere in vault
            $report.Add([PSCustomObject]@{
                MOC    = $mocFile.Name
                Link   = $raw
                Status = "BROKEN - not found"
                Action = "Remove"
            })
        }
        # If found, link is valid (even if moved - Obsidian resolves by name)
    }
}

# Display broken links grouped by MOC
$broken = $report | Where-Object { $_.Status -like "BROKEN*" }
Write-Host "`nBroken links found: $($broken.Count)"
$broken | Group-Object MOC | ForEach-Object {
    Write-Host "`n  $($_.Name):"
    $_.Group | ForEach-Object { Write-Host "    [[$(($_.Link -split '\|')[0])]]" }
}
