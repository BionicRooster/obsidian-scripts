# move_classified.ps1 — moves two newly classified clippings to their target folders

$moves = @(
    @{ From = "D:\Obsidian\Main\10 - Clippings\Summarize the movie _My Father's Name.md";         To = "D:\Obsidian\Main\01\Social\Summarize the movie _My Father's Name.md" },
    @{ From = "D:\Obsidian\Main\10 - Clippings\The ancient reason there are 60 minutes in an hour.md"; To = "D:\Obsidian\Main\01\Science\The ancient reason there are 60 minutes in an hour.md" }
)

foreach ($m in $moves) {
    if (Test-Path $m.From) {
        Move-Item -LiteralPath $m.From -Destination $m.To -Force
        Write-Host "Moved: $($m.From)" -ForegroundColor Green
        Write-Host "   To: $($m.To)" -ForegroundColor Cyan
    } else {
        Write-Host "NOT FOUND: $($m.From)" -ForegroundColor Red
    }
}
