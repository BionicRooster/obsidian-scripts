$moves = @(
    @{ src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Why You Wake at 217 am.md";
       dst = "C:\Users\awt\Sync\Obsidian\01\Health\Why You Wake at 217 am.md" },
    @{ src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\The Dishwasher in Your Brain.md";
       dst = "C:\Users\awt\Sync\Obsidian\01\Health\The Dishwasher in Your Brain.md" }
)
foreach ($m in $moves) {
    if (Test-Path $m.src) {
        Move-Item -Path $m.src -Destination $m.dst -Force
        Write-Output "Moved: $($m.src | Split-Path -Leaf)"
    } else {
        Write-Output "NOT FOUND: $($m.src | Split-Path -Leaf)"
    }
}
