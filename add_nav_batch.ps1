# Add nav property to files that are missing it
# UTF-8 safe

function Add-NavToFile {
    param([string]$FilePath, [string]$NavValue)
    if (-not (Test-Path $FilePath)) { Write-Host "NOT FOUND: $FilePath"; return }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    if ($content -match '(?m)^nav:') { Write-Host "ALREADY HAS NAV: $FilePath"; return }
    $pattern = '(?s)^(---\r?\n.*?\r?\n)(---)'
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, "`$1nav: `"[[$NavValue]]`"`n`$2"
        [System.IO.File]::WriteAllText($FilePath, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "UPDATED: $FilePath"
    } else { Write-Host "NO FRONTMATTER: $FilePath" }
}

$vault = 'D:\Obsidian\Main'

# Files needing nav added
$files = @(
    @{ path = "$vault\01\Health\How to Use Google Maps.md"; nav = "MOC - Health & Nutrition" },
    @{ path = "$vault\01\Health\Infant Respiratory Distress Syndrome Hyaline Membrane Disease.md"; nav = "MOC - Health & Nutrition" },
    @{ path = "$vault\01\PKM\04 - Indexes.md"; nav = "MOC - Personal Knowledge Management" },
    @{ path = "$vault\01\Science\The Magic of Moss and What It Teaches Us About the Art of Attentiveness to Life at All Scales.md"; nav = "MOC - Science & Nature" },
    @{ path = "$vault\01\Home\The McNamara Fallacy.md"; nav = "MOC - Home & Practical Life" },
    @{ path = "$vault\01\Home\Chiasmus.md"; nav = "MOC - Home & Practical Life" }
)

foreach ($f in $files) {
    Add-NavToFile -FilePath $f.path -NavValue $f.nav
}

# Handle Bahá'í files with special characters separately using Get-ChildItem
$bahaiDir = "$vault\01\Bah$([char]0x00e1)'$([char]0x00ed)"
$bahaiNav = "MOC - Bah$([char]0x00e1)'$([char]0x00ed) Faith"

$bahaiTargets = @(
    "Bah$([char]0x00e1)'$([char]0x00ed) - Life on Other Planets.md"
)

foreach ($name in $bahaiTargets) {
    $fullPath = Join-Path $bahaiDir $name
    Add-NavToFile -FilePath $fullPath -NavValue $bahaiNav
}

Write-Host "Done."
