# Add nav properties to classified files
$vault = "D:\Obsidian\Main"

# Define folder -> MOC mappings
$mocMappings = @{
    "01\Science" = "[[MOC - Science & Nature]]"
    "01\Technology" = "[[MOC - Technology & Computers]]"
    "01\Health" = "[[MOC - Health & Nutrition]]"
}

foreach ($folder in $mocMappings.Keys) {
    $folderPath = Join-Path $vault $folder
    $nav = $mocMappings[$folder]

    $files = Get-ChildItem -Path $folderPath -Filter "*.md" -File | Where-Object {
        # Only process recent files (last 7 days)
        $_.CreationTime -gt (Get-Date).AddDays(-7)
    }

    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        # Skip if already has nav property
        if ($content -match 'nav:') {
            Write-Host "SKIP (has nav): $($file.Name)"
            continue
        }

        # Add nav property before closing --- in YAML frontmatter
        if ($content -match '^---\r?\n') {
            # Find the closing ---
            $newContent = $content -replace '(^---\r?\n[\s\S]*?)(tags:\r?\n(?:  - [^\r\n]+\r?\n)+)(---)', "`$1`$2nav: `"$nav`"`r`n`$3"

            if ($newContent -ne $content) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Host "UPDATED: $($file.Name) with nav: $nav"
            } else {
                Write-Host "NO CHANGE: $($file.Name)"
            }
        }
    }
}
