# Get fresh page, find all caption URLs, try each
$url = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
$headers = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Accept-Language' = 'en-US,en;q=0.9'
}
$response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing
$content = $response.Content

# Find ALL caption base URLs
$capMatches = [regex]::Matches($content, '"baseUrl":"(https://www\.youtube\.com/api/timedtext[^"]+)"')
Write-Host "Found $($capMatches.Count) caption URLs"
foreach ($m in $capMatches) {
    $u = $m.Groups[1].Value -replace '\\u0026', '&'
    Write-Host "URL: $u"
}

# Try the first URL without variant parameter
if ($capMatches.Count -gt 0) {
    $capUrl = $capMatches[0].Groups[1].Value -replace '\\u0026', '&'
    # Remove variant=gemini if present, try plain XML
    $capUrl = $capUrl -replace '&variant=gemini', ''
    Write-Host "`nTrying: $capUrl"
    $resp = Invoke-WebRequest -Uri $capUrl -Headers $headers -UseBasicParsing
    Write-Host "Length: $($resp.Content.Length)"
    if ($resp.Content.Length -gt 0) {
        Write-Host $resp.Content.Substring(0, [Math]::Min(300, $resp.Content.Length))
    }
}
