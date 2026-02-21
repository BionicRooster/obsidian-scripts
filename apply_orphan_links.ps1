# Script to apply bidirectional links for orphan files

$connectionFile = "C:\Users\awt\PowerShell\orphan_connections.json"
$logFile = "C:\Users\awt\PowerShell\logs\orphan_link_changes.log"

# Load connections
$connections = Get-Content $connectionFile | ConvertFrom-Json
Write-Host "Applying $($connections.Count) orphan connections..."

$successCount = 0
$skipCount = 0

foreach ($conn in $connections) {
    $sourceFile = $conn.SourcePath
    $targetTitle = $conn.OrphanTitle

    # Read source file
    $content = Get-Content -Path $sourceFile -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        $skipCount++
        continue
    }

    # Escape regex special characters
    $escapedTarget = [regex]::Escape($targetTitle)

    # Pattern for unlinked mention
    $pattern = "(?<!\[\[)(?<!\[\[[^\]]*\|)\b($escapedTarget)\b(?!\]\])(?!\|[^\]]*\]\])"

    if ($content -match $pattern) {
        # Replace with link
        $newContent = [regex]::Replace(
            $content,
            $pattern,
            "[[$targetTitle]]",
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($newContent -ne $content) {
            try {
                $newContent | Set-Content -Path $sourceFile -NoNewline -Encoding UTF8 -ErrorAction Stop
                $successCount++
                Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $($conn.SourceFile) | $targetTitle"
                Write-Host "OK: $($conn.SourceFile) -> $targetTitle"
            } catch {
                Write-Host "SKIP (locked): $($conn.SourceFile)"
                $skipCount++
            }
        } else {
            $skipCount++
        }
    } else {
        $skipCount++
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "SUMMARY"
Write-Host "=========================================="
Write-Host "Successful links: $successCount"
Write-Host "Skipped: $skipCount"
