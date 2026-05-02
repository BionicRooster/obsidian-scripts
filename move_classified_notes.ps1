# Move classified notes to their appropriate 01/ subdirectories
$vault = "D:\Obsidian\Main"

# Technology: AI & UX article
Move-Item "$vault\10 - Clippings\Human Strategy In An AI-Accelerated Workflow.md" "$vault\01\Technology\Human Strategy In An AI-Accelerated Workflow.md" -Force

# Home (Sketchplanations)
Move-Item "$vault\10 - Clippings\Simplifying complex ideas in sketches 1.md" "$vault\01\Home\Simplifying complex ideas in sketches 1.md" -Force
Move-Item "$vault\10 - Clippings\Simplifying complex ideas in sketches.md" "$vault\01\Home\Simplifying complex ideas in sketches.md" -Force

# Coffee (uses en-dash in filename)
$coffeeFiles = Get-ChildItem "$vault\10 - Clippings\" | Where-Object { $_.Name -like "Coffee The Glorious*" }
foreach ($f in $coffeeFiles) {
    Move-Item $f.FullName "$vault\01\Home\$($f.Name)" -Force
}

# Science: Whale shark article
Move-Item "$vault\10 - Clippings\Whale Shark Swims Astounding 1,200km from Madagascar to Seychelles.md" "$vault\01\Science\Whale Shark Swims Astounding 1,200km from Madagascar to Seychelles.md" -Force

Write-Host "All files moved successfully."
