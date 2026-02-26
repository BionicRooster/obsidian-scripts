# moc_keywords.ps1 - Shared MOC Classification Definitions
# Single source of truth for keyword scoring, correct MOC file names, and default section placement.
# Dot-source this file in any script that classifies or cleans MOC links:
#   . "$PSScriptRoot\moc_keywords.ps1"
#
# Each entry in $mocDefinitions has:
#   MOCFile        - the exact filename of the MOC (must match vault)
#   DefaultSection - the real section header to use when adding new links
#   Keywords       - content keywords (2 pts each, max 10 matched per file)
#   Tags           - frontmatter/inline tags (10 pts each)
#   ExcludeKeywords - presence of any of these disqualifies this MOC entirely

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$mocDefinitions = @{

    "Bahá'í Faith" = @{
        MOCFile        = "MOC - Bahá'í Faith.md"
        DefaultSection = "## Core Teachings"
        Keywords       = @(
            "bahá'í", 'bahai', "bahá'u'lláh", 'bahaullah', 'báb', 'the bab',
            "'abdu'l-bahá", 'abdu', 'abdul-baha', 'shoghi effendi', 'guardian',
            'universal house of justice', 'uhj', 'ruhi', 'devotional',
            'feast', 'nineteen day', 'naw-rúz', 'naw-ruz', 'ridván', 'ridvan',
            "ayyám-i-há", 'mashriqu', 'local spiritual assembly', 'lsa',
            'national spiritual assembly', 'nsa', 'kitáb-i-aqdas', 'kitáb-i-íqán',
            'hidden words', 'seven valleys', 'gleanings', 'tablets of the divine plan',
            'haifa', 'akka', "'akká", 'shrine of the báb', 'mount carmel',
            'progressive revelation', 'covenant', 'administrative order',
            'nine year plan', 'five year plan', 'institute process', 'fireside',
            'cluster', 'teaching', 'pioneering', 'core activities', 'deepening'
        )
        Tags           = @("bahá'í", 'bahai', 'faith', 'religion', 'spiritual', 'devotional')
        ExcludeKeywords = @()
    }

    "Finance & Investment" = @{
        MOCFile        = "MOC - Finance & Investment.md"
        DefaultSection = "## Resources & Books"
        Keywords       = @(
            'finance', 'financial', 'investment', 'investing', 'stock', 'bond', 'etf',
            'mutual fund', 'retirement', '401k', 'ira', 'roth', 'pension',
            'savings', 'budget', 'budgeting', 'debt', 'credit', 'mortgage', 'loan',
            'interest rate', 'compound interest', 'portfolio', 'dividend',
            'capital gain', 'wealth', 'net worth', 'asset', 'liability',
            'balance sheet', 'cash flow', 'financial independence', 'early retirement',
            'frugal', 'banking', 'money market', 'cryptocurrency', 'bitcoin',
            'usaa', 'vanguard', 'fidelity', 'schwab', 'buffett', 'value investing'
        )
        Tags           = @('finance', 'investment', 'money', 'budget', 'retirement', 'wealth')
        ExcludeKeywords = @()
    }

    "Genealogy" = @{
        MOCFile        = "MOC - Genealogy.md"
        DefaultSection = "## Resources & How-Tos"
        Keywords       = @(
            'genealogy', 'ancestry', 'ancestor', 'descendant', 'family tree',
            'pedigree', 'lineage', 'haplogroup', 'y-dna', 'autosomal', 'ethnicity',
            'census', 'birth record', 'death record', 'marriage record', 'obituary',
            'probate', 'familysearch', 'findmypast', 'myheritage', 'ftdna',
            '23andme', 'ancestrydna', 'gedmatch', 'ellis island', 'ship manifest',
            'talbot', 'fillingim', 'dewey family', 'horn family'
        )
        Tags           = @('genealogy', 'ancestry', 'family', 'dna', 'heritage')
        ExcludeKeywords = @()
    }

    "Health & Nutrition" = @{
        MOCFile        = "MOC - Health & Nutrition.md"
        DefaultSection = "## Health Articles & Clippings"
        Keywords       = @(
            'health', 'healthy', 'nutrition', 'diet', 'exercise', 'fitness', 'workout',
            'vitamin', 'mineral', 'supplement', 'protein', 'carbohydrate', 'fat',
            'calorie', 'weight loss', 'metabolism', 'intermittent fasting',
            'medical', 'doctor', 'physician', 'hospital', 'diagnosis', 'treatment',
            'disease', 'illness', 'symptom', 'chronic', 'blood pressure', 'cholesterol',
            'diabetes', 'cancer', 'immune', 'vaccine', 'infection', 'virus', 'bacteria',
            'sleep', 'insomnia', 'circadian', 'meditation', 'mindfulness', 'stress',
            'esselstyn', 'ornish', 'mcdougall', 'barnard', 'greger', 'fuhrman',
            'campbell', 'wfpb', 'plant-based', 'whole food', 'blue zone'
        )
        Tags           = @('health', 'nutrition', 'medical', 'fitness', 'diet', 'wellness', 'exercise')
        ExcludeKeywords = @()
    }

    "Home & Practical Life" = @{
        MOCFile        = "MOC - Home & Practical Life.md"
        DefaultSection = "## Practical Tips & Life Hacks"
        Keywords       = @(
            'home', 'house', 'apartment', 'diy', 'repair', 'maintenance', 'renovation',
            'remodel', 'cleaning', 'organize', 'declutter', 'storage', 'furniture',
            'decor', 'interior design', 'plumbing', 'electrical', 'hvac',
            'roof', 'flooring', 'garage', 'basement', 'deck', 'patio', 'fence',
            'lawn', 'landscaping', 'pet', 'veterinary', 'off-grid', 'earthship',
            'stationery', 'fountain pen', 'ink', 'sketchplanation', 'xkcd',
            'cool tools', 'life hack', 'practical'
        )
        Tags           = @('home', 'diy', 'practical', 'household', 'maintenance')
        ExcludeKeywords = @('nlp', 'psychology', 'therapy')
    }

    "Music & Record" = @{
        MOCFile        = "MOC - Music & Record.md"
        DefaultSection = "## Music Performances & Articles"
        Keywords       = @(
            'music', 'musical', 'song', 'album', 'artist', 'band', 'musician',
            'guitar', 'piano', 'keyboard', 'drum', 'bass', 'violin', 'cello',
            'recorder', 'flute', 'clarinet', 'saxophone', 'trumpet', 'trombone',
            'singing', 'vocal', 'choir', 'harmony', 'melody', 'rhythm', 'tempo',
            'sheet music', 'notation', 'score', 'tablature',
            'concert', 'performance', 'gig', 'festival', 'vinyl', 'playlist',
            'rock', 'jazz', 'classical', 'pop', 'hip hop', 'country', 'folk',
            'hymn', 'worship', 'sacred music', 'mixing', 'mastering', 'studio',
            'composer', 'composition', 'arrangement', 'orchestration'
        )
        Tags           = @('music', 'song', 'album', 'instrument', 'musician', 'recording')
        ExcludeKeywords = @()
    }

    "NLP & Psychology" = @{
        MOCFile        = "MOC - NLP & Psychology.md"
        DefaultSection = "## Psychology & Behavior"
        Keywords       = @(
            'nlp', 'neuro-linguistic', 'neurolinguistic', 'bandler', 'grinder',
            'anchoring', 'reframe', 'reframing', 'submodality', 'meta-model',
            'metamodel', 'milton model', 'hypnosis', 'hypnotic', 'trance',
            'rapport', 'mirroring', 'pacing', 'leading', 'calibration',
            'representational system', 'vak', 'kinesthetic',
            'presupposition', 'limiting belief', 'parts integration', 'timeline',
            'phobia', 'trauma', 'ptsd', 'change work', 'therapeutic',
            'psychology', 'psychological', 'cognitive', 'behavioral', 'cbt',
            'unconscious', 'subconscious', 'mental', 'peak state',
            'motivation', 'goal setting', 'persuasion', 'negotiation',
            'cognitive bias', 'dunning-kruger', 'neuroscience', 'perception',
            'attention', 'learning', 'memory', 'decision making', 'thinking'
        )
        Tags           = @('nlp', 'psychology', 'therapy', 'mental', 'cognitive', 'behavioral', 'mind')
        ExcludeKeywords = @()
    }

    "Personal Knowledge Management" = @{
        MOCFile        = "MOC - Personal Knowledge Management.md"
        DefaultSection = "## PKM Systems & Methods"
        Keywords       = @(
            'pkm', 'personal knowledge', 'knowledge management', 'second brain',
            'obsidian', 'notion', 'roam', 'logseq', 'evernote', 'onenote',
            'note-taking', 'zettelkasten', 'slip box', 'backlink', 'markdown',
            'knowledge graph', 'map of content', 'frontmatter', 'yaml',
            'template', 'daily note', 'weekly review', 'periodic note',
            'para method', 'getting things done', 'gtd', 'workflow',
            'atomic note', 'evergreen note', 'permanent note', 'fleeting note',
            'how to take smart notes', 'ahrens', 'tiago forte',
            'building a second brain', 'basb', 'dataview', 'plugin', 'vault'
        )
        Tags           = @('pkm', 'obsidian', 'productivity', 'notes', 'knowledge', 'gtd', 'workflow')
        ExcludeKeywords = @('fountain pen ink', 'stationery shop')  # word-specific; avoid matching 'linking', 'thinking'
    }

    "Friends of the Georgetown Public Library" = @{
        MOCFile        = "MOC - Friends of the Georgetown Public Library.md"
        DefaultSection = "## FOL Operations & Procedures"
        Keywords       = @(
            'fol', 'friends of the library', 'georgetown public library',
            'hill country authors', 'hcas', 'little green light',
            'book sale', 'library board', 'library volunteer',
            'giving season', 'fundraising', 'library donation'
        )
        Tags           = @('fol', 'library', 'georgetown', 'friends')
        ExcludeKeywords = @()
    }

    "Japan & Japanese Culture" = @{
        MOCFile        = "MOC - Japan & Japanese Culture.md"
        DefaultSection = "## Arts & Culture"
        Keywords       = @(
            'japan', 'japanese', 'nihon', 'tokyo', 'kyoto', 'osaka',
            'samurai', 'ninja', 'geisha', 'kabuki', 'haiku', 'ikebana',
            'kintsugi', 'wabi-sabi', 'ikigai', 'kaizen', 'bushido',
            'zen', 'shinto', 'buddhism japan', 'tatami', 'origami',
            'manga', 'anime', 'bonsai', 'sumo', 'judo', 'karate',
            'sushi', 'ramen', 'miso', 'sake', 'matcha', 'wagyu',
            'inemuri', 'abacus', 'hanami', 'futon', 'shoji',
            'konmari', 'marie kondo', 'forest bathing', 'shinrin-yoku'
        )
        Tags           = @('japan', 'japanese', 'culture', 'asia')
        ExcludeKeywords = @()
    }

    "Reading & Literature" = @{
        MOCFile        = "MOC - Reading & Literature.md"
        DefaultSection = "## All Book Notes"
        Keywords       = @(
            'book', 'reading', 'literature', 'novel', 'fiction', 'non-fiction',
            'author', 'writer', 'writing', 'prose', 'poetry', 'poem',
            'kindle', 'ebook', 'audiobook', 'bookshelf',
            'review', 'summary', 'synopsis', 'plot', 'character', 'theme',
            'fantasy', 'sci-fi', 'science fiction', 'mystery', 'thriller',
            'biography', 'memoir', 'autobiography', 'bestseller',
            'reading list', 'to be read', 'currently reading',
            'highlight', 'annotation', 'clipping', 'publisher', 'edition'
        )
        Tags           = @('book', 'reading', 'literature', 'kindle', 'fiction', 'author')
        ExcludeKeywords = @()
    }

    "Recipes" = @{
        MOCFile        = "MOC - Recipes.md"
        DefaultSection = "## Main Dishes"
        Keywords       = @(
            'recipe', 'ingredient', 'cooking', 'baking', 'meal',
            'breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'appetizer',
            'soup', 'stew', 'salad', 'sandwich', 'pasta', 'rice', 'bread',
            'chicken', 'beef', 'pork', 'fish', 'seafood', 'vegetarian', 'vegan',
            'sauce', 'spice', 'herb', 'seasoning',
            'tablespoon', 'teaspoon', 'ounce', 'pound', 'gram',
            'prep time', 'cook time', 'servings', 'yield',
            'instant pot', 'slow cooker', 'air fryer', 'pressure cooker',
            'sourdough', 'ferment', 'pickle', 'preserve', 'jam'
        )
        Tags           = @('recipe', 'cooking', 'food', 'meal', 'baking', 'cuisine')
        ExcludeKeywords = @()
    }

    "Science & Nature" = @{
        MOCFile        = "MOC - Science & Nature.md"
        DefaultSection = "## Science Articles & Clippings"
        Keywords       = @(
            'science', 'scientific', 'research', 'study', 'experiment', 'hypothesis',
            'physics', 'chemistry', 'biology', 'geology', 'astronomy', 'ecology',
            'nature', 'natural', 'environment', 'ecosystem', 'habitat', 'wildlife',
            'animal', 'species', 'evolution', 'natural selection',
            'forest', 'ocean', 'marine', 'freshwater', 'climate', 'weather',
            'planet', 'solar system', 'galaxy', 'universe', 'cosmos',
            'nasa', 'satellite', 'astronaut', 'telescope',
            'fossil', 'dinosaur', 'paleontology', 'archaeology', 'ancient',
            'atom', 'molecule', 'element', 'periodic table',
            'cell', 'dna', 'gene', 'genome', 'organism',
            'micrometeorite', 'meteor', 'asteroid', 'comet',
            'gardening', 'compost', 'permaculture', 'hydroponics'
        )
        Tags           = @('science', 'nature', 'biology', 'physics', 'chemistry', 'space', 'environment')
        ExcludeKeywords = @()
    }

    "Soccer" = @{
        MOCFile        = "MOC - Soccer.md"
        DefaultSection = "## Soccer Culture & Values"
        Keywords       = @(
            'soccer', 'football', 'fútbol', 'futbol',
            'goal', 'goalkeeper', 'striker', 'midfielder', 'defender',
            'world cup', 'fifa', 'uefa', 'premier league', 'la liga',
            'bundesliga', 'serie a', 'mls',
            'penalty', 'free kick', 'offside', 'var', 'referee',
            'messi', 'ronaldo', 'pele', 'maradona', 'neymar', 'mbappe',
            'ted lasso', 'afc richmond', 'roy kent'
        )
        Tags           = @('soccer', 'football', 'sports', 'fifa', 'worldcup')
        ExcludeKeywords = @()
    }

    "Social Issues" = @{
        MOCFile        = "MOC - Social Issues.md"
        DefaultSection = "## Cultural Commentary"
        Keywords       = @(
            'social', 'society', 'community', 'civil rights', 'human rights',
            'justice', 'injustice', 'equality', 'equity', 'discrimination',
            'race', 'racial', 'racism', 'anti-racism', 'diversity', 'inclusion',
            'gender', 'sexism', 'feminism', 'lgbtq', 'transgender',
            'poverty', 'inequality', 'homeless', 'immigration', 'refugee',
            'politics', 'political', 'government', 'policy', 'legislation',
            'activism', 'protest', 'movement', 'reform', 'revolution',
            'education system', 'opportunity', 'privilege',
            'climate change', 'pollution', 'sustainability',
            'peace', 'war', 'conflict', 'violence', 'nonviolence', 'reconciliation',
            'indigenous', 'native american', 'first nations', 'aboriginal',
            'religion and society', 'interfaith', 'church and state'
        )
        Tags           = @('social', 'justice', 'politics', 'equality', 'rights', 'activism')
        ExcludeKeywords = @()
    }

    "Technology & Computers" = @{
        MOCFile        = "MOC - Technology & Computers.md"
        DefaultSection = "## Technology Articles & Clippings"
        Keywords       = @(
            'technology', 'tech', 'computer', 'computing', 'software', 'hardware',
            'programming', 'coding', 'developer', 'algorithm',
            'python', 'javascript', 'java', 'c#', 'ruby', 'php', 'sql', 'vba',
            'html', 'css', 'frontend', 'backend', 'database', 'server',
            'cloud', 'aws', 'azure', 'api', 'rest', 'docker', 'kubernetes',
            'linux', 'unix', 'command line', 'terminal', 'bash', 'powershell',
            'network', 'networking', 'tcp', 'ip', 'dns', 'http', 'https',
            'security', 'cybersecurity', 'encryption', 'authentication',
            'artificial intelligence', 'machine learning', 'deep learning',
            'big data', 'analytics', 'android', 'ios', 'mobile app',
            'git', 'github', 'version control',
            'cpu', 'gpu', 'ram', 'ssd', 'processor',
            'raspberry pi', 'arduino', 'maker', 'electronics', 'circuit',
            'excel', 'macro', 'spreadsheet', 'chromebook', 'browser'
        )
        Tags           = @('tech', 'technology', 'computer', 'programming', 'software', 'hardware', 'coding')
        ExcludeKeywords = @()
    }

    "Travel & Exploration" = @{
        MOCFile        = "MOC - Travel & Exploration.md"
        DefaultSection = "## Travel Tips & Resources"
        Keywords       = @(
            'travel', 'trip', 'journey', 'vacation', 'holiday', 'tourism',
            'destination', 'flight', 'airline', 'airport',
            'hotel', 'hostel', 'airbnb', 'accommodation', 'lodging',
            'passport', 'visa', 'luggage', 'packing',
            'national park', 'hiking', 'trail', 'camping',
            'beach', 'mountain', 'island', 'road trip',
            'narrowboat', 'canal', 'waterway', 'boat', 'sailing',
            'sightseeing', 'landmark', 'monument', 'itinerary'
        )
        Tags           = @('travel', 'trip', 'vacation', 'destination', 'tourism', 'adventure')
        ExcludeKeywords = @()
    }
}


# ============================================================
# SHARED SCORING FUNCTIONS
# Used identically by classify scripts and clean/analyze scripts
# so both see notes the same way.
# ============================================================

# Extract lowercase content and tags from a markdown file.
# Returns $null if the file cannot be read.
function Get-FileMetadata {
    param(
        [string]$FilePath   # Absolute path to the .md file
    )

    if (-not (Test-Path $FilePath)) { return $null }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return $null }

    # Collect tags from YAML frontmatter and inline #hashtags
    $tags = @()

    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $matches[1]

        # Multi-line YAML tag list:  tags:\n  - foo
        if ($frontmatter -match '(?m)^tags:\s*\n((?:\s*-\s*.+\n)+)') {
            foreach ($m in [regex]::Matches($matches[1], '-\s*(\S+)')) {
                $tags += $m.Groups[1].Value.ToLower()
            }
        }
        # Inline YAML tag list:  tags: [foo, bar]
        elseif ($frontmatter -match '(?m)^tags:\s*\[([^\]]+)\]') {
            foreach ($t in ($matches[1] -split ',\s*')) {
                $tags += $t.Trim().ToLower() -replace "^['""]|['""]$", ''
            }
        }
    }

    # Inline #tags in body (not inside wikilinks)
    foreach ($m in [regex]::Matches($content, '(?<!\[\[)#([a-zA-Z][a-zA-Z0-9_-]*)')) {
        $t = $m.Groups[1].Value.ToLower()
        if ($t -notin $tags) { $tags += $t }
    }

    return @{
        Content  = $content.ToLower()   # Full lowercased text for keyword matching
        Tags     = $tags                 # All tags (frontmatter + inline), lowercased
        FileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        FilePath = $FilePath
    }
}


# Score how well a file matches one MOC topic.
# Returns a hashtable with Score, MatchedItems, Reason.
#   Tags match:    10 pts each (strong signal)
#   Keywords match: 2 pts each, capped at 10 unique keyword hits per file
#   ExcludeKeyword: -100 (disqualifies entirely)
function Get-MOCMatchScore {
    param(
        [hashtable]$FileMetadata,   # Output of Get-FileMetadata
        [string]$MOCTopic           # Key in $mocDefinitions
    )

    if (-not $mocDefinitions.ContainsKey($MOCTopic)) {
        return @{ Score = 0; MatchedItems = @(); Reason = "No definition for: $MOCTopic" }
    }

    $def     = $mocDefinitions[$MOCTopic]
    $content = $FileMetadata.Content   # Already lowercased
    $tags    = $FileMetadata.Tags      # Already lowercased

    $score        = 0
    $matchedItems = [System.Collections.ArrayList]@()

    # Exclude check - any hit returns score -100
    foreach ($ex in $def.ExcludeKeywords) {
        if ($content -match [regex]::Escape($ex.ToLower())) {
            return @{
                Score        = -100
                MatchedItems = @("EXCLUDED:$ex")
                Reason       = "Contains excluded keyword: $ex"
            }
        }
    }

    # Tag matches - 10 pts each
    foreach ($expectedTag in $def.Tags) {
        foreach ($fileTag in $tags) {
            if ($fileTag -eq $expectedTag.ToLower()) {
                $score += 10
                [void]$matchedItems.Add("tag:$fileTag")
            }
        }
    }

    # Keyword matches in content - 2 pts each, cap at 10
    $kwHits = 0
    foreach ($kw in $def.Keywords) {
        if ($kwHits -ge 10) { break }
        if ($content -match "\b$([regex]::Escape($kw.ToLower()))\b") {
            $score += 2
            [void]$matchedItems.Add("kw:$kw")
            $kwHits++
        }
    }

    $reason = if ($matchedItems.Count -gt 0) {
        "Matched: " + (($matchedItems | Select-Object -First 5) -join ", ")
    } else { "No matches" }

    return @{ Score = $score; MatchedItems = $matchedItems; Reason = $reason }
}


# Score a file against ALL MOC topics and return results sorted descending by score.
# Each result object has: MOCTopic, MOCFile, DefaultSection, Score, Reason
function Find-BestMOCMatch {
    param(
        [hashtable]$FileMetadata   # Output of Get-FileMetadata
    )

    $results = foreach ($topic in $mocDefinitions.Keys) {
        $r = Get-MOCMatchScore -FileMetadata $FileMetadata -MOCTopic $topic
        [PSCustomObject]@{
            MOCTopic       = $topic
            MOCFile        = $mocDefinitions[$topic].MOCFile
            DefaultSection = $mocDefinitions[$topic].DefaultSection
            Score          = $r.Score
            Reason         = $r.Reason
        }
    }

    return $results | Sort-Object Score -Descending
}


# Resolve a wikilink target to an absolute file path, searching the vault.
# Returns $null if not found.
function Resolve-WikiLink {
    param(
        [string]$LinkTarget,   # The text inside [[ ]], e.g. "01/Science/Maslin Bread"
        [string]$VaultPath     # Root vault path
    )

    # Direct match with path separators normalised
    $directPath = Join-Path $VaultPath "$($LinkTarget -replace '[/\\]', '\').md"
    if (Test-Path $directPath) { return $directPath }

    # Search by filename anywhere in vault
    $baseName = Split-Path $LinkTarget -Leaf
    $found = Get-ChildItem -Path $VaultPath -Filter "$baseName.md" -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) { return $found.FullName }

    # Try smart apostrophe variant
    $altName = $baseName -replace "'", "'"
    if ($altName -ne $baseName) {
        $found = Get-ChildItem -Path $VaultPath -Filter "$altName.md" -Recurse -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    return $null
}


# Extract all wikilinks from a MOC file with their section context.
# Skips folder links (e.g. [[10 - Clippings]]) and MOC self-links.
# Returns array of hashtables: Target, Section, RawMatch
function Get-MOCLinks {
    param(
        [string]$MOCFilePath   # Absolute path to the MOC .md file
    )

    if (-not (Test-Path $MOCFilePath)) { return @() }

    $lines          = Get-Content -Path $MOCFilePath -Encoding UTF8
    $links          = @()
    $currentSection = "Uncategorized"

    foreach ($line in $lines) {
        # Track ## section headers
        if ($line -match '^##\s+(.+)$') {
            $currentSection = $matches[1].Trim()
            continue
        }

        # Extract [[target]] and [[target|alias]] links
        foreach ($m in [regex]::Matches($line, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')) {
            $target = $m.Groups[1].Value.Trim()

            # Skip folder links like [[10 - Clippings]]
            if ($target -match '^\d+\s*-\s*') { continue }
            # Skip links to other MOC files
            if ($target -match '^MOC - ') { continue }

            $links += @{
                Target   = $target
                Section  = $currentSection
                RawMatch = $m.Value
            }
        }
    }

    return $links
}
