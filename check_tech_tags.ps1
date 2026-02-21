# Script to check and add "tech" tag to all files linked in MOC - Technology & Computers
# UTF-8 encoding is preserved throughout

# Define the files to check from the MOC - Computer Sciences section
$filesToCheck = @(
    'Build a Modern Computer from First Principles',
    'Greenscreen backdrop',
    'Creating Deep Forgeries',
    'Myopic Optimization',
    'Fractals a Part of A',
    'When the Singularity Might Occur',
    'Hardware',
    # Networking & Systems
    'Augmented Reality is a Massively Multiplayer Online world',
    'glasswire',
    'Upgrading Our RV Internet Connection',
    'How to control your',
    'Creating my first home server',
    'Ensuring High Availability DHCP Service',
    'Unshielded Twisted Pair Cable Classifications',
    'Finding expiring or or soon to expire accounts in Linux',
    'FileZilla Has an Evil Twin that Steals FTP Logins',
    '10 Windows services',
    '10 Hidden URLs to Help You Rule the Web',
    'NSClient++ for NRPE',
    'How a group of neighbors created their own Internet service',
    'Kurose-Ross-Computer Networking',
    'The free space equation',
    'FiberFirst installation',
    # System Admin
    'Essential Linux System Administration Books',
    'How to Lock and Unlock a User Account in Linux',
    'Monitoring E-Mail with Nagios',
    'Nagios Support Forum',
    'Nagios Monitor Event Logs',
    'Nagios Support Performance Data Tool now available',
    'Troy Lea - Leveragin',
    '12 Essential Python For Loop Command Examples',
    'VMware KB Installing',
    'Document SQL Server 2000, 2005 and 2008 databases',
    'Linux home office server',
    'HowTo Disable The Iptables Firewall in Linux',
    # Databases & Access
    'How to Change Your Email address',
    'Delete tourists from',
    'How to Erase Yoursel',
    'MarkusPfundsteinmcp-',
    'ORDER BY Clause (Tra',
    'DateTime data in Microsoft Access',
    'All in One – System Rescue Toolkit Lite',
    'Obsidian MCP server',
    'Duplicate Detection',
    'SourceForge.net Apex',
    'How to Migrate to a',
    'ACCESS Dependency Checker',
    'Navathe-Fundamentals',
    'FileHippo.com Update',
    'Dataview plugin in Obsidian',
    'How to Dynamically and Iteratively Populate An Excel Workbook',
    'AcSpreadSheetType  List',
    'Navathe-Fundamentals of Database Systems, 6e',
    'Documenting query dependencies',
    'Show or Hide Tabs in Microsoft Access 2010',
    # Excel VBA
    'How to Choose the Best Chart for Your Data',
    'Excel Count Function',
    'Outlook Macro  Move',
    'Modular Spreadsheet',
    'VBA Express  Excel -',
    'Excel Create and nam',
    'Disable Alert Warning Messages in Excel',
    # Linux
    'Linux',
    'Removing Lock Screen'
)

# Set vault root directory
$vaultRoot = 'D:\Obsidian\Main'

# Initialize counters
$added = 0
$alreadyHad = 0
$notFound = 0
$skipped = 0

# Process each file name
foreach ($fileName in $filesToCheck) {
    # Try exact match first
    $files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $_.BaseName -eq $fileName -or $_.Name -eq "$fileName.md"
    }

    # If no exact match, try partial match
    if ($files.Count -eq 0) {
        # Create a wildcard pattern - match beginning of filename
        $pattern = [Regex]::Escape($fileName) + '.*'
        $files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
            $_.BaseName -match "^$pattern" -or $_.BaseName -eq $fileName
        } | Select-Object -First 1
    }

    if ($files.Count -eq 0 -and $null -eq $files) {
        $notFound++
        Write-Host "NOT FOUND: $fileName" -ForegroundColor Red
        continue
    }

    # Ensure $files is iterable
    if ($null -ne $files -and -not ($files -is [System.Array])) {
        $files = @($files)
    } elseif ($null -eq $files) {
        $notFound++
        continue
    }

    # Process each found file
    foreach ($file in $files) {
        # Skip files in 09 - Kindle Clippings
        if ($file.FullName -like "*09 - Kindle Clippings*") {
            $skipped++
            Write-Host "SKIPPED (Kindle): $($file.BaseName)" -ForegroundColor Yellow
            continue
        }

        # Skip MOC files
        if ($file.BaseName -like "*MOC*") {
            $skipped++
            Write-Host "SKIPPED (MOC): $($file.BaseName)" -ForegroundColor Yellow
            continue
        }

        # Skip contact/person files
        if ($file.BaseName -match '^#') {
            $skipped++
            Write-Host "SKIPPED (Contact): $($file.BaseName)" -ForegroundColor Yellow
            continue
        }

        # Read file with UTF-8 encoding
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        # Check for existing tags
        $hasYamlTech = $content -match '(?m)^tags:.*\btech\b'
        $hasInlineTech = $content -match '#tech\b'

        if ($hasYamlTech -or $hasInlineTech) {
            $alreadyHad++
            Write-Host "ALREADY HAS TAG: $($file.BaseName)" -ForegroundColor Green
        } else {
            # Add tech tag - check if YAML front matter exists
            $hasYaml = $content -match '(?m)^---\s'

            if ($hasYaml) {
                # File has YAML front matter
                if ($content -match '(?m)^tags:\s*(.*)$') {
                    # Tags line exists - append #tech
                    $content = $content -replace '(?m)^tags:\s*(.*)$', 'tags: $1 #tech'
                } else {
                    # No tags line - add one after ---
                    $content = $content -replace '(?m)^---\s*\n', "---`ntags: #tech`n"
                }
            } else {
                # No YAML front matter - add one at the top with tags
                $content = "---`ntags: #tech`n---`n`n$content"
            }

            # Write back with UTF-8 encoding (no BOM)
            $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBOM)
            $added++
            Write-Host "ADDED TAG: $($file.BaseName)" -ForegroundColor Cyan
        }
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Blue
Write-Host "Added: $added" -ForegroundColor Cyan
Write-Host "Already had tag: $alreadyHad" -ForegroundColor Green
Write-Host "Not found: $notFound" -ForegroundColor Red
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
