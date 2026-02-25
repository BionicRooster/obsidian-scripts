# Extract author fields from all Kindle Clippings files
$folder = "D:\Obsidian\Main\09 - Kindle Clippings"
$files = Get-ChildItem $folder -Filter "*.md" | Sort-Object Name

foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $inFrontmatter = $false
    $inAuthor = $false
    $fmCount = 0
    $authors = @()
    $title = ""
    
    foreach ($line in $lines) {
        if ($line -match '^---') {
            $fmCount++
            if ($fmCount -eq 2) { break }
            $inFrontmatter = $true
            continue
        }
        if (-not $inFrontmatter) { continue }
        
        # Title
        if ($line -match '^title:\s*["\x27]?(.+?)["\x27]?\s*$') {
            $title = $Matches[1].Trim('"').Trim("'")
        }
        
        # Author inline
        if ($line -match '^author:\s*["\x27]?([^"\x27\[\]\n]+)["\x27]?\s*$') {
            $a = $Matches[1].Trim()
            if ($a -and $a -ne '' -and $a -notmatch '^\s*$') { $authors += $a }
            $inAuthor = $false
        }
        # Author list start
        elseif ($line -match '^author(s)?:\s*$') {
            $inAuthor = $true
        }
        # Author list item
        elseif ($inAuthor -and $line -match '^\s+-\s+["\x27]?\[?\[?(.+?)\]?\]?["\x27]?\s*$') {
            $a = $Matches[1].Trim().Trim('"').Trim("'")
            if ($a -and $a -ne '') { $authors += $a }
        }
        elseif ($inAuthor -and $line -notmatch '^\s+-') {
            $inAuthor = $false
        }
    }
    
    Write-Host "FILE: $($f.Name)"
    Write-Host "TITLE: $title"
    foreach ($a in $authors) { Write-Host "AUTHOR: $a" }
    Write-Host "---"
}
