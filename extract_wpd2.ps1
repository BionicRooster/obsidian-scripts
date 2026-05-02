# Better WPD text extractor - filters out binary noise
# Extracts only human-readable text segments
$dir = 'D:\Documents\NLP\Master Class'

function Get-CleanText($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)

    # Split into chunks by non-printable boundaries
    $found = [regex]::Matches($text, '[ a-zA-Z0-9\.,;:\?\!\-\(\)\[\]\''"#@&\*\/\+\=\<\>]{8,}')

    $results = @()
    foreach ($m in $found) {
        $s = $m.Value.Trim()
        # Must have at least 50% alphabetic characters to filter out binary/printer data
        $letters = ($s.ToCharArray() | Where-Object { [char]::IsLetter($_) }).Count
        $ratio = if ($s.Length -gt 0) { $letters / $s.Length } else { 0 }
        if ($ratio -gt 0.5 -and $s -match '\s' -and $s.Length -ge 10) {
            $results += $s
        }
    }
    return $results -join "`n"
}

$files = Get-ChildItem -Path $dir -File | Where-Object { $_.Extension -match '\.(wpd|doc|wri)$' }
foreach ($f in $files) {
    Write-Output "===== $($f.Name) ====="
    Write-Output (Get-CleanText $f.FullName)
    Write-Output ''
}
