# Read the transactions CSV (ticket purchases)
$transactions = Import-Csv -Path "D:\Downloads\Hill Country Authors Series 2026 - Bryan Burrough-2026-02-13.csv"

# Read the unsubscribes CSV
$unsubscribes = Import-Csv -Path "D:\Downloads\Change My eMail Options-2026-02-13.csv"

# Build a hashtable of transaction counts per date
$txCounts = @{}
foreach ($row in $transactions) {
    # Extract just the date portion (YYYY-MM-DD) from Submission Date
    $date = ($row.'Submission Date' -split ' ')[0]
    if ($txCounts.ContainsKey($date)) {
        $txCounts[$date]++
    } else {
        $txCounts[$date] = 1
    }
}

# Build a hashtable of unsubscribe counts per date (only actual unsubscribes)
$unsubCounts = @{}
foreach ($row in $unsubscribes) {
    # Only count rows where the action is an unsubscribe
    if ($row.'Change my email status' -match 'Unsubscribe') {
        $date = ($row.'Submission Date' -split ' ')[0]
        if ($unsubCounts.ContainsKey($date)) {
            $unsubCounts[$date]++
        } else {
            $unsubCounts[$date] = 1
        }
    }
}

# Collect all unique dates from both files
$allDates = ($txCounts.Keys + $unsubCounts.Keys) | Sort-Object -Unique

# Build the combined output
$output = @()
foreach ($date in $allDates) {
    $txCount = if ($txCounts.ContainsKey($date)) { $txCounts[$date] } else { 0 }
    $unsubCount = if ($unsubCounts.ContainsKey($date)) { $unsubCounts[$date] } else { 0 }
    $output += [PSCustomObject]@{
        Date              = $date
        'Transaction Count' = $txCount
        'Unsubscribe Count' = $unsubCount
    }
}

# Write to CSV
$outputPath = "D:\Documents\Excel\HCAS Bryan Burrough Daily Counts.csv"
$output | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "Created $outputPath with $($allDates.Count) date rows"
Write-Host ""
$output | Format-Table -AutoSize
