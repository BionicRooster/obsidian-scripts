$clippingsDir = 'D:\Obsidian\Main\10 - Clippings'
$files = @(
    'All Religions Are One Baha'u'llah.md',
    'No Duh!.md',
    'SSD Getting Slower and How to Fix It.md',
    'We Are in a Digital Version of the Enclosures - Like the Landowners, Big Tech Has Power Without Responsibility.md'
)

foreach ($f in $files) {
    $path = Join-Path $clippingsDir $f
    Write-Output "=== FILE: $f ==="
    Get-Content $path -Encoding UTF8 -Raw
    Write-Output "=== END ==="
}
