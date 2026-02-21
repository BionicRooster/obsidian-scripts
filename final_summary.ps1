# Final summary of the tag addition process

$vaultRoot = 'D:\Obsidian\Main'

# All files listed in the MOC that should have been processed
$allFilesFromMOC = @(
    'Build a Modern Computer from First Principles',
    'Greenscreen backdrop',
    'Creating Deep Forgeries',
    'Myopic Optimization',
    'Fractals a Part of A',
    'When the Singularity Might Occur',
    'Hardware',
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
    'How to Choose the Best Chart for Your Data',
    'Excel Count Function',
    'Outlook Macro  Move',
    'Modular Spreadsheet',
    'VBA Express  Excel -',
    'Excel Create and nam',
    'Disable Alert Warning Messages in Excel',
    'Linux',
    'Removing Lock Screen'
)

$hasTag = 0
$missingTag = 0
$notFound = 0
$skipped = 0

Write-Host "Checking $($allFilesFromMOC.Count) files from MOC - Technology & Computers...`n" -ForegroundColor Blue

foreach ($fileName in $allFilesFromMOC) {
    # Find the file
    $files = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $_.BaseName -eq $fileName -or $_.BaseName -like "$fileName*"
    }

    if ($files.Count -eq 0) {
        $notFound++
    } else {
        # Ensure iterable
        if (-not ($files -is [System.Array])) {
            $files = @($files)
        }

        foreach ($file in $files) {
            # Skip exclusions
            if ($file.FullName -like "*09 - Kindle*") {
                $skipped++
                continue
            }
            if ($file.BaseName -like "*MOC*") {
                $skipped++
                continue
            }

            # Check content
            $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

            if ($content -match '#tech\b') {
                $hasTag++
            } else {
                $missingTag++
            }
        }
    }
}

Write-Host "=== FINAL SUMMARY ===" -ForegroundColor Cyan
Write-Host "Files checked from MOC: $($allFilesFromMOC.Count)" -ForegroundColor White
Write-Host "Files found with #tech tag: $hasTag" -ForegroundColor Green
Write-Host "Files missing #tech tag: $missingTag" -ForegroundColor Red
Write-Host "Files not found in vault: $notFound" -ForegroundColor Yellow
Write-Host "Files skipped (Kindle/MOC): $skipped" -ForegroundColor Yellow
Write-Host "`nSuccess rate: $([math]::Round(($hasTag / ($hasTag + $missingTag) * 100), 1))%" -ForegroundColor Green
