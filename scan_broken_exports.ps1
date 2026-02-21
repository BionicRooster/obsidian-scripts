# Scan for broken "Exported image" references
$vault = "D:\Obsidian\Main"

# Build list of existing images
$images = Get-ChildItem $vault -Recurse -Include '*.jpeg','*.jpg','*.png','*.gif' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name

# Scan markdown files for Exported image references
Get-ChildItem $vault -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match 'Exported%20image') {
        $matches = [regex]::Matches($content, 'Exported%20image[^\)]+\.(jpeg|jpg|png|gif)')
        foreach ($m in $matches) {
            $imgName = [uri]::UnescapeDataString($m.Value)
            if ($images -notcontains $imgName) {
                Write-Output "$($file.FullName): $imgName (MISSING)"
            }
        }
    }
}
