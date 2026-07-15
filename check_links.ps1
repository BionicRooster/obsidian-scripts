# Verify Related Notes links exist in vault
$linksToCheck = @(
    'NLP for Programmers - May 1995',
    'NLP Forum - DHE Article by Carolyn Maiers (April 1995)',
    'I Tried Zenclora, a Super-fast Linux Distro with Zero Bloat - and One Truly Special Feature',
    'Trevor Noah Explains How Kintsugi Helped Him Overcome Life''s Tragedies',
    'NLP Master Class Week 5',
    'NLP Master Class Week 7',
    'NLP Language Patterns',
    'Watch a 106-Year-Old Wizard of Oz Book Get Magically Restored'
)

foreach ($name in $linksToCheck) {
    $found = Get-ChildItem 'C:\Users\awt\Sync\Obsidian' -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -eq $name } | Select-Object -First 1
    if ($found) {
        Write-Host "EXISTS: $name"
    } else {
        Write-Host "MISSING: $name"
    }
}

# Search Downloads for Malinda Lloyd
Write-Host "`n=== Downloads search for Malinda Lloyd ==="
Get-ChildItem 'D:\Downloads' -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like '*Malinda*' -or $_.Name -like '*Lloyd*'
} | Select-Object FullName, Length, LastWriteTime
