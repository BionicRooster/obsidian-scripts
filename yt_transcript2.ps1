# Fetch transcript in XML format (no fmt=json3) and parse it
$capUrl = 'https://www.youtube.com/api/timedtext?v=aU_VuYBL2X8&ei=6PPjaeC8CK-g0_wPm8bncQ&caps=asr&opi=112496729&exp=xpe&xoaf=5&xowf=1&xospf=1&hl=en&ip=0.0.0.0&ipbits=0&expire=1776571992&sparams=ip,ipbits,expire,v,ei,caps,opi,exp,xoaf&signature=3F303B0B707ED47D6E13F88375B7DA4C95C2C6E5.9EEF4851F09684F69DDB2BAE7F8600C5164D22E8&key=yt8&kind=asr&lang=en&variant=gemini'
$headers = @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
$resp = Invoke-WebRequest -Uri $capUrl -Headers $headers -UseBasicParsing
$xml = [xml]$resp.Content
foreach ($t in $xml.transcript.text) {
    $start = [double]$t.start
    $mins = [int]($start / 60)
    $secs = [int]($start % 60)
    $ts = '{0}:{1:D2}' -f $mins, $secs
    $text = $t.'#text' -replace '&#39;', "'" -replace '&amp;', '&' -replace '&quot;', '"' -replace '\n', ' '
    Write-Host "$ts`t$text"
}
