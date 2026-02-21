$files = @(
    "Doctors Learn to Cook Healthy, 'Crave-able' Foods.md",
    "Plant-Based In A Small Town (How To Make It Work!) - Happy Herbivore Blog.md",
    "Use ChatGPT to make life easier.md",
    "Quick Thai Curry.md",
    "Showing Up for Yourself plus a Surprisingly Simple Recipe.md",
    "How Can You Live The Food Revolution_.md",
    "Somethings just have to be shared.md",
    "Recipe book link.md",
    "Sometimes Seniors Don't Understand Directions.md"
)

Set-Location "D:\Obsidian\Main\04 - GMail"

foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Output "---FILE: $f---"
        Get-Content $f -Encoding UTF8 -TotalCount 80
    }
}
