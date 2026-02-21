# Find markdown files outside of 01 subdirectories that might need classification
$vaultPath = 'D:\Obsidian\Main'

# Directories to skip entirely
$excludePatterns = @(
    '\\\.obsidian\\',
    '\\\.smart-env\\',
    '\\People\\',
    '\\Journals\\',
    '\\00 - Journal\\',
    '\\Templates\\',
    '\\\.resources',
    '\\images\\',
    '\\Attachments\\',
    '\\00 - Images\\',
    '\\00 - Home Dashboard\\',
    '\\01\\',
    '\\09 - Kindle Clippings\\'
)

# Find files in 10 - Clippings and 20 - Permanent Notes (common unclassified locations)
$locations = @(
    'D:\Obsidian\Main\10 - Clippings',
    'D:\Obsidian\Main\20 - Permanent Notes'
)

$results = @()
foreach ($loc in $locations) {
    if (Test-Path $loc) {
        $files = Get-ChildItem -Path $loc -Filter '*.md' -File
        foreach ($f in $files) {
            $relPath = $f.FullName.Replace($vaultPath + '\', '')
            $results += "$relPath"
        }
    }
}

Write-Host "Found $($results.Count) files to potentially classify"
Write-Host "---"
foreach ($r in $results) {
    Write-Host $r
}
