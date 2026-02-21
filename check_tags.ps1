$check = @('Ergonomic','audio','Astronomy','Soccer','Hobbies','craft','energy','fundraising','Cleaning','Behavior','DRM','eBook','Ferment','baking','dessert','healthy-cooking','literature','tablets','printing','virtualization','allergy','humor','9YearPlan','Sustainability','architecture','design','geology','maker','pecan')
# Get all tags from vault
$allTags = @{}
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | ForEach-Object {
    $c = Get-Content $_.FullName -Raw -Encoding UTF8
    if ($c -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yaml = $Matches[1]
        foreach ($line in ($yaml -split '\r?\n')) {
            if ($line -match '^\s*-\s*(.+)$') {
                $tag = $Matches[1].Trim().Trim('"').Trim("'")
                $allTags[$tag] = $true
            }
        }
    }
}
foreach ($t in $check) {
    $found = $allTags.ContainsKey($t)
    Write-Host "$t : $found"
}
