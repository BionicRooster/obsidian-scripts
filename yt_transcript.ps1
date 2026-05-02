$capUrl = 'https://www.youtube.com/api/timedtext?v=aU_VuYBL2X8&ei=6PPjaeC8CK-g0_wPm8bncQ&caps=asr&opi=112496729&exp=xpe&xoaf=5&xowf=1&xospf=1&hl=en&ip=0.0.0.0&ipbits=0&expire=1776571992&sparams=ip,ipbits,expire,v,ei,caps,opi,exp,xoaf&signature=3F303B0B707ED47D6E13F88375B7DA4C95C2C6E5.9EEF4851F09684F69DDB2BAE7F8600C5164D22E8&key=yt8&kind=asr&lang=en&variant=gemini&fmt=json3'
$headers = @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
try {
    $resp = Invoke-WebRequest -Uri $capUrl -Headers $headers -UseBasicParsing
    Write-Host $resp.Content
} catch {
    Write-Host "ERROR: $_"
    # Try XML format
    $capUrlXml = $capUrl -replace '&fmt=json3', ''
    $resp2 = Invoke-WebRequest -Uri $capUrlXml -Headers $headers -UseBasicParsing
    Write-Host $resp2.Content
}
