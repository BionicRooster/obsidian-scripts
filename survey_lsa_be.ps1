# Survey LSA folder location and filenames with lowercase 'be' as Baha'i Era

# 1. Find LSA directories
Write-Output "=== LSA Directories ==="
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Directory | Where-Object { $_.Name -like '*LSA*' } | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

# 2. Find filenames with lowercase 'be' following a number (Baha'i Era date pattern)
#    Patterns: "181 be", "181be", "year 181 be", "181 B.E." etc.
#    We want: digits followed by optional space then 'be' as a word (case-insensitive match for 'be' not 'BE' or 'Be')
Write-Output "`n=== Files with lowercase 'be' after a number (possible Baha'i Era dates) ==="
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.Name -cmatch '\d+\s*be\b'  # case-sensitive: 'be' not 'BE'
} | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

# 3. Also check for ' be ' surrounded by spaces (might catch other patterns)
Write-Output "`n=== Files with ' be ' (lowercase, surrounded by spaces or word boundaries) ==="
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.Name -cmatch '(?<!\w)be(?!\w)'  # lowercase 'be' as whole word, case-sensitive
} | Select-Object -First 50 | ForEach-Object {
    Write-Output "  $($_.Name)"
}
