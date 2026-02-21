$minorWords = @('a','an','the','and','but','or','for','nor','at','by','in','of','on','to','with','from','vs','vs.','is','it','as')
$excludeDirs = @('.obsidian','.smart-env','00 - Images','00 - Journal','Templates','.resources')

$results = @()

Get-ChildItem -Path 'D:\Obsidian\Main' -Filter '*.md' -Recurse |
  Where-Object {
    $skip = $false
    foreach ($d in $excludeDirs) {
      if ($_.FullName -match [regex]::Escape($d)) { $skip = $true; break }
    }
    -not $skip
  } |
  ForEach-Object {
    $name = $_.BaseName
    $words = $name -split '\s+'
    $isTitleCase = $true
    $reason = ""

    for ($i = 0; $i -lt $words.Count; $i++) {
      $w = $words[$i]
      if ($w -match '^\d') { continue }
      if ($w -cmatch "^[A-Z][A-Z]+$" -and $w.Length -gt 1) {
        # ALL CAPS word - not title case
        $isTitleCase = $false
        $reason = "ALL CAPS: '$w'"
        break
      }
      if ($i -eq 0) {
        if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
          $isTitleCase = $false
          $reason = "First word lowercase: '$w'"
          break
        }
      } else {
        $lower = $w.ToLower()
        if ($minorWords -contains $lower) {
          continue  # minor words can be either case
        } else {
          if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
            $isTitleCase = $false
            $reason = "Major word lowercase: '$w'"
            break
          }
        }
      }
    }

    if (-not $isTitleCase) {
      $results += [PSCustomObject]@{
        Name = $name
        Reason = $reason
        Path = $_.FullName
      }
    }
  }

$results | Select-Object -First 50 | Format-Table Name, Reason -AutoSize -Wrap
Write-Host "`nTotal non-title-case files found: $($results.Count)"
