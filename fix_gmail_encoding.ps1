# fix_gmail_encoding.ps1
# Fixes MIME encoding, HTML, and quoted-printable issues in Gmail markdown files
# Preserves YAML frontmatter, header (# title, **From/To/Date:**), and ## Links section
# Cleans up the body content between header --- and ## Links

param(
    # Path to the Gmail folder
    [string]$GmailFolder = "D:\Obsidian\Main\04 - GMail",

    # If set, only show what would be done
    [switch]$DryRun,

    # Limit number of files to process (0 = all)
    [int]$Limit = 0
)

# Function to decode quoted-printable UTF-8
# Handles =XX hex sequences and joins soft line breaks
function Decode-QuotedPrintableUTF8 {
    param([string]$Text)

    # Remove soft line breaks first (= at end of line means continuation)
    $Text = $Text -replace "=\r?\n", ""

    # Find and decode =XX sequences
    $result = New-Object System.Text.StringBuilder
    $bytes = New-Object System.Collections.ArrayList
    $i = 0

    while ($i -lt $Text.Length) {
        if ($Text[$i] -eq '=' -and ($i + 2) -lt $Text.Length) {
            $hex = $Text.Substring($i + 1, 2)
            if ($hex -match '^[0-9A-Fa-f]{2}$') {
                $byteValue = [Convert]::ToByte($hex, 16)
                [void]$bytes.Add($byteValue)
                $i += 3
                continue
            }
        }

        # Flush accumulated bytes as UTF-8
        if ($bytes.Count -gt 0) {
            try {
                [void]$result.Append([System.Text.Encoding]::UTF8.GetString([byte[]]$bytes.ToArray()))
            } catch {
                foreach ($b in $bytes) { [void]$result.Append([char]$b) }
            }
            $bytes.Clear()
        }

        [void]$result.Append($Text[$i])
        $i++
    }

    # Flush remaining bytes
    if ($bytes.Count -gt 0) {
        try {
            [void]$result.Append([System.Text.Encoding]::UTF8.GetString([byte[]]$bytes.ToArray()))
        } catch {
            foreach ($b in $bytes) { [void]$result.Append([char]$b) }
        }
    }

    return $result.ToString()
}

# Function to strip HTML tags and decode entities
function Strip-Html {
    param([string]$Html)

    # Remove style and script blocks entirely
    $Html = [regex]::Replace($Html, '<style[^>]*>[\s\S]*?</style>', '', 'IgnoreCase')
    $Html = [regex]::Replace($Html, '<script[^>]*>[\s\S]*?</script>', '', 'IgnoreCase')

    # Convert block elements to newlines
    $Html = $Html -replace '<br\s*/?>', "`n"
    $Html = $Html -replace '</p>', "`n`n"
    $Html = $Html -replace '</div>', "`n"
    $Html = $Html -replace '</li>', "`n"
    $Html = $Html -replace '</tr>', "`n"
    $Html = $Html -replace '<li[^>]*>', "- "
    $Html = $Html -replace '<h[1-6][^>]*>', "`n## "
    $Html = $Html -replace '</h[1-6]>', "`n"
    $Html = $Html -replace '<hr[^>]*>', "`n---`n"

    # Convert emphasis tags
    $Html = $Html -replace '<strong[^>]*>', '**'
    $Html = $Html -replace '</strong>', '**'
    $Html = $Html -replace '<b[^>]*>', '**'
    $Html = $Html -replace '</b>', '**'
    $Html = $Html -replace '<em[^>]*>', '*'
    $Html = $Html -replace '</em>', '*'
    $Html = $Html -replace '<i[^>]*>', '*'
    $Html = $Html -replace '</i>', '*'

    # Remove all remaining tags
    $Html = [regex]::Replace($Html, '<[^>]+>', '')

    # Decode HTML entities
    $Html = $Html -replace '&nbsp;', ' '
    $Html = $Html -replace '&amp;', '&'
    $Html = $Html -replace '&lt;', '<'
    $Html = $Html -replace '&gt;', '>'
    $Html = $Html -replace '&quot;', '"'
    $Html = $Html -replace '&#39;', "'"
    $Html = $Html -replace '&rsquo;', "'"
    $Html = $Html -replace '&lsquo;', "'"
    $Html = $Html -replace '&rdquo;', '"'
    $Html = $Html -replace '&ldquo;', '"'
    $Html = $Html -replace '&mdash;', '--'
    $Html = $Html -replace '&ndash;', '-'
    $Html = $Html -replace '&hellip;', '...'
    $Html = $Html -replace '&#(\d+);', { param($m) [char][int]$m.Groups[1].Value }

    return $Html
}

# Function to detect if a line looks like base64 encoded data
function Is-Base64Line {
    param([string]$Line)

    # Base64 lines are typically 76 characters of [A-Za-z0-9+/] optionally ending with =
    # and contain no spaces or special characters
    if ($Line.Length -ge 60 -and $Line -match '^[A-Za-z0-9+/=]+$') {
        return $true
    }
    return $false
}

# Function to extract plain text content from multipart MIME message
function Extract-PlainTextContent {
    param([string]$Body)

    # Split into lines
    $lines = $Body -split "`r?`n"
    $result = New-Object System.Collections.ArrayList

    # State tracking
    $inPlainText = $false
    $inHtml = $false
    $inAttachment = $false
    $sawContentType = $false
    $skipRest = $false

    # MIME boundary pattern
    $boundaryPattern = '^--[a-zA-Z0-9_=.-]{10,}|^------=_Part_'

    foreach ($line in $lines) {
        # Check for MIME boundary
        if ($line -match $boundaryPattern) {
            if ($inPlainText) {
                # We were in plain text and hit a boundary - we're done with plain text
                $skipRest = $true
            }
            $inPlainText = $false
            $inHtml = $false
            $inAttachment = $false
            $sawContentType = $false
            continue
        }

        # Skip everything after we've captured plain text and hit a boundary
        if ($skipRest) {
            continue
        }

        # Check for Content-Type header
        if ($line -match '^Content-Type:\s*text/plain') {
            $inPlainText = $true
            $inHtml = $false
            $inAttachment = $false
            $sawContentType = $true
            continue
        }
        if ($line -match '^Content-Type:\s*text/html') {
            $inHtml = $true
            $inPlainText = $false
            $inAttachment = $false
            $sawContentType = $true
            continue
        }
        # Skip image, application, and other binary content types
        if ($line -match '^Content-Type:\s*(image|application|audio|video)/') {
            $inAttachment = $true
            $inPlainText = $false
            $inHtml = $false
            $sawContentType = $true
            continue
        }
        if ($line -match '^Content-Type:' -or $line -match '^Content-Transfer-Encoding:') {
            continue
        }

        # Skip Content-Description, Content-Disposition, Content-ID headers (attachment metadata)
        if ($line -match '^Content-(Description|Disposition|ID):') {
            $inAttachment = $true
            continue
        }

        # Skip attachment content
        if ($inAttachment) {
            continue
        }

        # Skip HTML content
        if ($inHtml) {
            continue
        }

        # Skip base64 encoded data even if we're supposedly in plain text
        # (sometimes attachments appear without proper headers)
        if (Is-Base64Line -Line $line) {
            continue
        }

        # If we've seen a Content-Type: text/plain header, collect lines
        if ($inPlainText) {
            [void]$result.Add($line)
            continue
        }

        # If we haven't seen any Content-Type yet, this is probably pre-MIME content
        # or it's a simple message without MIME parts
        if (-not $sawContentType -and $line -notmatch '^Content-Type:' -and $line -notmatch '^MIME-Version:') {
            # Check if this line looks like HTML
            if ($line -match '^\s*<!DOCTYPE|^\s*<html|^\s*<head|^\s*<body|^\s*<div xmlns') {
                $skipRest = $true
                continue
            }
            [void]$result.Add($line)
        }
    }

    return ($result -join "`n")
}

# Function to clean the body content of a Gmail file
function Clean-GmailBody {
    param([string]$Body)

    # First, decode the entire body to handle soft line breaks properly
    # This joins lines that end with = and decodes =XX sequences
    $decodedBody = Decode-QuotedPrintableUTF8 -Text $Body

    # Check if this is a multipart MIME message
    $hasMimeBoundary = $decodedBody -match '--[a-zA-Z0-9_=.-]{10,}|------=_Part_'
    $hasContentType = $decodedBody -match 'Content-Type:\s*text/'

    if ($hasMimeBoundary -or $hasContentType) {
        # Extract the plain text part
        $cleanBody = Extract-PlainTextContent -Body $decodedBody
    }
    else {
        $cleanBody = $decodedBody
    }

    # If the result is mostly HTML (high tag density), strip HTML
    # Count HTML tags vs text content
    $tagMatches = [regex]::Matches($cleanBody, '<[^>]+>')
    $isHeavyHtml = ($tagMatches.Count -gt 10) -or ($cleanBody -match '^\s*<!DOCTYPE|^\s*<html|^\s*<body|<div[^>]*xmlns|<div[^>]*class=')

    if ($isHeavyHtml) {
        $cleanBody = Strip-Html -Html $cleanBody
    }

    # Remove any remaining quoted-printable (in case it wasn't decoded)
    if ($cleanBody -match '=[0-9A-Fa-f]{2}') {
        $cleanBody = Decode-QuotedPrintableUTF8 -Text $cleanBody
    }

    # Remove MIME-related headers that might remain
    $cleanBody = $cleanBody -replace '(?m)^boundary="[^"]*"\s*$', ''
    $cleanBody = $cleanBody -replace '(?m)^\[cid:[^\]]+\]\s*$', ''

    # Remove any stray MIME markers that might remain
    $cleanBody = $cleanBody -replace '--[a-zA-Z0-9_=.-]{20,}--?\s*$', ''
    $cleanBody = $cleanBody -replace '------=_Part_[^\r\n]*', ''

    # Clean up excessive whitespace
    $cleanBody = $cleanBody -replace '(\r?\n){3,}', "`n`n"
    $cleanBody = $cleanBody -replace '[ \t]+$', '' -replace '^[ \t]+', ''
    $cleanBody = $cleanBody.Trim()

    return $cleanBody
}

# Function to clean a single Gmail markdown file
function Clean-GmailFile {
    param([string]$Content)

    # Split into lines for processing
    $lines = $Content -split "`r?`n"

    # Find frontmatter boundaries (first and second ---)
    $fmStart = -1
    $fmEnd = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            if ($fmStart -eq -1) {
                $fmStart = $i
            } elseif ($fmEnd -eq -1) {
                $fmEnd = $i
                break
            }
        }
    }

    if ($fmEnd -eq -1) {
        return $Content  # No valid frontmatter
    }

    # Extract YAML frontmatter (lines 0 through fmEnd, inclusive)
    $frontmatter = ($lines[0..$fmEnd] -join "`n") + "`n"

    # Find the header section end (the --- after the title/from/to/date)
    # Header looks like:
    # # Title
    # **From:** ...
    # **To:** ...
    # **Date:** ...
    # ---
    $headerEnd = -1
    for ($i = $fmEnd + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            $headerEnd = $i
            break
        }
    }

    # Extract header if found
    $header = ""
    $bodyStartIndex = $fmEnd + 1

    if ($headerEnd -ne -1) {
        # Include lines from after frontmatter to the header separator (inclusive)
        $header = ($lines[($fmEnd + 1)..$headerEnd] -join "`n") + "`n"
        $bodyStartIndex = $headerEnd + 1
    }

    # Find ## Links section at the end
    $linksStart = -1
    for ($i = $lines.Count - 1; $i -gt $bodyStartIndex; $i--) {
        if ($lines[$i] -eq '## Links') {
            $linksStart = $i
            break
        }
    }

    # Extract links section and body
    $links = ""
    $bodyEndIndex = $lines.Count - 1

    if ($linksStart -ne -1) {
        $links = "`n" + ($lines[$linksStart..($lines.Count - 1)] -join "`n")
        $bodyEndIndex = $linksStart - 1
    }

    # Extract and clean the body
    if ($bodyStartIndex -le $bodyEndIndex) {
        $bodyLines = $lines[$bodyStartIndex..$bodyEndIndex]
        $body = $bodyLines -join "`n"
    }
    else {
        $body = ""
    }

    # Check if body has MIME/HTML issues OR soft line breaks
    $hasMimeIssues = $body -match '--[a-zA-Z0-9]{10,}|Content-Type:\s*text/|Content-Transfer-Encoding:|=3D|<html|<body|<div|<table'
    $hasSoftBreaks = $body -match '=\r?\n'
    $hasOtherIssues = $body -match '\[cid:|boundary="'

    if (-not $hasMimeIssues -and -not $hasSoftBreaks -and -not $hasOtherIssues) {
        return $Content  # No issues to fix
    }

    # Clean the body
    $cleanBody = Clean-GmailBody -Body $body

    # Reconstruct the file
    $result = $frontmatter
    if ($header) {
        $result += $header
    }
    $result += "`n" + $cleanBody
    if ($links) {
        $result += $links
    }
    $result += "`n"

    # Normalize line endings and clean up excessive newlines
    $result = $result -replace "`r`n", "`n"
    $result = $result -replace "`n{4,}", "`n`n`n"

    return $result
}

# Main processing
Write-Host "Gmail Encoding Fixer" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

# Get all markdown files
$files = Get-ChildItem -Path $GmailFolder -Filter "*.md" -File

Write-Host "Found $($files.Count) files in $GmailFolder" -ForegroundColor Green

# Find files with potential issues
# Pattern includes MIME boundaries, content headers, quoted-printable markers, HTML tags, and soft line breaks (= at end of line)
$problemPattern = '--[a-zA-Z0-9]{10,}|Content-Type:\s*text/|Content-Transfer-Encoding:|=3D|=20|<html|<body|<div class|<table|<span|=\r?\n|\[cid:|boundary="'
$problemFiles = @()

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match $problemPattern) {
        $problemFiles += @{
            File = $file
            Content = $content
        }
    }
}

Write-Host "Found $($problemFiles.Count) files with potential encoding issues" -ForegroundColor Yellow
Write-Host ""

if ($Limit -gt 0 -and $problemFiles.Count -gt $Limit) {
    $problemFiles = $problemFiles | Select-Object -First $Limit
    Write-Host "Processing first $Limit files" -ForegroundColor Yellow
}

$fixed = 0
$unchanged = 0
$errors = 0

foreach ($item in $problemFiles) {
    $file = $item.File
    $content = $item.Content

    try {
        $cleaned = Clean-GmailFile -Content $content

        if ($cleaned -ne $content) {
            if ($DryRun) {
                Write-Host "[DRY RUN] Would fix: $($file.Name)" -ForegroundColor Yellow
            } else {
                # Write with UTF-8 encoding (no BOM)
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($file.FullName, $cleaned, $utf8NoBom)
                Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
            }
            $fixed++
        } else {
            Write-Host "No changes: $($file.Name)" -ForegroundColor Gray
            $unchanged++
        }
    } catch {
        Write-Host "ERROR: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Files fixed: $fixed"
Write-Host "Unchanged: $unchanged"
Write-Host "Errors: $errors"
