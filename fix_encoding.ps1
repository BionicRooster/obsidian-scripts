# PowerShell script to fix UTF-8 encoding corruption (mojibake) in Obsidian vault
# Uses byte-level operations to avoid encoding issues in the script itself

$vaultPath = "D:\Obsidian\Main"
$filesFixed = 0

# Define patterns as hex strings and their UTF-8 replacements
# Pattern = mojibake bytes in hex, Replacement = correct UTF-8 bytes in hex
$patterns = @(
    # Right single quote (most common: displays as a special chars)
    @{ Find = "C3A2E282ACE284A2"; Replace = "27" },      # -> '
    @{ Find = "E28099"; Replace = "27" },                 # actual curly apostrophe -> '

    # Left single quote
    @{ Find = "C3A2E282ACCB9C"; Replace = "27" },        # -> '
    @{ Find = "E28098"; Replace = "27" },                 # actual -> '

    # Left double quote
    @{ Find = "C3A2E282ACC593"; Replace = "22" },        # -> "
    @{ Find = "E2809C"; Replace = "22" },                 # actual -> "

    # Right double quote
    @{ Find = "C3A2E282ACC29D"; Replace = "22" },        # -> "
    @{ Find = "E2809D"; Replace = "22" },                 # actual -> "

    # Em dash
    @{ Find = "C3A2E282ACE2809C"; Replace = "E28094" },  # -> actual em dash
    @{ Find = "E28094"; Replace = "2D2D" },              # em dash -> --

    # En dash
    @{ Find = "C3A2E282ACE28093"; Replace = "2D" },      # -> -

    # Non-breaking space corruption
    @{ Find = "C382C2A0"; Replace = "20" },              # -> space
    @{ Find = "C2A0"; Replace = "20" },                   # NBSP -> space

    # Corrupted checkbox/bullet
    @{ Find = "C3A2E296A2"; Replace = "2D" },            # -> -

    # Accented e (e acute)
    @{ Find = "C383C2A9"; Replace = "C3A9" },            # -> proper UTF-8 e

    # BOM
    @{ Find = "EFBBBF"; Replace = "" },                   # Remove BOM

    # Ellipsis
    @{ Find = "C3A2E282ACE2809A"; Replace = "2E2E2E" },  # -> ...

    # Bullet
    @{ Find = "C3A2E282ACE280A2"; Replace = "E280A2" }   # -> proper bullet
)

function Convert-HexToBytes {
    # Converts a hex string to a byte array with explicit typing
    param([string]$hex)

    # Return empty byte array for null/empty input
    if ([string]::IsNullOrEmpty($hex)) {
        return [byte[]]@()
    }

    # Create byte array of correct size
    [byte[]]$bytes = New-Object byte[] ($hex.Length / 2)

    # Convert each hex pair to a byte
    for ($i = 0; $i -lt $hex.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($hex.Substring($i, 2), 16)
    }

    # Return with explicit type to prevent PowerShell array unrolling
    return ,[byte[]]$bytes
}

function Find-BytePattern($source, $pattern, $startIndex) {
    if ($pattern.Length -eq 0 -or $source.Length -eq 0) { return -1 }
    for ($i = $startIndex; $i -le $source.Length - $pattern.Length; $i++) {
        $found = $true
        for ($j = 0; $j -lt $pattern.Length; $j++) {
            if ($source[$i + $j] -ne $pattern[$j]) {
                $found = $false
                break
            }
        }
        if ($found) { return $i }
    }
    return -1
}

function Replace-BytePattern {
    # Explicit parameter typing to prevent PowerShell type coercion issues
    param(
        [byte[]]$source,
        [byte[]]$find,
        [byte[]]$replace
    )

    # Create a List to build the result
    $result = New-Object System.Collections.Generic.List[byte]
    $i = 0
    $matchCount = 0  # Track actual matches for verification

    while ($i -lt $source.Length) {
        $pos = Find-BytePattern $source $find $i
        if ($pos -eq -1) {
            # No more matches, copy remaining bytes
            for ($j = $i; $j -lt $source.Length; $j++) {
                $result.Add($source[$j])
            }
            break
        }
        else {
            $matchCount++
            # Copy bytes before the match
            for ($j = $i; $j -lt $pos; $j++) {
                $result.Add($source[$j])
            }
            # Add replacement bytes (if any - empty replacement removes the pattern)
            if ($replace -ne $null -and $replace.Length -gt 0) {
                foreach ($b in $replace) {
                    $result.Add($b)
                }
            }
            # Advance past the matched pattern
            $i = $pos + $find.Length
        }
    }

    # Return results - use explicit byte array cast and separate properties
    # to avoid PowerShell hashtable unboxing issues
    $outputBytes = [byte[]]$result.ToArray()
    $wasModified = ($matchCount -gt 0)

    return [PSCustomObject]@{
        Bytes = $outputBytes
        Modified = $wasModified
        MatchCount = $matchCount
    }
}

Write-Host "Starting encoding fix scan in: $vaultPath" -ForegroundColor Cyan
Write-Host ("=" * 60)

$mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

foreach ($file in $mdFiles) {
    try {
        # Read original bytes with explicit type
        [byte[]]$originalBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        [byte[]]$currentBytes = $originalBytes.Clone()  # Clone to avoid reference issues
        $fileModified = $false

        foreach ($p in $patterns) {
            # Convert hex patterns to byte arrays with explicit typing
            [byte[]]$findBytes = Convert-HexToBytes $p.Find
            [byte[]]$replaceBytes = Convert-HexToBytes $p.Replace

            if ($findBytes.Length -gt 0) {
                $result = Replace-BytePattern -source $currentBytes -find $findBytes -replace $replaceBytes
                if ($result.Modified) {
                    # Explicitly cast to byte array to prevent type coercion
                    [byte[]]$currentBytes = $result.Bytes
                    $fileModified = $true
                }
            }
        }

        if ($fileModified) {
            # Verify the bytes actually changed before writing
            $bytesAreDifferent = ($currentBytes.Length -ne $originalBytes.Length)
            if (-not $bytesAreDifferent) {
                for ($i = 0; $i -lt $currentBytes.Length; $i++) {
                    if ($currentBytes[$i] -ne $originalBytes[$i]) {
                        $bytesAreDifferent = $true
                        break
                    }
                }
            }

            if ($bytesAreDifferent) {
                # Write the modified bytes
                [System.IO.File]::WriteAllBytes($file.FullName, [byte[]]$currentBytes)
                $filesFixed++
                Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "ERROR: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("=" * 60)
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "Files fixed: $filesFixed"
Write-Host ("=" * 60)
