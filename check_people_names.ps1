# Check named people from recently classified notes against People Index and 15 - People folder

$peopleDir = 'C:\Users\awt\Sync\Obsidian\15 - People'
$indexPath = 'C:\Users\awt\Sync\Obsidian\People Index.md'
$index = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$names = @(
    'Robin Wall Kimmerer',   # Moss article — botanist/author
    'Maria Popova',          # Moss article — The Marginalian writer
    'Mary Oliver',           # Moss article — poet, quoted
    'Rebecca Solnit',        # Moss article — mentioned
    'Annie Dillard',         # Moss article — mentioned
    'Mark Strand',           # Moss article — poet, quoted
    'Robert McNamara',       # McNamara Fallacy — subject
    'Daniel Yankelovich',    # McNamara Fallacy — coined term
    'Mark Forsyth',          # Chiasmus — author cited
    'Kahlil Gibran',         # Chiasmus + Titanic — mentioned
    'James Baldwin',         # Chiasmus — quoted
    'Mark Carney',           # Chiasmus — quoted
    'Delton West',           # Delton West Funeral — subject
    'Elaine Leo',            # Delton West Funeral — caller
    'Deborah Miller Marr',   # Huntington resources — author
    'Rainn Wilson',          # Titanic article — author
    'Andrew Carnegie',       # Titanic article — mentioned
    'Alexander Graham Bell'  # Titanic article — mentioned
)

Write-Host "Name | In 15-People | In People Index"
Write-Host "-----|-------------|----------------"

$missing = @()
foreach ($name in $names) {
    $file = Join-Path $peopleDir ($name + '.md')
    $hasFile = Test-Path $file
    $inIndex = $index -match [regex]::Escape($name)
    Write-Host "$name | $hasFile | $inIndex"
    if (-not $hasFile -and -not $inIndex) {
        $missing += $name
    }
}

Write-Host ""
Write-Host "=== NOT IN EITHER ==="
foreach ($n in $missing) { Write-Host "  - $n" }
