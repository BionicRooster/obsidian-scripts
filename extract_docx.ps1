param([string]$DocPath, [string]$OutPath)

$word = New-Object -ComObject Word.Application
$word.Visible = $false

$doc = $word.Documents.Open($DocPath)
$text = $doc.Content.Text
$doc.Close($false)
$word.Quit()

[System.IO.File]::WriteAllText($OutPath, $text, [System.Text.Encoding]::UTF8)
Write-Host "Done: $OutPath"
