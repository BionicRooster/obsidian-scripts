# Script to fix MIME-encoded headers in Gmail export files
# This script decodes:
# - =?utf-8?Q?...?= (Quoted-Printable encoded words)
# - =?utf-8?B?...?= (Base64 encoded words)
# - =XX (hex codes like =3D for equals, =20 for space)

param(
    [switch]$DryRun  # If set, only show what would be changed without modifying files
)

# Function to decode Quoted-Printable encoded-word (=?utf-8?Q?...?=)
function Decode-QuotedPrintableWord {
    param([string]$Encoded)

    # Remove the =?utf-8?Q? prefix and ?= suffix
    $content = $Encoded -replace '^\=\?[Uu][Tt][Ff]-?8\?[Qq]\?' -replace '\?\=$'

    # Replace underscores with spaces (per RFC 2047)
    $content = $content -replace '_', ' '

    # Decode =XX hex sequences
    $decoded = [regex]::Replace($content, '=([0-9A-Fa-f]{2})', {
        param($match)
        [char][int]("0x" + $match.Groups[1].Value)
    })

    return $decoded
}

# Function to decode Base64 encoded-word (=?utf-8?B?...?=)
function Decode-Base64Word {
    param([string]$Encoded)

    # Remove the =?utf-8?B? prefix and ?= suffix
    $content = $Encoded -replace '^\=\?[Uu][Tt][Ff]-?8\?[Bb]\?' -replace '\?\=$'

    try {
        $bytes = [System.Convert]::FromBase64String($content)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
        return $decoded
    } catch {
        return $Encoded  # Return original if decode fails
    }
}

# Function to decode all MIME encoded-words in a string
function Decode-MIMEEncodedWords {
    param([string]$Text)

    # Pattern for Quoted-Printable encoded words
    $qpPattern = '\=\?[Uu][Tt][Ff]-?8\?[Qq]\?[^\?]+\?\='

    # Pattern for Base64 encoded words
    $b64Pattern = '\=\?[Uu][Tt][Ff]-?8\?[Bb]\?[^\?]+\?\='

    # Decode Quoted-Printable
    $Text = [regex]::Replace($Text, $qpPattern, {
        param($match)
        Decode-QuotedPrintableWord $match.Value
    })

    # Decode Base64
    $Text = [regex]::Replace($Text, $b64Pattern, {
        param($match)
        Decode-Base64Word $match.Value
    })

    return $Text
}

# Function to decode standalone QP codes in body (=3D, =20, etc.)
function Decode-QuotedPrintableBody {
    param([string]$Text)

    # Decode =XX hex sequences (but only valid ASCII hex codes)
    $decoded = [regex]::Replace($Text, '=([0-9A-Fa-f]{2})', {
        param($match)
        $hexValue = [int]("0x" + $match.Groups[1].Value)
        # Only decode printable ASCII and common whitespace
        if ($hexValue -ge 32 -and $hexValue -le 126) {
            return [char]$hexValue
        } elseif ($hexValue -eq 10 -or $hexValue -eq 13 -or $hexValue -eq 9) {
            return [char]$hexValue
        }
        return $match.Value  # Return original if not safe to decode
    })

    return $decoded
}

# Target folder
$folder = "D:\Obsidian\Main\04 - GMail"

# Search patterns for the files we need to fix
$searchPatterns = @(
    "Preserving the Records of the Tobacco Industry",
    "Most Loved Recipe",
    "Showing Up for Yourself",
    "February 10, 2014 Weekly Newsletter",
    "Esteemed Doctor",
    "Fresh Pins",
    "ebook bargains",
    "handpicked new releases"
)

# Get all matching files
$allFiles = Get-ChildItem -Path $folder -Filter "*.md"
$targetFiles = @()

foreach ($pattern in $searchPatterns) {
    $matches = $allFiles | Where-Object { $_.Name -like "*$pattern*" }
    foreach ($m in $matches) {
        if ($targetFiles.FullName -notcontains $m.FullName) {
            $targetFiles += $m
        }
    }
}

Write-Host "Found $($targetFiles.Count) files to process:"
foreach ($f in $targetFiles) {
    Write-Host "  - $($f.Name)"
}
Write-Host ""

# Process each file
foreach ($file in $targetFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    # Read file content with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content

    # Check for MIME encoded-words
    $hasMIME = $content -match '\=\?[Uu][Tt][Ff]-?8\?[QqBb]\?'

    # Check for QP body codes (=3D, =20, etc.) - but avoid false positives
    $hasQPCodes = $content -match '=[0-9A-Fa-f]{2}'

    if ($hasMIME) {
        Write-Host "  Found MIME encoded-words, decoding..." -ForegroundColor Yellow
        $content = Decode-MIMEEncodedWords $content
    }

    # Only decode QP body codes if they look like email artifacts
    # Check for common patterns like =3D (equals), =20 (space), =0A (newline)
    if ($content -match '=3D|=20|=0[AD]') {
        Write-Host "  Found QP body codes (=3D, =20, etc.), decoding..." -ForegroundColor Yellow
        $content = Decode-QuotedPrintableBody $content
    }

    # Check if anything changed
    if ($content -ne $originalContent) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would save changes" -ForegroundColor Green

            # Show first few lines that changed
            $origLines = $originalContent -split "`n" | Select-Object -First 20
            $newLines = $content -split "`n" | Select-Object -First 20
            for ($i = 0; $i -lt $origLines.Count; $i++) {
                if ($origLines[$i] -ne $newLines[$i]) {
                    Write-Host "    Line $($i+1):" -ForegroundColor DarkGray
                    Write-Host "      OLD: $($origLines[$i])" -ForegroundColor Red
                    Write-Host "      NEW: $($newLines[$i])" -ForegroundColor Green
                }
            }
        } else {
            # Write with UTF-8 encoding (no BOM for Obsidian compatibility)
            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  Saved changes" -ForegroundColor Green
        }
    } else {
        Write-Host "  No MIME encoding found or no changes needed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
