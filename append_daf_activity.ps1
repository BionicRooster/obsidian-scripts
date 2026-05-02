$journal = 'D:\Obsidian\Main\2026-04-28.md'
$content = Get-Content -LiteralPath $journal -Encoding UTF8 -Raw
$entry = "`n- Clipped YouTube video: **CBA Coffee Chat - The DAF Opportunity** → ``10 - Clippings\``; linked to FOL MOC and Finance MOC"
$idx = $content.IndexOf('## My Notes')
if ($idx -ge 0) {
    $after = $idx + '## My Notes'.Length
    $next = [regex]::Match($content.Substring($after), '(?m)^---')
    if ($next.Success) {
        $pos = $after + $next.Index
        $content = $content.Substring(0, $pos) + $entry + "`n" + $content.Substring($pos)
    } else {
        $content = $content.TrimEnd() + $entry + "`n"
    }
    Set-Content -LiteralPath $journal -Value $content -Encoding UTF8 -NoNewline
    Write-Output "Appended"
}
