# Move LSA folder into 01\Baha'i and rename Be* -> BE* files
# Also update [[Be1xx]] wikilinks throughout vault

$ErrorActionPreference = 'Stop'
$vault = 'D:\Obsidian\Main'

# Locate 01\Baha'i folder via wildcard (avoids diacritical inline embedding)
$bahaiFolder = Get-ChildItem (Join-Path $vault '01') -Directory | Where-Object { $_.Name -like 'Bah*' } | Select-Object -First 1
if (-not $bahaiFolder) {
    Write-Error "Could not find 01\Baha'i folder"
    exit 1
}
Write-Output "Target parent: $($bahaiFolder.FullName)"

# -------------------------------------------------------------------
# Step 1: Move LSA folder into 01\Baha'i
# -------------------------------------------------------------------
Write-Output "`n=== Step 1: Move LSA folder ==="
$lsaSrc = Join-Path $vault 'LSA'
$lsaDst = Join-Path $bahaiFolder.FullName 'LSA'

if (Test-Path -LiteralPath $lsaDst) {
    Write-Output "  WARNING: $lsaDst already exists - skipping move"
} else {
    Move-Item -LiteralPath $lsaSrc -Destination $lsaDst
    Write-Output "  Moved: $lsaSrc"
    Write-Output "      -> $lsaDst"
}

# -------------------------------------------------------------------
# Step 2: Rename Be*.md -> BE*.md (two-step for Windows case sensitivity)
#         Also add nav property if missing
# -------------------------------------------------------------------
Write-Output "`n=== Step 2: Rename Be* -> BE* and add nav ==="
$yearDir = Join-Path $lsaDst 'Year in Review'
$bahaiMOCLink = "[[MOC - Bah$([char]0x00e1)'$([char]0x00ed) Faith]]"

$beFiles = Get-ChildItem $yearDir -Filter 'Be*.md' | Where-Object { $_.Name -cmatch '^Be\d' }
foreach ($f in $beFiles) {
    $oldPath = $f.FullName
    $newName = 'BE' + $f.Name.Substring(2)   # 'Be161.md' -> 'BE161.md'
    $newPath  = Join-Path $yearDir $newName
    $tmpName  = $newName + '.tmp'
    $tmpPath  = Join-Path $yearDir $tmpName

    # Two-step rename (required for Windows case-only changes)
    Rename-Item -LiteralPath $oldPath  -NewName $tmpName
    Rename-Item -LiteralPath $tmpPath  -NewName $newName
    Write-Output "  Renamed: $($f.Name) -> $newName"

    # Add nav property if not present
    $content = Get-Content -LiteralPath $newPath -Encoding UTF8 -Raw
    if ($content -notmatch 'nav:') {
        $content = $content -replace '(^---\r?\n)', "`$1nav: `"$bahaiMOCLink`"`n"
        Set-Content -LiteralPath $newPath -Value $content -Encoding UTF8 -NoNewline
        Write-Output "    + added nav"
    }
}
if (-not $beFiles) { Write-Output "  No Be*.md files found (already renamed?)" }

# -------------------------------------------------------------------
# Step 3: Update [[Be1xx]] -> [[BE1xx]] wikilinks vault-wide
#         Pattern: [[Be followed by a digit
#         Safe: 'Be' + digit is unambiguously a Baha'i Era year in this vault
# -------------------------------------------------------------------
Write-Output "`n=== Step 3: Update [[Be1xx]] wikilinks ==="

$filesToUpdate = @(
    Join-Path $vault 'People Index.md'
)
# Add all 15 - People files that contain the pattern
Get-ChildItem (Join-Path $vault '15 - People') -Filter '*.md' | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($c -cmatch '\[\[Be\d') { $filesToUpdate += $_.FullName }
}

foreach ($filePath in $filesToUpdate) {
    $c = Get-Content -LiteralPath $filePath -Encoding UTF8 -Raw
    $fixed = $c -replace '\[\[Be(\d)', '[[BE$1'
    if ($fixed -ne $c) {
        Set-Content -LiteralPath $filePath -Value $fixed -Encoding UTF8 -NoNewline
        $count = ([regex]::Matches($c, '\[\[Be\d')).Count
        Write-Output "  Updated $count link(s) in: $(Split-Path $filePath -Leaf)"
    }
}

Write-Output "`n=== Done ==="
