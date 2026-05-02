# Sort To-Do List: uncompleted first, then completed sorted by date descending
$path = 'D:\Obsidian\Main\To-Do List.md'
$content = Get-Content $path -Encoding UTF8

# Split on the separator lines
$headerLines = @()
$taskLines = @()
$footerLines = @()
$inHeader = $true
$inFooter = $false
$separatorCount = 0

foreach ($line in $content) {
    if ($inHeader) {
        $headerLines += $line
        if ($line -eq '---') {
            $separatorCount++
            if ($separatorCount -ge 1) {
                $inHeader = $false
            }
        }
    } elseif ($inFooter) {
        $footerLines += $line
    } elseif ($line -eq '---') {
        $inFooter = $true
        $footerLines += $line
    } else {
        $taskLines += $line
    }
}

# Separate uncompleted and completed tasks
$uncompleted = @()
$completed = @()
$currentTask = $null

foreach ($line in $taskLines) {
    if ($line -match '^\s*-\s*\[( |x)\]') {
        # Save previous task
        if ($currentTask -ne $null) {
            if ($currentTask[0] -match '^\s*-\s*\[x\]') {
                $completed += ,@($currentTask)
            } else {
                $uncompleted += ,@($currentTask)
            }
        }
        $currentTask = @($line)
    } elseif ($currentTask -ne $null -and ($line -match '^\t' -or $line -match '^    ')) {
        # Indented sub-task line belongs to current task
        $currentTask += $line
    } elseif ($line -eq '') {
        # Skip blank lines between tasks
        if ($currentTask -ne $null) {
            if ($currentTask[0] -match '^\s*-\s*\[x\]') {
                $completed += ,@($currentTask)
            } else {
                $uncompleted += ,@($currentTask)
            }
            $currentTask = $null
        }
    } else {
        # Continuation line or standalone (like #ToDo prefix)
        if ($currentTask -ne $null) {
            $currentTask += $line
        }
    }
}
# Handle last task
if ($currentTask -ne $null) {
    if ($currentTask[0] -match '^\s*-\s*\[x\]') {
        $completed += ,@($currentTask)
    } else {
        $uncompleted += ,@($currentTask)
    }
}

# Extract completion date from a task's first line
function Get-CompletionDate($taskArr) {
    $line = $taskArr[0]
    # Try ✅ YYYY-MM-DD
    if ($line -match '✅\s*(\d{4}-\d{2}-\d{2})') {
        return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    }
    # Try " YYYY-MM-DD (mojibake completion marker)
    if ($line -match '"[^"]*(\d{4}-\d{2}-\d{2})\s*$') {
        return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    }
    # Try trailing YYYY-MM-DD HH:MM:SS
    if ($line -match '(\d{4}-\d{2}-\d{2})\s+\d{2}:\d{2}:\d{2}\s*$') {
        return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    }
    # Try trailing YYYY-MM-DD
    if ($line -match '(\d{4}-\d{2}-\d{2})\s*$') {
        return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    }
    return [datetime]::MinValue
}

# Sort completed by date descending
$sortedCompleted = $completed | Sort-Object { Get-CompletionDate $_ } -Descending

# Clean up Related Notes in footer - remove broken path wikilinks
$cleanFooter = @()
foreach ($line in $footerLines) {
    # Skip lines with broken path-style wikilinks like [[path/to/file|alias]]
    if ($line -match '\[\[[^\]]+/[^\]]+\|[^\]]+\]\]') { continue }
    $cleanFooter += $line
}

# Reconstruct file
$output = @()
$output += $headerLines
foreach ($task in $uncompleted) {
    $output += $task
}
$output += ''
foreach ($task in $sortedCompleted) {
    $output += $task
}
$output += $cleanFooter

# Write back with UTF-8 encoding (preserve BOM)
$bom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllLines($path, $output, $bom)

Write-Host "Uncompleted tasks: $($uncompleted.Count)"
Write-Host "Completed tasks: $($sortedCompleted.Count)"
Write-Host "Done."
