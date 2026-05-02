# Add nav to the "Life on Other Planets" Bahá'í files

$navValue = "MOC - Bah$([char]0x00e1)'$([char]0x00ed) Faith"
$pattern = '(?s)^(---\r?\n.*?\r?\n)(---)'

$files = Get-ChildItem -Path 'D:\Obsidian\Main\01' -Recurse -Filter '*Life on Other Planets*'
foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match '(?m)^nav:') {
        Write-Host "ALREADY HAS NAV: $($f.FullName)"
    } elseif ($content -match $pattern) {
        $newContent = $content -replace $pattern, "`$1nav: `"[[$navValue]]`"`n`$2"
        [System.IO.File]::WriteAllText($f.FullName, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "UPDATED: $($f.FullName)"
    } else {
        Write-Host "NO FRONTMATTER: $($f.FullName)"
    }
}

# Also fix Delton West Funeral (frontmatter is not at top - has Related section before ---)
$dwtPath = "D:\Obsidian\Main\01\Bah$([char]0x00e1)'$([char]0x00ed)\Delton West Funeral.md"
$dwtContent = [System.IO.File]::ReadAllText($dwtPath, [System.Text.Encoding]::UTF8)
Write-Host "Delton West Funeral nav check:"
if ($dwtContent -match '(?m)^nav:') {
    Write-Host "ALREADY HAS NAV"
} else {
    Write-Host "First 200 chars: " + $dwtContent.Substring(0, [Math]::Min(200, $dwtContent.Length))
}
