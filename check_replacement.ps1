# Check for files containing U+FFFD replacement character
$replacementChar = [char]65533
$found = 0

Get-ChildItem -Path "D:\Obsidian\Main" -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        if ($content.Contains($replacementChar)) {
            Write-Host $_.FullName
            $found++
        }
    }
    catch {
        # Skip files with read errors
    }
}

Write-Host ""
Write-Host "Total files with replacement character: $found" -ForegroundColor Cyan
