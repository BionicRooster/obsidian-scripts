# Script to apply approved links to Obsidian vault
# Replaces unlinked mentions with [[wikilinks]]

param(
    [int]$StartIndex = 0,    # Starting index in cache (0-based)
    [int]$Count = 50         # Number of connections to process
)

$cacheFile = "C:\Users\awt\PowerShell\connection_cache.json"  # Path to cached connections
$logFile = "C:\Users\awt\PowerShell\logs\link_changes.log"    # Log file for tracking changes

# Load cached connections
if (-not (Test-Path $cacheFile)) {
    Write-Host "ERROR: Cache file not found. Run analyze_connections.ps1 first."
    exit 1
}

$allConnections = Get-Content $cacheFile | ConvertFrom-Json  # Load all connections from cache
$endIndex = [Math]::Min($StartIndex + $Count, $allConnections.Count)  # Calculate end index

Write-Host "Applying links for connections $($StartIndex + 1) to $endIndex..."
Write-Host ""

$successCount = 0   # Counter for successful link applications
$skipCount = 0      # Counter for skipped connections
$errorCount = 0     # Counter for errors

# Process each connection in the specified range
for ($i = $StartIndex; $i -lt $endIndex; $i++) {
    $conn = $allConnections[$i]  # Current connection to process
    $sourceFile = $conn.SourcePath  # Path to the source file
    $targetNote = $conn.TargetNote  # Name of the target note to link

    Write-Host "[$($i + 1)] $($conn.SourceFile) -> $targetNote"

    # Read the source file content
    $content = Get-Content -Path $sourceFile -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Host "   SKIP: Could not read file"
        $skipCount++
        continue
    }

    # Escape special regex characters in the target note title
    $escapedTarget = [regex]::Escape($targetNote)

    # Pattern to find unlinked mentions (whole word, not already in brackets)
    # Uses negative lookbehind for [[ and negative lookahead for ]]
    $pattern = "(?<!\[\[)(?<!\[\[[^\]]*\|)\b($escapedTarget)\b(?!\]\])(?!\|[^\]]*\]\])"

    # Check if there's an unlinked mention
    if ($content -match $pattern) {
        # Replace the first unlinked mention with a wikilink
        # We only replace the FIRST occurrence to be conservative
        $newContent = [regex]::Replace(
            $content,
            $pattern,
            "[[$targetNote]]",
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase,
            [TimeSpan]::FromSeconds(5)
        )

        # Only write if content actually changed
        if ($newContent -ne $content) {
            # Write the updated content back to the file
            $newContent | Set-Content -Path $sourceFile -NoNewline -Encoding UTF8

            Write-Host "   OK: Linked '$targetNote'"
            $successCount++

            # Log the change
            $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $($conn.SourceFile) | $targetNote"
            Add-Content -Path $logFile -Value $logEntry
        } else {
            Write-Host "   SKIP: No change needed (may already be linked)"
            $skipCount++
        }
    } else {
        Write-Host "   SKIP: Pattern not found (may already be linked)"
        $skipCount++
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "SUMMARY"
Write-Host "=========================================="
Write-Host "Successful links: $successCount"
Write-Host "Skipped: $skipCount"
Write-Host "Errors: $errorCount"
Write-Host ""
Write-Host "Changes logged to: $logFile"
