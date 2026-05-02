# Fetch page, extract fresh caption URL, then download and parse transcript
$url = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
$headers = @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'; 'Accept-Language' = 'en-US,en;q=0.9'}
$response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing
$content = $response.Content

# Find caption base URL
$capMatches = [regex]::Matches($content, '"baseUrl":"(https://www\.youtube\.com/api/timedtext[^"]+)"')
if ($capMatches.Count -eq 0) { Write-Host "No caption URL found"; exit }

$capUrl = $capMatches[0].Groups[1].Value -replace '\\u0026', '&'
Write-Host "Using caption URL: $capUrl" | Out-Null

# Fetch transcript XML
$resp = Invoke-WebRequest -Uri $capUrl -Headers $headers -UseBasicParsing
Write-Host "Response length: $($resp.Content.Length)"
Write-Host "Content: $($resp.Content.Substring(0, [Math]::Min(500, $resp.Content.Length)))"
