# Read the orphan files list
$files = Get-Content 'C:\Users\awt\PowerShell\Out\OrphanFiles_2025-12-22_084508.txt'

# Hash table to count files per folder
$folders = @{}

foreach ($f in $files) {
    if ($f -match 'D:\\Obsidian\\Main\\([^\\]+)') {
        $folder = $matches[1]
        if ($folders.ContainsKey($folder)) {
            $folders[$folder]++
        } else {
            $folders[$folder] = 1
        }
    }
}

# Display results sorted by count
$folders.GetEnumerator() | Sort-Object Value -Descending | Format-Table @{L='Count';E={$_.Value}}, @{L='Folder';E={$_.Key}} -AutoSize
