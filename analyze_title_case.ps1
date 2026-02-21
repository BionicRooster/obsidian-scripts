# Analyze title case issues, separating false positives from real fixes needed
$minorWords = @('a','an','the','and','but','or','for','nor','at','by','in','of','on','to','with','from','vs','vs.','is','it','as')
$excludeDirs = @('.obsidian','.smart-env','00 - Images','00 - Journal','Templates','.resources')

# Known acronyms that should stay ALL CAPS
$acronyms = @('MOC','LSA','UHJ','NLP','TX','CIT','GCCMA','WT','FEIN','AI','CNN','NFL','PDF','URL','PKM','FOL','DIY','DNS','VPN','HTTP','HTTPS','API','CSS','HTML','JS','SQL','JSON','XML','YAML','USB','GPU','CPU','RAM','SSD','HDD','LED','LCD','OLED','ADHD','OCD','PTSD','IQ','EQ','BMI','DNA','RNA','FDA','CDC','WHO','UN','EU','UK','US','USA','NYC','LA','DC','ATX','DFW','HVAC','IRS','SSN','LLC','INC','CEO','CFO','CTO','COO','VP','HR','IT','QA','PM','PR','FAQ','TL','DR','TLDR','ETA','FYI','ASAP','RSA','MVP','POC','KPI','ROI','SaaS','PaaS','SEO','SEM','CRM','ERP','IMO','IMHO','BTW','RSVP','PhD','MD','JD','MBA','BA','BS','MA','MS','LLM','II','III','IV','VI','VII','VIII','IX','XI','XII','USDA','BBC','PBS','NPR','GOP','NATO','NASA','JPEG','PNG','GIF','MP3','MP4')

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
    $isFalsePositive = $false

    for ($i = 0; $i -lt $words.Count; $i++) {
      $w = $words[$i]
      # Skip numbers
      if ($w -match '^\d') { continue }
      # Check for ALL CAPS words
      if ($w -cmatch '^[A-Z][A-Z]+$' -and $w.Length -gt 1) {
        if ($acronyms -contains $w) {
          # Known acronym - false positive
          $isFalsePositive = $true
          $isTitleCase = $false
          $reason = "FALSE POSITIVE acronym: '$w'"
          break
        }
        $isTitleCase = $false
        $reason = "ALL CAPS: '$w'"
        break
      }
      # Check first word capitalization
      if ($i -eq 0) {
        if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
          $isTitleCase = $false
          $reason = "First word lowercase: '$w'"
          break
        }
      } else {
        $lower = $w.ToLower()
        if ($minorWords -contains $lower) { continue }
        if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
          $isTitleCase = $false
          $reason = "Major word lowercase: '$w'"
          break
        }
      }
    }

    if (-not $isTitleCase) {
      $results += [PSCustomObject]@{
        Name = $name
        Reason = $reason
        FalsePositive = $isFalsePositive
        Path = $_.FullName
      }
    }
  }

$fp = ($results | Where-Object { $_.FalsePositive }).Count
$real = ($results | Where-Object { -not $_.FalsePositive }).Count
Write-Host "Total flagged: $($results.Count)"
Write-Host "False positives (acronyms): $fp"
Write-Host "Real fixes needed: $real"
Write-Host ""

# Output real fixes to a file for review
$realFixes = $results | Where-Object { -not $_.FalsePositive }
$realFixes | ForEach-Object {
    "$($_.Reason)`t$($_.Name)"
} | Out-File -FilePath 'C:\Users\awt\title_case_fixes_needed.txt' -Encoding utf8

# Also output full details as CSV
$realFixes | Select-Object Name, Reason, Path | Export-Csv -Path 'C:\Users\awt\title_case_fixes.csv' -NoTypeInformation -Encoding utf8

Write-Host "Real fixes written to title_case_fixes_needed.txt and title_case_fixes.csv"
Write-Host ""
Write-Host "=== REAL FIXES NEEDED ==="
$realFixes | ForEach-Object { Write-Host "$($_.Reason)`t$($_.Name)" }
