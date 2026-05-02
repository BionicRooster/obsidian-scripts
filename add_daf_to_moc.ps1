# Link the DAF video note to FOL MOC and Finance MOC

$dashDir = 'D:\Obsidian\Main\00 - Home Dashboard'
$noteBase = 'CBA Coffee Chat - The DAF Opportunity - How Nonprofits Can Capture More Donor-Advised Fund Gifts'
$link = "- [[$noteBase]]"

function Add-LinkToSection {
    param([string]$MOCPath, [string]$Section, [string]$LinkLine)
    $content = Get-Content -LiteralPath $MOCPath -Encoding UTF8 -Raw
    if ($content -match [regex]::Escape($noteBase)) {
        Write-Output "  Already present in $(Split-Path $MOCPath -Leaf)"
        return
    }
    $idx = $content.IndexOf($Section)
    if ($idx -lt 0) { Write-Output "  WARNING: section '$Section' not found in $(Split-Path $MOCPath -Leaf)"; return }
    $after = $idx + $Section.Length
    $nextSect = [regex]::Match($content.Substring($after), '(?m)^#{1,3} ')
    if ($nextSect.Success) {
        $insertPos = $after + $nextSect.Index
        while ($insertPos -gt ($after + 2) -and $content[$insertPos - 1] -match '[\r\n]') { $insertPos-- }
        $insertPos++
        $content = $content.Substring(0, $insertPos) + "`n$LinkLine" + $content.Substring($insertPos)
    } else {
        $content = $content.TrimEnd() + "`n$LinkLine`n"
    }
    Set-Content -LiteralPath $MOCPath -Value $content -Encoding UTF8 -NoNewline
    Write-Output "  Added to $(Split-Path $MOCPath -Leaf) > $Section"
}

# FOL MOC - FOL Operations & Procedures section
$folMOC = Join-Path $dashDir 'MOC - Friends of the Georgetown Public Library.md'
Add-LinkToSection -MOCPath $folMOC -Section '## FOL Operations & Procedures' -LinkLine $link

# Finance MOC - Financial Management section
$finMOC = Join-Path $dashDir 'MOC - Finance & Investment.md'
Add-LinkToSection -MOCPath $finMOC -Section '## Financial Management' -LinkLine $link

Write-Output "Done"
