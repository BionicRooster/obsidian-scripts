# move_classify_files.ps1 - Move recently classified files to correct folders

$vaultPath = 'D:\Obsidian\Main'

$moves = @(
    # New Research Brains: 10 - Clippings -> 01\Health\
    @{
        Src  = "$vaultPath\10 - Clippings\New Research Reveals Why Some Brains Can't Switch Off at Night.md"
        Dest = "$vaultPath\01\Health\New Research Reveals Why Some Brains Can't Switch Off at Night.md"
    },
    # Jerusalem Archaeology: 01\Religion -> 01\Social
    @{
        Src  = "$vaultPath\01\Religion\Jerusalem Archaeology Reveals Birth Of Christianity.md"
        Dest = "$vaultPath\01\Social\Jerusalem Archaeology Reveals Birth Of Christianity.md"
    }
)

foreach ($m in $moves) {
    if (-not (Test-Path $m.Src)) {
        Write-Host "NOT FOUND: $($m.Src)" -ForegroundColor Red
        continue
    }
    if (Test-Path $m.Dest) {
        Write-Host "DEST EXISTS: $($m.Dest)" -ForegroundColor Yellow
        continue
    }
    Move-Item -Path $m.Src -Destination $m.Dest
    Write-Host "MOVED: $([System.IO.Path]::GetFileName($m.Src))" -ForegroundColor Green
    Write-Host "   to: $($m.Dest)" -ForegroundColor DarkGray
}
