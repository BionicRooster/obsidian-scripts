# Script to check for curly apostrophes in recent file names and rename if needed
# Vault path
$vaultRoot = 'C:\Users\awt\Sync\Obsidian'
# Cutoff date for recent files
$cutoff = (Get-Date).AddDays(-2)

# Collect recent files excluding system folders
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter '*.md' | Where-Object {
    $_.CreationTime -ge $cutoff -and
    $_.FullName -notmatch '\\People\\' -and
    $_.FullName -notmatch '\\Journals\\' -and
    $_.FullName -notmatch '\\00 - Journal\\' -and
    $_.FullName -notmatch '\\Templates\\' -and
    $_.FullName -notmatch '\.resources' -and
    $_.FullName -notmatch '\\images\\' -and
    $_.FullName -notmatch '\\Attachments\\' -and
    $_.FullName -notmatch '\\00 - Images\\' -and
    $_.FullName -notmatch '\\00 - Home Dashboard\\' -and
    $_.Name -ne 'Orphan Files.md' -and
    $_.Name -ne 'People Index.md'
}

foreach ($file in $files) {
    # Check if filename contains curly apostrophe (U+2019)
    if ($file.Name -match [char]0x2019) {
        # Build corrected name by replacing curly apostrophe with straight apostrophe
        $newName = $file.Name -replace [char]0x2019, "'"
        $newPath = Join-Path $file.DirectoryName $newName
        Write-Output "RENAMING: $($file.Name) -> $newName"
        Rename-Item -Path $file.FullName -NewName $newName
    } else {
        Write-Output "OK: $($file.Name)"
    }
}
