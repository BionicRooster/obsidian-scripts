# Extract transcript params from page and call get_transcript API
$content = Get-Content 'C:\Users\awt\yt_page.html' -Raw -Encoding UTF8

# Find the engagement panel params for transcript
$m = [regex]::Match($content, '"getTranscriptEndpoint":\{"params":"([^"]+)"')
if ($m.Success) {
    Write-Host "Transcript params found: $($m.Groups[1].Value)"
    $params = $m.Groups[1].Value
} else {
    Write-Host "No getTranscriptEndpoint found, trying alternate..."
    # Try to find any engagementPanel serializedShareEntity or similar
    $m2 = [regex]::Match($content, '"engagementPanelSectionListRenderer".*?"transcript".*?"params":"([^"]+)"')
    if ($m2.Success) { Write-Host "Alt params: $($m2.Groups[1].Value)" }
}

# Also try extracting the innertube API key
$mk = [regex]::Match($content, '"INNERTUBE_API_KEY":"([^"]+)"')
if ($mk.Success) { Write-Host "API Key: $($mk.Groups[1].Value)" }

# Extract client version
$mv = [regex]::Match($content, '"INNERTUBE_CLIENT_VERSION":"([^"]+)"')
if ($mv.Success) { Write-Host "Client version: $($mv.Groups[1].Value)" }
