# Restore missing tags in files that should have them

$vaultRoot = 'D:\Obsidian\Main'

# List of files that should have #tech tags
$filesNeedingTags = @(
    'Greenscreen backdrop',
    'Linux',
    'Hardware',
    'When the Singularity Might Occur',
    'Duplicate Detection',
    'Excel Count Function',
    'FileHippo.com Update',
    'FileZilla Has an Evil Twin that Steals FTP Logins',
    'How to control your',
    'How to Lock and Unlock a User Account in Linux',
    'Modular Spreadsheet',
    'ORDER BY Clause (Tra',
    'SourceForge.net Apex',
    'Troy Lea - Leveragin',
    'VMware KB Installing'
)

$restored = 0

foreach ($fileName in $filesNeedingTags) {
    # Search for file
    $files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $_.BaseName -eq $fileName -or $_.BaseName -like "$fileName*"
    }

    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        # Check if tags exist
        if ($content -match 'tags:.*#tech') {
            # Already has tech tag
            continue
        }

        # Check if it has YAML
        if ($content -match '(?m)^---.*?^---') {
            # Add tech tag to YAML
            if ($content -match '(?m)^tags:') {
                # Tags line exists, add #tech to it
                $content = $content -replace '(?m)^tags:\s*(.*)$', 'tags: $1 #tech'
            } else {
                # Add tags line
                $content = $content -replace '(?m)^---\s*\n', "---`ntags: #tech`n"
            }

            # Write back
            $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBOM)

            $restored++
            Write-Host "RESTORED TAGS: $($file.BaseName)" -ForegroundColor Green
        }
    }
}

Write-Host "`nTotal files restored: $restored" -ForegroundColor Blue
