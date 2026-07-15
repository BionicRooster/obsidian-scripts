# Add ## Related Notes cross-links between thematically connected notes across topic areas
$vault = 'C:\Users\awt\Sync\Obsidian\01'

function Add-RelatedNotes {
    param(
        [string]$FilePath,
        [string[]]$Links,
        [string]$SubHeading = $null
    )
    if (-not (Test-Path $FilePath)) {
        Write-Output "  MISSING: $FilePath"
        return
    }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)

    $block = "`r`n`r`n## Related Notes"
    if ($SubHeading) { $block += "`r`n### $SubHeading" }
    foreach ($link in $Links) { $block += "`r`n- $link" }

    $newContent = $content.TrimEnd() + $block + "`r`n"
    [System.IO.File]::WriteAllText($FilePath, $newContent, [System.Text.UTF8Encoding]::new($false))
    Write-Output "  Updated: $([System.IO.Path]::GetFileName($FilePath))"
}

$social  = Join-Path $vault 'Social'
$nlp     = Join-Path $vault 'NLP'
$pkm     = Join-Path $vault 'PKM'
$science = Join-Path $vault 'Science'

# ── CLUSTER 1: Signaling Theory (NLP <-> Social) ────────────────────────────
Write-Output ""
Write-Output "=== Cluster 1: Signaling Theory (NLP <-> Social) ==="

Add-RelatedNotes `
    -FilePath (Join-Path $nlp 'The Alchemy of Confidence by Judith Donath.md') `
    -SubHeading 'Political Signaling (Applications)' `
    -Links @(
        '[[The Signaling of Donald Trump]]',
        '[[The Signaling of Donald Trump and Adolf Hitler]]',
        '[[Bernie Sanders signaling]]',
        '[[Bernie Sanders and Donald Trump Signaling Compaired]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social 'The Signaling of Donald Trump.md') `
    -SubHeading 'Signaling Theory' `
    -Links @(
        '[[The Alchemy of Confidence by Judith Donath]]',
        '[[The Signaling of Donald Trump and Adolf Hitler]]',
        '[[Bernie Sanders signaling]]',
        '[[Bernie Sanders and Donald Trump Signaling Compaired]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social 'The Signaling of Donald Trump and Adolf Hitler.md') `
    -SubHeading 'Signaling Theory' `
    -Links @(
        '[[The Alchemy of Confidence by Judith Donath]]',
        '[[The Signaling of Donald Trump]]',
        '[[Bernie Sanders signaling]]',
        '[[Bernie Sanders and Donald Trump Signaling Compaired]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social 'Bernie Sanders signaling.md') `
    -SubHeading 'Signaling Theory' `
    -Links @(
        '[[The Alchemy of Confidence by Judith Donath]]',
        '[[The Signaling of Donald Trump]]',
        '[[The Signaling of Donald Trump and Adolf Hitler]]',
        '[[Bernie Sanders and Donald Trump Signaling Compaired]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social 'Bernie Sanders and Donald Trump Signaling Compaired.md') `
    -SubHeading 'Signaling Theory' `
    -Links @(
        '[[The Alchemy of Confidence by Judith Donath]]',
        '[[The Signaling of Donald Trump]]',
        '[[The Signaling of Donald Trump and Adolf Hitler]]',
        '[[Bernie Sanders signaling]]'
    )

# ── CLUSTER 2: Learning & Cognition (PKM <-> NLP) ───────────────────────────
Write-Output ""
Write-Output "=== Cluster 2: Learning/Cognition (PKM <-> NLP) ==="

Add-RelatedNotes `
    -FilePath (Join-Path $pkm "Bloom's Taxonomy of Learning.md") `
    -SubHeading 'Learning Frameworks' `
    -Links @(
        '[[Competence Framework]]',
        '[[5 Strategies to Demystify the Learning Process for Struggling Students]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $nlp 'Competence Framework.md') `
    -SubHeading 'Learning Frameworks' `
    -Links @(
        "[[Bloom's Taxonomy of Learning]]",
        '[[5 Strategies to Demystify the Learning Process for Struggling Students]]'
    )

Add-RelatedNotes `
    -FilePath (Join-Path $nlp '5 Strategies to Demystify the Learning Process for Struggling Students.md') `
    -SubHeading 'Learning Frameworks' `
    -Links @(
        "[[Bloom's Taxonomy of Learning]]",
        '[[Competence Framework]]'
    )

# ── CLUSTER 3: Indigenous & Nature (Science <-> Social) ─────────────────────
Write-Output ""
Write-Output "=== Cluster 3: Indigenous/Nature (Science <-> Social) ==="

$fgName   = [char]0x27 + 'Forest Gardens' + [char]0x27 + ' Show How Native Land Stewardship Can Outdo Nature.md'
$damName  = [char]0x27 + 'Anything That Can Be Built Can Be Taken Down' + [char]0x27 + '.md'
$fgLink   = "[[" + [char]0x27 + "Forest Gardens" + [char]0x27 + " Show How Native Land Stewardship Can Outdo Nature]]"
$damLink  = "[[" + [char]0x27 + "Anything That Can Be Built Can Be Taken Down" + [char]0x27 + "]]"

Add-RelatedNotes `
    -FilePath (Join-Path $science $fgName) `
    -SubHeading 'Indigenous Knowledge & Land Stewardship' `
    -Links @(
        '[[10 Quotes From an Oglala Lakota Chief]]',
        $damLink
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social '10 Quotes From an Oglala Lakota Chief.md') `
    -SubHeading 'Indigenous Knowledge & Land Stewardship' `
    -Links @(
        $fgLink,
        $damLink
    )

Add-RelatedNotes `
    -FilePath (Join-Path $social $damName) `
    -SubHeading 'Indigenous Land & Water Rights' `
    -Links @(
        $fgLink,
        '[[10 Quotes From an Oglala Lakota Chief]]'
    )

Write-Output ""
Write-Output "=== Done ==="
