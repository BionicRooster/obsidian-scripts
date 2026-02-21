# Verify files have the tech tag

$vaultRoot = 'D:\Obsidian\Main'

# Sample files to verify
$filesToCheck = @(
    'Build a Modern Computer from First Principles',
    'FiberFirst installation',
    'DateTime data in Microsoft Access',
    'Greenscreen backdrop',
    'Hardware',
    'Linux'
)

Write-Host "Verification of #tech tag addition:`n" -ForegroundColor Blue

foreach ($fileName in $filesToCheck) {
    $files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $_.BaseName -eq $fileName
    }

    if ($files) {
        $content = [System.IO.File]::ReadAllText($files.FullName, [System.Text.Encoding]::UTF8)
        if ($content -match '#tech') {
            Write-Host "✓ $($files.BaseName): HAS #tech TAG" -ForegroundColor Green
        } else {
            Write-Host "✗ $($files.BaseName): MISSING #tech TAG" -ForegroundColor Red
        }
    } else {
        Write-Host "? ${fileName}: NOT FOUND" -ForegroundColor Yellow
    }
}
