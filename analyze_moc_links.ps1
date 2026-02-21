# MOC Link Analyzer - Find Misplaced Links in Obsidian MOCs
# This script analyzes all MOC files and identifies links that may be better suited to different MOCs
# Usage: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\analyze_moc_links.ps1" [-Fix] [-Limit 10]

param(
    # If set, will prompt to fix misplaced links interactively
    [switch]$Fix,

    # Limit the number of misplaced links to process (useful for testing)
    [int]$Limit = 0,

    # Output report file path
    [string]$ReportPath = "C:\Users\awt\moc_analysis_report.txt",

    # Export detailed JSON data
    [switch]$ExportJson
)

# Ensure UTF-8 encoding for proper handling of Bahá'í diacritics
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# ============================================================
# CONFIGURATION
# ============================================================

# Vault path configuration
$vaultPath = 'D:\Obsidian\Main'
$mocFolder = '00 - Home Dashboard'

# ============================================================
# MOC KEYWORD DEFINITIONS
# Each MOC has a set of keywords that indicate content belongs there
# Keywords are checked against file content and tags
# ============================================================

$mocKeywords = @{
    # Bahá'í Faith MOC - Religious/spiritual content
    "Bahá'í Faith" = @{
        Keywords = @(
            'bahá', 'bahai', "bahá'í", 'bahá''u''lláh', 'bahaullah', 'bab', 'the báb',
            'abdul-baha', "'abdu'l-bahá", 'abdu', 'shoghi effendi', 'guardian',
            'universal house of justice', 'uhj', 'ruhi', 'devotional',
            'feast', 'naw-rúz', 'naw-ruz', 'ridván', 'ridvan', 'ayyám-i-há', 'nineteen day', 'mashriqu',
            'local spiritual assembly', 'lsa', 'national spiritual assembly', 'nsa',
            'kitáb-i-aqdas', 'kitáb-i-íqán', 'hidden words', 'seven valleys', 'gleanings',
            'prayer', 'fasting', 'pilgrimage', 'haifa', 'akka', "'akká", 'shrine', 'arc',
            'unity', 'oneness', 'progressive revelation', 'covenant', 'administrative order',
            'nine year plan', 'institute', 'devotional gathering', 'fireside', 'deepening'
        )
        Tags = @('bahai', "bahá'í", 'faith', 'religion', 'spiritual', 'devotional')
        ExcludeKeywords = @()  # Keywords that suggest this is NOT the right MOC
    }

    # Finance & Investment MOC
    "Finance & Investment" = @{
        Keywords = @(
            'finance', 'financial', 'investment', 'investing', 'stock', 'bond', 'etf', 'mutual fund',
            'retirement', '401k', 'ira', 'roth', 'pension', 'savings', 'budget', 'budgeting',
            'debt', 'credit', 'mortgage', 'loan', 'interest rate', 'compound interest',
            'portfolio', 'dividend', 'capital gain', 'tax', 'deduction', 'income',
            'wealth', 'net worth', 'asset', 'liability', 'balance sheet', 'cash flow',
            'fire', 'financial independence', 'early retirement', 'frugal',
            'bank', 'banking', 'checking', 'savings account', 'cd', 'money market',
            'cryptocurrency', 'bitcoin', 'ethereum', 'blockchain'
        )
        Tags = @('finance', 'investment', 'money', 'budget', 'retirement', 'wealth')
        ExcludeKeywords = @()
    }

    # Health & Nutrition MOC
    "Health & Nutrition" = @{
        Keywords = @(
            'health', 'healthy', 'nutrition', 'diet', 'exercise', 'fitness', 'workout',
            'vitamin', 'mineral', 'supplement', 'protein', 'carbohydrate', 'fat', 'calorie',
            'weight loss', 'weight gain', 'bmi', 'metabolism', 'intermittent fasting',
            'medical', 'doctor', 'physician', 'hospital', 'clinic', 'diagnosis', 'treatment',
            'disease', 'illness', 'symptom', 'condition', 'chronic', 'acute',
            'mental health', 'anxiety', 'depression', 'therapy', 'counseling', 'psychology',
            'sleep', 'insomnia', 'circadian', 'melatonin', 'rest', 'recovery',
            'heart', 'cardiovascular', 'blood pressure', 'cholesterol', 'diabetes',
            'cancer', 'tumor', 'chemotherapy', 'radiation', 'oncology',
            'immune', 'immunity', 'vaccine', 'antibody', 'infection', 'virus', 'bacteria',
            'dental', 'teeth', 'oral', 'vision', 'eye', 'hearing', 'ear',
            'yoga', 'meditation', 'mindfulness', 'breathing', 'stress'
        )
        Tags = @('health', 'nutrition', 'medical', 'fitness', 'diet', 'wellness', 'exercise')
        ExcludeKeywords = @()
    }

    # Home & Practical Life MOC
    "Home & Practical Life" = @{
        Keywords = @(
            'home', 'house', 'apartment', 'rental', 'mortgage', 'property',
            'diy', 'repair', 'maintenance', 'fix', 'install', 'renovation', 'remodel',
            'garden', 'gardening', 'plant', 'seed', 'soil', 'compost', 'fertilizer',
            'kitchen', 'cooking', 'appliance', 'refrigerator', 'oven', 'stove',
            'cleaning', 'organize', 'declutter', 'storage', 'closet',
            'furniture', 'decor', 'interior design', 'paint', 'wallpaper',
            'plumbing', 'electrical', 'hvac', 'heating', 'cooling', 'insulation',
            'roof', 'siding', 'window', 'door', 'flooring', 'carpet', 'tile',
            'garage', 'basement', 'attic', 'shed', 'deck', 'patio', 'fence',
            'lawn', 'mowing', 'landscaping', 'tree', 'shrub', 'flower',
            'pet', 'dog', 'cat', 'veterinary', 'grooming',
            'genealogy', 'ancestry', 'family tree', 'dna', 'heritage',
            'rv', 'camper', 'mobile home', 'tiny house', 'alternative living',
            'sustainable', 'solar', 'off-grid', 'earthship', 'earthbag',
            'stationery', 'fountain pen', 'ink', 'writing tools', 'pen'
        )
        Tags = @('home', 'diy', 'gardening', 'practical', 'household', 'maintenance', 'genealogy')
        ExcludeKeywords = @('nlp', 'psychology', 'therapy')  # Avoid psychological content
    }

    # Music & Record MOC
    "Music & Record" = @{
        Keywords = @(
            'music', 'musical', 'song', 'album', 'artist', 'band', 'musician',
            'guitar', 'piano', 'keyboard', 'drum', 'bass', 'violin', 'cello',
            'recorder', 'flute', 'clarinet', 'saxophone', 'trumpet', 'trombone',
            'singing', 'vocal', 'choir', 'harmony', 'melody', 'rhythm', 'tempo',
            'sheet music', 'notation', 'score', 'tab', 'tablature',
            'concert', 'performance', 'live', 'gig', 'tour', 'festival',
            'record', 'vinyl', 'cd', 'streaming', 'spotify', 'playlist',
            'genre', 'rock', 'jazz', 'classical', 'pop', 'hip hop', 'country', 'folk',
            'hymn', 'worship', 'sacred music', 'anthem',
            'audio', 'sound', 'mixing', 'mastering', 'production', 'studio',
            'composer', 'composition', 'arrangement', 'orchestration'
        )
        Tags = @('music', 'song', 'album', 'instrument', 'musician', 'recording')
        ExcludeKeywords = @()
    }

    # NLP & Psychology MOC
    "NLP & Psychology" = @{
        Keywords = @(
            'nlp', 'neuro-linguistic', 'neurolinguistic', 'bandler', 'grinder',
            'anchoring', 'reframe', 'reframing', 'submodality', 'meta-model', 'metamodel',
            'milton model', 'hypnosis', 'hypnotic', 'trance', 'induction',
            'rapport', 'mirroring', 'pacing', 'leading', 'calibration',
            'representational system', 'vak', 'visual', 'auditory', 'kinesthetic',
            'presupposition', 'belief', 'limiting belief', 'empowering belief',
            'strategy', 'modeling', 'excellence', 'outcome', 'well-formed',
            'ecology', 'congruence', 'parts integration', 'timeline', 'time line',
            'phobia', 'trauma', 'ptsd', 'change work', 'therapy', 'therapeutic',
            'psychology', 'psychological', 'cognitive', 'behavioral', 'cbt',
            'unconscious', 'subconscious', 'conscious', 'mind', 'mental',
            'emotion', 'emotional', 'feeling', 'state', 'peak state',
            'motivation', 'drive', 'goal setting', 'achievement',
            'communication', 'influence', 'persuasion', 'negotiation',
            'dhe', 'design human engineering'
        )
        Tags = @('nlp', 'psychology', 'therapy', 'mental', 'cognitive', 'behavioral', 'mind')
        ExcludeKeywords = @()
    }

    # Personal Knowledge Management MOC
    "Personal Knowledge Management" = @{
        Keywords = @(
            'pkm', 'personal knowledge', 'knowledge management', 'second brain',
            'obsidian', 'notion', 'roam', 'logseq', 'evernote', 'onenote',
            'note-taking', 'note taking', 'notes', 'zettelkasten', 'slip box',
            'linking', 'backlink', 'wiki', 'markdown', 'graph', 'knowledge graph',
            'moc', 'map of content', 'index', 'hub', 'dashboard',
            'tag', 'tagging', 'metadata', 'frontmatter', 'yaml',
            'template', 'daily note', 'weekly review', 'periodic note',
            'para', 'projects', 'areas', 'resources', 'archives',
            'gtd', 'getting things done', 'productivity', 'workflow', 'process',
            'capture', 'organize', 'distill', 'express', 'code',
            'atomic note', 'evergreen', 'permanent note', 'fleeting note', 'literature note',
            'smart notes', 'how to take smart notes', 'ahrens', 'sönke',
            'tiago forte', 'building a second brain', 'basb',
            'dataview', 'plugin', 'sync', 'backup', 'vault'
        )
        Tags = @('pkm', 'obsidian', 'productivity', 'notes', 'knowledge', 'gtd', 'workflow')
        ExcludeKeywords = @('fountain pen', 'ink', 'stationery')  # Physical writing tools don't belong
    }

    # Reading & Literature MOC
    "Reading & Literature" = @{
        Keywords = @(
            'book', 'reading', 'literature', 'novel', 'fiction', 'non-fiction',
            'author', 'writer', 'writing', 'prose', 'poetry', 'poem',
            'chapter', 'page', 'paragraph', 'sentence', 'word',
            'kindle', 'ebook', 'audiobook', 'library', 'bookshelf',
            'review', 'summary', 'synopsis', 'plot', 'character', 'theme',
            'genre', 'fantasy', 'sci-fi', 'science fiction', 'mystery', 'thriller',
            'biography', 'memoir', 'autobiography', 'history', 'historical',
            'classic', 'bestseller', 'award', 'pulitzer', 'booker', 'nobel',
            'reading list', 'tbr', 'to be read', 'currently reading',
            'highlight', 'annotation', 'margin note', 'clipping',
            'publisher', 'publishing', 'edition', 'hardcover', 'paperback'
        )
        Tags = @('book', 'reading', 'literature', 'kindle', 'fiction', 'author')
        ExcludeKeywords = @()
    }

    # Recipes MOC
    "Recipes" = @{
        Keywords = @(
            'recipe', 'ingredient', 'cooking', 'baking', 'food', 'meal',
            'breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'appetizer',
            'soup', 'stew', 'salad', 'sandwich', 'pasta', 'rice', 'bread',
            'meat', 'chicken', 'beef', 'pork', 'fish', 'seafood', 'vegetarian', 'vegan',
            'vegetable', 'fruit', 'herb', 'spice', 'seasoning', 'sauce',
            'oven', 'stove', 'grill', 'bake', 'roast', 'fry', 'sauté', 'boil', 'simmer',
            'cup', 'tablespoon', 'teaspoon', 'ounce', 'pound', 'gram',
            'prep time', 'cook time', 'servings', 'yield', 'portion',
            'cuisine', 'italian', 'mexican', 'chinese', 'indian', 'french', 'american',
            'instant pot', 'slow cooker', 'air fryer', 'pressure cooker'
        )
        Tags = @('recipe', 'cooking', 'food', 'meal', 'baking', 'cuisine')
        ExcludeKeywords = @()
    }

    # Science & Nature MOC
    "Science & Nature" = @{
        Keywords = @(
            'science', 'scientific', 'research', 'study', 'experiment', 'hypothesis',
            'physics', 'chemistry', 'biology', 'geology', 'astronomy', 'ecology',
            'nature', 'natural', 'environment', 'ecosystem', 'habitat', 'wildlife',
            'animal', 'species', 'evolution', 'darwin', 'natural selection',
            'plant', 'tree', 'forest', 'ocean', 'marine', 'freshwater',
            'climate', 'weather', 'temperature', 'precipitation', 'storm',
            'earth', 'planet', 'solar system', 'galaxy', 'universe', 'cosmos',
            'space', 'nasa', 'satellite', 'rocket', 'astronaut', 'telescope',
            'fossil', 'dinosaur', 'paleontology', 'archaeology', 'ancient',
            'atom', 'molecule', 'element', 'periodic table', 'chemical',
            'energy', 'force', 'gravity', 'magnetism', 'electricity',
            'cell', 'dna', 'gene', 'genome', 'protein', 'organism',
            'micrometeorite', 'meteor', 'asteroid', 'comet'
        )
        Tags = @('science', 'nature', 'biology', 'physics', 'chemistry', 'space', 'environment')
        ExcludeKeywords = @()
    }

    # Soccer MOC
    "Soccer" = @{
        Keywords = @(
            'soccer', 'football', 'fútbol', 'futbol',
            'goal', 'goalkeeper', 'striker', 'midfielder', 'defender', 'forward',
            'match', 'game', 'tournament', 'league', 'cup', 'championship',
            'world cup', 'fifa', 'uefa', 'premier league', 'la liga', 'bundesliga', 'serie a',
            'team', 'club', 'player', 'coach', 'manager', 'transfer',
            'kick', 'pass', 'dribble', 'tackle', 'header', 'penalty', 'free kick',
            'offside', 'foul', 'yellow card', 'red card', 'referee',
            'stadium', 'pitch', 'field', 'net', 'post', 'crossbar',
            'messi', 'ronaldo', 'pele', 'maradona', 'neymar', 'mbappe'
        )
        Tags = @('soccer', 'football', 'sports', 'fifa', 'worldcup')
        ExcludeKeywords = @()
    }

    # Social Issues MOC
    "Social Issues" = @{
        Keywords = @(
            'social', 'society', 'community', 'civil', 'civic', 'citizen',
            'justice', 'injustice', 'equality', 'equity', 'discrimination',
            'race', 'racial', 'racism', 'anti-racism', 'diversity', 'inclusion',
            'gender', 'sexism', 'feminism', 'lgbtq', 'transgender', 'identity',
            'poverty', 'wealth gap', 'inequality', 'homeless', 'housing',
            'immigration', 'refugee', 'asylum', 'border', 'citizenship',
            'politics', 'political', 'government', 'policy', 'legislation', 'law',
            'rights', 'human rights', 'civil rights', 'freedom', 'liberty',
            'activism', 'protest', 'movement', 'reform', 'revolution',
            'education', 'school', 'access', 'opportunity', 'privilege',
            'environment', 'climate change', 'sustainability', 'pollution',
            'healthcare', 'insurance', 'medicare', 'medicaid', 'universal',
            'peace', 'war', 'conflict', 'violence', 'nonviolence', 'reconciliation'
        )
        Tags = @('social', 'justice', 'politics', 'equality', 'rights', 'activism')
        ExcludeKeywords = @()
    }

    # Technology & Computers/Computing MOC
    "Technology & Computers" = @{
        Keywords = @(
            'technology', 'tech', 'computer', 'computing', 'software', 'hardware',
            'programming', 'coding', 'developer', 'code', 'script', 'algorithm',
            'python', 'javascript', 'java', 'c#', 'c++', 'ruby', 'php', 'sql',
            'web', 'website', 'html', 'css', 'frontend', 'backend', 'fullstack',
            'database', 'server', 'cloud', 'aws', 'azure', 'google cloud',
            'api', 'rest', 'graphql', 'microservice', 'docker', 'kubernetes',
            'linux', 'windows', 'macos', 'unix', 'command line', 'terminal', 'shell',
            'network', 'networking', 'tcp', 'ip', 'dns', 'http', 'https',
            'security', 'cybersecurity', 'encryption', 'password', 'authentication',
            'ai', 'artificial intelligence', 'machine learning', 'ml', 'deep learning',
            'data', 'big data', 'analytics', 'visualization', 'dashboard',
            'mobile', 'android', 'ios', 'app', 'application',
            'git', 'github', 'version control', 'repository', 'commit',
            'cpu', 'gpu', 'ram', 'ssd', 'storage', 'memory', 'processor',
            'raspberry pi', 'arduino', 'maker', 'electronics', 'circuit',
            'excel', 'vba', 'macro', 'spreadsheet', 'powerpoint', 'word',
            'chromebook', 'chrome os', 'browser', 'extension'
        )
        Tags = @('tech', 'technology', 'computer', 'programming', 'software', 'hardware', 'coding')
        ExcludeKeywords = @()
    }

    # Travel & Exploration MOC
    "Travel & Exploration" = @{
        Keywords = @(
            'travel', 'trip', 'journey', 'vacation', 'holiday', 'tourism',
            'destination', 'location', 'place', 'city', 'country', 'region',
            'flight', 'airline', 'airport', 'plane', 'airplane',
            'hotel', 'hostel', 'airbnb', 'accommodation', 'lodging', 'resort',
            'passport', 'visa', 'customs', 'immigration', 'border',
            'luggage', 'packing', 'suitcase', 'backpack', 'carry-on',
            'national park', 'hiking', 'trail', 'camping', 'outdoor',
            'beach', 'mountain', 'lake', 'river', 'ocean', 'island',
            'road trip', 'driving', 'car rental', 'rv', 'camper', 'motorhome',
            'narrowboat', 'canal', 'waterway', 'boat', 'sailing',
            'pilgrimage', 'holy site', 'sacred', 'shrine', 'temple',
            'sightseeing', 'landmark', 'monument', 'museum', 'attraction',
            'itinerary', 'guide', 'map', 'navigation', 'directions',
            'culture', 'local', 'cuisine', 'language', 'customs'
        )
        Tags = @('travel', 'trip', 'vacation', 'destination', 'tourism', 'adventure')
        ExcludeKeywords = @()
    }
}

# Also handle alternate MOC names (some MOCs have similar names)
# Map actual MOC file names to our keyword definition keys
$mocAliases = @{
    "Technology & Computing" = "Technology & Computers"
    "Social Issues " = "Social Issues"  # Note trailing space in some MOC names
}

# Function to normalize MOC topic name for matching
function Get-NormalizedMOCTopic {
    param([string]$Topic)

    # First check if there's a direct alias
    if ($mocAliases.ContainsKey($Topic)) {
        return $mocAliases[$Topic]
    }

    # Return the topic as-is (UTF-8 should handle Bahá'í correctly)
    return $Topic
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Function to log messages with timestamp and color
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "INFO"    { "[INFO]   " }
        "SUCCESS" { "[SUCCESS]" }
        "WARNING" { "[WARNING]" }
        "ERROR"   { "[ERROR]  " }
        default   { "[INFO]   " }
    }

    $colorMap = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
    }

    if (-not $Color -or $Color -eq "White") {
        $Color = $colorMap[$Level]
    }

    Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $Color

    # Also append to report file
    "[$timestamp] $prefix $Message" | Add-Content -Path $ReportPath -Encoding UTF8
}

# Function to get all MOC files
function Get-MOCFiles {
    $mocFiles = Get-ChildItem -Path (Join-Path $vaultPath $mocFolder) -Filter "MOC - *.md" -ErrorAction SilentlyContinue

    $mocs = @()
    foreach ($file in $mocFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $topic = $baseName -replace '^MOC - ', ''
        $mocs += @{
            FileName = $file.Name
            BaseName = $baseName
            Topic = $topic
            FullPath = $file.FullName
        }
    }
    return $mocs | Sort-Object { $_.Topic }
}

# Function to extract all wiki links from a MOC file with their sections
function Get-MOCLinks {
    param([string]$MOCFilePath)

    if (-not (Test-Path $MOCFilePath)) {
        return @()
    }

    $content = Get-Content -Path $MOCFilePath -Raw -Encoding UTF8
    $lines = $content -split "`n"

    $links = @()
    $currentSection = "Uncategorized"

    foreach ($line in $lines) {
        # Track current section (## headers)
        if ($line -match '^##\s+(.+)$') {
            $currentSection = $matches[1].Trim()
        }

        # Extract wiki links - match [[target|alias]] or [[target]]
        $linkMatches = [regex]::Matches($line, '\[\[([^\]|]+)(?:\|([^\]]+))?\]\]')

        foreach ($match in $linkMatches) {
            $linkTarget = $match.Groups[1].Value.Trim()
            $linkAlias = if ($match.Groups[2].Value) { $match.Groups[2].Value.Trim() } else { $linkTarget }

            # Skip links to folders (typically numeric prefixes like "00 - ", "09 - ", "20 - ")
            if ($linkTarget -match '^\d+\s*-\s*') {
                continue
            }

            # Skip links to MOC files themselves
            if ($linkTarget -match '^MOC - ') {
                continue
            }

            $links += @{
                Target = $linkTarget
                Alias = $linkAlias
                Section = $currentSection
                RawMatch = $match.Value
            }
        }
    }

    return $links
}

# Function to find the actual file path for a wiki link target
function Resolve-WikiLink {
    param([string]$LinkTarget)

    # Handle path separators
    $searchName = $LinkTarget -replace '[/\\]', '\\'

    # Try direct match first
    $directPath = Join-Path $vaultPath "$searchName.md"
    if (Test-Path $directPath) {
        return $directPath
    }

    # Search for the file anywhere in the vault
    $baseName = Split-Path $LinkTarget -Leaf
    $found = Get-ChildItem -Path $vaultPath -Filter "$baseName.md" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($found) {
        return $found.FullName
    }

    # Try with smart apostrophe variations
    $altName = $baseName -replace "'", "'"
    if ($altName -ne $baseName) {
        $found = Get-ChildItem -Path $vaultPath -Filter "$altName.md" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    return $null
}

# Function to extract tags and content from a markdown file
function Get-FileMetadata {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        return $null
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) {
        return $null
    }

    # Extract frontmatter tags
    $tags = @()
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $matches[1]

        # Extract tags from YAML frontmatter
        if ($frontmatter -match '(?m)^tags:\s*\n((?:\s*-\s*.+\n)+)') {
            $tagLines = $matches[1]
            $tagMatches = [regex]::Matches($tagLines, '-\s*(\S+)')
            foreach ($m in $tagMatches) {
                $tags += $m.Groups[1].Value.ToLower()
            }
        }
        elseif ($frontmatter -match '(?m)^tags:\s*\[([^\]]+)\]') {
            $tagList = $matches[1] -split ',\s*'
            foreach ($t in $tagList) {
                $tags += $t.Trim().ToLower() -replace '^[''"]|[''"]$', ''
            }
        }
    }

    # Extract inline tags (#tag)
    $inlineTags = [regex]::Matches($content, '(?<!\[\[)#([a-zA-Z][a-zA-Z0-9_-]*)')
    foreach ($m in $inlineTags) {
        $tag = $m.Groups[1].Value.ToLower()
        if ($tag -notin $tags) {
            $tags += $tag
        }
    }

    return @{
        Content = $content.ToLower()
        Tags = $tags
        FileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        FilePath = $FilePath
    }
}

# Function to score how well a file matches a MOC topic
function Get-MOCMatchScore {
    param(
        [hashtable]$FileMetadata,
        [string]$MOCTopic
    )

    # Get the keyword set for this MOC using normalization
    $normalizedTopic = Get-NormalizedMOCTopic -Topic $MOCTopic

    if (-not $mocKeywords.ContainsKey($normalizedTopic)) {
        return @{ Score = 0; MatchedItems = @(); Reason = "No keywords defined for MOC" }
    }

    $keywords = $mocKeywords[$normalizedTopic]
    $content = $FileMetadata.Content
    $tags = $FileMetadata.Tags

    $score = 0
    $matchedItems = [System.Collections.ArrayList]@()

    # Check for exclude keywords first
    if ($keywords.ExcludeKeywords) {
        foreach ($excludeKw in $keywords.ExcludeKeywords) {
            if ($content -match [regex]::Escape($excludeKw.ToLower())) {
                return @{ Score = -100; MatchedItems = @("EXCLUDED: $excludeKw"); Reason = "Contains exclude keyword: $excludeKw" }
            }
        }
    }

    # Score tag matches (higher weight - 10 points each)
    foreach ($expectedTag in $keywords.Tags) {
        foreach ($fileTag in $tags) {
            if ($fileTag -eq $expectedTag.ToLower() -or $fileTag -match [regex]::Escape($expectedTag.ToLower())) {
                $score += 10
                [void]$matchedItems.Add("tag:$fileTag")
            }
        }
    }

    # Score keyword matches in content (2 points each, max 10 unique keywords)
    $keywordMatchCount = 0
    foreach ($kw in $keywords.Keywords) {
        if ($keywordMatchCount -ge 10) { break }  # Cap keyword matches

        $kwLower = $kw.ToLower()
        if ($content -match "\b$([regex]::Escape($kwLower))\b") {
            $score += 2
            [void]$matchedItems.Add("kw:$kw")
            $keywordMatchCount++
        }
    }

    $reason = if ($matchedItems.Count -gt 0) {
        "Matched: " + (($matchedItems | Select-Object -First 5) -join ", ")
    } else {
        "No keyword matches"
    }

    return @{
        Score = $score
        MatchedItems = $matchedItems
        Reason = $reason
    }
}

# Function to find the best MOC match for a file
function Find-BestMOCMatch {
    param([hashtable]$FileMetadata)

    $results = [System.Collections.ArrayList]@()

    foreach ($mocTopic in $mocKeywords.Keys) {
        $matchResult = Get-MOCMatchScore -FileMetadata $FileMetadata -MOCTopic $mocTopic
        [void]$results.Add(@{
            MOCTopic = $mocTopic
            Score = $matchResult.Score
            MatchedItems = $matchResult.MatchedItems
            Reason = $matchResult.Reason
        })
    }

    # Sort by score descending
    $results = $results | Sort-Object { $_.Score } -Descending

    return $results
}

# ============================================================
# MAIN ANALYSIS LOGIC
# ============================================================

# Clear previous report
if (Test-Path $ReportPath) {
    Remove-Item $ReportPath -Force
}

Write-Log "============================================================" "INFO"
Write-Log "  MOC LINK ANALYZER - Finding Misplaced Links" "INFO"
Write-Log "============================================================" "INFO"
Write-Log "Vault: $vaultPath" "INFO"
Write-Log "Report: $ReportPath" "INFO"
Write-Log "" "INFO"

# Get all MOC files
$mocs = Get-MOCFiles
Write-Log "Found $($mocs.Count) MOC files to analyze" "INFO"
Write-Log "" "INFO"

# Track all misplaced links
$misplacedLinks = @()
$analyzedCount = 0
$skippedCount = 0

# Analyze each MOC
foreach ($moc in $mocs) {
    Write-Log "Analyzing: $($moc.Topic)" "INFO"

    # Get all links in this MOC
    $links = Get-MOCLinks -MOCFilePath $moc.FullPath
    Write-Log "  Found $($links.Count) links" "INFO"

    foreach ($link in $links) {
        # Resolve the link to an actual file
        $filePath = Resolve-WikiLink -LinkTarget $link.Target

        if (-not $filePath) {
            $skippedCount++
            continue  # Can't analyze non-existent files
        }

        # Get file metadata
        $metadata = Get-FileMetadata -FilePath $filePath
        if (-not $metadata) {
            $skippedCount++
            continue
        }

        $analyzedCount++

        # Score this file against all MOCs
        $allScores = Find-BestMOCMatch -FileMetadata $metadata

        # Get score for current MOC (normalize the topic name for comparison)
        $normalizedCurrentTopic = Get-NormalizedMOCTopic -Topic $moc.Topic
        $currentMOCScore = ($allScores | Where-Object { $_.MOCTopic -eq $normalizedCurrentTopic }).Score
        if ($null -eq $currentMOCScore) { $currentMOCScore = 0 }

        # Get the best match
        $bestMatch = $allScores | Select-Object -First 1

        # Check if this link is misplaced (best match is different and significantly better)
        $isMisplaced = $false

        if ($bestMatch.MOCTopic -ne $normalizedCurrentTopic) {
            # Consider misplaced if best match score is at least 5 points higher, or current score is 0
            if ($bestMatch.Score -ge ($currentMOCScore + 5) -or ($currentMOCScore -eq 0 -and $bestMatch.Score -gt 0)) {
                $isMisplaced = $true
            }
        }

        if ($isMisplaced) {
            $misplacedLinks += @{
                FileName = $metadata.FileName
                FilePath = $filePath
                CurrentMOC = $moc.Topic
                CurrentSection = $link.Section
                CurrentScore = $currentMOCScore
                BestMOC = $bestMatch.MOCTopic
                BestScore = $bestMatch.Score
                BestReason = $bestMatch.Reason
                LinkTarget = $link.Target
                AllScores = $allScores | Select-Object -First 3  # Top 3 matches
            }
        }
    }
}

Write-Log "" "INFO"
Write-Log "============================================================" "INFO"
Write-Log "  ANALYSIS COMPLETE" "INFO"
Write-Log "============================================================" "INFO"
Write-Log "Files analyzed: $analyzedCount" "INFO"
Write-Log "Files skipped (not found): $skippedCount" "INFO"
Write-Log "Potentially misplaced links: $($misplacedLinks.Count)" "WARNING"
Write-Log "" "INFO"

# Apply limit if specified
if ($Limit -gt 0 -and $misplacedLinks.Count -gt $Limit) {
    Write-Log "Limiting output to first $Limit misplaced links" "INFO"
    $misplacedLinks = $misplacedLinks | Select-Object -First $Limit
}

# Output misplaced links report
if ($misplacedLinks.Count -gt 0) {
    Write-Log "============================================================" "INFO"
    Write-Log "  MISPLACED LINKS REPORT" "INFO"
    Write-Log "============================================================" "INFO"
    Write-Log "" "INFO"

    $i = 1
    foreach ($ml in $misplacedLinks) {
        Write-Log "--- Misplaced Link #$i ---" "WARNING"
        Write-Log "  File: $($ml.FileName)" "INFO"
        Write-Log "  Currently in: MOC - $($ml.CurrentMOC) / $($ml.CurrentSection)" "INFO"
        Write-Log "  Current MOC score: $($ml.CurrentScore)" "INFO"
        Write-Log "  SUGGESTED: MOC - $($ml.BestMOC) (score: $($ml.BestScore))" "SUCCESS"
        Write-Log "  Reason: $($ml.BestReason)" "INFO"
        Write-Log "" "INFO"
        $i++
    }
}

# Export JSON if requested
if ($ExportJson) {
    $jsonPath = $ReportPath -replace '\.txt$', '.json'
    $misplacedLinks | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log "JSON export saved to: $jsonPath" "INFO"
}

# Interactive fix mode
if ($Fix -and $misplacedLinks.Count -gt 0) {
    Write-Log "" "INFO"
    Write-Log "============================================================" "INFO"
    Write-Log "  INTERACTIVE FIX MODE" "INFO"
    Write-Log "============================================================" "INFO"

    foreach ($ml in $misplacedLinks) {
        Write-Host ""
        Write-Host "File: $($ml.FileName)" -ForegroundColor Cyan
        Write-Host "  Current: MOC - $($ml.CurrentMOC) / $($ml.CurrentSection) (score: $($ml.CurrentScore))" -ForegroundColor Yellow
        Write-Host "  Suggested: MOC - $($ml.BestMOC) (score: $($ml.BestScore))" -ForegroundColor Green
        Write-Host "  Reason: $($ml.BestReason)" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Action? [m]ove to suggested MOC, [s]kip, [q]uit"

        switch ($choice.ToLower()) {
            'm' {
                # This would need integration with the link editing logic
                Write-Host "  -> Moving link... (manual edit required)" -ForegroundColor Yellow
                Write-Host "  Remove from: MOC - $($ml.CurrentMOC)" -ForegroundColor Yellow
                Write-Host "  Add to: MOC - $($ml.BestMOC)" -ForegroundColor Green
            }
            'q' {
                Write-Host "Exiting fix mode." -ForegroundColor Gray
                break
            }
            default {
                Write-Host "  Skipped." -ForegroundColor Gray
            }
        }
    }
}

Write-Log "" "INFO"
Write-Log "Analysis complete. Report saved to: $ReportPath" "SUCCESS"

# Return summary object for programmatic use
return @{
    AnalyzedCount = $analyzedCount
    SkippedCount = $skippedCount
    MisplacedCount = $misplacedLinks.Count
    MisplacedLinks = $misplacedLinks
    ReportPath = $ReportPath
}
