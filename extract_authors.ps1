# Extract only clean author names from frontmatter author: fields across all .md files
# This is the most reliable source of real human names

$vaultRoot = "D:\Obsidian\Main"
$results = @{}

# Get all .md files excluding noisy folders
$files = Get-ChildItem -Path $vaultRoot -Recurse -File -Filter "*.md" | Where-Object {
    $_.FullName -notlike '*\15 - People\*' -and
    $_.FullName -notlike '*\00 - Home Dashboard\*' -and
    $_.FullName -notlike '*\00 - Journal\*' -and
    $_.FullName -notlike '*\Templates\*' -and
    $_.Name -ne 'People Index.md'
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Encoding UTF8 -Raw
    if (-not $content) { continue }
    
    # Only look at frontmatter (between first two ---)
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $Matches[1]
        
        # Find author block - handle various formats
        # Format 1: author: "Name" or author: Name
        if ($frontmatter -match '(?m)^author:\s*"?([^"\n\[\]]+)"?\s*$') {
            $name = $Matches[1].Trim().Trim('"').Trim("'")
            if ($name -match '^[A-Z][a-z]' -and $name.Length -gt 3 -and $name -notmatch '^\[') {
                if (-not $results.ContainsKey($name)) { $results[$name] = @() }
                $results[$name] += $file.FullName.Replace($vaultRoot + '\', '')
            }
        }
        
        # Format 2: author:\n  - "Name" or  - [[Name]]
        $authorSection = $false
        foreach ($line in ($frontmatter -split '\n')) {
            if ($line -match '^author') { $authorSection = $true; continue }
            if ($authorSection -and $line -match '^\s+-\s+"?(.+?)"?\s*$') {
                $name = $Matches[1].Trim().Trim('"').Trim("'")
                # Remove wikilink brackets
                $name = $name -replace '^\[\[(.+)\]\]$', '$1'
                if ($name -match '^[A-Z][a-z]' -and $name.Length -gt 3 -and $name -notmatch '^\[' -and $name -notmatch '@') {
                    if (-not $results.ContainsKey($name)) { $results[$name] = @() }
                    $results[$name] += $file.FullName.Replace($vaultRoot + '\', '')
                }
            } elseif ($authorSection -and $line -match '^\S' -and $line -notmatch '^author') {
                $authorSection = $false
            }
        }
    }
}

# Output sorted by name
$output = @()
foreach ($name in ($results.Keys | Sort-Object)) {
    $output += "NAME: $name"
    foreach ($f in ($results[$name] | Sort-Object -Unique)) {
        $output += "  FILE: $f"
    }
    $output += ""
}

$output | Out-File "C:\Users\awt\authors_clean.txt" -Encoding UTF8
Write-Host "Total unique authors: $($results.Count)"
