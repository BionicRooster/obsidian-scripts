# cleanup_people_index2.ps1
# Comprehensive cleanup of rebuilt People Index — removes false positives from
# bad frontmatter author-field parsing (concepts, brands, merged multi-author strings, etc.)

$path = 'D:\Obsidian\Main\People Index.md'
$lines = [System.Collections.Generic.List[string]]([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) -split "`n")

$removePatterns = @(
    '^Check, (Ecology|NLP)',
    '^Cure, .*(Phobia|Fast)',
    '^History, Change Personal',
    '^If, Me\.',
    '^Joel, The Way',
    '^Keyword, Using the',
    '^Make, Which We',
    '^Means, All',
    '^Model, .*(Meta|NLP|Jay Haley)',
    '^Pace, Future',
    '^Pangs\., Sudden Ethical',
    '^Patterns, NLP Language',
    '^Reframe, NLP',
    '^Reframing, NLP',
    '^Repair, Page',
    '^That, Know to Know',
    '^Training, NLP in',
    '^Utility\., Its',
    '^Valle, John J\. La',
    '^Washing, Page',
    '^Way, The',
    '^Leaf, Gold',
    '^Light, Little Green',
    '^Stove, Gold Finishing',
    '^Coding, Some Old Guy',
    '^Desk, (TOI Trending|Trending)',
    '^Dish, .*(Inside)',
    '^Files, Contributors to',
    '^Following, The',
    'Gmail',
    '^Green, Going$',
    '^Herbivore[,\)]',
    '^History\)',
    '^Homegrown, Mr\.',
    '^Honor$',
    '^However, Many Things',
    '^Information\., Updating',
    '^Instructables$',
    '^Lifewire$',
    '^Man, Lazy$',
    '^Maps, Collins',
    '^MarkusPfundstein$',
    '^OC$',
    '^Planet, One Green',
    '^Reclamation, Bureau of',
    '^Review, World Population',
    '^Sam$',
    '^SciTechDaily$',
    '^Sketchplanations$',
    '^User, Unknown$',
    '^Venice\.ai$',
    '^Voice, Legal$',
    '^Weblog, Doc Searls',
    '^Book, Vahinger',
    ' and .+,| and [A-Z]',
    '^Jr, Dr\.',
    '^Cordes, Written By Helen',
    '^Campbell, T\. Colin Campbell',
    '^Kristen Carli, MS',
    '^Jr\., Rey',
    '^Michael, Miller',
    '^Nicholson, Collins',
    '^Veer, Professor',
    '^Feldenkrais\., Moshe',
    '^Sr, Alfred',
    '^Jacobson, T\. Colin',
    '^Ross, James F\. Kurose',
    '^Schocken, Noam Nisan',
    '^Smith, Charlotte Rivers and',
    '^Wayne, Blaine T\. Bettinger',
    '^Roth, J\.D\. and',
    '^Fox, Melinda Coplin$',
    '^Tolocka, Profe$',
    '^Sr, Alfred W\. Talbot',
    '^Knows, What He',
    '^Bark, NLP Diss',
    '^Anchor, Chaining',
    '^Cordes, Written By'
)

$removed = 0
$i = 0
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '^### (.+)$') {
        $name = $matches[1]
        $shouldRemove = $false
        foreach ($pat in $removePatterns) {
            if ($name -match $pat) {
                $shouldRemove = $true
                Write-Host "REMOVE: $name  [$pat]"
                break
            }
        }
        if ($shouldRemove) {
            $end = $i + 1
            while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') { $end++ }
            $lines.RemoveRange($i, $end - $i)
            $removed++
            continue
        }
    }
    $i++
}

Write-Host ""
Write-Host "Removed $removed entries."
Write-Host "Remaining: $(($lines | Where-Object { $_ -match '^### ' }).Count)"
[System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Saved."
