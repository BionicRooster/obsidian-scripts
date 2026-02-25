$vault = 'D:\Obsidian\Main'
$enc   = [System.Text.Encoding]::UTF8
$results = @()

Get-ChildItem -Path $vault -Recurse -Filter '*.md' | ForEach-Object {
    $f = $_
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    $nameJapan    = $f.Name -ilike '*Japan*'
    $nameJapanese = $f.Name -ilike '*Japanese*'
    $tagJapan     = $text -match '(?m)^\s+- Japan'
    $contentMoc   = $text -match 'MOC - Japan & Japanese Culture'

    if ($nameJapan -or $nameJapanese -or $tagJapan -or $contentMoc) {
        if ($f.Name -notlike 'MOC - Japan*') {
            $reason = @()
            if ($nameJapan)    { $reason += 'name:Japan' }
            if ($nameJapanese) { $reason += 'name:Japanese' }
            if ($tagJapan)     { $reason += 'tag:Japan' }
            if ($contentMoc)   { $reason += 'MOC-linked' }
            $results += [PSCustomObject]@{
                File   = $f.Name -replace '\.md$',''
                Reason = $reason -join ', '
            }
        }
    }
}

$results | Sort-Object File | Format-Table -AutoSize -Wrap
Write-Host "Total: $($results.Count) notes matched"
