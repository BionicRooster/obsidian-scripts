$dir = "D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip"
$f = Get-ChildItem $dir | Where-Object { $_.Name -like "Reed*" } | Select-Object -First 1
Write-Host "Processing: $($f.FullName)"

$c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

# Find the h1 heading line (starts with "# Reed") and insert images after it
# The pattern to find is: the h1 line followed by a blank line and then "Reed Island"
$images = @"

![Steigerwald Lake National Wildlife Refuge scenic view — the refuge wetlands and Columbia River at Washougal, WA; Reed Island and Steigerwald are Ice Age Flood gravel bars at the mouth of the Columbia Gorge (USFWS)](https://www.fws.gov/sites/default/files/styles/banner_image_xs/public/banner_images/2021-12/Scenic-Steigerwald.jpg)

![Mt. View Trail overlook at Steigerwald NWR — looking over the Columbia River floodplain from the refuge trails near Reed Island and the Gorge entrance (USFWS)](https://www.fws.gov/sites/default/files/styles/scale_width_480/public/2023-04/First%20Overlook_SLNWR_Stashia%20of%20WTA_0.jpg)

![River Trail overlook at Steigerwald NWR — view of the Columbia River from the refuge that occupies the Ice Age Flood gravel bars described in this note (USFWS)](https://www.fws.gov/sites/default/files/styles/scale_width_480/public/2023-04/River%20Trail%20Overlook_SLNWR_Palmer_SCA%20Intern.jpg)

"@

# Find the position just after the H1 heading line
$lines = $c -split '(\r?\n)'
$result = [System.Text.StringBuilder]::new()
$inserted = $false

foreach ($line in $lines) {
    $result.Append($line) | Out-Null
    # Insert images after the H1 heading line (the line that starts with "# Reed")
    if (-not $inserted -and $line -match '^# Reed') {
        $result.Append($images) | Out-Null
        $inserted = $true
    }
}

$newContent = $result.ToString()
[System.IO.File]::WriteAllText($f.FullName, $newContent, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Images inserted successfully" -ForegroundColor Green
