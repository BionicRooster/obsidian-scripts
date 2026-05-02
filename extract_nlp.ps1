# Script to extract readable text from binary NLP files
# Uses ASCII text extraction with letter-ratio filtering

# Function to extract readable text from binary files
function Get-CleanText {
    param (
        [string]$path   # Path to the binary file to extract text from
    )
    # Read all raw bytes from the file
    $bytes = [System.IO.File]::ReadAllBytes($path)
    # Decode bytes as ASCII (binary files contain ASCII text interspersed with binary)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    # Find all sequences of printable characters that are at least 8 chars long
    $found = [regex]::Matches($text, '[ a-zA-Z0-9\.,;:\?\!\-\(\)\[\]' + "'" + '"#@&\*\/\+\=\<\>]{8,}')
    # Array to collect qualifying text segments
    $results = @()
    foreach ($m in $found) {
        # Trim whitespace from each match
        $s = $m.Value.Trim()
        # Count alphabetic characters in the segment
        $letters = ($s.ToCharArray() | Where-Object { [char]::IsLetter($_) }).Count
        # Compute ratio of letters to total length
        $ratio = if ($s.Length -gt 0) { $letters / $s.Length } else { 0 }
        # Keep only segments that are mostly letters, contain spaces, and are long enough
        if ($ratio -gt 0.5 -and $s -match '\s' -and $s.Length -ge 10) {
            $results += $s
        }
    }
    # Return all qualifying segments joined by newlines
    return $results -join "`n"
}

# Source directory containing the NLP Master Class files
$srcDir = 'D:\Documents\NLP\Master Class'

# List of binary files to extract
$files = @(
    'ALLERGY.WPD',
    'C-OF-E.WPD',
    'CH-P-HIS.WPD',
    'CHART2.WPD',
    'DEVELOP.WPD',
    'ECOLOGY.WPD',
    'ELIC-BEL.WPD',
    'IDSBAS.WPD',
    'LANG-CHG.WPD',
    'LANGPAT.WPD',
    'LNGPAT.WPD',
    'MARYANN.WRI',
    'METAMODL.WPD',
    'NLPFAQ.WPD',
    'OUTCOME.WPD',
    'PHOBIA.WPD',
    'PHOBIA.DOC',
    'PHOBIA2.WPD',
    'REFRAMES.WPD',
    'REFRAMES.DOC',
    'SIX-STEP.WPD',
    'SXST-BC.WPD',
    'SXST-BC2.WPD',
    'T-D-SRCH.WPD',
    'TRAIN1.WPD',
    'WEEK-1.WPD',
    'WEEK-2.WPD',
    'WEEK-2.DOC',
    'WEEK-3.WPD',
    'WEEK-3.DOC',
    'WEEK-4.WPD',
    'WEEK-4.DOC',
    'WEEK-5.WPD',
    'WEEK-6.WPD',
    'WEEK-6.DOC',
    'WEEK-7.WPD',
    'WELL.DOC',
    'PRESUP2.WPD',
    'NLP-FRUM.WPD'
)

# Output directory for extracted text files
$outDir = 'C:\Users\awt\nlp_extracted'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

foreach ($file in $files) {
    $fullPath = Join-Path $srcDir $file
    if (Test-Path $fullPath) {
        Write-Host "Extracting: $file"
        $extracted = Get-CleanText $fullPath
        # Save extracted text to output directory with .txt extension
        $outFile = Join-Path $outDir ($file + '.txt')
        [System.IO.File]::WriteAllText($outFile, $extracted, [System.Text.Encoding]::UTF8)
        # Show character count for verification
        Write-Host "  -> $($extracted.Length) chars extracted"
    } else {
        Write-Host "NOT FOUND: $file"
    }
}

Write-Host "Done."
