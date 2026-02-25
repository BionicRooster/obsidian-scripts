# update_japan_moc_links.ps1
# Bidirectionally link notes to MOC - Japan & Japanese Culture
# Group A: add nav property to frontmatter
# Group B: add Japan MOC to Related Notes section

$vault    = "D:\Obsidian\Main"
$enc      = [System.Text.Encoding]::UTF8
$japanMoc = "[[MOC - Japan & Japanese Culture]]"

# ---- helper: read file bytes, detect BOM, return (text, hasBom) ----
function Read-Vault($path) {
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    return @{ Text = $text; HasBom = $hasBom }
}

# ---- helper: write text back with correct BOM state ----
function Write-Vault($path, $text, $hasBom) {
    $outBytes = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($text) } else { $enc.GetBytes($text) }
    [System.IO.File]::WriteAllBytes($path, $outBytes)
}

# ---- Add nav line before closing --- of frontmatter ----
function Add-NavToFrontmatter($path, $navValue) {
    $r      = Read-Vault $path
    $text   = $r.Text
    $hasBom = $r.HasBom

    # Split into lines preserving line endings
    $lines   = $text -split "(?<=`n)"   # keep the newline with each line
    $result  = [System.Collections.Generic.List[string]]::new()
    $fmStart = $false   # found opening ---
    $fmDone  = $false   # found closing ---
    $inserted = $false
    $i = 0

    foreach ($line in $lines) {
        $trim = $line.TrimEnd("`r", "`n", " ")
        if ($i -eq 0 -and $trim -eq '---') {
            $fmStart = $true
            $result.Add($line)
            $i++; continue
        }
        if ($fmStart -and -not $fmDone -and $trim -eq '---') {
            # Insert nav before closing ---
            $result.Add("nav: `"$navValue`"`n")
            $fmDone   = $true
            $inserted = $true
        }
        $result.Add($line)
        $i++
    }

    if ($inserted) {
        Write-Vault $path ($result -join '') $hasBom
        Write-Host "  [nav added] $path"
    } else {
        Write-Host "  [WARNING] Could not add nav: $path"
    }
}

# ---- Add link to existing ## Related Notes, or append new section ----
function Add-ToRelatedNotes($path, $link) {
    $r      = Read-Vault $path
    $text   = $r.Text
    $hasBom = $r.HasBom

    if ($text -match '(?m)^## Related Notes') {
        $newText = $text -replace '(?m)(^## Related Notes[ \t]*\r?\n)', "`${1}- $link`n"
    } else {
        $newText = $text.TrimEnd() + "`n`n## Related Notes`n- $link`n"
    }
    Write-Vault $path $newText $hasBom
    Write-Host "  [related] $path"
}

# ===== GROUP A: add nav pointing to Japan MOC =====
$groupA = @(
    "$vault\01\Technology\How Akira Kurosawa's.md",
    "$vault\01\Home\8 Tiny Japanese Habits That Make a Massive Difference.md",
    "$vault\01\Home\I Copied 15 Japanese.md",
    "$vault\01\Home\Old Houses Japan.md",
    "$vault\01\Health\Japanese Cherry Blossom Body Oil.md",
    "$vault\01\Music\Making the `$25k Odaiko Drum on a Budget.md",
    "$vault\01\Soccer\Japanese Players Leave Dressing Room Spotless.md",
    "$vault\01\NLP_Psy\The Ancient Tool Used in Japan to Strengthen Memory & Focus The Abacus.md",
    "$vault\01\Recipes\Vegan Soba Noodles.md",
    "$vault\01\Recipes\Inari Sushi and Kale with Mushrooms.md",
    "$vault\01\Recipes\Healthy Sesame Soba Noodles with Spinach and Tofu [feedly] Recipe.md",
    "$vault\01\Travel\The Sleepy Japanese.md"
)

Write-Host "`n=== GROUP A: Adding nav to frontmatter ==="
foreach ($f in $groupA) {
    if (Test-Path -LiteralPath $f) {
        Add-NavToFrontmatter $f $japanMoc
    } else {
        Write-Host "  [MISSING] $f"
    }
}

# ===== GROUP B: add Japan MOC to Related Notes =====
$groupB = @(
    "$vault\01\NLP_Psy\Inemuri, the Japanese Art of Taking Power Naps.md",
    "$vault\01\Home\Prairiedog Japanese.md",
    "$vault\01\Social\The Japanese Cleaning Principle of Kiyomeru At Home.md",
    "$vault\01\Science\The 390 YO Tree Survived Bombing of Hiroshima.md",
    "$vault\01\Health\Dispatch from Okinawa - What the World's Longest-Lived Women Eat.md",
    "$vault\01\Health\Blue Zones - The Island Where People Forget to Die.md",
    "$vault\01\Health\Longevity Diet Discussion.md",
    "$vault\01\Health\Want Great Longevity and Health - It Takes a Village.md",
    "$vault\01\Recipes\Buckwheat Soba and Vegetables With Tofu Peanut Sauce.md",
    "$vault\01\Recipes\Healthy Sesame Soba Noodles with Spinach and Tofu.md",
    "$vault\01\Recipes\Green Tea Dip and Spread.md",
    "$vault\01\Home\Miso - The Different Colors & Substitutions.md",
    "$vault\01\Recipes\Japanese-Style Braised Tofu with Root Vegetables, Shiitakes, Red Chard, and Quick Pickles Recipe.md",
    "$vault\01\Travel\Japan.md"
)

Write-Host "`n=== GROUP B: Adding to Related Notes ==="
foreach ($f in $groupB) {
    if (Test-Path -LiteralPath $f) {
        Add-ToRelatedNotes $f $japanMoc
    } else {
        Write-Host "  [MISSING] $f"
    }
}

# ===== SPECIAL: Trevor Noah - add nav NLP_Psy + Japan to Related Notes =====
Write-Host "`n=== SPECIAL: Trevor Noah Kintsugi ==="
$trevorPath = "$vault\01\NLP_Psy\Trevor Noah Explains How Kintsugi.md"
if (Test-Path -LiteralPath $trevorPath) {
    Add-NavToFrontmatter $trevorPath "[[MOC - NLP & Psychology]]"
    Add-ToRelatedNotes   $trevorPath $japanMoc
}

Write-Host "`nDone."
