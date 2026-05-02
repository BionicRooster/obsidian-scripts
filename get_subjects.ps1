# Get thread topics from NLP forum file
$content = Get-Content 'C:\Users\awt\nlp_extracted\NLP-FRUM.WPD.txt' -Encoding UTF8
Write-Host "Total lines: $($content.Count)"
# Extract lines that look like Subject headers
$subjects = $content | Where-Object { $_ -match '^\? .+ \?$' -or $_ -match '^Subject\s*:' }
$subjects | Select-Object -Unique | ForEach-Object { Write-Host $_ }
