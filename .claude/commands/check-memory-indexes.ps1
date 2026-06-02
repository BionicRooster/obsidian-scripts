# check-memory-indexes.ps1
# Reads both Claude memory index files and runs deterministic validation checks.
# Called by optimize-memory.md to replace the mechanical portions of Steps 1 and 4.
#
# What it does:
#   1. Reads the global memory index (memory.md) and the project MEMORY.md for the given CWD
#   2. Outputs the full content of both files for AI review in subsequent steps
#   3. Checks every markdown link in each index for dead pointers (file doesn't exist)
#   4. Flags lines exceeding 150 characters (index entries should stay concise)
#   5. Warns if the global index exceeds 200 lines (it is always fully loaded; keep it lean)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File check-memory-indexes.ps1 -ProjectCwd "C:\Users\awt"
#
# Parameters:
#   -ProjectCwd   The current working directory of the Claude session. Used to derive the
#                 sanitized project key and locate the project MEMORY.md. Defaults to $PWD.

param(
    [string]$ProjectCwd = $PWD.Path  # CWD passed in from optimize-memory; drives project key derivation
)

# --- Constants ---
$GlobalMemoryDir  = "C:\Users\awt\.claude\memory"   # Root folder for global memory files
$GlobalIndexPath  = "$GlobalMemoryDir\memory.md"    # Global index — always at this fixed path
$MaxIndexLines    = 200                              # Global index line cap before warning
$MaxLineLength    = 150                              # Index entry line length cap before warning

# --- Derive project memory path from CWD ---
# Sanitize: strip drive colon, convert all separators (\ and /) to --
# Example: "C:\Users\awt" -> "C--Users-awt"
$sanitized        = $ProjectCwd -replace ':', '' -replace '\\', '--' -replace '/', '--'
$ProjectMemoryDir = "C:\Users\awt\.claude\projects\$sanitized\memory"  # Project memory root
$ProjectIndexPath = "$ProjectMemoryDir\MEMORY.md"                       # Project index file

# --- Helper: validate one index file ---
# Scans for dead markdown links and overly long lines; reports line count.
function Invoke-IndexCheck {
    param(
        [string]$IndexPath,   # Absolute path to the index .md file being checked
        [string]$MemoryDir,   # Base directory for resolving relative link targets
        [string]$Label        # Display label: "Global" or "Project"
    )

    Write-Output ""
    Write-Output "=== $Label INDEX CHECK: $IndexPath ==="

    # If the file doesn't exist at all, report and return early
    if (-not (Test-Path $IndexPath)) {
        Write-Output "    STATUS: NOT FOUND"
        return
    }

    # Read all lines with UTF-8 encoding (vault standard)
    $lines     = Get-Content $IndexPath -Encoding UTF8
    $lineCount = $lines.Count  # Total line count for cap check

    Write-Output "    Lines: $lineCount"

    # Warn if global index is over the always-loaded cap
    if ($Label -eq "Global" -and $lineCount -gt $MaxIndexLines) {
        Write-Output "    WARNING: exceeds $MaxIndexLines-line cap ($lineCount lines) — trim entries"
    }

    $deadLinks = [System.Collections.Generic.List[string]]::new()  # Dead pointer findings
    $longLines = [System.Collections.Generic.List[string]]::new()  # Long-line findings

    foreach ($line in $lines) {

        # Flag lines that exceed the length cap
        if ($line.Length -gt $MaxLineLength) {
            $preview = $line.Substring(0, [Math]::Min(80, $line.Length))
            $longLines.Add("    LONG ($($line.Length) chars): ${preview}...")
        }

        # Extract markdown link targets: [display text](target)
        $linkMatches = [regex]::Matches($line, '\[.*?\]\(([^)]+)\)')
        foreach ($m in $linkMatches) {
            $target = $m.Groups[1].Value.Trim()  # Raw link target from the markdown

            # Skip external URLs — only validate local file paths
            if ($target -match '^https?://') { continue }

            # Resolve the relative link target against the memory directory
            $resolved = Join-Path $MemoryDir $target

            if (-not (Test-Path $resolved)) {
                $deadLinks.Add("    DEAD: $target  =>  $resolved")
            }
        }
    }

    # Report dead pointers
    if ($deadLinks.Count -gt 0) {
        Write-Output "    Dead pointers ($($deadLinks.Count)):"
        foreach ($d in $deadLinks) { Write-Output $d }
    } else {
        Write-Output "    Dead pointers: none"
    }

    # Report long lines
    if ($longLines.Count -gt 0) {
        Write-Output "    Lines over ${MaxLineLength} chars ($($longLines.Count)):"
        foreach ($l in $longLines) { Write-Output $l }
    } else {
        Write-Output "    Lines over ${MaxLineLength} chars: none"
    }
}

# =============================================================================
# MAIN
# =============================================================================

Write-Output "Memory Index Check"
Write-Output "Run at:        $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Output "CWD:           $ProjectCwd"
Write-Output "Project key:   $sanitized"
Write-Output "Global index:  $GlobalIndexPath"
Write-Output "Project index: $ProjectIndexPath"

# --- Validation checks (replaces Step 4 mechanical checks) ---
Invoke-IndexCheck -IndexPath $GlobalIndexPath  -MemoryDir $GlobalMemoryDir  -Label "Global"
Invoke-IndexCheck -IndexPath $ProjectIndexPath -MemoryDir $ProjectMemoryDir -Label "Project"

# --- Full content dump (replaces Step 1 read) ---
Write-Output ""
Write-Output "=== GLOBAL INDEX CONTENT ==="
if (Test-Path $GlobalIndexPath) {
    Get-Content $GlobalIndexPath -Encoding UTF8
} else {
    Write-Output "(file not found)"
}

Write-Output ""
Write-Output "=== PROJECT INDEX CONTENT ==="
if (Test-Path $ProjectIndexPath) {
    Get-Content $ProjectIndexPath -Encoding UTF8
} else {
    Write-Output "(file not found)"
}
