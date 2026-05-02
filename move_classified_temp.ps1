$files = @(
    @{ src = "D:\Obsidian\Main\10 - Clippings\A New Politics for a Peaceful Future.md"; dst = "D:\Obsidian\Main\01\Bahá'í\" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\These 4 PowerShell one-liners can save you hours of monthly Windows maintenance.md"; dst = "D:\Obsidian\Main\01\Technology\" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Here's What Trump is Turning the U.S. Economy Into.md"; dst = "D:\Obsidian\Main\01\Social\" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Here's how to recycle those old laptops, iPhones and earbuds lying around.md"; dst = "D:\Obsidian\Main\01\Home\" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Temperature Scales - Fahrenheit and Celsius.md"; dst = "D:\Obsidian\Main\01\Home\" },
    @{ src = "D:\Obsidian\Main\10 - Clippings\Simplifying complex ideas in sketches.md"; dst = "D:\Obsidian\Main\01\Home\" }
)
foreach ($f in $files) {
    if (Test-Path $f.src) {
        Move-Item $f.src $f.dst -Force
        Write-Host "Moved: $(Split-Path $f.src -Leaf)"
    } else {
        Write-Host "NOT FOUND: $($f.src)"
    }
}
