[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$inputFile = 'C:\Users\awt\.claude\projects\C--Users-awt\5efd598c-2d96-481b-93b6-971c58264964\tool-results\toolu_01UAvmoJ37SoZ3QLyb9vyTqi.txt'
$content = Get-Content $inputFile -Encoding UTF8

# Track names and which files they appear in
$nameFiles = @{}

foreach ($line in $content) {
    # Extract source file path from line like: D:\path\file.md:19:**From:** Name
    $filePath = ''
    if ($line -match '^(D:\\[^:]+\.md):') {
        $filePath = $Matches[1]
    }

    # Match **From:** Name pattern
    if ($line -match '\*\*From:\*\*\s+([A-Z][a-zA-Z.]+(?:\s+[A-Z][a-zA-Z.]+){1,3})') {
        $name = $Matches[1].Trim()
        # Remove trailing bold markers
        $name = $name -replace '\s*\*\*.*$', ''
        $name = $name.Trim()

        if ($name.Length -gt 3 -and $name -notmatch '^\d') {
            if (-not $nameFiles.ContainsKey($name)) {
                $nameFiles[$name] = @()
            }
            if ($filePath -and $nameFiles[$name] -notcontains $filePath) {
                $nameFiles[$name] += $filePath
            }
        }
    }
}

# Output sorted by file count desc
$nameFiles.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    $fileCount = $_.Value.Count
    $files = ($_.Value | ForEach-Object { Split-Path $_ -Leaf }) -join '; '
    Write-Output "$($_.Key)`t$fileCount`t$files"
}
