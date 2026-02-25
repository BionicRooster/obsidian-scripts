$files = @(
    "D:\Obsidian\Main\09 - Kindle Clippings\Boyle-Alan Turing.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Bruzenak_et_al-Retire to an RV.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Dorfman-Mattelart-How to Read Donald Duck.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Fisher-The Canals of Britain.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Hawks-Berger-Cave of Bones.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Kahneman-Thinking, Fast and Slow.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\MD-MD-Keep It Simple, Keep It Whole.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Medina-Americas Sacred Calling.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Navathe-Fundamentals of Database Systems, 6e.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Nestor-Breath.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Newport-Slow Productivity.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Platt-Make Electronics.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Pysh-Warren Buffett's 3 Favorite Books.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Tellinger-Temples of The African Gods.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Venters-No Jim Crow Church.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Warren-Two Winters in a Tipi.md",
    "D:\Obsidian\Main\09 - Kindle Clippings\Wilson-Inverting The Pyramid.md"
)
foreach ($path in $files) {
    $name = Split-Path $path -Leaf
    Write-Host "=== $name ==="
    $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
    $lines | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
    Write-Host ""
}
