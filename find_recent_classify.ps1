# find_recent_classify.ps1 - Find recently CREATED vault files for classification
# Uses CreationTime only (not LastWriteTime) to avoid picking up files
# that were merely modified by automated scripts.

$vaultPath = 'D:\Obsidian\Main'   # Root of Obsidian vault
$cutoff    = (Get-Date).AddDays(-2)  # Look back 2 days by creation date

$results = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse |
  Where-Object { $_.CreationTime -ge $cutoff } |  # Created recently
  Where-Object {
    $rel = $_.FullName.Replace($vaultPath + '\', '')
    # Exclude system/support folders and MOC files
    $rel -notmatch '\\People\\'              -and
    $rel -notmatch '\\Journals\\'            -and
    $rel -notmatch '\\00 - Journal\\'        -and
    $rel -notmatch '\\0 - Journal\\'         -and
    $rel -notmatch '\\05 - Templates\\'      -and
    $rel -notmatch '\.resources'             -and
    $rel -notmatch '\\Attachments\\'         -and
    $rel -notmatch '\\00 - Images\\'         -and
    $rel -notmatch '\\images\\'              -and
    $rel -notmatch '\\00 - Home Dashboard\\' -and
    $_.Name -ne 'Orphan Files.md'            -and
    $_.Name -ne 'Empty Notes.md'             -and
    $_.Name -notlike 'MOC - *.md'
  } |
  ForEach-Object {
    $rel    = $_.FullName.Replace($vaultPath + '\', '')
    $inRoot = $rel -notmatch '\\'   # No backslash = directly in vault root
    [PSCustomObject]@{
      Name     = $_.BaseName
      RelPath  = $rel
      FullPath = $_.FullName
      Created  = $_.CreationTime.ToString('yyyy-MM-dd HH:mm')
      InRoot   = $inRoot
    }
  } |
  Sort-Object Created -Descending

$results | Format-Table Name, RelPath, InRoot, Created -AutoSize
Write-Host "Total: $($results.Count) files"
