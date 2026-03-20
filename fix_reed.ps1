# fix_reed.ps1 - Fix Reed Island filename and Tellinger MOC entry

$reedDir = 'D:\Obsidian\Main\03 - Completed Projects\2024 Columbia River Trip'
$mocDir  = 'D:\Obsidian\Main\00 - Home Dashboard'

# Find the Reed Island file (whatever its actual name is)
$reedFile = Get-ChildItem $reedDir | Where-Object { $_.Name -match 'Reed' -and $_.Name -match 'Steigerwald' } | Select-Object -First 1

if ($null -eq $reedFile) {
    Write-Host 'Reed Island file not found' -ForegroundColor Red
} else {
    Write-Host "Found: $($reedFile.Name)"
    # Show actual char codes in the name
    $reedFile.Name.ToCharArray() | ForEach-Object {
        $code = [int]$_
        $hex  = '{0:X4}' -f $code
        Write-Host "  '$_' U+$hex"
    }

    $newName = 'Reed Island & Steigerwald Wildlife Refuge.md'
    $newPath = Join-Path $reedDir $newName

    if ($reedFile.Name -eq $newName) {
        Write-Host 'Already has correct name' -ForegroundColor DarkGray
    } elseif (Test-Path $newPath) {
        Write-Host 'Destination already exists' -ForegroundColor DarkGray
    } else {
        Rename-Item -LiteralPath $reedFile.FullName -NewName $newName
        Write-Host "Renamed to: $newName" -ForegroundColor Green
    }
}

# Helper: read UTF-8 with BOM support
function Read-Utf8 {
    param([string]$Path)
    $bytes  = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) } else { [System.Text.Encoding]::UTF8.GetString($bytes) }
    return [PSCustomObject]@{ Text = $text; HasBom = $hasBom }
}

function Write-Utf8 {
    param([string]$Path, [string]$Text, [bool]$HasBom)
    $enc      = [System.Text.Encoding]::UTF8
    $outBytes = $enc.GetBytes($Text)
    if ($HasBom) { $outBytes = [byte[]](0xEF, 0xBB, 0xBF) + $outBytes }
    [System.IO.File]::WriteAllBytes($Path, $outBytes)
}

# Add Tellinger to Science MOC after "What Mummy DNA Reveals"
# (Ukraine's anchor failed due to apostrophe type; using the next entry instead)
Write-Host ''
Write-Host 'Adding Tellinger to Science & Nature MOC...' -ForegroundColor Cyan

$sciMocPath = Join-Path $mocDir 'MOC - Science & Nature.md'
$f = Read-Utf8 $sciMocPath

$linkText   = 'Tellinger-Temples of The African Gods'
$anchor     = '- [[What Mummy DNA Reveals]]'          # Anchor that definitely exists (no apostrophe)

if ($f.Text -match [regex]::Escape($linkText)) {
    Write-Host '  Already present' -ForegroundColor DarkGray
} elseif ($f.Text -notmatch [regex]::Escape($anchor)) {
    Write-Host "  WARN: anchor not found: $anchor" -ForegroundColor Yellow
} else {
    # Insert BEFORE "What Mummy DNA Reveals" so Tellinger (T) sorts before W
    $newText = $f.Text -replace [regex]::Escape($anchor), "- [[$linkText]]`n$anchor"
    Write-Utf8 $sciMocPath $newText $f.HasBom
    Write-Host "  Added [[$linkText]]" -ForegroundColor Green
}
