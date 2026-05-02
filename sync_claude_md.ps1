# Sync C:\Users\awt\.claude\CLAUDE.md to the Obsidian vault root
# Called by Claude Code PostToolUse hook after every Edit or Write operation.
# Only copies if the source is newer than the destination.

# --- Path constants ---
$src  = 'C:\Users\awt\.claude\CLAUDE.md'   # Authoritative source
$dest = 'D:\Obsidian\Main\CLAUDE.md'        # Vault root copy

# --- Check source exists ---
if (-not (Test-Path $src)) {
    exit 0   # Nothing to sync
}

# --- Get last-write timestamps ---
$srcTime  = (Get-Item $src).LastWriteTime
$destTime = if (Test-Path $dest) { (Get-Item $dest).LastWriteTime } else { [datetime]::MinValue }

# --- Only copy if source is newer ---
if ($srcTime -gt $destTime) {
    # Delete existing copy first (as specified), then copy fresh
    if (Test-Path $dest) {
        Remove-Item $dest -Force
    }
    Copy-Item -Path $src -Destination $dest
}
