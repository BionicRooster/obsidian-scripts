Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$PersonIndex = @{}
$PeopleNoteNames = @{ 'John Smith' = $true }
$MaxNameLength = 50
$IgnoredValues = @('n/a', 'unknown')
$NotPersonPatterns = @('^\d', '^https?://')

function Test-IsNotAName {
    param([string]$Value)
    $v = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $true }
    if ($v.Length -gt $MaxNameLength) { return $true }
    return $false
}

function ConvertTo-LastFirst {
    param([string]$Name)
    $n = $Name -replace '^\[\[(.+?)(\|.+?)?\]\]$', '$1'
    $n = $n.Trim()
    if ($n -match '^[^,]+,\s*.+$') { return $n }
    $parts = $n -split '\s+'
    if ($parts.Count -le 1) { return $n }
    $last = $parts[-1]
    $first = ($parts[0..($parts.Count - 2)]) -join ' '
    return "$last, $first"
}

function Register-Person {
    param([string]$RawName, [string]$SourceFile)
    $clean = $RawName -replace '^\[\[(.+?)(\|.+?)?\]\]$', '$1'
    $clean = $clean.Trim()
    if (Test-IsNotAName $clean) { return }
    $normalized = ConvertTo-LastFirst $clean
    if (-not $PersonIndex.ContainsKey($normalized)) {
        $PersonIndex[$normalized] = @{ SourceFiles = [System.Collections.Generic.HashSet[string]]::new() }
    }
    [void]$PersonIndex[$normalized].SourceFiles.Add($SourceFile)
}

Register-Person -RawName 'Jane Doe' -SourceFile 'TestFile'
Register-Person -RawName 'Adams, Scott' -SourceFile 'AnotherFile'
Write-Host "PersonIndex count: $($PersonIndex.Count)"
foreach ($k in $PersonIndex.Keys) { Write-Host "  Key: $k" }
