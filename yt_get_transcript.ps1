# Use get_transcript innertube API with the params from the page
$apiKey = 'REMOVED_API_KEY'
$clientVersion = '2.20260416.01.00'
$params = 'CgthVV9WdVlCTDJYOBISQ2dOaGMzSVNBbVZ1R2dBJTNEGAEqM2VuZ2FnZW1lbnQtcGFuZWwtc2VhcmNoYWJsZS10cmFuc2NyaXB0LXNlYXJjaC1wYW5lbDAAOAFAAQ%3D%3D'

$url = "https://www.youtube.com/youtubei/v1/get_transcript?key=$apiKey"

$body = @{
    context = @{
        client = @{
            clientName    = 'WEB'
            clientVersion = $clientVersion
            hl            = 'en'
        }
    }
    params  = $params
} | ConvertTo-Json -Depth 5

$headers = @{
    'User-Agent'   = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    'Content-Type' = 'application/json'
    'Origin'       = 'https://www.youtube.com'
    'Referer'      = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
}

$resp = Invoke-WebRequest -Uri $url -Method POST -Body $body -Headers $headers -UseBasicParsing
$resp.Content | Out-File 'C:\Users\awt\yt_transcript_raw.json' -Encoding UTF8
Write-Host "Saved. Length: $($resp.Content.Length)"
Write-Host $resp.Content.Substring(0, [Math]::Min(500, $resp.Content.Length))
