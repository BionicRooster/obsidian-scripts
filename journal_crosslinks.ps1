$journal = 'C:\Users\awt\Sync\Obsidian\2026-04-22.md'
$text = [System.IO.File]::ReadAllText($journal, [System.Text.Encoding]::UTF8)
$entry = @'

- Crosslinked 11 notes across 3 topic clusters: (1) Signaling Theory: 4 Social files linked bidirectionally to The Alchemy of Confidence by Judith Donath (NLP); (2) Learning/Cognition: Bloom's Taxonomy of Learning (PKM) linked to Competence Framework and 5 Strategies to Demystify Learning (NLP); (3) Indigenous/Nature: Forest Gardens (Science) linked to 10 Quotes From an Oglala Lakota Chief and Anything That Can Be Built Can Be Taken Down (Social).
'@
$text = $text.TrimEnd() + $entry
[System.IO.File]::WriteAllText($journal, $text, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Journal updated'
