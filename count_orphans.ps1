$vaultPath = "D:\Obsidian\Main"
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch "05 - Templates" -and
    $_.FullName -notmatch "attachments" -and
    $_.FullName -notmatch "00 - Journal" -and
    $_.FullName -notmatch "11 - Evernote" -and
    $_.FullName -notmatch "12 - OneNote" -and
    $_.FullName -notmatch "_resources" -and
    $_.BaseName -notmatch "^\d{4}-\d{2}-\d{2}$" -and
    $_.BaseName -ne "Untitled"
}
$allFilesForLinks = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
$linkedFiles = @{}
foreach ($file in $allFilesForLinks) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $m = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        foreach ($match in $m) {
            $linkTarget = $match.Groups[1].Value
            if ($linkTarget -match '/') { $linkTarget = $linkTarget.Split('/')[-1] }
            if ($linkTarget -match '#') { $linkTarget = $linkTarget.Split('#')[0] }
            $linkTarget = $linkTarget.Trim()
            if ($linkTarget) { $linkedFiles[$linkTarget] = $true }
        }
    }
}
$orphanCount = 0
$priorityOrphans = 0
foreach ($file in $allFiles) {
    if (-not $linkedFiles.ContainsKey($file.BaseName)) {
        $orphanCount++
        if ($file.FullName -match "Permanent Notes|04 - Indexes|15 - People|16 - Organizations|00 - Home Dashboard") {
            $priorityOrphans++
        }
    }
}
Write-Host "Total orphans (excluding Journal/Evernote/OneNote): $orphanCount"
Write-Host "Priority orphans (key directories): $priorityOrphans"
