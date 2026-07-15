# Check Related Notes sections of recently added notes
$files = @(
    'C:\Users\awt\Sync\Obsidian\20 - Permanent Notes\Medieval Monks Knew Something About Vinegar We''ve Completely Forgot.md',
    'C:\Users\awt\Sync\Obsidian\01\Science\How Moss Could Help Roads Cope with Heavy Rain and Reduce Air Pollution.md',
    'C:\Users\awt\Sync\Obsidian\01\Science\What Drew These 1,300 Perfect Circles on the Sea Floor We May Finally Know.md',
    'C:\Users\awt\Sync\Obsidian\20 - Permanent Notes\The Story of the Manchester Bee Tattoo.md',
    'C:\Users\awt\Sync\Obsidian\20 - Permanent Notes\The 22 May 2017 Manchester Terrorist Attack - Bee Tattoo.md'
)

foreach ($f in $files) {
    if (Test-Path $f) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($f)
        $content = Get-Content $f -Encoding UTF8 -Raw
        Write-Host "=== $name ==="
        # Extract Related Notes section
        if ($content -match '(?s)## Related Notes(.*)$') {
            Write-Host $Matches[1].Trim()
        } else {
            Write-Host "(no Related Notes section)"
        }
        Write-Host ""
    }
}
