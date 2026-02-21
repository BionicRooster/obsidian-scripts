# Move categorized files from Gmail to appropriate 01 folders
$vault = "D:\Obsidian\Main"
$gmail = "$vault\04 - GMail"

$moved = @()

# Define categories (pattern -> destination)
$categories = @(
    @{ Pattern = "^iTunes Single of the Week"; Dest = "01\Music" }
    @{ Pattern = "Long Long Honeymoon"; Dest = "01\Travel" }
    @{ Pattern = "The Fit RV"; Dest = "01\Travel" }
    @{ Pattern = "Cool Tears"; Dest = "01\Travel" }
    @{ Pattern = "shore excursion"; Dest = "01\Travel" }
    @{ Pattern = "Nassem and Neda Khozein"; Dest = "01\Baha'i" }
    @{ Pattern = "Emailing to Evernote"; Dest = "01\PKM" }
    @{ Pattern = "Evernote \+ NYT"; Dest = "01\PKM" }
    @{ Pattern = "IFTTT"; Dest = "01\Technology" }
)

foreach ($cat in $categories) {
    $destPath = Join-Path $vault $cat.Dest

    $files = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object { $_.Name -match $cat.Pattern }

    foreach ($file in $files) {
        $targetPath = Join-Path $destPath $file.Name

        if (Test-Path -LiteralPath $targetPath) {
            Write-Host "SKIP (exists): $($file.Name)"
            continue
        }

        Move-Item -LiteralPath $file.FullName -Destination $destPath
        $moved += [PSCustomObject]@{
            File = $file.Name
            Destination = $cat.Dest
        }
        Write-Host "MOVED: $($file.Name) -> $($cat.Dest)"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Total files moved: $($moved.Count)"
