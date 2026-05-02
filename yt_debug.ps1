# Save full page content and look for transcript data
$url = 'https://www.youtube.com/watch?v=aU_VuYBL2X8'
$headers = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Accept-Language' = 'en-US,en;q=0.9'
}
$response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing
$content = $response.Content

# Save page for inspection
$content | Out-File 'C:\Users\awt\yt_page.html' -Encoding UTF8

# Look for engagementPanel / transcript in page
if ($content -match 'engagementPanel') { Write-Host 'engagementPanel: YES' } else { Write-Host 'engagementPanel: NO' }
if ($content -match 'transcriptRenderer') { Write-Host 'transcriptRenderer: YES' } else { Write-Host 'transcriptRenderer: NO' }
if ($content -match 'ytInitialPlayerResponse') { Write-Host 'ytInitialPlayerResponse: YES' } else { Write-Host 'ytInitialPlayerResponse: NO' }

# Extract description
$m = [regex]::Match($content, '"shortDescription":"((?:[^"\\]|\\.)*)\"')
if ($m.Success) { Write-Host "`nDESCRIPTION:`n$($m.Groups[1].Value -replace '\\n',"`n" -replace '\\u0026','&')" }
