# Remove nav properties from frontmatter and outgoing wikilinks from body
# in Kindle Clippings files

$folder = "D:\Obsidian\Main\09 - Kindle Clippings"

function CleanFile($path, $removeNavFromFM, $removeBodyPattern) {
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $original = $content
    
    if ($removeNavFromFM) {
        # Remove nav: line from frontmatter (any value)
        $content = $content -replace '(?m)^nav:.*\r?\n', ''
    }
    if ($removeBodyPattern) {
        foreach ($pat in $removeBodyPattern) {
            $content = $content -replace $pat, ''
        }
    }
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Cleaned: $(Split-Path $path -Leaf)"
    }
}

# Files with nav in frontmatter only
CleanFile "$folder\Dorfman-Mattelart-How to Read Donald Duck.md" $true $null
CleanFile "$folder\Kurose-Ross-Computer Networking.md" $true $null
CleanFile "$folder\Lessig-One Way Forward.md" $true $null
CleanFile "$folder\Medina-Americas Sacred Calling.md" $true @('(?m)^\*\*Navigation:\*\*.*\[\[MOC.*?\]\].*\r?\n')
CleanFile "$folder\The Seven Wonders of Washington State.md" $true $null
CleanFile "$folder\Thinking, Fast and Slow.md" $true $null

# Files with outgoing wikilinks in body but no nav in frontmatter
# Kahneman - remove Related Notes section before # heading
$kahnPath = "$folder\Kahneman-Thinking, Fast and Slow.md"
$kahn = [System.IO.File]::ReadAllText($kahnPath, [System.Text.Encoding]::UTF8)
$kahn = $kahn -replace '(?s)## Related Notes\s*\n(- \[\[.*?\]\]\s*\n)+\s*', ''
[System.IO.File]::WriteAllText($kahnPath, $kahn, [System.Text.Encoding]::UTF8)
Write-Host "Cleaned Related Notes: Kahneman-Thinking, Fast and Slow.md"

# Hawks-Berger - remove Navigation line with wikilinks
CleanFile "$folder\Hawks-Berger-Cave of Bones.md" $false @('(?m)^\*\*Navigation:\*\*.*\[\[MOC.*?\]\].*\r?\n')

# Newport - remove Navigation line with wikilinks
CleanFile "$folder\Newport-Slow Productivity.md" $false @('(?m)^\*\*Navigation:\*\*.*\[\[MOC.*?\]\].*\r?\n')

# Tellinger - remove Navigation line with wikilinks
CleanFile "$folder\Tellinger-Temples of The African Gods.md" $false @('(?m)^\*\*Navigation:\*\*.*\[\[MOC.*?\]\].*\r?\n')

# Warren - remove Navigation line with wikilinks
CleanFile "$folder\Warren-Two Winters in a Tipi.md" $false @('(?m)^\*\*Navigation:\*\*.*\[\[MOC.*?\]\].*\r?\n')

Write-Host "Done."
