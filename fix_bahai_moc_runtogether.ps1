$vault   = 'D:\Obsidian\Main'
$dotD    = [char]0x1E0D
$aAcute  = [char]0x00E1

# Fix run-together ]]## in Baha'i Faith MOC
$bahai = Get-ChildItem "$vault\00 - Home Dashboard" |
         Where-Object { $_.Name -like 'MOC - Bah*Faith*' } | Select-Object -First 1

$content = Get-Content -LiteralPath $bahai.FullName -Encoding UTF8 -Raw
$fixed   = $content -replace '(\]\])(#{1,3} )', "`$1`n`$2"

if ($fixed -ne $content) {
    Set-Content -LiteralPath $bahai.FullName -Value $fixed -Encoding UTF8 -NoNewline
    Write-Output "Fixed run-together in $($bahai.Name)"
} else {
    Write-Output "No run-together found"
}

# Final zero-check
$bad = 0
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($c -and ($c -cmatch "Ridv[a$aAcute]n")) { $bad++ }
}
Write-Output "Final wrong-d count: $bad"

# Journal entry
$journal = 'D:\Obsidian\Main\2026-04-28.md'
$jContent = Get-Content -LiteralPath $journal -Encoding UTF8 -Raw
$entry = "`n- **Ri$($dotD)v$($aAcute)n dotted-d fix**: found and replaced 261+ instances of incorrect `Ri$($dotD)v$($aAcute)n` spelling across 145 files; renamed 9 .md files (5 already had $($aAcute) + wrong d; 4 had neither); fixed Bah$($aAcute)'$($dotD) Faith MOC run-together"
$idx = $jContent.IndexOf('## My Notes')
if ($idx -ge 0) {
    $after = $idx + '## My Notes'.Length
    $next  = [regex]::Match($jContent.Substring($after), '(?m)^---')
    if ($next.Success) {
        $pos = $after + $next.Index
        $jContent = $jContent.Substring(0, $pos) + $entry + "`n" + $jContent.Substring($pos)
    } else {
        $jContent = $jContent.TrimEnd() + $entry + "`n"
    }
    Set-Content -LiteralPath $journal -Value $jContent -Encoding UTF8 -NoNewline
    Write-Output "Journal updated"
}
