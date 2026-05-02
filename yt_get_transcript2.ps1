# URL-decode params before using in API call
$apiKey = 'REMOVED_API_KEY'
$clientVersion = '2.20260416.01.00'
$paramsEncoded = 'CgthVV9WdVlCTDJYOBISQ2dOaGMzSVNBbVZ1R2dBJTNEGAEqM2VuZ2FnZW1lbnQtcGFuZWwtc2VhcmNoYWJsZS10cmFuc2NyaXB0LXNlYXJjaC1wYW5lbDAAOAFAAQ%3D%3D'
# URL-decode
$params = [uri]::UnescapeDataString($paramsEncoded)
Write-Host "Decoded params: $params"

$url = "https://www.youtube.com/youtubei/v1/get_transcript?key=$apiKey"

$bodyObj = @{
    context = @{
        client = @{
            clientName    = 'WEB'
            clientVersion = $clientVersion
            hl            = 'en'
            gl            = 'US'
        }
    }
    params  = $params
}
$body = $bodyObj | ConvertTo-Json -Depth 5

$headers = @{
    'User-Agent'      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Content-Type'    = 'application/json'
    'Origin'          = 'https://www.youtube.com'
    'Referer'         = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
    'X-Youtube-Client-Name'    = '1'
    'X-Youtube-Client-Version' = $clientVersion
}

try {
    $resp = Invoke-WebRequest -Uri $url -Method POST -Body $body -Headers $headers -UseBasicParsing
    Write-Host "Success. Length: $($resp.Content.Length)"
    $resp.Content | Out-File 'C:\Users\awt\yt_transcript_raw.json' -Encoding UTF8
    Write-Host $resp.Content.Substring(0, [Math]::Min(1000, $resp.Content.Length))
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
}
