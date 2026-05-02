$url = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
$headers = @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
$response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing
$content = $response.Content

if ($content -match '"title":"([^"]+)"') { Write-Host "TITLE: $($matches[1])" }
if ($content -match '"ownerChannelName":"([^"]+)"') { Write-Host "CHANNEL: $($matches[1])" }
if ($content -match '"shortDescription":"([^"]{0,400})"') { Write-Host "DESC: $($matches[1])" }
if ($content -match 'captionTracks') { Write-Host "CAPTIONS: found" } else { Write-Host "CAPTIONS: not found" }

$capMatches = [regex]::Matches($content, '"baseUrl":"(https://www\.youtube\.com/api/timedtext[^"]+)"')
foreach ($m in $capMatches) {
    $capUrl = $m.Groups[1].Value -replace '\\u0026', '&'
    Write-Host "CAP_URL: $capUrl"
    break
}
