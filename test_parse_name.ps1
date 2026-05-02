# Test Parse-PersonName generational suffix handling in isolation

# Minimal stubs to avoid loading the full script
$script:nameBlocklist = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
@('the','a','an','and','or','but','of','to','in','on','at','by','for','from','with','as',
  'is','was','has','have','had','are','were','be','been','did','do','does','can','could',
  'will','would','shall','should','may','might','must','let','get','got','make','made',
  'meta','anti','pre','post','sub','super','non','un','re','de','co','pro',
  'nlp','faq','moc','toc','via','per','aka',
  'jr','sr','model','outcomes','acuity','technology','ranch',
  'di','da','du','des','del','der','den','dos','das') |
    ForEach-Object { [void]$script:nameBlocklist.Add($_) }

$script:givenNameSet = $null   # Disable CSV validation for this test

function Parse-PersonName {
    param([string]$raw)

    $name = ($raw -replace '^\[\[|\]\]$', '' -replace '\|.*$', '').Trim()
    $name = $name -replace '^(Dr|Mr|Mrs|Ms|Miss|Prof|Rev|Sir|Lt|Capt|Col|Gen|Sgt|Sen|Rep|Hon)\.?\s+', ''
    if ([string]::IsNullOrWhiteSpace($name)) { return $null }

    $genSuffixRx = '^(Jr\.?|Sr\.?|II|III|IV|V|VI|VII|2nd|3rd|4th|5th)$'
    $genSuffix   = ''

    $last = ''; $first = ''
    if ($name -match '^([^,]+),\s*(.+)$') {
        $last     = $Matches[1].Trim()
        $firstRaw = $Matches[2].Trim()
        $fParts = $firstRaw -split '\s+'
        if ($fParts.Count -ge 2 -and $fParts[-1] -match $genSuffixRx) {
            $genSuffix = $fParts[-1]
            $first     = ($fParts[0..($fParts.Count - 2)]) -join ' '
        } else {
            $first = $firstRaw
        }
    } else {
        $parts = $name -split '\s+'
        if ($parts.Count -lt 2) { return $null }
        if ($parts.Count -ge 3 -and $parts[-1] -match $genSuffixRx) {
            $genSuffix = $parts[-1]
            $parts     = $parts[0..($parts.Count - 2)]
        }
        $last  = $parts[-1]
        $first = ($parts[0..($parts.Count - 2)]) -join ' '
    }

    $last  = $last  -replace '[^\p{L}\p{N}''`.\-]+$', ''
    $first = $first -replace '[^\p{L}\p{N}''`.\-]+$', ''
    if ($last  -match '^(.*\p{L}\p{L})\.$') { $last  = $Matches[1] }
    if ($first -match '^(.*\p{L}\p{L})\.$') { $first = $Matches[1] }
    if ([string]::IsNullOrWhiteSpace($last) -or [string]::IsNullOrWhiteSpace($first)) { return $null }
    if ($last  -cnotmatch '^[\p{Lu}]') { return $null }
    if ($first -cnotmatch '^[\p{Lu}]') { return $null }

    $firstWord = ($first -split '\s+')[0]
    $lastWord  = $last
    if ($script:nameBlocklist.Contains($firstWord) -or $script:nameBlocklist.Contains($lastWord)) { return $null }
    $firstWords = $first -split '\s+'
    foreach ($fw in $firstWords) {
        $fwClean = $fw -replace '[^\p{L}]', ''
        if ($fwClean.Length -gt 1 -and $script:nameBlocklist.Contains($fwClean)) { return $null }
    }
    if ($lastWord -cmatch '^[A-Z]{4,}$') { return $null }
    if ($lastWord -match '(?i)(ing|tion|ness|ment|ized|izing|ified|ifying|ated|ating|\Bly|ology)$') { return $null }

    $displayFirst = if ($genSuffix) { "$first $genSuffix" } else { $first }
    $fullName     = if ($genSuffix) { "$first $last $genSuffix" } else { "$first $last" }

    return @{
        Key     = "$($last.ToLower()), $($first.ToLower())"
        Display = "$last, $displayFirst"
        First   = $first
        Last    = $last
        Full    = $fullName
    }
}

$tests = @(
    @{ Input = 'Martin W. Brossman III';  ExpectKey = 'brossman, martin w.'; ExpectDisplay = 'Brossman, Martin W. III'; ExpectFull = 'Martin W. Brossman III' },
    @{ Input = 'John Smith Jr.';          ExpectKey = 'smith, john';          ExpectDisplay = 'Smith, John Jr.';         ExpectFull = 'John Smith Jr.' },
    @{ Input = 'Robert F. Kennedy Jr';    ExpectKey = 'kennedy, robert f.';   ExpectDisplay = 'Kennedy, Robert F. Jr';   ExpectFull = 'Robert F. Kennedy Jr' },
    @{ Input = 'Brossman, Martin W. III'; ExpectKey = 'brossman, martin w.';  ExpectDisplay = 'Brossman, Martin W. III'; ExpectFull = 'Martin W. Brossman III' },
    @{ Input = 'John Smith';              ExpectKey = 'smith, john';           ExpectDisplay = 'Smith, John' },
    @{ Input = 'Adams, Scott';            ExpectKey = 'adams, scott';          ExpectDisplay = 'Adams, Scott' },
    @{ Input = 'belief';                  ExpectKey = $null;                   ExpectDisplay = $null },  # single word
    @{ Input = 'd. Elicit the belief';    ExpectKey = $null;                   ExpectDisplay = $null },  # lowercase last
    @{ Input = 'RANCH, DALLES MOUNTAIN'; ExpectKey = $null;                   ExpectDisplay = $null },  # all-caps
    @{ Input = 'Peter as Paul Valery';    ExpectKey = $null;                   ExpectDisplay = $null }   # 'as' in name
)

$pass = 0; $fail = 0
foreach ($t in $tests) {
    $result = Parse-PersonName -raw $t.Input
    $gotKey  = if ($result) { $result.Key }     else { $null }
    $gotDisp = if ($result) { $result.Display } else { $null }
    $gotFull = if ($result) { $result.Full }    else { $null }
    $keyOk   = ($gotKey  -eq $t.ExpectKey)
    $dispOk  = ($gotDisp -eq $t.ExpectDisplay)
    $fullOk  = (-not $t.ContainsKey('ExpectFull')) -or ($gotFull -eq $t.ExpectFull)
    $ok = $keyOk -and $dispOk -and $fullOk
    if ($ok) {
        Write-Host "PASS: '$($t.Input)' -> Display='$gotDisp' Full='$gotFull'"
        $pass++
    } else {
        Write-Host "FAIL: '$($t.Input)'"
        if (-not $keyOk)  { Write-Host "  Key:     expected '$($t.ExpectKey)'  got '$gotKey'" }
        if (-not $dispOk) { Write-Host "  Display: expected '$($t.ExpectDisplay)'  got '$gotDisp'" }
        if (-not $fullOk) { Write-Host "  Full:    expected '$($t.ExpectFull)'  got '$gotFull'" }
        $fail++
    }
}
Write-Host "`n$pass passed, $fail failed."
