# verify_moves.ps1 - Confirms the 4 classified files reached their target folders

$checks = @(
    @{ dir = 'D:\Obsidian\Main\01\Science'; pattern = '*Ancient scrolls*' },
    @{ dir = 'D:\Obsidian\Main\01\Science'; pattern = '*book scientist*' },
    @{ dir = 'D:\Obsidian\Main\01\PKM';    pattern = '*Claude Code*Obsidian*' },
    @{ dir = 'D:\Obsidian\Main\01\PKM';    pattern = 'Claude MCP*' }
)

foreach ($c in $checks) {
    $found = Get-ChildItem -Path $c.dir -Filter $c.pattern -ErrorAction SilentlyContinue
    if ($found) {
        Write-Output "OK : $($found.Name)"
    } else {
        Write-Output "MISSING: $($c.pattern) in $($c.dir)"
    }
}
