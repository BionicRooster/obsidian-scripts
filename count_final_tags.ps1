# Count files with tech tags from recent modifications

$vaultRoot = 'D:\Obsidian\Main'

# Get all files modified in last 8 hours
$allFiles = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-8) -and `
    $_.FullName -notlike "*09 - Kindle*" -and `
    $_.FullName -notlike "*MOC*"
}

$withTech = 0
$errors = 0

foreach ($file in $allFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        if ($content -match '#tech') {
            $withTech++
        }
    } catch {
        $errors++
    }
}

Write-Host "Files modified with #tech tag: $withTech" -ForegroundColor Green
Write-Host "Access errors: $errors" -ForegroundColor Yellow
