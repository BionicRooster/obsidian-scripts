# Final verification: find notes not linked in any MOC
$vault = 'D:\Obsidian\Main'
$dashDir = 'D:\Obsidian\Main\00 - Home Dashboard'

# Load all MOC content
$mocFiles = Get-ChildItem $dashDir -Filter '*.md'
$allMocContent = ($mocFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw }) -join ' '

# Get candidate notes (exclude structural/special folders)
$notes = Get-ChildItem -Path $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\00 - Home Dashboard\*' -and
    $_.FullName -notlike '*\15 - People\*' -and
    $_.FullName -notlike '*\00 - Journal\*' -and
    $_.FullName -notlike '*\Journals\*' -and
    $_.FullName -notlike '*\Templates\*' -and
    $_.FullName -notlike '*\05 - Templates\*' -and
    $_.FullName -notlike '*\.resources\*' -and
    $_.FullName -notlike '*\Attachments\*' -and
    $_.FullName -notlike '*\00 - Images\*' -and
    $_.FullName -notlike '*\09 - Kindle Clippings\*' -and
    $_.Name -ne 'Orphan Files.md' -and
    $_.Name -ne 'People Index.md' -and
    $_.Name -ne 'To-Do List.md'
}

$unclassified = @()
foreach ($f in $notes) {
    $base = $f.BaseName
    if (-not ($allMocContent -match [regex]::Escape($base))) {
        $unclassified += $f.FullName
    }
}

Write-Output "Unclassified count: $($unclassified.Count)"
$unclassified | ForEach-Object { Write-Output $_ }
