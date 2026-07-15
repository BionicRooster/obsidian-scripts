# move_recent_classified.ps1
# Moves the 4 recently classified clippings to their target 01/ subdirectories.

$vault = 'C:\Users\awt\Sync\Obsidian'
$clippings = Join-Path $vault '10 - Clippings'

$moves = @(
    @{
        src = Join-Path $clippings "Ancient scrolls are being 'read' by machine learning `u{2013} with human knowledge to detect language and make sense of them.md"
        dst = Join-Path $vault "01\Science\Ancient scrolls are being 'read' by machine learning `u{2013} with human knowledge to detect language and make sense of them.md"
    },
    @{
        src = Join-Path $clippings "As a 'book scientist' I work with microscopes, imaging technologies and AI to preserve ancient texts.md"
        dst = Join-Path $vault "01\Science\As a 'book scientist' I work with microscopes, imaging technologies and AI to preserve ancient texts.md"
    },
    @{
        src = Join-Path $clippings "I paired Claude Code with Obsidian CLI and it finally organized five years of notes.md"
        dst = Join-Path $vault "01\PKM\I paired Claude Code with Obsidian CLI and it finally organized five years of notes.md"
    },
    @{
        src = Join-Path $clippings "Claude MCP Obsidian Tools Reference.md"
        dst = Join-Path $vault "01\PKM\Claude MCP Obsidian Tools Reference.md"
    }
)

foreach ($m in $moves) {
    if (Test-Path $m.src) {
        Move-Item -Path $m.src -Destination $m.dst -Force
        Write-Output "Moved: $([System.IO.Path]::GetFileName($m.src))"
    } else {
        Write-Output "NOT FOUND: $([System.IO.Path]::GetFileName($m.src))"
    }
}

Write-Output "Done."
