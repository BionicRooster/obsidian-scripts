# Fix duplicate nav lines inserted after closing --- by AddNav function
# Pattern: after frontmatter closing ---, there should not be a nav: line
$clippings = "D:\Obsidian\Main\10 - Clippings"
$fixed = 0

$files = Get-ChildItem -LiteralPath $clippings -Filter "*.md" | Where-Object { $_.Name -ne "10 - Clippings.md" }

foreach ($file in $files) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw

    # Find the closing --- of the frontmatter
    # Pattern: a line that is just "---" followed by nav: line should be removed
    # The frontmatter ends at the first --- that appears after the opening ---
    # Then there should be a blank line or content, NOT another nav: line

    # Pattern to remove: "---\nnav: "..." \n" appearing AFTER frontmatter
    # We can detect this by finding "---\nnav:" where it's not the first ---
    $pattern = '(?m)^---\r?\nnav: "[^"]*"\r?\n'
    $matches = [regex]::Matches($c, $pattern)

    if ($matches.Count -gt 1) {
        # More than one "---\nnav:" sequence - the second one is spurious
        # Remove all but the first occurrence
        $firstMatch = $matches[0]
        # Replace occurrences after the first
        for ($i = $matches.Count - 1; $i -ge 1; $i--) {
            $m = $matches[$i]
            # Remove the "nav: "..."\n" part (keep the "---\n")
            $navLine = "nav: " + $m.Value.Split("`n")[1] + "`n"
            $removeStart = $m.Index + 4  # skip past "---\n"
            $removeLength = $navLine.Length
            $c = $c.Substring(0, $removeStart) + $c.Substring($removeStart + $removeLength)
        }
        [System.IO.File]::WriteAllText($file.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "Fixed duplicate nav in: $($file.Name)"
        $fixed++
    }
}

Write-Host "`nFixed $fixed files."
