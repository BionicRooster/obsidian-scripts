# Append classify session entries to the Claude Action Log
# Uses Add-Content with UTF8 encoding to preserve vault encoding

$logFile = 'C:\Users\awt\Sync\Obsidian\01\PKM\Claude Action Log.md'

$lines = @(
    "",
    "[INGEST] On oil omega 3 eating plan.md -> Health & Nutrition / Plant-Based Nutrition; Perplexity research note on omega-3 ALA sources for vegans; frontmatter + nav added; moved to 01/Health/",
    "[INGEST] On oil omega 3 sources.md -> Health & Nutrition / Plant-Based Nutrition; companion note on omega-3 food/supplement sources; frontmatter + nav added; moved to 01/Health/",
    "[INGEST] TDS in Non-Therapeutic Environments.md -> NLP & Psychology / NLP Archive; moved to 01/NLP/",
    "[INGEST] Early to Bed at The Triad - Manhattan West 72nd Street.md -> Music & Record / Music Performances & Articles; moved to 01/Music/",
    "[INGEST] Pacific Warming Signals Strong El Nino Risk Wion Climate Tracker.md -> Science & Nature / Science Articles & Clippings; moved to 01/Science/",
    "[INGEST] John McWhorter on Controversy and Reconstructing Fats Waller Early to Bed.md -> Music & Record / Music Performances & Articles; moved to 01/Music/",
    "[INGEST] A Warning from 1994 of a Two-Tiered Society Robert Reich.md -> Social Issues / Social & Political Commentary; moved to 01/Social/",
    "[INGEST] Get a Replacement Voter Registration Card.md -> Home & Personal / Civic Resources; moved to 01/Home/",
    "[INGEST] Metonic Cycle.md -> Science & Nature / Astronomy; recovered from garbled char-interpolation path; moved to 01/Science/",
    "[INGEST] University of Texas at Austin 2014 Commencement Address - Admiral William H. McRaven.md -> Psychology / Leadership & Motivation; moved to 01/Psychology/",
    "[INGEST] Runner Who Killed Mountain Lion With Bare Hands Describes How He Survived.md -> Science & Nature / Science Articles & Clippings; moved to 01/Science/",
    "[INGEST] Truncated Filenames.md -> PKM / vault maintenance note; frontmatter + nav added; left in vault root per rule",
    "[DATA LOSS] Saros Eclipse Cycle.md permanently lost -- content overwritten by Metonic Cycle.md during garbled-path batch move ([char]0xNNNN not evaluated in bare string literal); no recovery possible",
    "[RECOVERY] 4 garbled Baha'i path files recovered via binary-safe ReadAllBytes/WriteAllBytes: BahA~1'i -> Ruth Kronick Funeral (Allen).md; Baha'i (wrong) -> Eric Harper - A New Video for You.md; wrong tone mark -> Is Caring For Your Mental Health a Spiritual Practice.md; literal [char] path -> Metonic Cycle.md",
    "[PEOPLE] Burke, Kenneth - People Index stub added; source: TDS in Non-Therapeutic Environments",
    "[PEOPLE] Erickson, Milton - People Index stub added; source: TDS in Non-Therapeutic Environments",
    "[PEOPLE] Kauffman, Travis - People Index stub added; source: Runner Who Killed Mountain Lion",
    "[PEOPLE] Petersburg, Ty - People Index stub added; source: Runner Who Killed Mountain Lion",
    "[SYNTHESIS] Neurolinguistic Programming.md (30 - Synthesis) updated: source_count 9->11; TDS subsection added under Core Concepts (Milton Model mechanism, non-therapeutic uses, AI/LLM fuzzy-match parallel); Nafs cross-reference added to NLP and Related Topics (ammara/lawwamma/mutma'inna mapped to NLP positive intention/Meta-Model/third position)"
)

# Write each line as UTF-8 without re-encoding content
foreach ($line in $lines) {
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

Write-Output "Done -- $($lines.Count - 1) entries appended"
