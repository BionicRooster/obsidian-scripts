# Include visitorData from page in the API request
$apiKey = 'REMOVED_API_KEY'
$clientVersion = '2.20260416.01.00'
$params = 'CgthVV9WdVlCTDJYOBISQ2dOaGMzSVNBbVZ1R2dBJTNEGAEqM2VuZ2FnZW1lbnQtcGFuZWwtc2VhcmNoYWJsZS10cmFuc2NyaXB0LXNlYXJjaC1wYW5lbDAAOAFAAQ=='
$visitorData = 'CgtrTmNJdDRPQWx2NCi16I_PBjIKCgJVUxIEGgAgEg=='

$url = "https://www.youtube.com/youtubei/v1/get_transcript?key=$apiKey&prettyPrint=false"

$bodyObj = @{
    context = @{
        client = @{
            clientName    = 'WEB'
            clientVersion = $clientVersion
            hl            = 'en'
            gl            = 'US'
            visitorData   = $visitorData
        }
    }
    params  = $params
}
$body = $bodyObj | ConvertTo-Json -Depth 5

$headers = @{
    'User-Agent'               = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Content-Type'             = 'application/json'
    'Origin'                   = 'https://www.youtube.com'
    'Referer'                  = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
    'X-Youtube-Client-Name'    = '1'
    'X-Youtube-Client-Version' = $clientVersion
    'X-Goog-Visitor-Id'        = $visitorData
}

try {
    $resp = Invoke-WebRequest -Uri $url -Method POST -Body $body -Headers $headers -UseBasicParsing
    Write-Host "Success. Length: $($resp.Content.Length)"
    $resp.Content | Out-File 'C:\Users\awt\yt_transcript_raw.json' -Encoding UTF8
    # Parse and print the transcript segments
    $json = $resp.Content | ConvertFrom-Json
    $actions = $json.actions
    Write-Host "Actions count: $($actions.Count)"
    Write-Host $resp.Content.Substring(0, [Math]::Min(2000, $resp.Content.Length))
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    Write-Host "Error $statusCode`: $($_.Exception.Message)"
}
