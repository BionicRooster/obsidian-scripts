# find_orphans.ps1
# Locate orphan files listed in Orphan Files.md

$vaultRoot = 'D:\Obsidian\Main'

$targets = @(
    '2010 Personal Calendar Summary.md',
    '2011 Personal Calendar Summary.md',
    '2012 Personal Calendar Summary.md',
    '2013 Personal Calendar Summary.md',
    '2014 Personal Calendar Summary.md',
    '2015 Personal Calendar Summary.md',
    '2016 Personal Calendar Summary.md',
    '2017 Personal Calendar Summary.md',
    '2018 Personal Calendar Summary.md',
    '2019 Personal Calendar Summary.md',
    '2020 Personal Calendar Summary.md',
    '2021 Personal Calendar Summary.md',
    '2022 Personal Calendar Summary.md',
    '2023 Personal Calendar Summary.md',
    '2024 Personal Calendar Summary.md',
    '2025 Personal Calendar Summary.md',
    '2026-04-14.md',
    'HCAS Mark Updegrove 2026 Schedule.md'
)

foreach ($t in $targets) {
    $found = Get-ChildItem -Path $vaultRoot -Recurse -Filter $t -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Write-Output "FOUND: $($found.FullName)"
    } else {
        Write-Output "MISSING: $t"
    }
}
