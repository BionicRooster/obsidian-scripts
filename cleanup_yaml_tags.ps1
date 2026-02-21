# Clean up files where tags appear both in YAML and outside

$vaultRoot = 'D:\Obsidian\Main'
$files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddHours(-3)
}

$fixed = 0
$problemFiles = @()

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Check if YAML front matter exists and there's also tags outside
    if ($content -match '(?m)^---.*?^---\s*\n' -and $content -match '(?m)^---.*?^---\s*\n.*?^tags:') {
        $problemFiles += $file.BaseName

        # Extract YAML part
        $yamlMatch = $content -match '(?m)^---(.*?)^---'
        if ($yamlMatch) {
            $yamlBlock = $matches[1]

            # Remove the entire YAML section
            $afterYaml = $content -replace '(?m)^---(.*?)^---\s*\n', ''

            # Remove any standalone tags: lines that appear after YAML
            $afterYaml = $afterYaml -replace '(?m)^tags:.*\n', ''

            # Add clean YAML back with tags if it didn't have them
            if ($yamlBlock -notmatch 'tags:') {
                $content = "---`ntags: #tech`n---`n`n$afterYaml"
            } else {
                $content = "---$yamlBlock---`n`n$afterYaml"
            }

            # Write back
            $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBOM)

            $fixed++
            Write-Host "CLEANED: $($file.BaseName)" -ForegroundColor Cyan
        }
    }
}

Write-Host "`nFixed files: $fixed" -ForegroundColor Blue
if ($problemFiles.Count -gt 0) {
    Write-Host "Problem files cleaned: $($problemFiles -join ', ')" -ForegroundColor Yellow
}
