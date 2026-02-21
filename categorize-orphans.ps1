# Categorize orphan files by top-level folder
$orphanFile = "C:\Users\awt\PowerShell\Out\OrphanFiles_2025-12-24_121630.txt"
$lines = Get-Content $orphanFile | Where-Object { $_ -ne "" }

$categories = @{}
foreach ($line in $lines) {
    # Extract the folder after D:\Obsidian\Main\
    $relativePath = $line -replace "^D:\\Obsidian\\Main\\", ""
    $topFolder = ($relativePath -split "\\")[0]
    if (-not $categories.ContainsKey($topFolder)) {
        $categories[$topFolder] = 0
    }
    $categories[$topFolder]++
}

$categories.GetEnumerator() | Sort-Object Value -Descending | Format-Table @{L='Count';E={$_.Value}}, @{L='Folder';E={$_.Key}} -AutoSize
