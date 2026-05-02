# Move clippings to appropriate 01/ subdirectories
$bahaiDir = "D:\Obsidian\Main\01\Bah" + [char]0x00e1 + "'" + [char]0x00ed

$moves = @(
    @{ src = "D:\Obsidian\Main\10 - Clippings\Readings From Cluster Reflection Gathering.md";
       dst = "$bahaiDir\Readings From Cluster Reflection Gathering.md" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\How 400-Year-Old Books Are Professionally Restored.md";
       dst = "D:\Obsidian\Main\01\Science\How 400-Year-Old Books Are Professionally Restored.md" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Ortelius Atlas Conservation - Disbinding and Washing the Maps.md";
       dst = "D:\Obsidian\Main\01\Science\Ortelius Atlas Conservation - Disbinding and Washing the Maps.md" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Ortelius Atlas Conservation - Paper Chemistry and Deacidification.md";
       dst = "D:\Obsidian\Main\01\Science\Ortelius Atlas Conservation - Paper Chemistry and Deacidification.md" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Book Conservation - 170-Year-Old Marriage Record Book (NEDCC).md";
       dst = "D:\Obsidian\Main\01\Science\Book Conservation - 170-Year-Old Marriage Record Book (NEDCC).md" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\The Suppression of Economic History in American Schools - Edna Morse (1901).md";
       dst = "D:\Obsidian\Main\01\Social\The Suppression of Economic History in American Schools - Edna Morse (1901).md" }
)

foreach ($m in $moves) {
    if (Test-Path $m.src) {
        Move-Item -Path $m.src -Destination $m.dst -Force
        Write-Output "Moved: $($m.src | Split-Path -Leaf)"
    } else {
        Write-Output "NOT FOUND: $($m.src | Split-Path -Leaf)"
    }
}
