# parse_mbox_recipes.ps1
# Parses an mbox file and creates individual markdown files in the Obsidian vault.
# If an email contains a recipe or a recipe URL, creates a recipe markdown file.

param(
    # Path to the mbox file to parse
    [string]$MboxPath = "D:\Downloads\takeout-20260204T142136Z-3-001\Takeout\Mail\Recipes.mbox",

    # Destination folder for email markdown files
    [string]$GmailFolder = "D:\Obsidian\Main\04 - GMail",

    # Destination folder for recipe files
    [string]$RecipeFolder = "D:\Obsidian\Main\03 - Recipes",

    # Maximum number of emails to process (0 = all)
    [int]$Limit = 0,

    # Skip the first N emails
    [int]$Skip = 0,

    # If set, only show what would be done without creating files
    [switch]$DryRun,

    # If set, fetch URLs to check for recipes
    [switch]$FetchUrls
)

# Ensure output directories exist
if (-not (Test-Path $GmailFolder)) {
    New-Item -ItemType Directory -Path $GmailFolder -Force | Out-Null
}
if (-not (Test-Path $RecipeFolder)) {
    New-Item -ItemType Directory -Path $RecipeFolder -Force | Out-Null
}

# Function to decode quoted-printable text
function Decode-QuotedPrintable {
    param([string]$Text)

    # Replace soft line breaks (=\r\n or =\n)
    $Text = $Text -replace "=\r?\n", ""

    # Replace =XX hex codes
    $decoded = [regex]::Replace($Text, '=([0-9A-Fa-f]{2})', {
        param($match)
        [char][int]("0x" + $match.Groups[1].Value)
    })

    return $decoded
}

# Function to decode base64 text
function Decode-Base64 {
    param([string]$Text)

    try {
        $bytes = [System.Convert]::FromBase64String($Text.Trim())
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return $Text
    }
}

# Function to decode MIME encoded-word (=?charset?encoding?text?=)
function Decode-MimeEncodedWord {
    param([string]$Text)

    # Match =?charset?encoding?text?= patterns
    $pattern = '=\?([^?]+)\?([BbQq])\?([^?]*)\?='

    $decoded = [regex]::Replace($Text, $pattern, {
        param($match)
        $charset = $match.Groups[1].Value
        $encoding = $match.Groups[2].Value.ToUpper()
        $encodedText = $match.Groups[3].Value

        try {
            if ($encoding -eq 'B') {
                # Base64
                $bytes = [System.Convert]::FromBase64String($encodedText)
                $enc = [System.Text.Encoding]::GetEncoding($charset)
                return $enc.GetString($bytes)
            } elseif ($encoding -eq 'Q') {
                # Quoted-printable (with _ for space)
                $qpText = $encodedText -replace '_', ' '
                $qpText = Decode-QuotedPrintable -Text $qpText
                return $qpText
            }
        } catch {
            return $match.Value
        }
        return $match.Value
    })

    return $decoded
}

# Function to strip HTML tags and decode entities
function Strip-Html {
    param([string]$Html)

    # Remove style and script tags with content
    $Html = $Html -replace '<style[^>]*>.*?</style>', '' -replace '<script[^>]*>.*?</script>', ''

    # Replace br and p tags with newlines
    $Html = $Html -replace '<br\s*/?>', "`n"
    $Html = $Html -replace '</p>', "`n`n"
    $Html = $Html -replace '</div>', "`n"
    $Html = $Html -replace '</li>', "`n"

    # Remove all other HTML tags
    $Html = $Html -replace '<[^>]+>', ''

    # Decode common HTML entities
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
    $Html = $Html -replace '&mdash;', '—'
    $Html = $Html -replace '&ndash;', '–'
    $Html = $Html -replace '&#\d+;', ''

    # Collapse multiple newlines
    $Html = $Html -replace "(\r?\n){3,}", "`n`n"

    # Trim whitespace from each line
    $lines = $Html -split "`n" | ForEach-Object { $_.Trim() }

    return ($lines -join "`n").Trim()
}

# Function to extract URLs from text
function Extract-Urls {
    param([string]$Text)

    # First clean up any remaining quoted-printable line breaks
    $cleanText = $Text -replace '=\r?\n', ''

    # For HTML, extract href values first
    $urls = @()

    # Extract URLs from href attributes
    $hrefMatches = [regex]::Matches($cleanText, 'href="(https?://[^"]+)"')
    foreach ($m in $hrefMatches) {
        $url = $m.Groups[1].Value
        $url = $url -replace '[.,;:!?\)\]]+$', ''
        if ($url.Length -gt 20) {
            $urls += $url
        }
    }

    # Extract standalone URLs (not in href)
    # Use word boundaries to avoid concatenated URLs
    $urlPattern = '(?<![">])https?://[^\s<>"''=\)\]\r\n>]+'
    $urlMatches = [regex]::Matches($cleanText, $urlPattern)

    foreach ($m in $urlMatches) {
        $url = $m.Value

        # Clean up trailing punctuation
        $url = $url -replace '[.,;:!?\)\]]+$', ''

        # Skip if URL is too short, looks broken, or already extracted
        if ($url.Length -gt 20 -and $url -notmatch '=3D|=20') {
            $urls += $url
        }
    }

    # Deduplicate and return
    return $urls | Select-Object -Unique
}

# Function to check if content is likely a recipe
function Test-IsRecipe {
    param(
        [string]$Subject,
        [string]$Body
    )

    # Strong indicator: "recipe" in subject
    if ($Subject -match '\brecipe\b') {
        return $true
    }

    # Primary recipe indicators (must have at least one)
    $primaryKeywords = @(
        'recipe', 'ingredients:', 'directions:', 'instructions:', 'prep time',
        'cook time', 'total time', 'servings:', 'yield:'
    )

    $combined = "$Subject $Body".ToLower()

    $hasPrimary = $false
    foreach ($keyword in $primaryKeywords) {
        if ($combined -match [regex]::Escape($keyword)) {
            $hasPrimary = $true
            break
        }
    }

    if (-not $hasPrimary) {
        return $false
    }

    # Secondary recipe keywords
    $secondaryKeywords = @(
        'tablespoon', 'teaspoon', 'tbsp', 'tsp', 'cup', 'cups', 'oz', 'ounce',
        'preheat', 'bake', 'simmer', 'saute', 'sauté', 'stir', 'mix', 'blend',
        'chop', 'dice', 'slice', 'mince', 'marinate', 'vegan', 'vegetarian'
    )

    $secondaryCount = 0
    foreach ($keyword in $secondaryKeywords) {
        if ($combined -match "\b$([regex]::Escape($keyword))\b") {
            $secondaryCount++
        }
    }

    # Need at least 2 secondary keywords
    return $secondaryCount -ge 2
}

# Function to sanitize filename
function Get-SafeFilename {
    param([string]$Name)

    # Remove/replace invalid filename characters
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $invalidRegex = "[{0}]" -f [Regex]::Escape($invalidChars)
    $safeName = $Name -replace $invalidRegex, '_'

    # Replace smart quotes with standard quotes (using Unicode escapes)
    $safeName = $safeName -replace [char]0x2018, "'"  # Left single quote
    $safeName = $safeName -replace [char]0x2019, "'"  # Right single quote
    $safeName = $safeName -replace [char]0x201C, '"'  # Left double quote
    $safeName = $safeName -replace [char]0x201D, '"'  # Right double quote

    # Truncate if too long
    if ($safeName.Length -gt 100) {
        $safeName = $safeName.Substring(0, 100)
    }

    return $safeName.Trim()
}

# Function to parse a single email message
function Parse-Email {
    param([string]$RawMessage)

    $email = @{
        Headers = @{}
        Body = ""
        PlainText = ""
        Html = ""
    }

    # Split into lines
    $lines = $RawMessage -split "`r?`n"

    # Parse headers (everything before first blank line)
    $headerSection = $true
    $currentHeader = ""
    $currentValue = ""
    $bodyStartIndex = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($headerSection) {
            if ($line -eq "") {
                # End of headers
                if ($currentHeader -ne "") {
                    $email.Headers[$currentHeader] = $currentValue.Trim()
                }
                $headerSection = $false
                $bodyStartIndex = $i + 1
            } elseif ($line -match '^\s+') {
                # Continuation of previous header
                $currentValue += " " + $line.Trim()
            } elseif ($line -match '^([^:]+):\s*(.*)$') {
                # New header
                if ($currentHeader -ne "") {
                    $email.Headers[$currentHeader] = $currentValue.Trim()
                }
                $currentHeader = $matches[1]
                $currentValue = $matches[2]
            }
        }
    }

    # Get body content
    $bodyLines = $lines[$bodyStartIndex..($lines.Count - 1)]
    $body = $bodyLines -join "`n"
    $email.Body = $body

    # Check if multipart
    $contentType = $email.Headers["Content-Type"]
    if ($contentType -match 'multipart.*boundary="?([^";\s]+)"?') {
        $boundary = $matches[1]
        $parts = $body -split "--$([regex]::Escape($boundary))"

        foreach ($part in $parts) {
            if ($part -match 'Content-Type:\s*text/plain') {
                # Extract plain text part
                $partLines = $part -split "`r?`n"
                $encoding = "7bit"
                $foundHeaderEnd = $false
                $contentStartIndex = 0

                # Find the blank line that separates headers from content
                for ($idx = 0; $idx -lt $partLines.Count; $idx++) {
                    $line = $partLines[$idx]

                    # Extract encoding from headers
                    if ($line -match 'Content-Transfer-Encoding:\s*(.+)') {
                        $encoding = $matches[1].Trim().ToLower()
                    }

                    # Look for first non-header, non-empty line after we see Content-Type
                    # Headers end when we see a blank line AFTER seeing Content-Type
                    if ($line -match 'Content-Type:') {
                        # We're in the headers section
                        $foundHeaderEnd = $false
                    }

                    # Empty line after Content-Type signals end of headers
                    if ($line.Trim() -eq "" -and $idx -gt 0 -and $partLines[$idx - 1] -notmatch '^\s*$') {
                        $foundHeaderEnd = $true
                        $contentStartIndex = $idx + 1
                        break
                    }
                }

                if ($foundHeaderEnd -and $contentStartIndex -lt $partLines.Count) {
                    $partContent = $partLines[$contentStartIndex..($partLines.Count - 1)]
                    $textBody = $partContent -join "`n"
                } else {
                    # Fallback: just skip lines that look like headers
                    $partContent = $partLines | Where-Object {
                        $_ -notmatch '^Content-Type:' -and
                        $_ -notmatch '^Content-Transfer-Encoding:' -and
                        $_ -notmatch '^\s+charset='
                    }
                    $textBody = $partContent -join "`n"
                }

                if ($encoding -eq "quoted-printable") {
                    $textBody = Decode-QuotedPrintable -Text $textBody
                } elseif ($encoding -eq "base64") {
                    $textBody = Decode-Base64 -Text $textBody
                }

                $textBody = $textBody.Trim()
                $email.PlainText = $textBody
            }
            elseif ($part -match 'Content-Type:\s*text/html') {
                # Extract HTML part
                $partLines = $part -split "`r?`n"
                $encoding = "7bit"
                $foundHeaderEnd = $false
                $contentStartIndex = 0

                for ($idx = 0; $idx -lt $partLines.Count; $idx++) {
                    $line = $partLines[$idx]

                    if ($line -match 'Content-Transfer-Encoding:\s*(.+)') {
                        $encoding = $matches[1].Trim().ToLower()
                    }

                    if ($line.Trim() -eq "" -and $idx -gt 0 -and $partLines[$idx - 1] -notmatch '^\s*$') {
                        $foundHeaderEnd = $true
                        $contentStartIndex = $idx + 1
                        break
                    }
                }

                if ($foundHeaderEnd -and $contentStartIndex -lt $partLines.Count) {
                    $partContent = $partLines[$contentStartIndex..($partLines.Count - 1)]
                    $htmlBody = $partContent -join "`n"
                } else {
                    $partContent = $partLines | Where-Object {
                        $_ -notmatch '^Content-Type:' -and
                        $_ -notmatch '^Content-Transfer-Encoding:'
                    }
                    $htmlBody = $partContent -join "`n"
                }

                if ($encoding -eq "quoted-printable") {
                    $htmlBody = Decode-QuotedPrintable -Text $htmlBody
                } elseif ($encoding -eq "base64") {
                    $htmlBody = Decode-Base64 -Text $htmlBody
                }

                $email.Html = $htmlBody
            }
        }
    } else {
        # Single part
        $transferEncoding = $email.Headers["Content-Transfer-Encoding"]
        if ($transferEncoding) {
            $transferEncoding = $transferEncoding.ToLower().Trim()
        }

        if ($transferEncoding -eq "quoted-printable") {
            $body = Decode-QuotedPrintable -Text $body
        } elseif ($transferEncoding -eq "base64") {
            $body = Decode-Base64 -Text $body
        }

        if ($contentType -match 'text/html') {
            $email.Html = $body
        } else {
            $email.PlainText = $body
        }
    }

    return $email
}

# Main processing
Write-Host "Reading mbox file: $MboxPath" -ForegroundColor Cyan

# Read the file
$content = [System.IO.File]::ReadAllText($MboxPath, [System.Text.Encoding]::UTF8)

# Split into individual messages (each starts with "From " at beginning of line)
$messages = $content -split '(?m)^From [^\n]+\n' | Where-Object { $_.Trim() -ne "" }

Write-Host "Found $($messages.Count) messages" -ForegroundColor Green

# Apply skip and limit
if ($Skip -gt 0) {
    $messages = $messages | Select-Object -Skip $Skip
}
if ($Limit -gt 0) {
    $messages = $messages | Select-Object -First $Limit
}

Write-Host "Processing $($messages.Count) messages (after skip/limit)" -ForegroundColor Green

$processed = 0
$emailsCreated = 0
$recipesCreated = 0
$errors = 0
$urlsToFetch = @()

foreach ($rawMessage in $messages) {
    $processed++

    try {
        $email = Parse-Email -RawMessage $rawMessage

        # Get key headers
        $subject = Decode-MimeEncodedWord -Text ($email.Headers["Subject"] -replace "^\s+", "")
        if ([string]::IsNullOrWhiteSpace($subject)) {
            $subject = "(No Subject)"
        }

        $from = $email.Headers["From"]
        $to = $email.Headers["To"]
        $date = $email.Headers["Date"]
        $messageId = $email.Headers["Message-ID"]
        $gmailLabels = $email.Headers["X-Gmail-Labels"]

        # Parse date for YAML
        $parsedDate = $null
        if ($date) {
            try {
                # Try to parse the date
                $parsedDate = [DateTime]::Parse($date)
            } catch {
                # Keep original if parsing fails
            }
        }

        # Get body text (prefer plain text, fall back to stripped HTML)
        $bodyText = $email.PlainText
        if ([string]::IsNullOrWhiteSpace($bodyText) -and $email.Html) {
            $bodyText = Strip-Html -Html $email.Html
        }

        # Extract URLs (only from plain text body to avoid HTML parsing issues)
        $urls = @()
        if ($bodyText) {
            $urls = Extract-Urls -Text $bodyText
        }
        $urls = $urls | Select-Object -Unique

        # Create safe filename
        $safeSubject = Get-SafeFilename -Name $subject
        $datePrefix = if ($parsedDate) { $parsedDate.ToString("yyyy-MM-dd") + " - " } else { "" }
        $fileName = "$datePrefix$safeSubject"

        # Ensure unique filename
        $baseName = $fileName
        $counter = 1
        while (Test-Path (Join-Path $GmailFolder "$fileName.md")) {
            $fileName = "$baseName ($counter)"
            $counter++
        }

        # Create YAML frontmatter
        $yaml = @"
---
type: email
from: "$($from -replace '"', '\"')"
to: "$($to -replace '"', '\"')"
subject: "$($subject -replace '"', '\"')"
date: $(if ($parsedDate) { $parsedDate.ToString("yyyy-MM-dd HH:mm:ss") } else { $date })
message_id: "$($messageId -replace '"', '\"')"
gmail_labels: "$($gmailLabels -replace '"', '\"')"
tags:
  - email
  - gmail-recipes
---

"@

        # Build markdown content
        $mdContent = $yaml
        $mdContent += "# $subject`n`n"

        if ($from) {
            $mdContent += "**From:** $from`n"
        }
        if ($to) {
            $mdContent += "**To:** $to`n"
        }
        if ($date) {
            $mdContent += "**Date:** $date`n"
        }
        $mdContent += "`n---`n`n"

        if ($bodyText) {
            $mdContent += $bodyText
        }

        if ($urls.Count -gt 0) {
            $mdContent += "`n`n## Links`n`n"
            foreach ($url in $urls) {
                $mdContent += "- $url`n"
            }
        }

        # Write email markdown file
        $emailFilePath = Join-Path $GmailFolder "$fileName.md"

        if ($DryRun) {
            Write-Host "[$processed] Would create: $emailFilePath" -ForegroundColor Yellow
        } else {
            [System.IO.File]::WriteAllText($emailFilePath, $mdContent, [System.Text.Encoding]::UTF8)
            $emailsCreated++
            Write-Host "[$processed] Created: $fileName.md" -ForegroundColor Green
        }

        # Check if this is a recipe
        $isRecipe = Test-IsRecipe -Subject $subject -Body $bodyText

        if ($isRecipe) {
            # Create recipe file
            $recipeFileName = "$datePrefix$safeSubject - Recipe"
            $recipeFilePath = Join-Path $RecipeFolder "$recipeFileName.md"

            $recipeYaml = @"
---
type: recipe
title: "$($subject -replace '"', '\"')"
source: email
source_date: $(if ($parsedDate) { $parsedDate.ToString("yyyy-MM-dd") } else { $date })
tags:
  - recipe
  - email-recipe
---

"@
            $recipeMd = $recipeYaml
            $recipeMd += "# $subject`n`n"
            $recipeMd += "**Source:** Email from $from`n"
            $recipeMd += "**Date:** $date`n`n"
            $recipeMd += "---`n`n"
            $recipeMd += $bodyText

            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($recipeFilePath, $recipeMd, [System.Text.Encoding]::UTF8)
                $recipesCreated++
                Write-Host "  -> Also created recipe: $recipeFileName.md" -ForegroundColor Cyan
            } else {
                Write-Host "  -> Would also create recipe: $recipeFileName.md" -ForegroundColor Yellow
            }
        }

        # Check for recipe URLs
        foreach ($url in $urls) {
            # Filter for recipe-looking URLs
            if ($url -match 'recipe|cook|food|kitchen|skillet|allrecipes|epicurious|seriouseats|delish|tasty|yummly|thekitchn|bonappetit|foodnetwork|simplyrecipes|budgetbytes|minimalistbaker|loveandlemons|halfbakedharvest|cooking|smittenkitchen|pinchofyum|damndelicious|ohsheglows|vegankitchen|fatfreevegan|happyherbivore|veggiebelly|theppk') {
                $urlsToFetch += @{
                    Url = $url
                    Subject = $subject
                    Date = $parsedDate
                    From = $from
                }
            }
        }

    } catch {
        $errors++
        Write-Host "[$processed] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Processed: $processed messages"
Write-Host "Emails created: $emailsCreated"
Write-Host "Recipes created: $recipesCreated"
Write-Host "Errors: $errors"
Write-Host "Recipe URLs found: $($urlsToFetch.Count)"

if ($urlsToFetch.Count -gt 0) {
    Write-Host "`nRecipe URLs to fetch:" -ForegroundColor Yellow
    $urlsToFetch | ForEach-Object { Write-Host "  $($_.Url)" }

    # Save URLs to file for manual/later processing
    $urlsFile = Join-Path $GmailFolder "_recipe_urls_to_fetch.txt"
    $urlsToFetch | ForEach-Object { "$($_.Subject)`t$($_.Url)" } | Out-File -FilePath $urlsFile -Encoding UTF8
    Write-Host "`nRecipe URLs saved to: $urlsFile" -ForegroundColor Green
}

Write-Host "`nDone!" -ForegroundColor Green
