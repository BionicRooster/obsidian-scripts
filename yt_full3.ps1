# Try alternative transcript endpoints
$vid = 'aU_VuYBL2X8'
$headers = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Accept-Language' = 'en-US,en;q=0.9'
}

# Try listing available transcripts
$listUrl = "https://www.youtube.com/api/timedtext?v=$vid&type=list"
Write-Host "=== Transcript list ==="
try {
    $r = Invoke-WebRequest -Uri $listUrl -Headers $headers -UseBasicParsing
    Write-Host "Length: $($r.Content.Length)"
    Write-Host $r.Content
} catch { Write-Host "Error: $_" }

# Try the inner API
Write-Host "`n=== Inner API attempt ==="
$innerUrl = "https://www.youtube.com/youtubei/v1/get_transcript?key=REMOVED_API_KEY"
$body = @{
    context = @{
        client = @{
            clientName = "WEB"
            clientVersion = "2.20240101"
        }
    }
    params = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`n`t$vid"))
} | ConvertTo-Json -Depth 5
try {
    $r2 = Invoke-WebRequest -Uri $innerUrl -Method POST -Body $body -ContentType 'application/json' -Headers $headers -UseBasicParsing
    Write-Host "Length: $($r2.Content.Length)"
    Write-Host $r2.Content.Substring(0, [Math]::Min(500, $r2.Content.Length))
} catch { Write-Host "Error: $_" }
