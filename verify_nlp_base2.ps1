$vault = "D:\Obsidian\Main"
$enc   = [System.Text.Encoding]::UTF8
$results = @()

Get-ChildItem -Path $vault -Recurse -Filter "*.md" | ForEach-Object {
    $f = $_
    $bytes  = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    $tagNLP      = $text -match '(?m)^\s+- NLP($|\s)'
    $tagNLPPsy   = $text -match '(?m)^\s+- NLP_Psy'
    $tagPsych    = $text -match '(?m)^\s+- psychology'
    $nameNLP     = $f.Name -ilike '*NLP*'
    $inFolder    = $f.FullName -like '*\NLP_Psy\*'

    if ($tagNLP -or $tagNLPPsy -or $tagPsych -or $nameNLP -or $inFolder) {
        if ($f.Name -notlike 'MOC - NLP*') {
            $reason = @()
            if ($inFolder)   { $reason += 'path:NLP_Psy' }
            if ($tagNLP)     { $reason += 'tag:NLP' }
            if ($tagNLPPsy)  { $reason += 'tag:NLP_Psy' }
            if ($tagPsych)   { $reason += 'tag:psychology' }
            if ($nameNLP)    { $reason += 'name:NLP' }
            $results += [PSCustomObject]@{
                File   = $f.Name -replace '\.md$',''
                Folder = $f.Directory.Name
                Reason = $reason -join ', '
            }
        }
    }
}

Write-Host "=== OUTSIDE NLP_Psy folder ==="
$results | Where-Object { $_.Folder -ne 'NLP_Psy' } | Sort-Object File | Format-Table File,Folder,Reason -AutoSize

Write-Host "Total inside NLP_Psy:  $(($results | Where-Object {$_.Folder -eq 'NLP_Psy'}).Count)"
Write-Host "Total outside NLP_Psy: $(($results | Where-Object {$_.Folder -ne 'NLP_Psy'}).Count)"
Write-Host "Grand total:           $($results.Count)"
