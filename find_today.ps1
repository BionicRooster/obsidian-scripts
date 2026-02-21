# Find markdown files created today, excluding system folders
$vaultPath = "D:\Obsidian\Main"
$today = (Get-Date).Date

# Exclusion patterns for system/non-content folders
$excludePatterns = @(
    '\\People\\',
    '\\Journals\\',
    '\\00 - Journal\\',
    '\\Templates\\',
    '\\\.resources',
    '\\images\\',
    '\\Attachments\\',
    '\\00 - Images\\',
    '\\00 - Home Dashboard\\'
)

Get-ChildItem $vaultPath -Recurse -Filter '*.md' | Where-Object {
    $file = $_
    # Check creation date is today
    if ($file.CreationTime.Date -ne $today) { return $false }
    # Check exclusion patterns
    foreach ($pat in $excludePatterns) {
        if ($file.FullName -match [regex]::Escape($pat).Replace('\\\\','\\')) { return $false }
    }
    return $true
} | ForEach-Object {
    $rel = $_.FullName.Substring($vaultPath.Length + 1)
    # Check if file has nav property
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $hasNav = $content -match '(?m)^nav:'
    # Check if file has YAML frontmatter
    $hasYaml = $content -match '^---\s*\r?\n'
    Write-Output "$($_.CreationTime.ToString('yyyy-MM-dd HH:mm'))|$hasNav|$hasYaml|$rel"
}
