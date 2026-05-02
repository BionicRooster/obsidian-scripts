# Add nav property to New Mexico travel files that are missing it
$travelFiles = @(
    'D:\Obsidian\Main\01\Travel\Santa Fe Scenic Railroad.md',
    'D:\Obsidian\Main\01\Travel\Acoma Sky City - 60 mi w of Alb.md',
    'D:\Obsidian\Main\01\Travel\Pecos National Historical Park.md',
    'D:\Obsidian\Main\01\Travel\Santa Fe Plaza.md',
    'D:\Obsidian\Main\01\Travel\Turquoise Trail National Scenic Byway.md',
    'D:\Obsidian\Main\01\Travel\Cumbres & Toltec Scenic Railroad.md'
)

foreach ($f in $travelFiles) {
    if (Test-Path $f) {
        $content = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        if ($content -notmatch 'nav:') {
            # Insert nav before the closing --- of the YAML frontmatter
            # Find the second --- and insert before it
            $lines = $content -split "`n"
            $closingIdx = -1
            $inFrontmatter = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i].Trim() -eq '---') {
                    if (-not $inFrontmatter) {
                        $inFrontmatter = $true
                    } else {
                        $closingIdx = $i
                        break
                    }
                }
            }
            if ($closingIdx -gt 0) {
                $newLines = $lines[0..($closingIdx-1)] + 'nav: "[[MOC - Travel & Exploration]]"' + $lines[$closingIdx..($lines.Count-1)]
                $newContent = $newLines -join "`n"
                [System.IO.File]::WriteAllText($f, $newContent, [System.Text.Encoding]::UTF8)
                Write-Output "Updated: $(Split-Path $f -Leaf)"
            } else {
                Write-Output "No frontmatter found: $f"
            }
        } else {
            Write-Output "Already has nav: $(Split-Path $f -Leaf)"
        }
    } else {
        Write-Output "NOT FOUND: $f"
    }
}
