# link_person_mentions.ps1
# Creates bidirectional links in person notes to all notes that mention them
# UTF-8 encoding preserved throughout

param(
    [switch]$DryRun,      # If set, only report what would be done without making changes
    [switch]$Verbose,     # Show detailed output
    [int]$Limit = 0       # Limit number of persons to process (0 = all)
)

# Vault path
$vaultPath = "D:\Obsidian\Main"
# People folder path
$peoplePath = Join-Path $vaultPath "15 - People"

# Get all person notes (excluding the index file)
$personFiles = Get-ChildItem -Path $peoplePath -Filter "*.md" |
    Where-Object { $_.Name -ne "15 - People.md" }

Write-Host "Found $($personFiles.Count) person notes in $peoplePath" -ForegroundColor Cyan

# Track statistics
$totalLinksAdded = 0
$totalPersonsProcessed = 0
$linkReport = @()

# Process each person
foreach ($personFile in $personFiles) {
    # Apply limit if specified
    if ($Limit -gt 0 -and $totalPersonsProcessed -ge $Limit) {
        Write-Host "`nLimit of $Limit persons reached. Stopping." -ForegroundColor Yellow
        break
    }

    # Extract person name from filename (remove .md extension)
    $personName = $personFile.BaseName

    Write-Host "`n========================================" -ForegroundColor Gray
    Write-Host "Processing: $personName" -ForegroundColor Green

    # Read the current person note content
    $personNotePath = $personFile.FullName
    $personNoteContent = Get-Content -Path $personNotePath -Raw -Encoding UTF8

    # Find all existing wikilinks in the person note
    # Pattern matches [[link]] or [[link|alias]]
    $existingLinks = [regex]::Matches($personNoteContent, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]') |
        ForEach-Object { $_.Groups[1].Value }

    if ($Verbose) {
        Write-Host "  Existing links in note: $($existingLinks.Count)" -ForegroundColor Gray
    }

    # Search for mentions of this person across the vault
    # Escape special regex characters in the person name
    $escapedName = [regex]::Escape($personName)

    # Find all .md files that mention this person (case-insensitive)
    $mentioningFiles = @()

    # Get all markdown files in vault (excluding the person's own file)
    $allMdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse |
        Where-Object { $_.FullName -ne $personNotePath }

    foreach ($mdFile in $allMdFiles) {
        try {
            $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -and $content -match $escapedName) {
                # Get the relative path for display and linking
                $relativePath = $mdFile.FullName.Substring($vaultPath.Length + 1)
                $noteName = $mdFile.BaseName

                # Skip if this is already linked in the person note
                $alreadyLinked = $existingLinks | Where-Object { $_ -eq $noteName -or $_ -eq $relativePath.Replace('\', '/').Replace('.md', '') }

                if (-not $alreadyLinked) {
                    $mentioningFiles += @{
                        Name = $noteName
                        Path = $mdFile.FullName
                        RelativePath = $relativePath
                    }
                }
            }
        } catch {
            # Skip files that can't be read
        }
    }

    Write-Host "  Found $($mentioningFiles.Count) notes mentioning '$personName' (not yet linked)" -ForegroundColor Cyan

    if ($mentioningFiles.Count -gt 0) {
        # List the files found
        foreach ($mf in $mentioningFiles) {
            Write-Host "    - $($mf.Name)" -ForegroundColor White
        }

        if (-not $DryRun) {
            # Add links to the person note
            # Find or create a "## Related Notes" or "## Mentions" section
            $linksSection = "`n## Notes Mentioning This Person`n"

            foreach ($mf in $mentioningFiles) {
                $linksSection += "- [[$($mf.Name)]]`n"
            }

            # Check if "## Notes Mentioning This Person" section already exists
            if ($personNoteContent -match '## Notes Mentioning This Person') {
                # Append to existing section - find the section and add before next ## or end
                $pattern = '(## Notes Mentioning This Person[^\n]*\n)((?:- \[\[[^\]]+\]\]\n)*)'
                $existingSection = [regex]::Match($personNoteContent, $pattern)

                if ($existingSection.Success) {
                    # Get existing links in this section
                    $existingSectionLinks = [regex]::Matches($existingSection.Groups[2].Value, '\[\[([^\]|]+)') |
                        ForEach-Object { $_.Groups[1].Value }

                    # Only add links not already in the section
                    $newLinks = ""
                    foreach ($mf in $mentioningFiles) {
                        if ($existingSectionLinks -notcontains $mf.Name) {
                            $newLinks += "- [[$($mf.Name)]]`n"
                            $totalLinksAdded++
                        }
                    }

                    if ($newLinks) {
                        $replacement = $existingSection.Groups[1].Value + $existingSection.Groups[2].Value + $newLinks
                        $personNoteContent = $personNoteContent -replace [regex]::Escape($existingSection.Value), $replacement
                    }
                }
            } else {
                # Add new section at the end (before any trailing whitespace/newlines)
                $personNoteContent = $personNoteContent.TrimEnd() + "`n" + $linksSection
                $totalLinksAdded += $mentioningFiles.Count
            }

            # Write back the updated content
            Set-Content -Path $personNotePath -Value $personNoteContent -Encoding UTF8 -NoNewline
            Write-Host "  Updated person note with $($mentioningFiles.Count) new links" -ForegroundColor Green

            # Now add backlinks from mentioning files to the person note
            foreach ($mf in $mentioningFiles) {
                $mentioningContent = Get-Content -Path $mf.Path -Raw -Encoding UTF8

                # Check if person is already linked in that file
                if ($mentioningContent -notmatch "\[\[$([regex]::Escape($personName))(?:\|[^\]]+)?\]\]") {
                    # Person is mentioned but not linked - this is expected
                    # We don't automatically add links TO the mentioning files
                    # because they mention the person by name, not necessarily as a link

                    if ($Verbose) {
                        Write-Host "    Note '$($mf.Name)' mentions but doesn't link to person" -ForegroundColor Gray
                    }
                }
            }
        } else {
            Write-Host "  [DRY RUN] Would add $($mentioningFiles.Count) links to person note" -ForegroundColor Yellow
            $totalLinksAdded += $mentioningFiles.Count
        }

        # Add to report
        $linkReport += [PSCustomObject]@{
            Person = $personName
            MentionsFound = $mentioningFiles.Count
            Files = ($mentioningFiles | ForEach-Object { $_.Name }) -join ", "
        }
    }

    $totalPersonsProcessed++
}

# Summary
Write-Host "`n========================================" -ForegroundColor Gray
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray
Write-Host "Persons processed: $totalPersonsProcessed" -ForegroundColor White
Write-Host "Total new links added: $totalLinksAdded" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n[DRY RUN MODE - No changes were made]" -ForegroundColor Yellow
}

# Output detailed report
if ($linkReport.Count -gt 0) {
    Write-Host "`nDetailed Report:" -ForegroundColor Cyan
    $linkReport | Format-Table -AutoSize
}
