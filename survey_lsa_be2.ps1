# Broader survey: LSA folder tree and all 'be' filename variations

# 1. Full LSA folder tree
Write-Output "=== LSA Folder Tree ==="
Get-ChildItem 'D:\Obsidian\Main\LSA' -Recurse | ForEach-Object {
    $indent = '  ' * ($_.FullName.Split('\').Count - 'D:\Obsidian\Main\LSA'.Split('\').Count)
    if ($_.PSIsContainer) {
        Write-Output "${indent}[DIR] $($_.Name)"
    } else {
        Write-Output "${indent}$($_.Name)"
    }
}

# 2. Any .md files anywhere containing 'be' (case-sensitive lowercase) in the basename
#    as a standalone token - includes patterns like "be", "- be -", "be.", etc.
Write-Output "`n=== All files with standalone lowercase 'be' in name ==="
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.BaseName -cmatch '(?i)(?<![A-Za-z])be(?![A-Za-z])'
} | Where-Object {
    # Only lowercase 'be' (not BE or Be)
    $_.BaseName -cmatch '(?<![A-Za-z])be(?![A-Za-z])'
} | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

# 3. Check LSA files specifically for 'be' in any case
Write-Output "`n=== LSA files with 'be' or 'BE' or 'B.E.' in name ==="
Get-ChildItem 'D:\Obsidian\Main\LSA' -Recurse -Filter '*.md' | Where-Object {
    $_.Name -imatch 'b\.?e\.?'
} | ForEach-Object {
    Write-Output "  $($_.Name)"
}
