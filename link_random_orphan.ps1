<#
.SYNOPSIS
    Obsidian Random Orphan MOC Linker - AI-Enhanced Subsection-Based Keywords Version

.DESCRIPTION
    This script finds a random orphan file in the Obsidian vault
    and creates UNIDIRECTIONAL links FROM MOC subsections TO the orphan file based
    on content and tag analysis using STATIC curated keyword matching at the
    SUBSECTION level, with optional AI-powered suitability verification.

    This version (v5.0) adds AI suitability checking via Claude API:
    1. Automatically discovers ALL MOC files in the vault
    2. Extracts subsections (identified by "## " heading prefix) from each MOC
    3. Looks up keywords from the static $subsectionKeywords hashtable
       organized by: MOC Name -> Subsection Name -> Keywords Array
    4. Matches orphan files against curated keywords for each MOC subsection
    5. Uses BOTH content analysis AND tag extraction for categorization
    6. **NEW** Uses Claude AI to verify match suitability (unless -SkipAI is set)
    7. **NEW** Automatically relocates notes to correct subsections when AI detects mismatch
    8. Creates UNIDIRECTIONAL links (MOC subsection -> orphan only)

    An "orphan" is defined as a file with no incoming links from any other file
    in the vault.

    **AI SUITABILITY CHECK**:
    When enabled (default), the script uses Claude API to analyze whether keyword
    matches are contextually appropriate. If a note doesn't truly belong in the
    matched subsection, Claude suggests the correct location and the link is
    created there instead. Requires ANTHROPIC_API_KEY environment variable.

    **CRITICAL SAFETY CONSTRAINT**:
    This script ONLY links to EXISTING MOC files. It will NEVER create new MOC files.
    Multiple validation layers ensure this constraint:
    - MOCs are discovered by scanning existing files matching "MOC - *.md"
    - Before any linking, each matched MOC is validated to exist on disk
    - A final safety check occurs immediately before any file write operation

    If you need to create a new MOC, do so manually first, then run this script.

.PARAMETER DryRun
    When specified, the script will analyze and report without making any changes
    to files. Useful for previewing what would be done.

.PARAMETER LogPath
    Path to the persistent log file. Defaults to C:\Users\awt\random_orphan_linker.log

.PARAMETER Count
    Number of orphan files to process in this run. Each processed orphan is
    removed from the in-memory list before processing the next. Orphans are
    selected randomly. Defaults to 1.

.PARAMETER SkipAI
    When specified, disables the AI-based suitability checking and uses only
    keyword matching. Useful when the API is unavailable, for faster processing,
    or for testing keyword matching without AI validation.

.EXAMPLE
    .\link_random_orphan.ps1
    Runs the script with AI verification enabled (requires ANTHROPIC_API_KEY).

.EXAMPLE
    .\link_random_orphan.ps1 -DryRun
    Runs in preview mode without making changes.

.EXAMPLE
    .\link_random_orphan.ps1 -Count 5
    Processes 5 randomly selected orphan files with AI verification.

.EXAMPLE
    .\link_random_orphan.ps1 -Count 10 -SkipAI
    Processes 10 orphan files using only keyword matching (no AI verification).

.EXAMPLE
    .\link_random_orphan.ps1 -Count 10 -DryRun
    Preview what would happen when processing 10 randomly selected orphan files.

.NOTES
    Author: Claude Code Assistant
    Version: 5.0 - AI-Enhanced Suitability Checking with Automatic Relocation
    Requires: PowerShell 5.1+
    Optional: ANTHROPIC_API_KEY environment variable for AI features

    This script appends to a persistent log file for tracking all linking operations
    across multiple runs.

    IMPORTANT: This script will NEVER create new MOC files. It only modifies
    existing files to add links between orphan files and existing MOCs.
#>

param(
    # $DryRun: Switch to enable dry-run mode - when set, no files will be modified
    # but all analysis will be performed and logged
    [switch]$DryRun = $false,

    # $LogPath: Path to the persistent log file where all operations are recorded
    # This log is appended to (not overwritten) on each run
    [string]$LogPath = 'C:\Users\awt\random_orphan_linker.log',

    # $Count: Number of orphan files to process in this run
    # Each processed orphan is removed from the in-memory list before processing the next
    # Default is 1 for backwards compatibility
    [int]$Count = 1,

    # $SkipAI: Switch to disable AI-based suitability checking
    # Default is $true (AI disabled) for faster processing without API dependency
    # Use -SkipAI:$false to enable AI validation (requires ANTHROPIC_API_KEY)
    [switch]$SkipAI = $true
)

#region Configuration Variables

# $vaultPath: The root directory of the Obsidian vault
# All file operations are relative to this path
$vaultPath = 'D:\Obsidian\Main'

# $mocFolder: The folder containing all MOC (Map of Content) files
# MOCs are organizational documents that link related notes together
$mocFolder = '00 - Home Dashboard'

# $mocPattern: Filename pattern used to identify MOC files
# Files matching this pattern will be discovered and used for categorization
$mocPattern = 'MOC - *.md'

# $skipFolders: Array of folder names to exclude from orphan detection
# These folders contain files that don't need linking (journals, templates, images, etc.)
$skipFolders = @(
    '0 - Journal',       # Daily journal entries - self-contained
    '05 - Templates',    # Template files - not meant to be linked
    '00 - Images',       # Image attachments - linked via embeds
    'attachments',       # Alternative attachment folder
    '.trash',            # Obsidian's trash folder
    '.obsidian',         # Obsidian configuration folder
    '.smart-env'         # Smart environment plugin folder
)

# $subsectionKeywords: Nested hashtable mapping MOC names to subsections to keyword arrays
# Structure: MOC Name (string) -> Subsection Name (string) -> Keywords (array)
# This is the PRIMARY source of keywords for matching at the subsection level
# Each MOC contains multiple subsections, each with its own curated keyword list
$subsectionKeywords = @{

    #===========================================================================
    # MOC: Bahá'í Faith
    # Subsection-based keywords for Bahá'í Faith topics
    #===========================================================================
    "Bahá'í Faith" = @{
        "Central Figures" = @(
            "Bahá'u'lláh", "Bahaullah", "Baha'u'llah", "Baháulláh",
            "'Abdu'l-Bahá", "Abdul-Baha", "Abdu'l-Baha", "Abdu'l-Bahá",
            "The Báb", " Bab ", "the Báb", "central figure", "prophet", "manifestation",
            "founder", "master", "exemplar", "covenant", "Mírzá Ḥusayn-'Alí",
            "Siyyid 'Alí-Muḥammad", "Abbas Effendi", "Blessed Beauty",
            "Ancient Beauty", "Blessed Perfection",
            "Mírzá Husayn-Alí Núrí",
            "Siyyid Alí-Muhammad",
            "Mírzá Mihdí",
            "Navváb",
            "Bahíyyih Khánum",
            "Greatest Holy Leaf",
            "Purest Branch",
            "Herald",
            "Promised One",
            "Revelation",
            "Apostle of Bahá'u'lláh",
            "Letters of the Living",
            "Declaration of the Báb")
        "Core Teachings" = @(
            # NOTE: Removed standalone "spiritual" and "divine" (too generic)
            "Bahá'í", "Bahai", "Baha'i", "prayer", "tablet", "Kitáb", "Hidden Words", "Seven Valleys",
            "Gleanings", "Bahá'í teachings", "Bahá'í principles", "spiritual development", "divine teachings",
            "oneness of humanity", "unity of mankind", "progressive revelation",
            "independent investigation", "science & religion",
            "elimination of prejudice", "equality", "universal peace",
            "compulsory education", "auxiliary language", "constructive resilience",
            "bicentenary", "centenary", "Dawn-Breakers", "Nabil's Narrative",
            "unity of mankind",
            "unity of God",
            "unity of religion",
            "Manifestation of God",
            "Most Great Peace",
            "Lesser Peace",
            "World Order",
            "New World Order",
            "elimination of extremes of wealth and poverty",
            "universal auxiliary language",
            "harmony of science and religion",
            "independent investigation of truth",
            "elimination of all forms of prejudice",
            "universal compulsory education", "Badí")
        "Administrative Guidance" = @(
            "LSA", "local spiritual assembly", "NSA", "national spiritual assembly",
            "Bahá'í guidance", "administrative", "consultation", "Spiritual Assembly", "UHJ", "universal house of justice",
            "Bahá'í election", "convention", "Bahá'í delegate", "membership", "Bahá'í cluster",
            "jurisdiction", "Bahá'í region", "Feast", "Nineteen Day Feast",
            "delegates", "electoral process", "no nominations", "no campaigning",
            "spiritual assembly jurisdiction", "cluster agency", "Area Teaching Committee",
            "regional Bahá'í council", "annual convention", "unit convention", "electoral unit",
            "electoral district")
        "Bahá'í Institutions" = @(
            "Universal House of Justice", "UHJ", "World Centre", "Haifa",
            "institution", "administrative order", "continental counsellors",
            "auxiliary board", "regional council", "training institute",
            "Ruhi", "study circle", "devotional gathering",
            "International Teaching Centre",
            "Continental Board of Counsellors",
            "Auxiliary Board member",
            "assistant to Auxiliary Board",
            "Bahá'í International Community",
            "Office of External Affairs",
            "Bahá'í World Centre",
            "Arc buildings",
            "Seat of the Universal House of Justice",
            "Institution of the Learned",
            "Institution of the Rulers",
            "twin pillars")
        "Nine Year Plan" = @(
            "Nine Year Plan", "plan", "goals", "expansion", "consolidation",
            "community building", "intensive program of growth", "IPG",
            "cycle of activities", "core activities", "cluster development",
            "society-building power",
            "protagonists of change",
            "Milestone 3 cluster",
            "intensive programme of growth",
            "movement of populations",
            "educational process",
            "community-building process",
            "release of society-building power",
            "protagonists",
            "home-front pioneer",
            "international pioneer",
            "25-year series of plans")
        "Ridván Messages" = @(
            "Ridván", "Ridvan", "message", "letter", "annual",
            "festival", "declaration", "supreme body",
            "King of Festivals",
            "Most Great Festival",
            "Garden of Ridván",
            "Najíbíyyih Garden",
            "first day of Ridván",
            "ninth day of Ridván",
            "twelfth day of Ridván",
            "annual Ridván message",
            "Declaration of Bahá'u'lláh",
            "April 21",
            "twelve-day period")
        "Community & Service" = @(
            "Bahá'í community", "Bahá'í service", "Bahá'í feast", "Nineteen Day Feast", "holy day",
            "commemoration", "teaching", "pioneering", "travel teaching",
            "fireside", "children's class", "junior youth",
            "devotional", "social action",
            "tutor",
            "animator",
            "facilitator",
            "core activity",
            "neighbourhood",
            "home visit",
            "expansion phase",
            "consolidation phase",
            "reflection meeting",
            "cluster coordinator",
            "institute coordinator",
            "accompaniment",
            "capacity building")
        "Social Issues & Unity" = @(
            "unity",
            "social issues",
            "race amity", "race unity",
            "elimination of prejudice",
            "unity in diversity",
            "oneness of humanity",
            "organic unity",
            "world citizenship",
            "global civilization",
            "collective security",
            "world tribunal",
            "world parliament",
            "world executive",
            "federalism")
        "Bahá'í Books & Resources" = @(
            # NOTE: Removed generic "resource"
            "Bahá'í writings", "Bahá'í publication", "Bahá'í scripture",
            "Bahá'í deepening", "Bahá'í compilation", "Bahá'í book",
            "Tablets of Bahá'u'lláh",
            "Kitáb-i-Íqán",
            "Book of Certitude",
            "Epistle to the Son of the Wolf",
            "Proclamation of Bahá'u'lláh",
            "Summons of the Lord of Hosts",
            "Gems of Divine Mysteries",
            "Call of the Divine Beloved",
            "Tabernacle of Unity",
            "Days of Remembrance"
            "Kitáb-i-Aqdas (The Most Holy Book)", "Kitáb-i-Íqán (The Book of Certitude)", 
            "The Hidden Words", "Gleanings from the Writings of Bahá'u'lláh", 
            "Epistle to the Son of the Wolf", "Tablets of Bahá'u'lláh", 
            "Summons of the Lord of Hosts", "Days of Remembrance", 
            "Call of the Divine Beloved", "Gems of Divine Mysteries", 
            "The Seven Valleys", "The Four Valleys", "Tabernacle of Unity", 
            "Prayers and Meditations", "Proclamation of Bahá'u'lláh", 
            "Selections from the Writings of Bahá'u'lláh", 
            "Selections from the Writings of the Báb", 
            "The Persian Bayán (selections)", 
            "The Arabic Bayán (selections)", "Prayers from the Báb", 
            "Some Answered Questions", "Paris Talks", 
            "The Promulgation of Universal Peace", "Tablets of the Divine Plan", 
            "Selections from the Writings of ‘Abdu’l‑Bahá", 
            "The Secret of Divine Civilization", "Memorials of the Faithful", 
            "‘Abdu’l‑Bahá in London", "A Traveller’s Narrative", 
            "Prayers and Tablets of ‘Abdu’l‑Bahá", "God Passes By", 
            "The World Order of Bahá'u'lláh", "The Advent of Divine Justice", 
            "The Promised Day Is Come", "Citadel of Faith", 
            "Messages to the Bahá'í World", 
            "Letters from the Guardian to Australia and New Zealand", 
            "Messages from the Universal House of Justice",
            "Turning Point: Selected Messages of the Universal House of Justice", 
            "Century of Light", "The Promise of World Peace", 
            "The Dawn‑Breakers: Nabíl’s Narrative of the Early Days of the Bahá'í Revelation", 
            "Bahá'u'lláh and the New Era", "The Bahá'í Faith: An Introduction", 
            "The Bahá'í Faith: The Emerging Global Religion", "Release the Sun", 
            "Christ and Bahá'u'lláh", "Bahá'u'lláh: The King of Glory", 
            "'Abdu'l‑Bahá: The Centre of the Covenant", 
            "Bahá'u'lláh: The Supreme Manifestation of God", "Robe of Light", 
            "Bahá'í Prayers", "Bahá'í Prayers (US edition)", "Bahá'í Prayers for Children", 
            "Shining Stars: Bahá'í Prayers and Passages for Children", "Bahá'í Scriptures", 
            "The Splendour of God", "The Bahá'í Faith: An Introduction (Gloria Faizi)", "Immortal Youth", "The Knights of Bahá'u'lláh")
        "Clippings & Resources" = @(
            # NOTE: Removed generic "news"
            "Bahá'í persecution", "Iran persecution", "human rights Iran",
            "Bahá'í news", "Bahá'í article",
            "Bahá'í World News Service",
            "BWNS",
            "Bahá'í International Community",
            "BIC statement",
            "One Country newsletter",
            "Bahá'í World magazine",
            "persecution in Iran",
            "Yaran",
            "imprisoned Bahá'ís",
            "human rights violations"
            )
        "Related Topics" = @(
            "interfaith", "world religions","pagan", "yule",
            "Parliament of the World's Religions",
            "interfaith dialogue",
            "United Religions Initiative",
            "comparative religion",
            "world peace conference",
            "disarmament",
            "collective security",
            "global governance",
            "sustainable development",
            "climate change ethics", "Georgetown Ministerial Alliance")
    }

    #===========================================================================
    # MOC: Finance & Investment
    # Subsection-based keywords for finance & investment topics
    #===========================================================================
    "Finance & Investment" = @{
        "Investing Strategies" = @(
            # NOTE: Removed generic words like "bond" (matches James Bond, chemical bond,
            "price-to-earnings ratio",
            "P/E ratio",
            "market capitalization",
            "blue chip stocks",
            "small cap",
            "mid cap",
            "large cap",
            "sector rotation",
            "momentum investing",
            "contrarian investing",
            "FIRE movement",
            "financial independence",
            "total return",
            "risk tolerance",
            "asset class",
            "equity",
            "fixed income", "dividend",
            "alternative investments",
            # Using more specific financial terms to avoid false positives
            "investing", "investment strategy", "dividend investing", "value investing",
            "growth investing", "index fund", "ETF", "mutual fund", "stock market",
            "stock portfolio", "treasury bond", "municipal bond", "bond fund",
            "asset allocation", "diversification", "dollar-cost averaging",
            "rebalancing", "Warren Buffett", "Benjamin Graham", "fundamental analysis",
            "technical analysis", "dividend yield", "capital gains", "compound interest",
            "passive investing", "401k", "Roth IRA", "brokerage"
        )
        "Resources & Books" = @(
            # NOTE: Removed generic "book" and "resource" - too common
            "Intelligent Investor",
            "Security Analysis", "financial education", "investing books",
            "Rich Dad Poor Dad", "Bogleheads",
            "A Random Walk Down Wall Street",
            "The Little Book of Common Sense Investing",
            "One Up on Wall Street",
            "Peter Lynch",
            "John Bogle",
            "Jack Bogle",
            "The Psychology of Money",
            "Morgan Housel",
            "The Millionaire Next Door",
            "Your Money or Your Life",
            "I Will Teach You to Be Rich",
            "Ramit Sethi")
        "Financial Management" = @(
            "financial", "management", "budget", "budgeting", "expense",
            "income", "cash flow", "net worth", "savings", "emergency fund",
            "debt", "credit", "loan", "mortgage", "financial planning",
            "Little Green Light", "Zeffy", "nonprofit", "giving", "donation",
            "50/30/20 rule",
            "zero-based budgeting",
            "envelope system",
            "sinking fund",
            "high-yield savings account",
            "money market account",
            "certificate of deposit",
            "CD ladder",
            "debt avalanche",
            "debt snowball",
            "FICO score",
            "credit utilization",
            "liquid assets",
            "net worth statement",
            "personal balance sheet")
        "Tax Software" = @(
            # NOTE: "tax" alone is specific enough in context
            "tax return", "TurboTax", "HandR Block", "tax filing", "tax deduction",
            "tax credit", "tax refund", "IRS", "W-2", "1099", "Schedule C",
            "federal tax", "state tax", "tax preparation", "tax software",
            "income tax", "property tax",
            "Form 1040",
            "Schedule A",
            "itemized deduction",
            "standard deduction",
            "adjusted gross income",
            "AGI",
            "MAGI",
            "earned income tax credit",
            "EITC",
            "child tax credit",
            "FreeTaxUSA",
            "IRS Free File",
            "IRS Direct File",
            "quarterly estimated tax",
            "Form 1099",
            "tax bracket",
            "marginal tax rate")
        "Insurance" = @(
            "insurance", "USAA", "claim", "policy", "premium", "deductible",
            "coverage", "auto insurance", "home insurance", "life insurance",
            "health insurance", "liability",
            "bodily injury liability",
            "property damage liability",
            "comprehensive coverage",
            "collision coverage",
            "uninsured motorist",
            "underinsured motorist",
            "PIP",
            "personal injury protection",
            "umbrella policy",
            "declarations page",
            "actual cash value",
            "replacement cost",
            "bundling discount",
            "claims history")
    }

    #===========================================================================
    # MOC: Health & Nutrition
    # Subsection-based keywords for health & nutrition topics
    #===========================================================================
    "Health & Nutrition" = @{
        "Plant-Based Nutrition" = @(
            "vegan", "plant-based", "vegetarian", "whole food",
            "plant-forward", "meatless", "dairy-free", "animal-free",
            "plant protein", "legumes", "beans", "lentils", "tofu", "tempeh",
            "minimally processed",
            "no added oil",
            "nutrient density",
            "caloric density",
            "fiber intake",
            "phytonutrients",
            "antioxidants",
            "plant protein sources",
            "complete protein",
            "amino acids",
            "B12 supplementation",
            "vitamin D",
            "omega-3 fatty acids",
            "flaxseed")
        "Key Research & Books" = @(
            "China Study", "Campbell", "Esselstyn", "Ornish", "McDougall",
            "Barnard", "Greger", "Fuhrman", "nutrition research", "dietary evidence",
            "nutrition science", "heart disease reversal",
            "Prevent and Reverse", "Whole Foods Plant Based", "How Not to Die",
            "T. Colin Campbell",
            "Caldwell Esselstyn",
            "Dean Ornish",
            "Joel Fuhrman",
            "Michael Greger",
            "NutritionFacts.org",
            "lifestyle medicine",
            "Blue Zones",
            "Dan Buettner",
            "longevity diet",
            "Adventist Health Study",
            "EPIC-Oxford study",
            "Nurses Health Study")
        "Medical & Health" = @(
            "medical", "doctor", "physician", "hospital", "surgery", "treatment",
            "diagnosis", "symptom", "condition", "disease", "illness", "patient",
            # NOTE: Removed "test" (too generic - matches unit test, test drive, etc.)
            "healthcare", "checkup", "medical test", "procedure", "allergy", "implant",
            "ACDF", "spine", "knee", "hip", "coronavirus", "COVID",
            "primary care physician", "lung disease", "kidney disease", "heart disease",
            "risk factor", "impaired","longitudinal studies",
            "specialist referral",
            "preventive care",
            "screening",
            "diagnostic imaging",
            "preterm", "birth", 
            "MRI",
            "CT scan",
            "blood panel",
            "lipid panel",
            "hemoglobin A1C",
            "blood pressure",
            "BMI", "HGA1C",
            "body mass index",
            "chronic disease management",
            "acute care",
            "outpatient",
            "inpatient",
            # Sleep and rest related (from Inemuri article)
            "inemuri",
            "power nap",
            "micro-nap",
            "sleep deprivation",
            "sleep habits",
            "napping",
            "co-sleeping",
            "karoshi",
            "death by overwork",
            # Respiratory and illness related (from CORONA Common Sense)
            "respiratory therapist",
            "ventilator",
            "fever",
            "pneumonia",
            "electrolytes",
            "dehydration",
            "rehydrate",
            "wheezing",
            "congestion",
            "phlegm",
            "bronchial",
            "oxygen level",
            "pursed lip breathing")
        "Exercise & Wellness" = @(
            "exercise", "workout", "fitness", "walking", "stretching", "yoga",
            "movement", "physical activity", "cardio", "strength", "flexibility",
            "wellness", "wellbeing", "health benefits",
            "aerobic exercise",
            "anaerobic exercise",
            "resistance training",
            "HIIT",
            "functional fitness",
            "flexibility training",
            "mobility work",
            "range of motion",
            "resting heart rate",
            "target heart rate zone",
            "VO2 max",
            "metabolic equivalent",
            "active recovery",
            "overtraining",
            "progressive overload",
            "periodization")
        "Health Articles & Clippings" = @(
            "health news",
            "pandemic", "mental health", "healthcare policy",
            "clinical trial results",
            "peer-reviewed",
            "meta-analysis",
            "systematic review",
            "epidemiological study",
            "cohort study",
            "randomized controlled trial",
            "RCT",
            "public health guidelines",
            "CDC recommendations",
            "WHO guidelines",
            "health policy",
            "medical breakthrough",
            "drug approval")
        "WFPB Resources" = @(
            "WFPB", "whole food plant-based", "plant-based diet", "oil-free",
            "SOS-free", "salt-free", "sugar-free", "starch solution",
            "Engine 2", "Forks Over Knives",
            "PlantPure Nation",
            "What the Health",
            "Game Changers",
            "Dr. McDougall's Health and Medical Center",
            "TrueNorth Health Center",
            "Physicians Committee for Responsible Medicine",
            "PCRM",
            "21-Day Kickstart",
            "starch-based diet",
            "low-fat vegan",
            "high-carb low-fat",
            "HCLF")
        "Clippings & Resources" = @(
            "vegan restaurant", "plant-based restaurant", "healthy eating"
        )
        "Resources & Indexes" = @(
            "food database", "recipe index",
            "nutrition database",
            "USDA FoodData Central",
            "Cronometer",
            "MyFitnessPal",
            "calorie tracking",
            "macro tracking",
            "micronutrient analysis",
            "glycemic index",
            "glycemic load",
            "anti-inflammatory foods")
    }

    #===========================================================================
    # MOC: Home & Practical Life
    # Subsection-based keywords for home & practical life topics
    #===========================================================================
    "Home & Practical Life" = @{
        "Genealogy" = @(
            "genealogy", "DNA", "ancestry", "family tree",
            "autosomal", "heritage", "ancestor", "descendant", "lineage",
            "family history", "Talbot", "surname", "relatives",
            "autosomal DNA",
            "Y-DNA",
            "mtDNA",
            "mitochondrial DNA",
            "haplogroup",
            "centiMorgan",
            "genetic distance",
            "DNA match",
            "shared DNA",
            "chromosome browser",
            "endogamy",
            "pedigree collapse",
            "genetic genealogy",
            "FamilySearch",
            "Find A Grave",
            "Ancestry.com",
            "23andMe",
            "MyHeritage",
            "GEDCOM")
        "Home Projects & Repairs" = @(
            "home project", "repair", "DIY", "maintenance", "fix", "install",
            "remodel", "renovation", "drywall", "flooring", "garage",
            "home improvement", "contractor", "handyman",
            "load-bearing wall",
            "stud finder",
            "drywall repair",
            "spackle",
            "joint compound",
            "primer",
            "caulking",
            "weatherstripping",
            "HVAC filter",
            "circuit breaker",
            "GFCI outlet",
            "PEX plumbing",
            "shut-off valve",
            "water heater maintenance",
            "grout cleaning",
            "tile replacement",
            "wood filler",
            "wood putty")
        "Sustainable Building & Alternative Homes" = @(
            "earthbag", "earthship", "tiny house", "alternative building",
            "sustainable", "SIP", "cordwood", "insulation", "rocket stove",
            "off-grid", "eco-friendly", "natural building", "cob", "straw bale",
            "green building", "passive house", "Habitat for Humanity",
            "thermal mass",
            "passive solar design",
            "photovoltaic panels",
            "solar thermal",
            "greywater recycling",
            "rainwater harvesting",
            "composting toilet",
            "natural insulation",
            "hemp-lime",
            "hempcrete",
            "adobe construction",
            "rammed earth",
            "living roof",
            "green roof",
            "net-zero energy")
        "Gardening & Urban Farming" = @(
            "garden", "gardening", "urban farm", "seeds", "heirloom",
            "container gardening", "food forest", "fruit tree", "permaculture",
            "organic", "composting", "raised bed", "vegetable garden",
            "companion planting",
            "crop rotation",
            "succession planting",
            "no-till gardening",
            "hugelkultur",
            "lasagna gardening",
            "sheet mulching",
            "cover crops",
            "seed starting",
            "hardening off",
            "transplanting",
            "USDA hardiness zone",
            "microgreens",
            "vertical gardening",
            "hydroponics",
            "aquaponics")
        "RV & Mobile Living" = @(
            "camper", "mobile living", "full-time RV",
            "RVing", "campground", "boondocking", "travel trailer",
            "Instant Pot", "mobile internet",
            "full-time RVing",
            "workamping",
            "dry camping",
            "shore power",
            "dump station",
            "black water",
            "grey water",
            "fresh water tank",
            "slide-out",
            "fifth wheel",
            "Class A",
            "Class B",
            "Class C",
            "toy hauler",
            "tow vehicle",
            "weight distribution hitch")
        "Entertainment & Film" = @(
            # NOTE: Removed "TV" and "show" - too short/generic
            "movie", "film", "television", "TV show", "TV series",
            "cinema", "watch list", "Rohan", "Lord of the Rings",
            "Netflix", "documentary",
            "streaming service",
            "watchlist",
            "film genre",
            "documentary film",
            "limited series",
            "miniseries",
            "anthology series",
            "binge-watching",
            "film score",
            "cinematography",
            "screenplay",
            "director's cut",
            "Criterion Collection",
            "arthouse cinema",
            "foreign film",
            "subtitle")
        "Life Productivity & Organization" = @(
            "organization", "Kaizen", "retirement", "planning",
            "Evernote", "virtual desktop",
            "efficiency", "time management", "habits",
            "time blocking",
            "Pomodoro Technique",
            "batch processing",
            "shallow work",
            "energy management",
            "decision fatigue",
            "context switching",
            "morning routine",
            "evening routine",
            "habit stacking",
            "atomic habits",
            "friction reduction",
            "activation energy",
            "keystone habit")
        "Practical Tips & Life Hacks" = @(
            # NOTE: Removed generic words like "tip", "hack", "guide", "practical", "useful", "safe"
            "life hack", "how-to guide", "practical tip", "eyeglasses", "glasses frames",
            "key finder", "grocery stickers", "PLU codes", "death planning",
            "funeral planning", "estate planning", "life tips",
            "life optimization",
            "problem-solving",
            "troubleshooting guide",
            "maintenance schedule",
            "home inventory",
            "important documents organization",
            "password manager",
            "digital declutter",
            "email management",
            "meal prep",
            "emergency preparedness",
            "go bag")
        "Sketchplanations" = @(
            "Sketchplanations", "sketch", "explanation", "visual", "diagram",
            "infographic", "concept", "illustrated",
            "visual thinking",
            "concept illustration",
            "explanatory diagram",
            "visual learning",
            "graphic explanation",
            "mental model",
            "visual metaphor",
            "knowledge visualization",
            "information design",
            "educational graphics")
        # Friends of the Georgetown Public Library subsections
        "FOL Board Members & Contacts" = @(
            "FOL board", "FOL member", "FOL volunteer",
            "Friends of the Georgetown Public Library",
            "Friends of Library", "library board", "library volunteer",
            "Georgetown Public Library", "BOD", "board of directors")
        "Hill Country Authors Series (HCAS)" = @(
            "HCAS", "Hill Country Authors Series", "Hill Country Authors",
            "author event", "author series", "book signing", "author talk",
            "literary event", "author reading")
        "FOL Operations & Procedures" = @(
            "FOL", "Friends of the Georgetown Public Library",
            "Friends of Library", "FOL meeting", "FOL board meeting",
            "library support", "library advocacy", "library fundraising",
            "FOL organizational", "FOL postage", "FOL tribute",
            "library communications", "BOD")
        "Giving Season & Fundraising" = @(
            "Giving Season", "giving campaign", "annual giving",
            "FOL donation", "library donation", "library fundraising",
            "donor recognition", "membership drive", "fundraising campaign",
            "year-end giving", "charitable giving")
        "Little Green Light (FOL Database)" = @(
            "Little Green Light", "LGL", "donor database",
            "donor management", "constituent database", "fundraising software",
            "donor tracking", "gift tracking", "membership database",
            "Zeffy", "direct mail", "email opt out")
    }

    #===========================================================================
    # MOC: Music & Record
    # Subsection-based keywords for music & recorder topics
    #===========================================================================
    "Music & Records" = @{
        "Recorder Resources" = @(
            "recorder", "soprano recorder", "alto recorder", "tenor recorder",
            "bass recorder", "contrabass recorder", "baroque fingering",
            "tuning", "woodwind", "renaissance recorder", "modern recorder",
            "recorder comparison", "specifications",
            "fipple flute",
            "windway",
            "labium",
            "voicing",
            "block",
            "consort of recorders",
            "SATB ensemble",
            "Ganassi fingering",
            "historical fingering",
            "Mollenhauer",
            "Moeck",
            "Yamaha recorder",
            "Aulos",
            "Zen-On",
            "recorder method book",
            "recorder repertoire",
            "descant recorder")
        "Music Theory & Performance" = @(
            # NOTE: Removed "key" (too common,
            "diatonic scale",
            "chromatic scale",
            "major mode",
            "minor mode",
            "modal scales",
            "Ionian",
            "Dorian",
            "Phrygian",
            "Lydian",
            "Mixolydian",
            "Aeolian",
            "Locrian",
            "interval",
            "tritone",
            "perfect fifth",
            "diminished chord",
            "augmented chord",
            "cadence",
            "authentic cadence",
            "plagal cadence",
            "deceptive cadence",
            # NOTE: Removed "theory" (too generic), "scale" (could be weight scale)
            "music theory", "musical notation", "musical scale", "chord progression",
            "key signature", "rhythm", "tempo", "time signature", "harmony", "melody",
            "musical performance", "choral singing", "singing", "vocal music"
        )
        "Songs & Hymns" = @(
            # NOTE: Removed "song" alone - too generic
            "hymn", "anthem", "Lift Every Voice", "lyrics", "sheet music",
            "musical arrangement", "songbook", "worship song", "folk song",
            "sacred music",
            "congregational singing",
            "four-part harmony",
            "SATB",
            "hymnal",
            "hymnody",
            "gospel music",
            # NOTE: Removed standalone "spiritual" (too generic - keep "Negro spiritual")
            "Negro spiritual",
            "African American spiritual",
            "choral anthem",
            "a cappella",
            "madrigal",
            "part song",
            "round",
            "canon")
        "Record Labels & Resources" = @(
            "record label", "folk music", "37d03d", "indie", "recording",
            "album", "artist",
            "indie record label",
            "independent music",
            "music distribution",
            "vinyl pressing",
            "LP",
            "EP",
            "single",
            "album release",
            "music streaming",
            "Bandcamp",
            "SoundCloud",
            "music discovery")
        "Index" = @(
            # NOTE: Removed science terms that were incorrectly placed here
            # (taxonomy, scientific classification, species list, biodiversity index,
            # field guide, identification key, natural history collection)
            "music collection",
            "music catalog",
            "discography",
            "music library",
            "listening log",
            "music journal",
            "album notes",
            "liner notes",
            "track listing")
        "Clippings & Resources" = @(
            "square recorder", "shakuhachi"
        )
        "Music Performances & Articles" = @(
            "performance", "Bobby McFerrin", "improvisation",
            "guitar", "flamenco", "concert", "drumming",
            "live performance",
            "concert hall",
            "recital",
            "chamber music",
            "world music",
            "folk tradition",
            "ethnomusicology",
            "musical anthropology",
            "musical improvisation",
            "jazz improvisation",
            "call and response",
            "polyrhythm",
            "syncopation",
            "groove")
    }

    #===========================================================================
    # MOC: NLP & Psychology
    # Subsection-based keywords for NLP & psychology topics
    #===========================================================================
    "NLP & Psychology" = @{
        "Core NLP Concepts" = @(
            "NLP", "neuro-linguistic programming", "presupposition",
            "representational systems",
            "VAK",
            "visual",
            "auditory",
            "kinesthetic",
            "submodalities",
            "predicates",
            "sensory acuity",
            "state management",
            "map of reality",
            "territory",
            "presuppositions of NLP",
            "well-formedness conditions")
        "Techniques & Patterns" = @(
            # NOTE: Removed generic words like "pattern", "process"
            "NLP technique", "NLP pattern", "therapeutic intervention",
            "behavioral pattern", "communication pattern", "Slight of mouth",
            "swish pattern",
            "visual squash",
            "parts integration",
            "belief change pattern",
            "Disney strategy",
            "new behavior generator",
            "spelling strategy",
            "motivation strategy",
            "decision-making strategy",
            "future pacing")
        "Reframing" = @(
            "reframe", "reframing", "six step reframe", "sleight of mouth",
            "perspective", "meaning", "context reframe", "content reframe",
            "context reframing",
            "content reframing",
            "meaning reframing",
            "outframing",
            "preframing",
            "deframing",
            "counter-example",
            "chunk up",
            "chunk down",
            "lateral chunking",
            "hierarchy of ideas",
            "logical levels of change")
        "Phobia & Trauma Work" = @(
            "phobia", "phobia cure", "fast phobia cure", "trauma", "PTSD",
            "fear", "anxiety", "dissociation", "VK dissociation",
            "visual-kinesthetic dissociation",
            "double dissociation",
            "fast phobia model",
            "reimprinting",
            "timeline therapy",
            "core transformation",
            "eye movement integration",
            "EMDR-like techniques", "EMDR",
            "resource anchoring")
        "Change Work" = @(
            # NOTE: Removed "change" (too generic - matches climate change, code change, etc.)
            "NLP change work", "personal history", "timeline",
            "cellular change", "transformation", "breakthrough",
            "personal breakthrough",
            "limiting belief",
            "limiting decision",
            "significant emotional event",
            "SEE",
            "gestalt",
            "reimprint",
            "integration",
            "generative change",
            "remedial change",
            "unconscious mind")
        "Anchoring & States" = @(
            # NOTE: Removed "state" (too generic - matches state of matter, US state, etc.)
            "anchor", "anchoring", "emotional state", "circle of excellence",
            "resource state", "peak state", "rapport", "calibration",
            "resource anchor",
            "collapse anchors",
            "stacking anchors",
            "chaining anchors",
            "sliding anchor",
            "spatial anchor",
            "tonal anchor",
            "kinesthetic anchor",
            "positive state",
            "resourceful state",
            "break state",
            "neutral state")
        "Logical Levels" = @(
            "logical levels", "neurological levels", "Dilts", "identity",
            "beliefs", "values", "capabilities", "behavior", "environment",
            "alignment", "wired",
            "Robert Dilts",
            "alignment process",
            "congruence",
            "mission",
            "vision",
            "purpose",
            "spiritual level",
            "identity level",
            "beliefs and values level",
            "capabilities level",
            "behavior level",
            "environment level")
        "Language Patterns" = @(
            "language pattern", "embedded command", "metaphor",
            "hypnotic language", "Milton model", "Erickson", "trance",
            "conversational hypnosis",
            "Milton Model",
            "artfully vague",
            "nominalization",
            "unspecified verb",
            "modal operator",
            "universal quantifier",
            "lost performative",
            "tag question",
            "double bind",
            "embedded suggestion",
            "temporal predicate")
        "Strategies & Modeling" = @(
            # NOTE: Removed "strategy" and "test" (too generic)
            "NLP strategy", "modeling", "TOTE", "reading strategy", "spelling strategy",
            "motivation strategy", "decision strategy", "profiling",
            "elicitation",
            "strategy elicitation",
            "eye accessing cues",
            "eye patterns",
            "lead system",
            "reference system",
            "internal dialogue",
            "representational sequence",
            "decision point",
            "exit point")
        "Outcomes & Ecology" = @(
            # NOTE: Removed standalone "ecology" (too generic, keep NLP-specific "ecology check")
            "outcome", "well-formed outcome", "NLP ecology", "ecology check",
            "ROET", "SCORE", "goal setting", "specification",
            "SMART goals",
            "positive outcome",
            "sensory evidence",
            "self-initiated",
            "self-maintained",
            "resources identified",
            "first step",
            "secondary gain",
            "systemic thinking",
            "consequences")
        "Communication & Influence" = @(
            "communication", "influence", "persuasion", "belief",
            "eliciting", "transderivational search", "yes sayer", "no sayer",
            "pacing",
            "leading",
            "matching",
            "mirroring",
            "cross-over mirroring",
            "backtracking",
            "perceptual positions",
            "first position",
            "second position",
            "third position",
            "meta position",
            "associated",
            "dissociated")
        "Cognitive Science" = @(
            "cognitive", "Kahneman", "thinking fast and slow", "bias",
            "heuristic", "attention", "cocktail party effect", "blindness",
            "misdirection", "victim effect", "zero price",
            "System 1 and System 2",
            "cognitive bias",
            "confirmation bias",
            "anchoring bias",
            "availability heuristic",
            "representativeness heuristic",
            "loss aversion",
            "prospect theory",
            "framing effect",
            "sunk cost fallacy",
            "endowment effect")
        "Learning & Memory" = @(
            "learning theory", "memory technique", "Bloom's taxonomy", "retention",
            "memory recall",
            "encoding",
            "storage",
            "retrieval",
            "working memory",
            "long-term memory",
            "episodic memory",
            "semantic memory",
            "procedural memory",
            "spaced repetition",
            "interleaving",
            "elaboration",
            "dual coding",
            "chunking",
            "mnemonic")
        "Meta Model & Language" = @(
            "meta model", "metamodel", "distortion", "NLP deletion", "generalization",
            "meta model question", "language precision",
            "deletions",
            "distortions",
            "generalizations",
            "deep structure",
            "surface structure",
            "transformational grammar",
            "nominalization recovery",
            "referential index",
            "comparative deletion",
            "mind reading",
            "complex equivalence",
            "cause-effect")
        "NLP Technique Overview" = @(
            "NLP intervention",
            "surety", "NLP process",
            "intervention design",
            "presenting problem",
            "desired state",
            "leverage point",
            "pattern interrupt",
            "installation",
            "testing",
            "calibration")
        "NLP for Programmers & Technical Applications" = @(
            "programmer", "technical",
        ,
            "cognitive load",
            "debugging mindset",
            "problem decomposition",
            "state machine",
            "pattern matching",
            "refactoring thinking",
            "API for the mind",
            "mental debugging",
            "cognitive optimization")
        "Historical NLP Resources (CompuServe Era)" = @(
            "CompuServe", "historical", "FAQ", "1992", "archive",
            "directory", "training", "NLP World",
            "alt.psychology.nlp",
            "NLP newsgroup",
            "NLP mailing list",
            "early NLP community",
            "NLP pioneers",
            "Richard Bandler",
            "John Grinder",
            "Leslie Cameron-Bandler",
            "David Gordon",
            "Robert Dilts origins")
        "Andrew Moreno Series" = @(
            "Andrew Moreno", "NLP challenge", "NLP progress report",
            "NLP practitioner journal",
            "skill development",
            "practice log",
            "NLP exercises",
            "daily practice",
            "integration exercises")
        "NLP Theory Discussions" = @(
            "NLP discussion", "NLP theory", "parts work", "NLP imprint",
            "neural net", "AI",
            "epistemology of NLP",
            "modeling methodology",
            "structure of subjective experience",
            "representational tracking",
            "minimal cues",
            "utilization",
            "rapport building")
        "Related Resources" = @(
            # NOTE: Removed generic "resource" and "book"
            "personal development", "trauma work", "trauma healing",
            "My Grandmother's Hands", "Resmaa Menakem", "self-help",
            "somatic experiencing",
            "body-based therapy",
            "polyvagal theory",
            "Stephen Porges",
            "Peter Levine",
            "nervous system regulation",
            "vagal tone",
            "window of tolerance",
            "co-regulation")
        "Prove the Theorem Series (Extended)" = @(
            # Keywords for the Prove the Theorem NLP exercise series
            "Prove the Theorem",
            "PTS",
            "theorem",
            "proposition",
            "NLP exercise",
            "NLP drill",
            "mastery exercise",
            "advanced NLP practice",
            "skill building",
            "competency development",
            "deliberate practice",
            "NLP mastery",
            "structured exercise",
            "practitioner development")
    }

    #===========================================================================
    # MOC: Personal Knowledge Management
    # Subsection-based keywords for PKM topics
    #===========================================================================
    "Personal Knowledge Management" = @{
        "Vault Analysis and Structure" = @(
            "vault", "analysis", "structure", "statistics",
            "batch", "implementation",
            "graph analysis",
            "node degree",
            "orphan notes",
            "hub notes",
            "backlink analysis",
            "link density",
            "cluster analysis",
            "vault statistics",
            "file naming convention",
            "folder structure",
            "flat structure",
            "nested folders")
        "PKM Systems and Methods" = @(
            # NOTE: Removed generic "method", "system", "framework"
            "PKM", "PARA method", "Zettelkasten", "second brain", "map of content",
            "Tiago Forte", "Building a Second Brain", "knowledge management",
            "personal knowledge", "note-taking system",
            "Projects Areas Resources Archives",
            "CODE framework",
            "Capture Organize Distill Express",
            "progressive summarization",
            "evergreen notes",
            "atomic notes",
            "literature notes",
            "permanent notes",
            "reference notes",
            "fleeting notes",
            "concept notes")
        "Obsidian Integration" = @(
            "Obsidian", "plugin", "integration", "sync", "Google Calendar",
            "automation", "workflow",
            "Obsidian plugin",
            "community plugin",
            "core plugin",
            "Dataview",
            "Templater",
            "QuickAdd",
            "Periodic Notes",
            "Calendar plugin",
            "Excalidraw",
            "Kanban",
            "Tasks plugin",
            "graph view",
            "local graph")
        "Note-Taking and Learning" = @(
            "note-taking", "smart notes", "Ahrens",
            "Cornell method",
            "outline method",
            "mapping method",
            "charting method",
            "sentence method",
            "active recall",
            "elaborative interrogation",
            "self-explanation",
            "retrieval practice",
            "testing effect",
            "generation effect")
        "Productivity Philosophy" = @(
            "productivity", "slow productivity", "Newport", "Cal Newport",
            "deep work", "focus", "discipline", "philosophy", "KonMari",
            "tidying up",
            "essentialism",
            "Greg McKeown",
            "digital minimalism",
            "attention management",
            "time affluence",
            "chronotype",
            "ultradian rhythm",
            "circadian rhythm",
            "maker's schedule",
            "manager's schedule",
            "flow state",
            "peak performance")
        "GTD and Productivity Methods" = @(
            "GTD", "Getting Things Done", "David Allen", "Nozbe", "task management",
            "inbox zero", "next action", "project", "context", "review",
            "capture",
            "clarify",
            "organize",
            "reflect",
            "engage",
            "weekly review",
            "someday/maybe",
            "waiting for",
            "reference material",
            "tickler file",
            "natural planning model",
            "runway",
            "10,000 feet",
            "30,000 feet",
            "50,000 feet")
        "Writing Tools" = @(
            "writing", "fountain pen", "ink", "Noodler's", "journal", "notebook",
            "analog", "handwriting", "pencil", "Kuru Toga", "0.5",
            "journaling practice",
            "morning pages",
            "bullet journal",
            "BuJo",
            "rapid logging",
            "signifiers",
            "collections",
            "migration",
            "pen rotation",
            "ink collection",
            "fountain pen maintenance",
            "nib types")
        "Indexes and Tags" = @(
            "index note", "tag system", "category", "taxonomy", "classification",
            "folksonomy",
            "controlled vocabulary",
            "hierarchical tags",
            "nested tags",
            "tag taxonomy",
            "ontology",
            "metadata",
            "properties",
            "frontmatter",
            "YAML frontmatter",
            "aliases",
            "MOC",
            "Map of Content")
        "Templates" = @(
            "template", "daily note", "weekly note", "article template",
            "book template", "full note",
            "note template",
            "daily note template",
            "meeting notes template",
            "project template",
            "book notes template",
            "Templater syntax",
            "dynamic templates",
            "template variables",
            "date formatting")
        "Resources" = @(
            # NOTE: Removed generic "resource", "library", "reference", "collection"
            "PKM resource", "knowledge library", "reference material",
            "PKM community",
            "Obsidian Discord",
            "Obsidian forum",
            "PKM newsletter",
            "digital garden",
            "public Zettelkasten",
            "Learn in Public",
            "working with the garage door up")
    }

    #===========================================================================
    # MOC: Reading and Literature
    # Subsection-based keywords for reading and literature topics
    #===========================================================================
    "Reading and Literature" = @{
        "Key Books by Topic" = @(
            # NOTE: Removed "title" (matches "Untitled",
            "book annotation",
            "marginalia",
            "reading notes",
            "book summary",
            "key takeaways",
            "actionable insights",
            "book club",
            "reading group",
            "bestseller",
            "Pulitzer Prize",
            "National Book Award",
            "Booker Prize",
            # NOTE: Removed "book" alone, "author" alone - too generic
            "book review", "reading list", "literature",
            "book summary", "book recommendation", "must-read"
        )
        "Productivity and Learning" = @(
            "speed reading",
            "meta-learning",
            "ultralearning",
            "Scott Young",
            "learning how to learn",
            "deliberate practice",
            "Anders Ericsson",
            "10000 hour rule",
            "skill acquisition",
            "mastery",
            "expertise")
        "Psychology and Thinking" = @(
            "psychology", "thinking", "behavioral",
            "mind", "brain",
            "behavioral economics",
            "Dan Ariely",
            "Richard Thaler",
            "nudge theory",
            "choice architecture",
            "bounded rationality",
            "Herbert Simon",
            "mental models",
            "Shane Parrish",
            "Farnam Street",
            "first principles")
        "Health and Nutrition" = @(
            "health", "nutrition",
            "Breath", "Nestor",
            "nutrition book",
            "health memoir",
            "medical narrative",
            "patient story",
            "health transformation",
            "lifestyle change",
            "healing journey",
            "chronic illness narrative",
            "recovery story")
        "Spirituality and Religion" = @(
            "spirituality", "religion", "Jesus", "Gospel", "Thomas", "Nyland",
            "Boteach", "Kosher",
            "contemplative literature",
            "mystical writing",
            "sacred texts",
            "wisdom literature",
            "spiritual memoir",
            "pilgrimage narrative",
            "religious history",
            "comparative theology",
            "interfaith reading")
        "Social Issues" = @(
            "social commentary",
            "investigative journalism",
            "longform journalism",
            "narrative nonfiction",
            "creative nonfiction",
            "literary journalism",
            "reportage",
            "immersion journalism",
            "New Journalism")
        "Technology" = @(
            "technology", "ChatGPT", "Wolfram", "computing",
            "elements of computing",
            "tech book",
            "programming book",
            "computer science",
            "AI book",
            "technology ethics",
            "digital society",
            "future of technology",
            "tech history",
            "Silicon Valley",
            "startup culture")
        "Travel and Adventure" = @(
            "adventure", "journey",
            "travel memoir",
            "adventure narrative",
            "expedition account",
            "travelogue",
            "travel writing",
            "place-based writing",
            "nature writing",
            "outdoor literature",
            "wilderness narrative")
        "Science and Nature" = @(
            
        ,
            "popular science",
            "science communication",
            "science writing",
            "nature essay",
            "environmental writing",
            "climate literature",
            "cli-fi",
            "ecological writing",
            "natural history")
        "Crafts and Making" = @(
            "craft", "making", "bookbinding", "hand bookbinding", "electronics",
            "Make Electronics",
            "maker movement",
            "craftspersonship",
            "artisan skills",
            "handmade",
            "traditional crafts",
            "folk arts",
            "craft revival",
            "slow making",
            "workshop book",
            "how-to guide",
            "project book")
        "Fiction and Literature" = @(
            "fiction", "novel", "story", "Waking Up Dead", "Eleven", "Fallout",
            "Brave Ones",
            "literary fiction",
            "contemporary fiction",
            "genre fiction",
            "short story collection",
            "novella",
            "novel",
            "saga",
            "series",
            "debut novel",
            "award-winning fiction",
            "book-to-film adaptation")
        "Organization and Lifestyle" = @(
            "lifestyle", "tidying", "cool tool", "pencil", "CoolTools",
            "minimalist",
            "decluttering",
            "minimalism",
            "simple living",
            "intentional living",
            "hygge",
            "lagom",
            "wabi-sabi",
            "slow living",
            "mindful living",
            "home organization",
            "life design",
            "lifestyle design")
        "All Book Notes" = @(
            "book notes", "all books",
            "reading tracker",
            "book log",
            "reading journal",
            "Goodreads",
            "StoryGraph",
            "LibraryThing",
            "reading statistics",
            "books read",
            "reading goal",
            "reading challenge",
            "TBR pile",
            "to be read")
        "Kindle Clippings" = @(
            # NOTE: Removed "note" (too common in Obsidian context,
            "Kindle highlights",
            "Kindle notes",
            "clippings.txt",
            "Readwise",
            "highlight export",
            "annotation sync",
            "digital marginalia",
            "ebook annotation",
            "highlight organization",
            "quote collection",
            "Kindle clipping", "Kindle highlight", "Amazon Kindle"
        )
        "Chrome/Web Clippings" = @(
            # NOTE: Removed "web", "article", "saved" - too generic
            "web clipping", "Chrome extension", "browser clipping", "saved article",
            "web clipper",
            "Pocket",
            "Instapaper",
            "Raindrop.io",
            "Notion Web Clipper",
            "article save",
            "read later",
            "offline reading",
            "web archive",
            "Wayback Machine",
            "article distillation",
            "reader mode")
        "Book Index" = @(
            # NOTE: Removed "library" - too generic
            "book index", "book catalog", "reading catalog", "book collection",
            "personal library",
            "home library",
            "library catalog",
            "Libib",
            "book database",
            "ISBN",
            "book metadata",
            "library organization")
    }

    #===========================================================================
    # MOC: Recipes
    # Subsection-based keywords for recipe topics
    #===========================================================================
    "Recipes" = @{
        "Related" = @(
            # NOTE: Removed generic "index"
            "recipe nutrition", "healthy cooking", "meal planning",
            "weekly menu",
            "batch cooking",
            "food prep",
            "recipe scaling",
            "ingredient substitution",
            "dietary modification",
            "allergy-friendly",
            "nut-free",
            "gluten-free",
            "soy-free")
        "Soups and Stews" = @(
            # NOTE: These are specific enough
            "soup recipe", "stew recipe", "chowder", "gumbo", "broth",
            "bisque", "black bean soup", "lentil soup", "vegetable soup", "noodle soup",
            "carrot soup", "tomato soup", "chickpea stew", "daal", "dal recipe",
            "minestrone", "curry",
            "gazpacho",
            "borscht",
            "pho",
            "ramen broth",
            "miso soup",
            "posole",
            "pozole",
            "ribollita",
            "mulligatawny",
            "split pea soup",
            "butternut squash soup",
            "corn chowder",
            "hot and sour soup")
        "Main Dishes" = @(
            # NOTE: Removed "loaf" (too generic - could be bread loaf, meatloaf, etc.,
            "Buddha bowl",
            "grain bowl",
            "power bowl",
            "nourish bowl",
            "stir-fry",
            "one-pot meal",
            "sheet pan dinner",
            "skillet dinner",
            "stuffed pepper",
            "stuffed squash",
            "veggie lasagna",
            "eggplant parmesan",
            "jackfruit pulled pork",
            "cauliflower steak",
            "portobello burger",
            "main dish", "entree recipe", "dinner recipe", "lo mein", "veggie burger",
            "meatball recipe", "chili recipe", "pasta recipe", "spaghetti", "gnocchi",
            "casserole", "rice and beans", "risotto", "fried rice", "spring roll",
            "curry recipe", "tagine", "couscous recipe", "tempeh recipe", "tofu recipe"
        )
        "Sides and Salads" = @(
            "side dish", "salad", "tabbouleh", "quinoa salad", "rainbow salad",
            "summer salad", "potato", "mashed", "colcannon", "couscous",
            "millet", "carrot", "cauliflower", "corn salad", "kichadi",
            "grain salad",
            "pasta salad",
            "bean salad",
            "slaw",
            "coleslaw",
            "roasted vegetables",
            "glazed carrots",
            "maple roasted",
            "balsamic roasted",
            "garlic mashed",
            "twice-baked",
            "hasselback",
            "gratin",
            "au gratin")
        "Breads and Baked Goods" = @(
            "bread", "baked", "focaccia", "tortilla", "soda bread", "muffin",
            "pumpkin bread", "whole wheat", "bread machine", "yeast",
            "artisan bread", "cake", "cakes",
            "no-knead bread",
            "sourdough starter",
            "levain",
            "poolish",
            "biga",
            "autolyse",
            "bulk fermentation",
            "proofing",
            "scoring",
            "dutch oven bread",
            "pullman loaf",
            "enriched dough")
        "Desserts and Sweets" = @(
            "dessert", "sweet", "cookie", "brownie", "cake", "pie", "bar",
            "graham cracker", "apple", "chocolate", "vegan dessert",
            "gingerbread", "war cake", "popcorn", "pecans", "granola",
            "vegan baking", "pie", "custard",
            "egg replacer",
            "flax egg",
            "chia egg",
            "aquafaba",
            "coconut whipped cream",
            "cashew cream",
            "date sweetened",
            "maple syrup",
            "nice cream",
            "frozen banana",
            "energy balls",
            "bliss balls",
            "raw dessert")
        "Fermented Foods" = @(
            "fermented", "sauerkraut", "kimchi", "pickle", "probiotic",
            "lacto-fermented", "cultured",
            "wild fermentation",
            "lacto-fermentation",
            "brine",
            "starter culture",
            "fermentation vessel",
            "airlock",
            "fermentation weight",
            "kombucha",
            "water kefir",
            "milk kefir alternative",
            "tempeh making",
            "miso making")
        "Sauces, Dips and Condiments" = @(
            "sauce", "dip", "condiment", "queso", "hummus", "chutney",
            "marmalade", "ketchup", "catchup", "dressing", "seasoning",
            "ras el hanout", "cajun", "pickled", "onion",
            "tahini sauce",
            "cashew sauce",
            "nutritional yeast sauce",
            "cheese sauce",
            "pesto",
            "chimichurri",
            "harissa",
            "zhug",
            "romesco",
            "aioli",
            "baba ganoush",
            "muhammara",
            "tzatziki alternative",
            "raita")
        "Beverages" = @(
            # NOTE: Removed "tea" (matches etc.,
            "plant milk",
            "oat milk homemade",
            "almond milk",
            "cashew milk",
            "green smoothie",
            "protein smoothie",
            "açaí bowl",
            "smoothie bowl",
            "infused water",
            "herbal infusion",
            "nut milk bag",
            "cold brew",
            # NOTE: Removed "ginger", "lemon" (ingredients, not drinks)
            "beverage recipe", "drink recipe", "smoothie recipe", "mango lassi",
            "turmeric latte", "golden milk", "herbal tea", "chai", "hot chocolate"
        )
        "Basics and Staples" = @(
            "basic", "staple", "homemade", "from scratch", "base recipe",
            "vegetable broth",
            "homemade stock",
            "spice blend",
            "seasoning mix",
            "salad dressing",
            "vinaigrette",
            "nut butter",
            "seed butter",
            "plant-based milk",
            "vegan butter",
            "flax meal",
            "chia pudding base")
        "Sweet Potato Collection" = @(
            "sweet potato", "yam", "sweet potato recipe", "sweet potato biscuit",
            "sweet potato curry", "sweet potato brownie",
            "baked sweet potato",
            "mashed sweet potato",
            "sweet potato fries",
            "sweet potato casserole",
            "sweet potato pie",
            "sweet potato soup",
            "stuffed sweet potato",
            "sweet potato hash",
            "sweet potato toast",
            "spiralized sweet potato",
            "sweet potato noodles")
    }

    #===========================================================================
    # MOC: Science and Nature
    # Subsection-based keywords for science and nature topics
    #===========================================================================
    "Science and Nature" = @{
        "Micrometeorites" = @(
            "micrometeorite", "micrometeoroid", "stardust", "cosmic dust",
            "space dust", "meteorite", "Larsen", "collecting", "finding",
            "astrophysics", "hunt",
            "cosmic spherule",
            "interplanetary dust particle",
            "IDP",
            "zodiacal dust",
            "micrometeoroid",
            "ablation sphere",
            "barred olivine",
            "porphyritic",
            "S-type spherule",
            "I-type spherule",
            "G-type spherule",
            "unmelted micrometeorite",
            "Jon Larsen",
            "Project Stardust",
            "urban micrometeorites",
            "rooftop collecting")
        "Earth Sciences and Geology" = @(
            "geology", "geological", "earth science", "earthquake", "tsunami",
            "dam removal", "petrified forest", "ice age", "flood", "scablands",
            "methane", "crater", "Amazon", "ancient farmers",
            "plate tectonics",
            "subduction zone",
            "volcanic activity",
            "seismology",
            "stratigraphy",
            "sedimentary rock",
            "igneous rock",
            "metamorphic rock",
            "mineral identification",
            "rock cycle",
            "erosion",
            "weathering",
            "geomorphology",
            "glaciology",
            "hydrology",
            "paleoclimatology")
        "Archaeology and Anthropology" = @(
            # NOTE: Removed "ancient" (too common,
            "excavation",
            "stratigraphy",
            "provenience",
            "context",
            "artifact",
            "assemblage",
            "ecofact",
            "biofact",
            "feature",
            "midden",
            "radiocarbon dating",
            "carbon-14",
            "dendrochronology",
            "thermoluminescence",
            "paleoanthropology",
            "hominid",
            "lithic analysis",
            "zooarchaeology",
            # NOTE: Removed "Roman" (could be name or food item)
            "archaeology", "archaeological", "anthropology", "fossil", "prehistoric",
            "Cave of Bones", "Neanderthal", "Hannibal expedition", "Nutcracker Man",
            "Easter Island", "Arctic expedition", "Native American history",
            "ancient civilization", "lidar archaeology", "space archaeologist")
        "Paleontology" = @(
            "Mammoth", "Dinosaur"
            "paleontology", "paleontologist", "fossil record", "stratigraphy", "biostratigraphy",
            "geologic time scale", "Permian period", "Cretaceous period", "Pleistocene epoch",
            "Quaternary period", "morphology", "taxonomy", "phylogeny", "cladistics", "cladogram",
            "extinction event", "evolutionary lineage", "speciation", "convergent evolution", 
            "trace fossil", "coprolite", "body fossil", "amniote", "marine invertebrates",
            "vertebrate paleontology", "invertebrate paleontology", "micropaleontology", 
            "taphonomy", "paleoecology", "paleobiology", "biofacies", "paleoenvironment",
            "index fossil", "Holotype specimen", "Quaternary megafauna", "sedimentary deposits",
            "paleoclimatology", "radiometric dating", "relative dating", "mass extinction", "paleontological")
        "Gardening and Nature" = @(
            "moss", "plant", "ozone", "fig tree",
            "apricot", "apple tree", "square-foot gardening", "rain barrel",
            "string of turtles", "native land", "forest garden", "conservation",
            "phenology",
            "first frost date",
            "last frost date",
            "growing season",
            "pollinator garden",
            "native plants",
            "xeriscaping",
            "rain garden",
            "wildlife habitat",
            "bird-friendly garden",
            "butterfly garden",
            "integrated pest management",
            "IPM",
            "beneficial insects")
        "Travel and Natural Wonders" = @(
            "natural wonder", "rock formation", "Bisti Badlands", "Hiroshima",
            "bonsai", "land art", "Crawick",
            "geological formation",
            "natural landmark",
            "UNESCO World Heritage",
            "geopark",
            "biosphere reserve",
            "scenic overlook",
            "vista point",
            "geological survey",
            "natural monument",
            "wilderness area")
        "Life Sciences" = @(
            "life science", "biology", "octopi", "genetic",
            "specialisation", "fairy circle", "evolution",
            "cell biology",
            "molecular biology",
            "genetics",
            "genomics",
            "proteomics",
            "evolutionary biology",
            "ecology",
            "biodiversity",
            "taxonomy",
            "phylogenetics",
            "cladistics",
            "speciation",
            "adaptation",
            "natural selection")
        "Space and Planetary Science" = @(
            # NOTE: Removed "machine learning" (belongs in AI section)
            # NOTE: Removed "IBM" (too generic for space)
            "space", "planetary", "Mars", "NASA", "space mission",
            "space science",
            "exoplanet",
            "astrobiology",
            "habitability",
            "Goldilocks zone",
            "solar system",
            "asteroid belt",
            "Kuiper belt",
            "Oort cloud",
            "space telescope",
            "James Webb",
            "Hubble",
            "planetary exploration",
            "Mars rover",
            "Perseverance",
            "Curiosity",
            "lunar exploration")
        "Weather" = @(
            "weather", "climate", "atmosphere", "meteorology",
            "forecast",
            "meteorology",
            "atmospheric science",
            "weather pattern",
            "pressure system",
            "front",
            "cold front",
            "warm front",
            "precipitation",
            "humidity",
            "dew point",
            "wind chill",
            "heat index",
            "severe weather",
            "storm system")
        "Index" = @(
            "science topic", "nature topic"
        )
    }

    #===========================================================================
    # MOC: Soccer
    # Subsection-based keywords for soccer topics
    #===========================================================================
    "Soccer" = @{
        "Soccer Books and Literature" = @(
            "soccer book", "football book", "Believe", "Egner",
            "Inverting the Pyramid", "Wilson", "Coach Beard",
            "Zonal Marking",
            "Michael Cox",
            "The Mixer",
            "Jonathan Wilson",
            "The Numbers Game",
            "Chris Anderson",
            "Soccernomics",
            "Simon Kuper",
            "Brilliant Orange",
            "David Winner",
            "Fear and Loathing in La Liga")
        "Ted Lasso and English Football Culture" = @(
            "Ted Lasso", "AFC Richmond", "English football", "Premier League",
            "EPL", "coaching", "Wizard of Oz", "Brett Goldstein",
            "Richmond FC",
            "Nate Shelley",
            "Roy Kent",
            "Keeley Jones",
            "Rebecca Welton",
            "Diamond Dogs",
            "believe sign",
            "biscuits with the boss",
            "football is life",
            "relegation battle",
            "promotion race",
            "Championship",
            "FA Cup")
        "Learning the Game" = @(
            "4-4-2", "4-3-3", "midfielder", "striker",
            "defender", "goalkeeper", "role", "soccer position",
            "Laws of the Game",
            "IFAB",
            "offside rule",
            "advantage rule",
            "VAR",
            "yellow card",
            "red card",
            "penalty kick",
            "free kick",
            "corner kick",
            "throw-in",
            "goal kick",
            "first touch",
            "ball control",
            "passing accuracy")
        "Positions and Formations" = @(
            "position", "formation", "numbers", "player role", "tactics",
            "DICK'S Sporting Goods",
            "false nine",
            "inverted winger",
            "box-to-box midfielder",
            "holding midfielder",
            "regista",
            "trequartista",
            "sweeper keeper",
            "wingback",
            "fullback",
            "center back",
            "defensive midfielder",
            "attacking midfielder",
            "playmaker")
        "Teams and Leagues" = @(
            "team", "league", "Major League Soccer", 
            "squad", "roster", "club",
            "top flight",
            "first division",
            "second division",
            "Champions League",
            "Europa League",
            "Conference League",
            "domestic cup",
            "league cup",
            "transfer window",
            "deadline day",
            "loan deal",
            "buyout clause")
        "Major League Soccer (MLS)" = @(
            "Austin FC", "Charlotte FC", "Chicago Fire FC", "FC Cincinnati", 
            "Columbus Crew", "D.C. United", "Inter Miami CF", "CF Montréal", 
            "Nashville SC", "New England Revolution", "New York City FC", 
            "New York Red Bulls", "Orlando City SC", "Philadelphia Union", 
            "Toronto FC", "Houston Dynamo FC", 
            "Sporting Kansas City", "LA Galaxy", "Los Angeles Football Club", 
            "Minnesota United FC", "Portland Timbers", "Real Salt Lake", 
            "San Jose Earthquakes", "Seattle Sounders FC", "Vancouver Whitecaps FC", 
            "Colorado Rapids", "FC Dallas", "St. Louis City SC", "San Diego FC",
            "MLS", "LAFC", "Seattle Sounders",
            "Atlanta United", "Inter Miami", "American soccer",
            "Designated Player",
            "DP rule",
            "salary cap",
            "Supporters Shield",
            "MLS Cup",
            "playoff format",
            "expansion team",
            "SuperDraft",
            "Homegrown Player",
            "allocation money",
            "TAM",
            "GAM")
        "World Cup and International Football" = @(
            "World Cup", "international", "FIFA", "Germany",
            "USA", "national team", "tournament",
            "FIFA ranking",
            "continental confederation",
            "CONCACAF",
            "UEFA",
            "CONMEBOL",
            "qualifying round",
            "group stage",
            "knockout round",
            "round of 16",
            "quarterfinal",
            "semifinal",
            "third-place playoff",
            "final")
        "2022 Qatar World Cup" = @(
            "Qatar", "2022", "upset",
            "dressing room",
            "Lusail Stadium",
            "Al Bayt Stadium",
            "Argentina champion",
            "Lionel Messi",
            "Kylian Mbappé",
            "Morocco semifinal",
            "Japan upset",
            "Germany elimination",
            "penalty shootout",
            "golden boot",
            "golden ball",
            "young player award")
        "Soccer Culture and Values" = @(
            # NOTE: Removed "art", "flow", "respect" (too generic - cause false positives)
            # NOTE: Removed "teamwork", "sportsmanship" (too generic)
            "beautiful game",
            "joga bonito",
            "tiki-taka",
            "gegenpressing",
            "total football",
            "catenaccio",
            "calcio",
            "football culture",
            "supporter culture",
            "tifo",
            "ultras",
            "matchday atmosphere")
        "Related MOCs" = @(
            "sports psychology",
            "athletic performance",
            "team dynamics",
            "coaching philosophy",
            "leadership in sports",
            "sports analytics")
    }

    #===========================================================================
    # MOC: Social Issues and Culture
    # Subsection-based keywords for social issues topics
    #===========================================================================
    "Social Issues" = @{
        "Race and Equity" = @(
            "race", "racial", "racism", "equity", "Black", "African American",
            "white supremacy", "prejudice", "discrimination",
            "Sum of Us", "McGhee", "Menakem", "Jim Crow", "ally", "color blindness",
            "police", "shooting",
            "systemic racism",
            "structural racism",
            "implicit bias",
            "unconscious bias",
            "microaggression",
            "colorism",
            "redlining",
            "housing discrimination",
            "school-to-prison pipeline",
            "mass incarceration",
            "restorative justice",
            "reparations",
            "affirmative action",
            "equal opportunity")
        "Justice and Politics" = @(
            "justice", "politics", "political", "DEI", "diversity", "inclusion",
            "Seven Mountain Mandate", "income inequality", "authoritarianism",
            "Trump", "Saudi", "voting", "legislature",
            "social democracy",
            "progressive politics",
            "grassroots organizing",
            "community organizing",
            "civic engagement",
            "voter registration",
            "gerrymandering",
            "electoral reform",
            "ranked choice voting",
            "campaign finance",
            "lobbying",
            "political polarization")
        "Religion and Society" = @(
            "society", "hijab", "Islamic", "persecution",
            "Iran", "Christianity", "Parliament of Religions",
            "Jimmy Carter",
            "secularism",
            "separation of church and state",
            "religious pluralism",
            "religious freedom",
            "faith-based initiative",
            "religious exemption",
            "megachurch",
            "prosperity gospel",
            "fundamentalism",
            "evangelical")
        "Cultural Commentary" = @(
            "cultural", "elite", "rigged", "wisdom",
            "America's stories", "Donald Duck", "WWII", "Kristallnacht",
            "consumer", "remix",
            "cultural criticism",
            "media literacy",
            "propaganda",
            "misinformation",
            "disinformation",
            "fact-checking",
            "media bias",
            "echo chamber",
            "filter bubble",
            "cancel culture",
            "call-out culture",
            "accountability")
        "Cult Awareness" = @(
            "cult", "indoctrination", "cohesion", "decohesion", "manipulation",
            "group dynamics", "awareness",
            "high-demand group",
            "undue influence",
            "thought reform",
            "love bombing",
            "information control",
            "BITE model",
            "Steven Hassan",
            "exit counseling",
            "recovery from cults",
            "spiritual abuse",
            "coercive control")
        "Peace and Unity" = @(
            "peace", "world peace", "mindfulness", "meditation",
            "conflict resolution",
            "nonviolence",
            "conflict transformation",
            "peacebuilding",
            "reconciliation",
            "restorative circles",
            "community mediation",
            "dialogue facilitation",
            "truth and reconciliation",
            "transitional justice",
            "healing circles")
        "Culture" = @(
            "cultural identity",
            "cultural heritage",
            "cultural preservation",
            "multiculturalism",
            "cross-cultural communication",
            "cultural competency",
            "cultural humility",
            "intercultural dialogue",
            "cultural exchange")
    }

    #===========================================================================
    # MOC: Technology & Computers
    # Subsection-based keywords matching the actual MOC file structure
    # NOTE: This matches the exact MOC filename "MOC - Technology & Computers.md"
    #===========================================================================
    "Technology & Computers" = @{
        "Computer Sciences" = @(
            # Theoretical and foundational computer science topics
            "computer science",
            "algorithm",
            "data structure",
            "computational complexity",
            "automata theory",
            "computability",
            "Turing machine",
            "big O notation",
            "recursion",
            "abstraction",
            "computer architecture",
            "discrete mathematics",
            "formal languages",
            "NP-complete",
            "sorting algorithm",
            "search algorithm",
            "graph theory",
            "tree structure",
            "hash table",
            "stack",
            "queue",
            "linked list")
        "Networking & Systems" = @(
            # Network infrastructure and protocols
            "network",
            "networking",
            "TCP/IP",
            "TCP",
            "UDP",
            "router",
            "switch",
            "firewall",
            "DNS",
            "DHCP",
            "subnet",
            "IP address",
            "OSI model",
            "LAN",
            "WAN",
            "VPN",
            "bandwidth",
            "latency",
            "packet",
            "protocol",
            "Ethernet",
            "Wi-Fi",
            "802.11",
            "network topology",
            "gateway",
            "NAT",
            "port forwarding",
            "FiberFirst",
            "free space equation")
        "Databases & Access" = @(
            # Database systems and Microsoft Access
            # NOTE: Removed "table" (too generic - matches ASCII table, times table, etc.)
            # NOTE: Removed "index" (too generic - matches book index, music index, etc.)
            "database",
            "SQL",
            "query",
            "Microsoft Access",
            "Access database",
            "database table",
            "relationship",
            "primary key",
            "foreign key",
            "inner join", "outer join",
            "database index",
            "normalization",
            "RDBMS",
            "INSERT",
            "UPDATE",
            "DELETE",
            "WHERE clause",
            "ORDER BY",
            "GROUP BY",
            "query dependencies",
            "AcSpreadSheetType",
            "DoCmd",
            "recordset",
            "DAO",
            "ADO")
        "Excel VBA" = @(
            # Excel automation and VBA programming
            "Excel",
            "VBA",
            "Visual Basic for Applications",
            "macro",
            "spreadsheet",
            "workbook",
            "worksheet",
            "cell",
            "range",
            "formula",
            "pivot table",
            "ActiveX",
            "UserForm",
            "module",
            "subroutine",
            "function",
            "paste special",
            "create worksheet",
            "disable alert",
            "Application object",
            "Workbooks collection",
            "Worksheets collection",
            "Cells property",
            "Range object",
            "Selection object",
            "ActiveCell")
        "Linux Resources & Guides" = @(
            # Linux operating system and administration
            "Linux",
            "Ubuntu",
            "Debian",
            "Fedora",
            "Zorin",
            "Zorin OS",
            "bash",
            "shell",
            "terminal",
            "command line",
            "apt",
            "apt-get",
            "dpkg",
            "grub",
            "bootloader",
            "kernel",
            "systemctl",
            "systemd",
            "chmod",
            "chown",
            "sudo",
            "root",
            "LinuxLive USB",
            "Live USB",
            "reinstall grub",
            "boot repair",
            "partition",
            "mount",
            "fstab")
        "Maker Projects" = @(
            # DIY electronics and maker culture
            "maker",
            "maker project",
            "DIY electronics",
            "Raspberry Pi",
            "Arduino",
            "RC2014",
            "Z80",
            "soldering",
            "PCB",
            "printed circuit board",
            "breadboard",
            "LED",
            "motor",
            "sensor",
            "microcontroller",
            "GPIO",
            "wall plotter",
            "hanging plotter",
            "electronics project",
            "hobbyist",
            "single-board computer",
            "ESP32",
            "ESP8266",
            "Pico")
        "Computing Fundamentals" = @(
            # Foundational computing concepts
            "computing fundamentals",
            "binary",
            "hexadecimal",
            "bit",
            "byte",
            "logic gate",
            "Boolean",
            "von Neumann",
            "ALU",
            "arithmetic logic unit",
            "CPU",
            "central processing unit",
            "memory",
            "instruction set",
            "assembly",
            "machine code",
            "compilation",
            "Elements of Computing Systems",
            "Nand to Tetris",
            "Nisan",
            "Schocken",
            "Alan Turing",
            "Turing",
            "Enigma",
            "computer history")
        "Hardware & Electronics" = @(
            # Physical computing and electronics
            "hardware",
            "electronics",
            "circuit",
            "resistor",
            "capacitor",
            "transistor",
            "diode",
            "IC",
            "integrated circuit",
            "chip",
            "motherboard",
            "RAM",
            "SSD",
            "HDD",
            "hard drive",
            "USB",
            "port",
            "connector",
            "Make Electronics",
            "Platt",
            "USB port identification",
            "power supply",
            "voltage",
            "amperage",
            "ohm",
            "multimeter")
        "Software & Tools" = @(
            # Software applications and utilities
            # NOTE: Removed "tool" (too generic - matches garden tool, hand tool, etc.)
            "software",
            "application",
            "software tool",
            "utility",
            "backup",
            "backup solution",
            "sync",
            "installer",
            "portable",
            "freeware",
            "open source",
            "license",
            "update",
            "patch",
            "version",
            "USMT",
            "User State Migration Tool",
            "Microsoft Office",
            "Office 2021",
            "TurboTax",
            "Writage",
            "CompuServe",
            "eM Client",
            "eMClient")
        "Devices & Hardware" = @(
            # Consumer electronics and devices
            "device",
            "TiVo",
            "DVR",
            "digital video recorder",
            "router",
            "modem",
            "printer",
            "scanner",
            "monitor",
            "keyboard",
            "mouse",
            "webcam",
            "headset",
            "smart device",
            "IoT",
            "Internet of Things",
            "peripheral",
            "external drive",
            "USB hub",
            "docking station")
        "Chromebook" = @(
            # Chrome OS and Chromebook-specific topics
            "Chromebook",
            "Chrome OS",
            "ChromeOS",
            "Google Chromebook",
            "Crostini",
            "Linux on Chromebook",
            "web app",
            "PWA",
            "Progressive Web App",
            "Google Drive",
            "Chrome browser",
            "Lacros",
            "Chrome Remote Desktop",
            "Chromebook recovery",
            "powerwash",
            "developer mode",
            "crosh",
            "Chrome shell")
        "Troubleshooting & Guides" = @(
            # Problem-solving and how-to guides
            # NOTE: Removed "fix", "problem", "solution", "guide" (too generic)
            # NOTE: Removed "eBay", "combine shipping" (not relevant to troubleshooting)
            "troubleshoot",
            "troubleshooting",
            "tech troubleshooting",
            "error message",
            "how-to",
            "tech tutorial",
            "step-by-step",
            "malware",
            "malware removal",
            "virus",
            "system recovery",
            "factory reset",
            "computer repair",
            "Windows troubleshooting",
            "diagnostic",
            "safe mode",
            "system restore")
        "AI & Machine Learning" = @(
            # Artificial intelligence and ML topics
            # NOTE: Removed "training" (too generic - matches job training, sports training)
            # NOTE: Removed "model" (too generic - matches fashion model, scale model)
            "AI",
            "artificial intelligence",
            "machine learning",
            "ML",
            "ChatGPT",
            "GPT",
            "neural network",
            "deep learning",
            "LLM",
            "large language model",
            "transformer",
            "AI model",
            "ML model",
            "AI training",
            "model training",
            "prompt",
            "prompt engineering",
            "Claude",
            "Anthropic",
            "OpenAI",
            "Wolfram",
            "What Is ChatGPT Doing",
            "natural language processing",
            "NLP AI",
            "computer vision",
            "generative AI",
            "foundation model")
        "System Administration" = @(
            # Server and system management topics
            "system admin",
            "sysadmin",
            "system administration",
            "VMware",
            "Nagios",
            "monitoring",
            "server",
            "user account",
            "Active Directory",
            "Group Policy",
            "PowerShell scripting",
            "bash scripting",
            "cron job",
            "scheduled task",
            "service management",
            "systemd",
            "container",
            "Docker",
            "Kubernetes",
            "virtualization",
            "hypervisor",
            "load balancing",
            "high availability",
            "disaster recovery",
            "iptables",
            "firewall configuration")
        "Retro Computing & Hardware" = @(
            # Vintage and classic computing
            "retro computing",
            "vintage computer",
            "RC2014",
            "Z80",
            "Altair",
            "CPUville",
            "LiFePO4",
            "PCB",
            "circuit board",
            "kit",
            "Digicomp",
            "mechanical computer",
            "8-bit",
            "6502",
            "CP/M",
            "BASIC",
            "retrocomputing",
            "emulator",
            "FPGA",
            "Forrest Mims",
            "classic computer")
        "Media & Entertainment" = @(
            # Home media and entertainment systems
            "media",
            "entertainment",
            "XBMC",
            "Kodi",
            "TiVo",
            "Kindle",
            "ebook",
            "streaming",
            "home theater",
            "home theater PC",
            "HTPC",
            "media server",
            "Plex",
            "Jellyfin",
            "digital media",
            "media streaming",
            "codec",
            "transcoding",
            "audio format",
            "FLAC",
            "video format",
            "4K",
            "HDR",
            "automated media center",
            "Kindle Unswindle")
        "UX & Design" = @(
            # User experience and design topics
            "UX",
            "user experience",
            "UI",
            "user interface",
            "design",
            "accessibility",
            "a11y",
            "deaf",
            "hearing impaired",
            "screen reader",
            "usability",
            "wireframe",
            "prototype",
            "human-computer interaction",
            "HCI",
            "inclusive design",
            "universal design")
        "Programming & Development" = @(
            # Software development and coding
            "programming",
            "development",
            "coding",
            "code",
            "LiveCode",
            "SQL",
            "ORDER BY",
            "script",
            "developer",
            "integrated development environment",
            "IDE",
            "code editor",
            "VS Code",
            "debugger",
            "profiler",
            "unit testing",
            "test-driven development",
            "TDD",
            "continuous integration",
            "CI/CD",
            "DevOps",
            "agile methodology",
            "API design",
            "REST",
            "GraphQL",
            "microservices")
    }

    #===========================================================================
    # MOC: Travel and Exploration
    # Subsection-based keywords for travel topics
    #===========================================================================
    "Travel and Exploration" = @{
        "Narrowboat and Canal Travel" = @(
            "narrowboat", "canal", "waterway", "lock", "mooring", "River Thames",
            "British waterways", "England canal", "Petkus", "Rolt", "Fisher",
            "cruising",
            "British Waterways",
            "Canal and River Trust",
            "CRT license",
            "continuous cruiser",
            "winding hole",
            "pound",
            "summit level",
            "tunnel",
            "bridge hole",
            "tow path",
            "gongoozler",
            "boat handling",
            "stern gear",
            "prop shaft",
            "engine hours",
            "boat safety scheme",
            "BSS")
        "RV and Alternative Living" = @(
            "RV", "motorhome", "recreational vehicle", "retire to RV", "tipi",
            "alternative living", "full-time travel", "Hollywood RV Park",
            "Long Long Honeymoon",
            "nomadic lifestyle",
            "location independence",
            "remote work travel",
            "digital nomad",
            "van life",
            "skoolie",
            "bus conversion",
            "tiny living",
            "minimalist travel",
            "slow travel",
            "overlanding",
            "expedition vehicle")
        "National Parks and Nature" = @(
            "national park", "Big Bend", "Yellowstone", "Yosemite",
            "Grand Canyon", "Zion", "Arches", "Glacier", "outdoor", "hiking",
            "park pass",
            "America the Beautiful pass",
            "backcountry permit",
            "wilderness permit",
            "Leave No Trace",
            "trail etiquette",
            "summit",
            "trailhead",
            "switchback",
            "elevation gain",
            "scramble",
            "bushwhack",
            "cairn",
            "blaze",
            "trail marker")
        "Specific Locations" = @(
            "travel destination", "travel guide",
            "destination guide",
            "travel itinerary",
            "points of interest",
            "POI",
            "off the beaten path",
            "hidden gem",
            "local favorite",
            "must-see",
            "day trip",
            "road trip",
            "scenic drive",
            "scenic route")
        "Washington State" = @(
            "Washington", "Washington State", "Seattle", "Channeled Scablands",
            "Ice Age Flood", "Seven Wonders", "Pacific Northwest",
            "Olympic Peninsula",
            "San Juan Islands",
            "Mount Rainier",
            "North Cascades",
            "Columbia River Gorge",
            "Puget Sound",
            "Spokane",
            "Palouse",
            "wine country",
            "Walla Walla",
            "Leavenworth",
            "Whidbey Island")
        "Santa Fe" = @(
            "Santa Fe", "New Mexico", "Southwest", "desert",
            "adobe architecture",
            "Pueblo style",
            "Canyon Road",
            "Georgia O'Keeffe",
            "Native American art",
            "turquoise jewelry",
            "chile culture",
            "Hatch chile",
            "high desert",
            "Sangre de Cristo Mountains",
            "Bandelier National Monument")
        "Atlanta" = @(
            "Atlanta", "Georgia", "GA", "things to do",
            "MLK National Historic Site",
            "Atlanta BeltLine",
            "Piedmont Park",
            "Georgia Aquarium",
            "World of Coca-Cola",
            "Centennial Olympic Park",
            "Ponce City Market",
            "Krog Street Market",
            "Little Five Points")
        "Moscow" = @(
            "Moscow", "Russia", "Eastern Europe",
            "Red Square",
            "Kremlin",
            "St. Basil's Cathedral",
            "Bolshoi Theatre",
            "Moscow Metro",
            "Gorky Park",
            "Tretyakov Gallery",
            "Pushkin Museum")
        "Japan" = @(
            "Japan", "Japanese", "Tokyo", "Kyoto", "Nagomi", "Mogi",
            "Shinkansen",
            "bullet train",
            "ryokan",
            "onsen",
            "tatami",
            "zen garden",
            "temple",
            "shrine",
            "torii gate",
            "sake brewery",
            "izakaya",
            "ramen shop",
            "convenience store",
            "konbini",
            "JR Pass")
        "Pilgrimage" = @(
            "pilgrimage", "spiritual journey", "holy site", "sacred",
            "religious travel",
            "Camino de Santiago",
            "Camino Francés",
            "pilgrim passport",
            "credencial",
            "albergue",
            "pilgrim hostel",
            "Buen Camino",
            "Way of St. James",
            "spiritual walk",
            "walking meditation",
            "labyrinth walk",
            "sacred site")
        "Travel Index" = @(
            "travel planning",
            "trip planner",
            "packing list",
            "travel checklist",
            "travel journal",
            "trip report",
            "destination research",
            "travel resources")
    }
}

#endregion Configuration Variables

#region Logging Functions

<#
.SYNOPSIS
    Writes a message to both console and the persistent log file.

.DESCRIPTION
    This function handles all logging operations, writing timestamped entries
    to both the console (with color coding) and the persistent log file.

.PARAMETER Message
    The message text to log.

.PARAMETER Level
    The severity level: INFO, WARNING, ERROR, or SUCCESS.
    Determines console color and log prefix.

.PARAMETER NoConsole
    When specified, writes only to the log file without console output.
#>
function Write-Log {
    param(
        # $Message: The text content to be logged
        [string]$Message,

        # $Level: Severity level determining color and prefix (INFO, WARNING, ERROR, SUCCESS)
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',

        # $NoConsole: Switch to suppress console output (log file only)
        [switch]$NoConsole
    )

    # $timestamp: Current date/time formatted for log entries (ISO 8601 format)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # $logEntry: The complete formatted log line with timestamp, level, and message
    $logEntry = "[$timestamp] [$Level] $Message"

    # Append the log entry to the persistent log file
    # Using -Append ensures we don't overwrite previous log entries
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8

    # Write to console with appropriate color coding based on severity
    if (-not $NoConsole) {
        # $consoleColor: The foreground color for console output based on severity level
        $consoleColor = switch ($Level) {
            'INFO'    { 'White' }      # Standard informational messages
            'WARNING' { 'Yellow' }     # Warning conditions that need attention
            'ERROR'   { 'Red' }        # Error conditions that prevented an operation
            'SUCCESS' { 'Green' }      # Successful completion of operations
        }
        Write-Host $logEntry -ForegroundColor $consoleColor
    }
}

<#
.SYNOPSIS
    Writes a section header to the log for visual organization.

.DESCRIPTION
    Creates a visually distinct separator in both console and log file
    to mark the beginning of a new section of operations.

.PARAMETER Title
    The title text to display in the section header.
#>
function Write-LogSection {
    param(
        # $Title: The heading text for the log section
        [string]$Title
    )

    # $separator: A line of equals signs for visual separation
    $separator = "=" * 60

    # Write blank line, separator, title, separator pattern
    Write-Log "" -Level INFO -NoConsole
    Write-Log $separator -Level INFO
    Write-Log "  $Title" -Level INFO
    Write-Log $separator -Level INFO
}

#endregion Logging Functions

#region MOC Discovery Functions

<#
.SYNOPSIS
    Discovers all MOC (Map of Content) files in the vault.

.DESCRIPTION
    Scans the MOC folder for all files matching the MOC naming pattern
    (e.g., "MOC - Recipes.md") and returns their paths and extracted names.

    This function enables dynamic discovery of MOCs rather than relying
    on a hardcoded list, ensuring all current MOCs are included.

.OUTPUTS
    Array of hashtables containing:
    - FullPath: Absolute file system path to the MOC file
    - RelativePath: Path relative to vault root (without .md extension)
    - Name: Display name extracted from filename (e.g., "Recipes")
    - FileName: Full filename without extension (e.g., "MOC - Recipes")
#>
function Get-AllMOCs {
    Write-Log "Discovering all MOC files in vault..." -Level INFO

    # $mocFolderPath: Full path to the folder containing MOC files
    $mocFolderPath = Join-Path $vaultPath $mocFolder

    # $mocFiles: Collection of all files matching the MOC naming pattern
    # Pattern matches files like "MOC - Recipes.md", "MOC - Technology and Computing.md"
    $mocFiles = Get-ChildItem -Path $mocFolderPath -Filter $mocPattern -File -ErrorAction SilentlyContinue

    # $mocs: Array to collect discovered MOC information
    $mocs = @()

    foreach ($file in $mocFiles) {
        # $fileName: File name without the .md extension
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        # $mocName: The topic name extracted from the filename
        # Removes "MOC - " prefix to get just the topic (e.g., "Recipes", "Technology and Computing")
        $mocName = $fileName -replace '^MOC - ', ''

        # $relativePath: Path relative to vault root (for Obsidian linking)
        # Format: "00 - Home Dashboard/MOC - Recipes" (no .md extension)
        $relativePath = Join-Path $mocFolder $fileName

        $mocs += @{
            FullPath = $file.FullName        # Absolute path for file reading
            RelativePath = $relativePath      # Relative path for Obsidian links
            Name = $mocName                   # Display name (topic only)
            FileName = $fileName              # Full filename without extension
        }
    }

    Write-Log "Discovered $($mocs.Count) MOC files" -Level SUCCESS
    return $mocs
}

<#
.SYNOPSIS
    Extracts all subsections from a MOC file content.

.DESCRIPTION
    Parses the content of a MOC file to find all level-2 headings (## Heading)
    which represent the subsections of the MOC. Returns an array of subsection names.

.PARAMETER Content
    The raw text content of the MOC file.

.OUTPUTS
    Array of strings containing subsection names (without the ## prefix).
#>
function Get-MOCSubsections {
    param(
        # $Content: The raw markdown content of the MOC file
        [string]$Content
    )

    # $subsections: Array to collect discovered subsection names
    $subsections = @()

    # $subsectionPattern: Regex pattern to match level-2 markdown headings
    # Pattern: Start of line, ##, space, then capture the heading text
    $subsectionPattern = '(?m)^## (.+)$'

    # $matches: All regex matches found in the content
    $matchResults = [regex]::Matches($Content, $subsectionPattern)

    foreach ($match in $matchResults) {
        # $subsectionName: The text of the heading (group 1 of the regex)
        $subsectionName = $match.Groups[1].Value.Trim()

        # Skip certain meta-sections that shouldn't receive orphan links
        # $skipSections: Array of section names to exclude from linking
        $skipSections = @(
            "Related Notes",
            "Recently Connected Orphans",
            "Related MOCs",
            "Related",
            "Index",
            "Tags"
        )

        # $shouldSkip: Boolean flag indicating if this section should be excluded
        $shouldSkip = $false
        foreach ($skipSection in $skipSections) {
            if ($subsectionName -eq $skipSection) {
                $shouldSkip = $true
                break
            }
        }

        if (-not $shouldSkip) {
            $subsections += $subsectionName
        }
    }

    return $subsections
}

<#
.SYNOPSIS
    Returns keywords for a specific MOC subsection from the static lookup table.

.DESCRIPTION
    Looks up the keywords for a given MOC name and subsection name from the
    $subsectionKeywords hashtable. Returns an empty array if no match is found.

.PARAMETER MOCName
    The display name of the MOC (e.g., "Recipes", "Technology and Computing").

.PARAMETER SubsectionName
    The name of the subsection within the MOC (e.g., "Soups and Stews").

.OUTPUTS
    Array of keyword strings for the given MOC subsection.
#>
function Get-SubsectionKeywords {
    param(
        # $MOCName: The topic name of the MOC (without "MOC - " prefix)
        [string]$MOCName,

        # $SubsectionName: The name of the subsection within the MOC
        [string]$SubsectionName
    )

    # $keywords: Array to store the retrieved keywords
    $keywords = @()

    # Attempt direct lookup by MOC name
    if ($subsectionKeywords.ContainsKey($MOCName)) {
        # $mocSubsections: The hashtable of subsections for this MOC
        $mocSubsections = $subsectionKeywords[$MOCName]

        if ($mocSubsections.ContainsKey($SubsectionName)) {
            $keywords = $mocSubsections[$SubsectionName]
        }
    }

    # If no direct match, try alternate MOC name formats
    if ($keywords.Count -eq 0) {
        # $alternateMocNames: Array of possible alternate MOC name formats to try
        $alternateMocNames = @()

        # Try without trailing space (some MOC files have trailing spaces in names)
        $alternateMocNames += $MOCName.TrimEnd()

        # Try with "and Culture" suffix variation for Social Issues
        if ($MOCName -like "*Social Issues*") {
            $alternateMocNames += "Social Issues"
            $alternateMocNames += "Social Issues and Culture"
        }

        # Try abbreviated forms
        if ($MOCName -eq "Music and Recorders") {
            $alternateMocNames += "Music and Record"
        }

        # Handle Bahá'í encoding variations (UTF-8 vs ASCII vs different diacritics)
        # The MOC filename may have different encoding than the hashtable key
        if ($MOCName -match "Bah.*Faith" -or $MOCName -like "*Baha*Faith*") {
            $alternateMocNames += "Bahá'í Faith"
            $alternateMocNames += "Baha'i Faith"
            $alternateMocNames += "Bahai Faith"
        }

        foreach ($altName in $alternateMocNames) {
            if ($subsectionKeywords.ContainsKey($altName)) {
                # $mocSubsections: The hashtable of subsections for this alternate MOC name
                $mocSubsections = $subsectionKeywords[$altName]

                if ($mocSubsections.ContainsKey($SubsectionName)) {
                    $keywords = $mocSubsections[$SubsectionName]
                    break
                }
            }
        }
    }

    return $keywords
}

#endregion MOC Discovery Functions

#region Tag Extraction Functions

<#
.SYNOPSIS
    Extracts all tags from a file's content.

.DESCRIPTION
    Parses markdown content to find all Obsidian-style tags (#tagname).
    Returns an array of unique tag names (without the # prefix).

.PARAMETER Content
    The raw text content of the file.

.OUTPUTS
    Array of unique tag strings (lowercase, without # prefix).
#>
function Get-FileTags {
    param(
        # $Content: The raw markdown content of the file
        [string]$Content
    )

    # $tags: Array to collect discovered tags
    $tags = @()

    if (-not $Content) {
        return $tags
    }

    # $tagPattern: Regex pattern to match Obsidian tags
    # Pattern: # followed by word characters, hyphens, or underscores
    # Negative lookbehind (?<!\[\[) prevents matching links like [[#heading]]
    $tagPattern = '(?<!\[\[)#([a-zA-Z][a-zA-Z0-9_-]*)'

    # $matchResults: All tag matches found in the content
    $matchResults = [regex]::Matches($Content, $tagPattern)

    foreach ($match in $matchResults) {
        # $tagName: The tag text (group 1, without the # prefix)
        $tagName = $match.Groups[1].Value.ToLower()

        # Add to array if not already present (deduplication)
        if ($tags -notcontains $tagName) {
            $tags += $tagName
        }
    }

    return $tags
}

<#
.SYNOPSIS
    Maps common tags to MOC subsections for categorization.

.DESCRIPTION
    Returns a hashtable mapping tag names to MOC/Subsection combinations.
    This allows files with specific tags to be matched to relevant subsections.

.OUTPUTS
    Hashtable mapping tag name (lowercase) to array of [MOCName, SubsectionName] pairs.
#>
function Get-TagToSubsectionMap {
    # $tagMap: Hashtable mapping tag names to MOC subsections
    # Key = lowercase tag name, Value = array of @(MOCName, SubsectionName) pairs
    $tagMap = @{
        # Bahá'í Faith tags
        "bahai" = ,@("Bahá'í Faith", "Core Teachings")
        "baha'i" = ,@("Bahá'í Faith", "Core Teachings")
        "bahá'í" = ,@("Bahá'í Faith", "Core Teachings")
        "lsa" = ,@("Bahá'í Faith", "Administrative Guidance")
        "nsa" = ,@("Bahá'í Faith", "Administrative Guidance")
        "ridvan" = ,@("Bahá'í Faith", "Ridván Messages")
        "ridván" = ,@("Bahá'í Faith", "Ridván Messages")

        # Finance tags
        "investing" = ,@("Finance and Investment", "Investing Strategies")
        "dividendinvesting" = ,@("Finance and Investment", "Investing Strategies")
        "stocks" = ,@("Finance and Investment", "Investing Strategies")
        "value-investing" = ,@("Finance and Investment", "Investing Strategies")
        "taxes" = ,@("Finance and Investment", "Tax Software")

        # Health tags
        "vegan" = @(@("Health and Nutrition", "Plant-Based Nutrition"), @("Recipes", "Main Dishes"))
        "wfpb" = ,@("Health and Nutrition", "WFPB Resources")
        "health" = ,@("Health and Nutrition", "Medical and Health")

        # Recipe tags
        "recipe" = ,@("Recipes", "Main Dishes")
        "cooking" = ,@("Recipes", "Main Dishes")
        "food" = ,@("Recipes", "Main Dishes")
        "soup" = ,@("Recipes", "Soups and Stews")
        "dessert" = ,@("Recipes", "Desserts and Sweets")
        "bread" = ,@("Recipes", "Breads and Baked Goods")

        # Science tags
        "science" = ,@("Science and Nature", "Life Sciences")
        "micrometeoroid" = ,@("Science and Nature", "Micrometeorites")
        "nature" = ,@("Science and Nature", "Gardening and Nature")
        "archaeology" = ,@("Science and Nature", "Archaeology and Anthropology")
        "paleontology" = ,@("Science and Nature", "Paleontology")
        "geology" = ,@("Science and Nature", "Earth Sciences and Geology")

        # Technology tags
        "technology" = ,@("Technology and Computing", "Software and Applications")
        "computing" = ,@("Technology and Computing", "System Administration")
        "programming" = ,@("Technology and Computing", "Programming and Development")
        "linux" = ,@("Technology and Computing", "System Administration")

        # Music tags
        "music" = ,@("Music and Record", "Music Theory and Performance")
        "recorder" = ,@("Music and Record", "Recorder Resources")
        "education" = ,@("Music and Record", "Music Theory and Performance")
        "folkmusic" = ,@("Music and Record", "Music Theory and Performance")
        "blues" = ,@("Music and Record", "Music Theory and Performance")
        "rockmusic" = ,@("Music and Record", "Music Theory and Performance")
        "rockandroll" = ,@("Music and Record", "Music Theory and Performance")

        # NLP tags
        "nlp" = ,@("NLP and Psychology", "Core NLP Concepts")
        "psychology" = ,@("NLP and Psychology", "Cognitive Science")
        "technique" = ,@("NLP and Psychology", "Techniques and Patterns")
        "learning" = ,@("NLP and Psychology", "Learning and Memory")

        # PKM tags
        "pkm" = ,@("Personal Knowledge Management", "PKM Systems and Methods")
        "obsidian" = ,@("Personal Knowledge Management", "Obsidian Integration")
        "knowledge" = ,@("Personal Knowledge Management", "Note-Taking and Learning")
        "productivity" = ,@("Personal Knowledge Management", "Productivity Philosophy")

        # Reading tags
        "books" = ,@("Reading and Literature", "Key Books by Topic")
        "audiobook" = ,@("Reading and Literature", "Kindle Clippings")
        "library" = ,@("Reading and Literature", "Book Index")

        # Soccer tags
        "soccer" = ,@("Soccer", "Learning the Game")
        "football" = ,@("Soccer", "Learning the Game")
        "sports" = ,@("Soccer", "Learning the Game")
        "tedlasso" = ,@("Soccer", "Ted Lasso and English Football Culture")
        "mls" = ,@("Soccer", "Major League Soccer (MLS)")
        "worldcup" = ,@("Soccer", "World Cup and International Football")

        # Social Issues tags
        "politics" = ,@("Social Issues", "Justice and Politics")
        "justice" = ,@("Social Issues", "Justice and Politics")
        "culture" = ,@("Social Issues", "Cultural Commentary")
        "peace" = ,@("Social Issues", "Peace and Unity")
        "racism" = ,@("Social Issues", "Race and Equity")

        # Travel tags
        "travel" = ,@("Travel and Exploration", "Specific Locations")
        "canal" = ,@("Travel and Exploration", "Narrowboat and Canal Travel")
        "rv" = ,@("Travel and Exploration", "RV and Alternative Living")
        "nationalpark" = ,@("Travel and Exploration", "National Parks and Nature")

        # Home and Practical Life tags
        "genealogy" = ,@("Home and Practical Life", "Genealogy")
        "diy" = ,@("Home and Practical Life", "Home Projects and Repairs")
        "gardening" = ,@("Home and Practical Life", "Gardening and Urban Farming")
        "sustainable" = ,@("Home and Practical Life", "Sustainable Building and Alternative Homes")
        "movie" = ,@("Home and Practical Life", "Entertainment & Film")
        "film" = ,@("Home and Practical Life", "Entertainment & Film")

        # Bahá'í Faith - additional subsections
        "central-figures" = ,@("Bahá'í Faith", "Central Figures")
        "institution" = ,@("Bahá'í Faith", "Bahá'í Institutions")
        "uhj" = ,@("Bahá'í Faith", "Bahá'í Institutions")

        # Recipes - additional subsections
        "ferment" = ,@("Recipes", "Fermented Foods")
        "fermented" = ,@("Recipes", "Fermented Foods")
        "kimchi" = ,@("Recipes", "Fermented Foods")
        "sauerkraut" = ,@("Recipes", "Fermented Foods")
        "condiment" = ,@("Recipes", "Sauces, Dips & Condiments")
        "sauce" = ,@("Recipes", "Sauces, Dips & Condiments")
        "beverage" = ,@("Recipes", "Beverages")
        "tea" = ,@("Recipes", "Beverages")

        # Science - additional subsections
        "space" = ,@("Science and Nature", "Space & Planetary Science")
        "nasa" = ,@("Science and Nature", "Space & Planetary Science")
        "planetary" = ,@("Science and Nature", "Space & Planetary Science")

        # Technology - additional subsections
        "ai" = ,@("Technology and Computing", "AI & Machine Learning")
        "machine-learning" = ,@("Technology and Computing", "AI & Machine Learning")
        "llm" = ,@("Technology and Computing", "AI & Machine Learning")
        "maker" = ,@("Technology and Computing", "Maker Projects")
        "arduino" = ,@("Technology and Computing", "Maker Projects")
        "raspberry-pi" = ,@("Technology and Computing", "Maker Projects")
        "robot" = ,@("Technology and Computing", "Maker Projects")
        "robotics" = ,@("Technology and Computing", "Maker Projects")
        "retro-computer" = ,@("Technology and Computing", "Retro Computing & Hardware")
        "z80" = ,@("Technology and Computing", "Retro Computing & Hardware")
        "rc2014" = ,@("Technology and Computing", "Retro Computing & Hardware")

        # NLP - additional subsections
        "metamodel" = ,@("NLP and Psychology", "Meta Model & Language")

        # Social Issues - additional subsections
        "religion" = ,@("Social Issues", "Religion & Society")
        "cult" = ,@("Social Issues", "Cult Awareness")
        "cults" = ,@("Social Issues", "Cult Awareness")

        # Travel - additional subsections
        "pilgrimage" = ,@("Travel and Exploration", "Pilgrimage")

        # ===================================================================
        # NEW TAGS ADDED 2026-01-12
        # ===================================================================

        # Bahá'í Faith - newly added subsections
        "nineyearplan" = ,@("Bahá'í Faith", "Nine Year Plan")
        "growth" = ,@("Bahá'í Faith", "Nine Year Plan")
        "teaching" = ,@("Bahá'í Faith", "Community & Service")
        "pioneering" = ,@("Bahá'í Faith", "Community & Service")
        "unity" = ,@("Bahá'í Faith", "Social Issues & Unity")
        "equity" = ,@("Bahá'í Faith", "Social Issues & Unity")
        "clippings" = ,@("Bahá'í Faith", "Clippings & Resources")
        "news" = ,@("Bahá'í Faith", "Clippings & Resources")
        "interfaith" = ,@("Bahá'í Faith", "Related Topics")

        # Finance & Investment - newly added subsections
        "finance" = ,@("Finance & Investment", "Resources & Books")
        "money" = ,@("Finance & Investment", "Financial Management")
        "management" = ,@("Finance & Investment", "Financial Management")
        "insurance" = ,@("Finance & Investment", "Insurance")

        # Health & Nutrition - newly added subsections
        "breathing" = ,@("Health & Nutrition", "Exercise & Wellness")
        "medical" = ,@("Health & Nutrition", "Health Articles & Clippings")
        "diet" = ,@("Health & Nutrition", "Resources & Indexes")

        # Home & Practical Life - newly added subsections
        "organization" = ,@("Home & Practical Life", "Life Productivity & Organization")
        "lifehacking" = ,@("Home & Practical Life", "Practical Tips & Life Hacks")
        "cooltools" = ,@("Home & Practical Life", "Practical Tips & Life Hacks")
        "sketchplanations" = ,@("Home & Practical Life", "Sketchplanations")
        "fol" = ,@("Home & Practical Life", "FOL Board Members & Contacts")
        "bod" = ,@("Home & Practical Life", "FOL Board Members & Contacts")
        "hcas" = ,@("Home & Practical Life", "Hill Country Authors Series (HCAS)")
        "charity" = @(@("Home & Practical Life", "FOL Operations & Procedures"), @("Home & Practical Life", "Giving Season & Fundraising"))
        "givingseason" = ,@("Home & Practical Life", "Giving Season & Fundraising")
        "lgl" = ,@("Home & Practical Life", "Little Green Light (FOL Database)")

        # Music & Records - newly added subsections
        "faith" = ,@("Music & Records", "Songs & Hymns")
        "vinyl" = ,@("Music & Records", "Record Labels & Resources")
        "concert" = ,@("Music & Records", "Music Performances & Articles")

        # NLP & Psychology - newly added subsections
        "reframe" = ,@("NLP & Psychology", "Reframing")
        "phobia" = ,@("NLP & Psychology", "Phobia & Trauma Work")
        "personaldevelopment" = @(@("NLP & Psychology", "Change Work"), @("NLP & Psychology", "Related Resources"))
        "levels" = ,@("NLP & Psychology", "Logical Levels")
        "language" = ,@("NLP & Psychology", "Language Patterns")
        "modeling" = ,@("NLP & Psychology", "Strategies & Modeling")
        "mentalecology" = ,@("NLP & Psychology", "Outcomes & Ecology")
        "compuserve" = ,@("NLP & Psychology", "Historical NLP Resources (CompuServe Era)")
        "training" = ,@("NLP & Psychology", "Andrew Moreno Series")

        # Personal Knowledge Management - newly added subsections
        "workflow" = ,@("Personal Knowledge Management", "GTD and Productivity Methods")
        "pencil" = ,@("Personal Knowledge Management", "Writing Tools")
        "journal" = ,@("Personal Knowledge Management", "Writing Tools")
        "tags" = ,@("Personal Knowledge Management", "Indexes and Tags")
        "template" = ,@("Personal Knowledge Management", "Templates")

        # Reading and Literature - newly added subsections
        "spirituality" = ,@("Reading and Literature", "Spirituality and Religion")
        "socialissues" = ,@("Reading and Literature", "Social Issues")
        "craft" = ,@("Reading and Literature", "Crafts and Making")
        "fiction" = ,@("Reading and Literature", "Fiction and Literature")
        "reading" = ,@("Reading and Literature", "All Book Notes")
        "web" = ,@("Reading and Literature", "Chrome/Web Clippings")

        # Recipes - newly added subsections
        "nutrition" = @(@("Health & Nutrition", "Plant-Based Nutrition"), @("Recipes", "Related"))

        # Science and Nature - newly added subsections
        "meteorology" = ,@("Science and Nature", "Weather")

        # Soccer - newly added subsections
        "fifaworldcup" = ,@("Soccer", "2022 Qatar World Cup")

        # Social Issues - newly added subsections
        "social" = ,@("Social Issues", "Culture")

        # Technology & Computers - newly added subsections
        "computer" = @(@("Technology & Computers", "Computer Sciences"), @("Technology & Computers", "Computing Fundamentals"), @("Technology & Computers", "Chromebook"))
        "microsoftaccess" = ,@("Technology & Computers", "Databases & Access")
        "db" = ,@("Technology & Computers", "Databases & Access")
        "microsoftexcel" = ,@("Technology & Computers", "Excel VBA")
        "hardware" = @(@("Technology & Computers", "Hardware & Electronics"), @("Technology & Computers", "Devices & Hardware"))
        "electronics" = ,@("Technology & Computers", "Hardware & Electronics")
        "howto" = ,@("Technology & Computers", "Troubleshooting & Guides")
        "media" = ,@("Technology & Computers", "Media & Entertainment")
        "entertainment" = ,@("Technology & Computers", "Media & Entertainment")
        "design" = ,@("Technology & Computers", "UX & Design")

        # Travel and Exploration - newly added subsections
        "washingtonstate" = ,@("Travel and Exploration", "Washington State")
        "santafe" = ,@("Travel and Exploration", "Santa Fe")
        "texas" = ,@("Travel and Exploration", "Atlanta")
        "europe" = ,@("Travel and Exploration", "Moscow")
        "japan" = ,@("Travel and Exploration", "Japan")
        "index" = @(@("Music & Records", "Index"), @("Personal Knowledge Management", "Indexes and Tags"), @("Science and Nature", "Index"), @("Travel and Exploration", "Travel Index"))
    }

    return $tagMap
}

#endregion Tag Extraction Functions

#region Core Functions

<#
.SYNOPSIS
    Retrieves all orphan files from the Obsidian vault.

.DESCRIPTION
    Scans the entire vault to identify "orphan" files - markdown files that have
    no incoming wiki-style links from any other file in the vault. These files
    are isolated and would benefit from being connected to relevant MOCs.

.OUTPUTS
    Array of hashtables containing orphan file information:
    - Name: The file name without extension
    - RelativePath: Path relative to vault root
    - FullPath: Absolute file system path
    - Folder: Parent folder name
    - SizeBytes: File size in bytes (for display purposes)
#>
function Get-OrphanFiles {
    Write-Log "Scanning vault for all markdown files..." -Level INFO

    # $mdFiles: Collection of all markdown files found recursively in the vault
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    Write-Log "Found $($mdFiles.Count) total markdown files" -Level INFO

    # $fileMap: Hashtable mapping lowercase file names to their full paths
    # Used for resolving wiki-style links to actual files
    $fileMap = @{}
    foreach ($file in $mdFiles) {
        # $baseName: File name without the .md extension
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        # Store with lowercase key for case-insensitive matching
        $fileMap[$baseName.ToLower()] = $file.FullName
    }

    # $linkedFiles: Hashtable tracking which files have at least one incoming link
    # Key = lowercase filename, Value = $true if the file is linked to
    $linkedFiles = @{}

    Write-Log "Scanning files for outgoing links to identify linked targets..." -Level INFO

    # Scan each file's content for wiki-style links [[target]] or [[target|alias]]
    foreach ($file in $mdFiles) {
        # Skip Orphan Files.md - its links shouldn't count toward marking files as non-orphans
        # This file is auto-generated by the maintenance script and links to all orphans
        if ($file.Name -eq "Orphan Files.md") { continue }

        # $content: The raw text content of the current file being scanned
        # Note: Using -LiteralPath to handle files with special characters like [[ in names
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # $linkMatches: All wiki-style link matches found in the file content
        # Pattern matches [[link]] and [[link|display text]] formats
        $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

        foreach ($match in $linkMatches) {
            # $linkTarget: The target file referenced in the wiki link
            # Note: Do NOT trim - filenames may have intentional trailing spaces
            $linkTarget = $match.Groups[1].Value

            # Remove any heading anchors (e.g., [[File#Heading]] -> File)
            if ($linkTarget -match '^([^#]+)#') {
                $linkTarget = $matches[1]
            }

            # Extract just the filename from paths (e.g., [[Folder/File]] -> File)
            # Obsidian links can include folder paths, but we match on filename only
            if ($linkTarget -match '[/\\]') {
                # $linkTarget: Extract just the filename portion after the last slash
                $linkTarget = Split-Path $linkTarget -Leaf
            }

            # $linkTargetLower: Lowercase version for case-insensitive lookup
            # Trim only leading spaces, preserve trailing (some filenames have trailing spaces)
            $linkTargetLower = $linkTarget.TrimStart().ToLower()

            # Mark this target file as having an incoming link
            if ($fileMap.ContainsKey($linkTargetLower)) {
                $linkedFiles[$linkTargetLower] = $true
            }
        }
    }

    Write-Log "Identified $($linkedFiles.Count) files with incoming links" -Level INFO

    # $orphans: Array to collect all orphan file information
    $orphans = @()

    # Check each file to see if it's an orphan (no incoming links)
    foreach ($file in $mdFiles) {
        # $baseName: File name without extension for lookup
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        # $relativePath: Path relative to vault root (for display and linking)
        $relativePath = $file.FullName.Replace($vaultPath + "\", "")

        # Check if this file should be skipped based on folder exclusions
        # $skip: Boolean flag indicating whether to exclude this file
        $skip = $false
        foreach ($folder in $skipFolders) {
            if ($relativePath -match "^$([regex]::Escape($folder))") {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }

        # If file has no incoming links, it's an orphan
        if (-not $linkedFiles.ContainsKey($baseName.ToLower())) {
            $orphans += @{
                Name = $baseName                              # File name without extension
                RelativePath = $relativePath                   # Path relative to vault
                FullPath = $file.FullName                     # Absolute file system path
                Folder = Split-Path $relativePath -Parent      # Parent folder path
                SizeBytes = $file.Length                       # File size for sorting
            }
        }
    }

    Write-Log "Found $($orphans.Count) orphan files (no incoming links)" -Level INFO
    return $orphans
}

<#
.SYNOPSIS
    Tests if a file matches a specific MOC subsection based on curated keywords.

.DESCRIPTION
    Analyzes a file's name, content, and tags to determine if it logically belongs
    to a specific MOC subsection. Uses the static $subsectionKeywords lookup.

    Matching is done in multiple tiers:
    1. Keyword in filename - HIGH confidence
    2. Keyword in heading - HIGH confidence
    3. Tag match - HIGH confidence
    4. Keyword in content body - MEDIUM confidence

.PARAMETER FileName
    The name of the file (without extension) to analyze.

.PARAMETER Content
    The raw text content of the file.

.PARAMETER Tags
    Array of tags extracted from the file.

.PARAMETER Keywords
    Array of keywords for the specific MOC subsection.

.PARAMETER MOCName
    The name of the MOC being matched against.

.PARAMETER SubsectionName
    The name of the subsection being matched against.

.OUTPUTS
    Hashtable with:
    - Match: Boolean indicating if the subsection matched
    - Reason: String explaining why the match occurred
    - Confidence: 'HIGH' or 'MEDIUM' confidence level
#>
function Test-FileAgainstSubsection {
    param(
        # $FileName: The file name to check against keywords
        [string]$FileName,

        # $Content: The file's text content to check against patterns
        [string]$Content,

        # $Tags: Array of tags extracted from the file
        [array]$Tags,

        # $Keywords: Array of keywords for the MOC subsection
        [array]$Keywords,

        # $MOCName: The name of the MOC for tag matching
        [string]$MOCName,

        # $SubsectionName: The name of the subsection for tag matching
        [string]$SubsectionName
    )

    # $searchName: Lowercase filename for case-insensitive keyword matching
    $searchName = $FileName.ToLower()

    # $searchContent: Lowercase content for case-insensitive content matching
    $searchContent = if ($Content) { $Content.ToLower() } else { "" }

    # Check tag-based matching first (using tag-to-subsection map)
    # $tagMap: The mapping of tags to MOC subsections
    $tagMap = Get-TagToSubsectionMap

    foreach ($tag in $Tags) {
        if ($tagMap.ContainsKey($tag)) {
            # $mappings: Array of MOC/Subsection pairs for this tag
            $mappings = $tagMap[$tag]

            foreach ($mapping in $mappings) {
                # $mapMOC: The MOC name from the mapping
                # $mapSubsection: The subsection name from the mapping
                $mapMOC = $mapping[0]
                $mapSubsection = $mapping[1]

                # Check if this mapping matches the current MOC/subsection
                if ($mapMOC -eq $MOCName -and $mapSubsection -eq $SubsectionName) {
                    return @{
                        Match = $true
                        Reason = "Tag match (static map): #$tag"
                        Confidence = 'HIGH'
                    }
                }
            }
        }
    }

    # Dynamic tag-to-keyword matching
    # Check if any file tag matches any keyword for this subsection
    # This catches tags that aren't in the static map but match subsection keywords
    foreach ($tag in $Tags) {
        foreach ($keyword in $Keywords) {
            if (-not $keyword) { continue }

            # $keywordLower: Lowercase version of keyword for comparison
            $keywordLower = $keyword.ToLower()

            # $keywordForTag: Keyword with spaces replaced by hyphens (tags use hyphens)
            # e.g., "plant-based" tag should match "plant-based" keyword
            $keywordForTag = $keywordLower -replace '\s+', '-'

            # Exact match: tag equals keyword or hyphenated version
            if ($tag -eq $keywordLower -or $tag -eq $keywordForTag) {
                return @{
                    Match = $true
                    Reason = "Tag matches keyword: #$tag"
                    Confidence = 'HIGH'
                }
            }

            # Partial match: tag contains keyword as component (for compound tags)
            # e.g., #vegan-recipe contains "vegan", #plant-based-nutrition contains "plant-based"
            # Using word boundaries with hyphen as delimiter
            $escapedKeyword = [regex]::Escape($keywordLower)
            $escapedKeywordHyphen = [regex]::Escape($keywordForTag)
            if ($tag -match "(^|-)$escapedKeyword(-|$)" -or $tag -match "(^|-)$escapedKeywordHyphen(-|$)") {
                return @{
                    Match = $true
                    Reason = "Tag contains keyword: #$tag ~ '$keyword'"
                    Confidence = 'HIGH'
                }
            }
        }
    }

    # Check keywords from the subsection lookup
    foreach ($keyword in $Keywords) {
        if (-not $keyword) { continue }

        # $escapedKeyword: Regex-safe version of the keyword
        $escapedKeyword = [regex]::Escape($keyword.ToLower())

        # $wordBoundaryPattern: Pattern with word boundaries for whole-word matching
        # This prevents "RV" from matching "SuRVivors" or "service"
        $wordBoundaryPattern = "\b$escapedKeyword\b"

        # Check if keyword appears in filename (HIGH confidence)
        # Using word boundaries to ensure whole-word matches only
        if ($searchName -match $wordBoundaryPattern) {
            return @{
                Match = $true
                Reason = "Keyword in filename: '$keyword'"
                Confidence = 'HIGH'
            }
        }

        # Check if keyword appears prominently in content (in a heading)
        # $headingPattern: Pattern to find keyword in markdown headings (whole word only)
        $headingPattern = "^#+\s+.*\b$escapedKeyword\b"
        if ($searchContent -match $headingPattern) {
            return @{
                Match = $true
                Reason = "Keyword in heading: '$keyword'"
                Confidence = 'HIGH'
            }
        }
    }

    # Check for keywords in body content (MEDIUM confidence)
    # Requires 2+ keyword matches to reduce false positives from generic words
    # $mediumMatchCount: Counter for keywords found in content
    $mediumMatchCount = 0

    # $matchedKeywords: Array to track which keywords matched
    $matchedKeywords = @()

    foreach ($keyword in $Keywords) {
        if (-not $keyword) { continue }

        # $escapedKeyword: Regex-safe version of the keyword
        $escapedKeyword = [regex]::Escape($keyword.ToLower())

        # Check for keyword as whole word in content (using word boundaries)
        # $wordPattern: Pattern to match keyword as whole word
        $wordPattern = "\b$escapedKeyword\b"
        if ($searchContent -match $wordPattern) {
            $mediumMatchCount++
            $matchedKeywords += $keyword
        }
    }

    # Only return MEDIUM match if 2+ keywords matched (reduces false positives)
    if ($mediumMatchCount -ge 2) {
        # $displayKeywords: First 3 matched keywords for display in reason
        $displayKeywords = $matchedKeywords | Select-Object -First 3
        return @{
            Match = $true
            Reason = "Multiple keywords in content ($mediumMatchCount): $($displayKeywords -join ', ')"
            Confidence = 'MEDIUM'
        }
    }

    # No match found (or only 1 keyword - not enough for MEDIUM confidence)
    return @{
        Match = $false
        Reason = $null
        Confidence = $null
    }
}

#region AI Suitability Check Functions

<#
.SYNOPSIS
    Invokes the Claude API to analyze text content.

.DESCRIPTION
    Makes a REST API call to the Anthropic Claude API. Uses the ANTHROPIC_API_KEY
    environment variable for authentication. Returns Claude's response text.

.PARAMETER Prompt
    The prompt/instructions to send to Claude.

.PARAMETER Content
    The content to be analyzed by Claude.

.PARAMETER MaxTokens
    Maximum tokens in the response. Defaults to 500.

.OUTPUTS
    String containing Claude's response, or $null if the call fails.
#>
function Invoke-ClaudeAPI {
    param(
        # $Prompt: The system/user prompt for Claude
        [string]$Prompt,

        # $Content: The content to analyze
        [string]$Content,

        # $MaxTokens: Maximum response tokens
        [int]$MaxTokens = 500
    )

    # $apiKey: The Anthropic API key from environment variable
    $apiKey = $env:ANTHROPIC_API_KEY

    if (-not $apiKey) {
        Write-Log "ERROR: ANTHROPIC_API_KEY environment variable not set" -Level ERROR
        return $null
    }

    # $apiUrl: The Claude API endpoint
    $apiUrl = "https://api.anthropic.com/v1/messages"

    # $headers: HTTP headers for the API request
    $headers = @{
        "x-api-key" = $apiKey
        "anthropic-version" = "2023-06-01"
        "content-type" = "application/json"
    }

    # Truncate content if too long (keep first 3000 chars to stay within token limits)
    # $truncatedContent: Content truncated to fit API limits
    $truncatedContent = if ($Content.Length -gt 3000) {
        $Content.Substring(0, 3000) + "`n... [content truncated]"
    } else {
        $Content
    }

    # $body: The request body for Claude API
    $body = @{
        model = "claude-sonnet-4-20250514"
        max_tokens = $MaxTokens
        messages = @(
            @{
                role = "user"
                content = "$Prompt`n`n---`nCONTENT TO ANALYZE:`n$truncatedContent"
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        # $response: The API response from Claude
        $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body -ContentType "application/json; charset=utf-8"

        # Extract and return the text response
        if ($response.content -and $response.content.Count -gt 0) {
            return $response.content[0].text
        }
        return $null
    }
    catch {
        Write-Log "Claude API error: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Uses Claude AI to validate if a note truly belongs in a proposed subsection.

.DESCRIPTION
    After keyword matching suggests a subsection, this function uses Claude AI
    to evaluate whether the note's content actually fits the topic. If the match
    is deemed unsuitable, Claude suggests the correct subsection from the
    available options.

.PARAMETER OrphanName
    The name of the orphan file being evaluated.

.PARAMETER OrphanContent
    The content of the orphan file.

.PARAMETER ProposedMOC
    The MOC name suggested by keyword matching.

.PARAMETER ProposedSubsection
    The subsection name suggested by keyword matching.

.PARAMETER AllSubsections
    Hashtable of all available MOCs and their subsections for suggesting alternatives.
    Format: @{ "MOC Name" = @("Subsection1", "Subsection2", ...) }

.OUTPUTS
    Hashtable with:
    - IsSuitable: Boolean indicating if the proposed match is appropriate
    - CorrectMOC: If not suitable, the suggested correct MOC name (or $null)
    - CorrectSubsection: If not suitable, the suggested correct subsection (or $null)
    - Reason: Explanation for the decision
#>
function Test-SubsectionSuitabilityWithAI {
    param(
        # $OrphanName: Name of the orphan file
        [string]$OrphanName,

        # $OrphanContent: Content of the orphan file
        [string]$OrphanContent,

        # $ProposedMOC: The MOC suggested by keyword matching
        [string]$ProposedMOC,

        # $ProposedSubsection: The subsection suggested by keyword matching
        [string]$ProposedSubsection,

        # $AllSubsections: All available MOC/subsection combinations
        [hashtable]$AllSubsections
    )

    # Build a formatted list of all available MOCs and subsections for Claude
    # $subsectionList: Formatted string listing all MOC/subsection options
    $subsectionList = ""
    foreach ($mocName in $AllSubsections.Keys | Sort-Object) {
        $subsectionList += "`n$mocName :"
        foreach ($sub in $AllSubsections[$mocName]) {
            $subsectionList += "`n  - $sub"
        }
    }

    # $prompt: The prompt asking Claude to evaluate the match
    $prompt = @"
You are evaluating whether a note belongs in a specific MOC (Map of Content) subsection in an Obsidian knowledge vault.

FILE NAME: $OrphanName
PROPOSED LOCATION: $ProposedMOC / $ProposedSubsection

Your task:
1. Read the note content below
2. Determine if this note TRULY belongs in "$ProposedMOC / $ProposedSubsection"
3. If NOT suitable, suggest the BEST alternative from the available subsections

Available MOCs and Subsections:
$subsectionList

RESPOND IN EXACTLY THIS FORMAT (no other text):
SUITABLE: YES or NO
CORRECT_MOC: [MOC name if NO, otherwise leave blank]
CORRECT_SUBSECTION: [Subsection name if NO, otherwise leave blank]
REASON: [Brief 1-sentence explanation]

Examples:
- If suitable: "SUITABLE: YES`nCORRECT_MOC:`nCORRECT_SUBSECTION:`nREASON: The note discusses Bahá'í prayers and teachings."
- If not suitable: "SUITABLE: NO`nCORRECT_MOC: Health & Nutrition`nCORRECT_SUBSECTION: Plant-Based Nutrition`nREASON: This is a vegan recipe, not related to technology."
"@

    # Call Claude API for evaluation
    # $response: Claude's response to the suitability check
    $response = Invoke-ClaudeAPI -Prompt $prompt -Content $OrphanContent -MaxTokens 300

    if (-not $response) {
        Write-Log "AI suitability check failed - API returned no response" -Level WARNING
        # Return suitable=true to fall back to keyword-based matching
        return @{
            IsSuitable = $true
            CorrectMOC = $null
            CorrectSubsection = $null
            Reason = "AI check unavailable - using keyword match"
        }
    }

    # Parse Claude's response
    # $isSuitable: Boolean extracted from SUITABLE: line
    $isSuitable = $response -match "SUITABLE:\s*YES"

    # $correctMOC: MOC name extracted from CORRECT_MOC: line
    $correctMOC = $null
    if ($response -match "CORRECT_MOC:\s*(.+?)(?:`n|$)") {
        $correctMOC = $matches[1].Trim()
        if ($correctMOC -eq "" -or $correctMOC -eq "N/A") {
            $correctMOC = $null
        }
    }

    # $correctSubsection: Subsection name extracted from CORRECT_SUBSECTION: line
    $correctSubsection = $null
    if ($response -match "CORRECT_SUBSECTION:\s*(.+?)(?:`n|$)") {
        $correctSubsection = $matches[1].Trim()
        if ($correctSubsection -eq "" -or $correctSubsection -eq "N/A") {
            $correctSubsection = $null
        }
    }

    # $reason: Explanation extracted from REASON: line
    $reason = "No reason provided"
    if ($response -match "REASON:\s*(.+?)(?:`n|$)") {
        $reason = $matches[1].Trim()
    }

    return @{
        IsSuitable = $isSuitable
        CorrectMOC = $correctMOC
        CorrectSubsection = $correctSubsection
        Reason = $reason
    }
}

<#
.SYNOPSIS
    Builds a hashtable of all available MOCs and their subsections.

.DESCRIPTION
    Iterates through all discovered MOCs and extracts their subsections,
    returning a hashtable that maps MOC names to arrays of subsection names.
    This is used to provide Claude with the complete list of available
    categorization options.

.PARAMETER MOCs
    Array of MOC objects from Get-AllMOCs function.

.OUTPUTS
    Hashtable mapping MOC names to arrays of subsection names.
#>
function Get-AllAvailableSubsections {
    param(
        # $MOCs: Array of MOC objects
        [array]$MOCs
    )

    # $result: Hashtable to store MOC -> subsections mapping
    $result = @{}

    foreach ($moc in $MOCs) {
        # Read MOC content to extract subsections
        # $mocContent: The full text content of the MOC file
        $mocContent = Get-Content -LiteralPath $moc.FullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

        if ($mocContent) {
            # $subsections: Array of subsection names from this MOC
            $subsections = Get-MOCSubsections -Content $mocContent

            # Only include subsections that have keywords defined
            # $subsectionsWithKeywords: Filtered list of subsections that have keyword mappings
            $subsectionsWithKeywords = @()
            foreach ($sub in $subsections) {
                $keywords = Get-SubsectionKeywords -MOCName $moc.Name -SubsectionName $sub
                if ($keywords.Count -gt 0) {
                    $subsectionsWithKeywords += $sub
                }
            }

            if ($subsectionsWithKeywords.Count -gt 0) {
                $result[$moc.Name] = $subsectionsWithKeywords
            }
        }
    }

    return $result
}

#endregion AI Suitability Check Functions

<#
.SYNOPSIS
    Adds a link to a specific subsection within a MOC file.

.DESCRIPTION
    Modifies an EXISTING MOC file to include a UNIDIRECTIONAL link to the orphan file
    under a specific subsection heading. The link is inserted immediately after
    the subsection heading (## Heading).

    IMPORTANT: This function NEVER creates new MOC files. It only modifies
    existing MOC files. Multiple validation checks ensure the MOC file
    exists before any write operations occur.

.PARAMETER MOCPath
    The relative path to the MOC file (without .md extension).

.PARAMETER SubsectionName
    The name of the subsection to add the link under.

.PARAMETER OrphanName
    The display name for the orphan file link.

.PARAMETER OrphanRelPath
    The relative path to the orphan file.

.OUTPUTS
    Boolean indicating success ($true) or failure/skip ($false).
#>
function Add-LinkToSubsection {
    param(
        # $MOCPath: Relative path to MOC file (no extension)
        [string]$MOCPath,

        # $SubsectionName: The ## heading name to insert the link after
        [string]$SubsectionName,

        # $OrphanName: Display text for the orphan link
        [string]$OrphanName,

        # $OrphanRelPath: Relative path to orphan file
        [string]$OrphanRelPath
    )

    # $fullMOCPath: Absolute file system path to the MOC file
    $fullMOCPath = Join-Path $vaultPath "$MOCPath.md"

    # CRITICAL VALIDATION #1: Verify MOC file exists before any operations
    # Using -LiteralPath for paths with special characters
    # Using -PathType Leaf to ensure it's a FILE, not a directory
    if (-not (Test-Path -LiteralPath $fullMOCPath -PathType Leaf)) {
        Write-Log "  BLOCKED: MOC file does not exist: $MOCPath" -Level ERROR
        Write-Log "  Expected path: $fullMOCPath" -Level ERROR
        Write-Log "  This script ONLY links to existing MOCs - it will NOT create new ones" -Level ERROR
        return $false
    }

    try {
        # $content: Current content of the MOC file
        # Using -LiteralPath for paths with special characters in names
        $content = Get-Content -LiteralPath $fullMOCPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

        # VALIDATION #2: Ensure we actually read content from the file
        # An empty or null result indicates something is wrong
        if (-not $content) {
            Write-Log "  BLOCKED: Could not read content from MOC: $fullMOCPath" -Level ERROR
            return $false
        }

        # $linkPath: The Obsidian-compatible path (forward slashes, no extension)
        # Obsidian requires forward slashes in links, even on Windows
        # Computed early so we can use it for duplicate detection
        $linkPath = $OrphanRelPath.Replace('\', '/').Replace('.md', '')

        # Check if orphan is already linked anywhere in the MOC using the full path
        # $escapedLinkPath: Regex-safe version of the full link path
        $escapedLinkPath = [regex]::Escape($linkPath)
        if ($content -match "\[\[$escapedLinkPath") {
            Write-Log "  Link to orphan already exists in MOC" -Level WARNING
            return $false
        }

        # Also check by orphan name for more robust duplicate detection
        # $escapedOrphanName: Regex-safe version of the orphan name
        # Check if orphan name appears as LINK TARGET (left side of |), not just display text
        # Matches: [[OrphanName]] or [[OrphanName|display]] but NOT [[Other|OrphanName]]
        $escapedOrphanName = [regex]::Escape($OrphanName)
        if ($content -match "\[\[$escapedOrphanName(\]\]|\|)") {
            Write-Log "  Link to orphan (by name) already exists in MOC" -Level WARNING
            return $false
        }

        # $newLink: Formatted wiki link with display text
        $newLink = "- [[$linkPath|$OrphanName]]"

        # $subsectionPattern: Pattern to find the specific subsection heading
        # Escape the subsection name for regex safety
        $escapedSubsection = [regex]::Escape($SubsectionName)
        $subsectionPattern = "(## $escapedSubsection[^\n]*\n)"

        # Check if the subsection exists in the MOC
        if ($content -notmatch $subsectionPattern) {
            Write-Log "  WARNING: Subsection '$SubsectionName' not found in MOC" -Level WARNING
            Write-Log "  Creating subsection at end of MOC content..." -Level INFO

            # Find the best place to insert the new subsection
            # Try to insert before --- or **Tags:** sections
            if ($content -match '(?m)^---\s*$') {
                # Insert before the first --- separator
                $content = $content -replace '(?m)(^---\s*$)', "## $SubsectionName`n$newLink`n`n`$1"
            } elseif ($content -match '\*\*Tags:\*\*') {
                # Insert before **Tags:**
                $content = $content -replace '(\*\*Tags:\*\*)', "## $SubsectionName`n$newLink`n`n`$1"
            } else {
                # Append to end of file
                $content = $content.TrimEnd() + "`n`n## $SubsectionName`n$newLink`n"
            }
        } else {
            # Insert link immediately after the subsection header
            $content = $content -replace $subsectionPattern, "`$1$newLink`n"
        }

        # Write changes unless in dry-run mode
        if (-not $DryRun) {
            # CRITICAL VALIDATION #3: Final safety check before writing
            # Verify the file STILL exists right before we write to prevent
            # any race conditions or edge cases from creating new files
            if (-not (Test-Path -LiteralPath $fullMOCPath -PathType Leaf)) {
                Write-Log "  BLOCKED: MOC file disappeared before write: $fullMOCPath" -Level ERROR
                return $false
            }

            # Use -LiteralPath for consistent path handling with special characters
            Set-Content -LiteralPath $fullMOCPath -Value $content -Encoding UTF8 -NoNewline
        }
        return $true
    }
    catch {
        Write-Log "  Error adding link to subsection: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Validates that a MOC file exists on disk.

.DESCRIPTION
    Helper function to verify that a MOC file exists before attempting
    any operations that reference it. This is a central validation point
    to ensure the script NEVER attempts to create new MOC files.

.PARAMETER MOCRelativePath
    The relative path to the MOC file (without .md extension).

.OUTPUTS
    Boolean - $true if MOC exists, $false if not.
#>
function Test-MOCExists {
    param(
        # $MOCRelativePath: Relative path to MOC (without .md extension)
        [string]$MOCRelativePath
    )

    # $fullPath: Complete absolute path to the MOC file
    $fullPath = Join-Path $vaultPath "$MOCRelativePath.md"

    # Use -LiteralPath to handle special characters in path
    # Use -PathType Leaf to ensure it's a file, not a directory
    return (Test-Path -LiteralPath $fullPath -PathType Leaf)
}

#endregion Core Functions

#region Main Execution

# Initialize the log with a session header
Write-LogSection "RANDOM ORPHAN MOC LINKER v4.0 - SUBSECTION-BASED KEYWORDS"
Write-Log "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
Write-Log "Vault path: $vaultPath" -Level INFO
Write-Log "Log path: $LogPath" -Level INFO

# CRITICAL SAFETY NOTICE: Display at startup to ensure operator awareness
Write-Log "" -Level INFO
Write-Log "*** SAFETY CONSTRAINT: This script ONLY links to EXISTING MOCs ***" -Level WARNING
Write-Log "*** New MOC files will NEVER be created by this script ***" -Level WARNING
Write-Log "*** Links are UNIDIRECTIONAL: MOC subsection -> orphan only ***" -Level WARNING
Write-Log "" -Level INFO

if ($DryRun) {
    Write-Log "*** DRY RUN MODE ENABLED - No files will be modified ***" -Level WARNING
}

Write-Log "Processing up to $Count orphan(s) in this run" -Level INFO

# $totalOrphansProcessed: Counter for total orphans processed across all iterations
$totalOrphansProcessed = 0

# $totalLinksCreated: Counter for total links created across all iterations
$totalLinksCreated = 0

# $allProcessedOrphans: Array to track all orphans processed in this session
$allProcessedOrphans = @()

# $orphansWithLinks: Array to track orphans that actually received at least one link
$orphansWithLinks = @()

# $allLinkedSubsections: Array to track all MOC/subsection combinations that received links
# Each entry is a hashtable with OrphanName, MOCName, and SubsectionName
$allLinkedSubsections = @()

# Step 1: Discover all MOC files in the vault
Write-LogSection "STEP 1: Discovering MOC Files"

# $allMOCs: Array of all discovered MOC files with their metadata
$allMOCs = Get-AllMOCs

if ($allMOCs.Count -eq 0) {
    Write-Log "No MOC files found in vault. Exiting." -Level ERROR
    exit 1
}

# Log all discovered MOCs
Write-Log "Discovered MOCs:" -Level INFO
foreach ($moc in $allMOCs) {
    Write-Log "  - $($moc.Name)" -Level INFO
}

# Build the available subsections map for AI suitability checking (unless SkipAI is set)
# $allAvailableSubsections: Hashtable mapping MOC names to arrays of subsection names
$allAvailableSubsections = $null
if (-not $SkipAI) {
    $allAvailableSubsections = Get-AllAvailableSubsections -MOCs $allMOCs
    Write-Log "Built subsection map for AI validation ($($allAvailableSubsections.Count) MOCs with keywords)" -Level INFO
} else {
    Write-Log "AI suitability checking is DISABLED (-SkipAI flag)" -Level WARNING
}

# Step 2: Find all orphan files in the vault
Write-LogSection "STEP 2: Finding Orphan Files"

# $orphanFiles: Array of all orphan files with metadata
$orphanFiles = Get-OrphanFiles

if ($orphanFiles.Count -eq 0) {
    Write-Log "No orphan files found in vault. Exiting." -Level WARNING
    exit 0
}

# $shuffledOrphans: Orphan files in random order for processing
# Using [System.Collections.ArrayList] to allow removal of items during iteration
$shuffledOrphans = [System.Collections.ArrayList]@($orphanFiles | Sort-Object { Get-Random })

# $orphansToProcess: The actual number of orphans we'll process (min of Count and available)
$orphansToProcess = [Math]::Min($Count, $shuffledOrphans.Count)

Write-Log "Will process $orphansToProcess of $($shuffledOrphans.Count) orphan files (random selection)" -Level INFO

#==============================================================================
# MAIN PROCESSING LOOP - Process up to $Count orphans
#==============================================================================
for ($iteration = 1; $iteration -le $orphansToProcess; $iteration++) {

    # Step 3: Get a random orphan from the remaining list
    Write-LogSection "ORPHAN $iteration of $orphansToProcess - Random Selection"

    # $randomOrphan: A randomly selected orphan file (first in shuffled list)
    $randomOrphan = $shuffledOrphans[0]

    # $sizeKB: File size converted to kilobytes for display
    $sizeKB = [math]::Round($randomOrphan.SizeBytes / 1024, 2)

    Write-Log "Random orphan file selected:" -Level SUCCESS
    Write-Log "  Name: $($randomOrphan.Name)" -Level INFO
    Write-Log "  Path: $($randomOrphan.RelativePath)" -Level INFO
    Write-Log "  Size: $sizeKB KB ($($randomOrphan.SizeBytes) bytes)" -Level INFO
    Write-Log "  Folder: $($randomOrphan.Folder)" -Level INFO

    # Step 4: Read the orphan file content and extract tags
    Write-LogSection "ORPHAN $iteration - Analyzing Content and Tags"

    # $orphanContent: The full text content of the random orphan file
    $orphanContent = Get-Content -Path $randomOrphan.FullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    if (-not $orphanContent) {
        Write-Log "ERROR: Could not read file content for $($randomOrphan.Name)" -Level ERROR
        # Remove this orphan from the list and continue to the next
        $shuffledOrphans.RemoveAt(0)
        continue
    }

    # $orphanTags: Array of tags extracted from the orphan file
    $orphanTags = Get-FileTags -Content $orphanContent

    # Virtual tag: Treat files in "09 - Kindle Clippings" folder as having the "books" tag
    # $isKindleClipping: Boolean indicating if file is in the Kindle Clippings folder
    $isKindleClipping = $randomOrphan.Folder -like "*09 - Kindle Clippings*"
    if ($isKindleClipping -and $orphanTags -notcontains "books") {
        # Add "books" tag virtually without modifying the actual file
        $orphanTags += "books"
        Write-Log "Added virtual 'books' tag (file is in 09 - Kindle Clippings folder)" -Level INFO
    }

    Write-Log "Extracted $($orphanTags.Count) tag(s) from file:" -Level INFO
    foreach ($tag in $orphanTags) {
        Write-Log "  - #$tag" -Level INFO
    }

    # $contentPreview: First 500 characters of content for logging purposes
    $contentPreview = if ($orphanContent.Length -gt 500) {
        $orphanContent.Substring(0, 500) + "..."
    } else {
        $orphanContent
    }
    Write-Log "Content preview (first 500 chars):" -Level INFO
    Write-Log $contentPreview -Level INFO -NoConsole

    # Step 5: Match against all MOC subsections
    Write-LogSection "ORPHAN $iteration - Matching Against MOC Subsections"

# $allMatches: Array to store ALL matches before confidence filtering
$allMatches = @()

# Iterate through each MOC and its subsections
foreach ($moc in $allMOCs) {
    Write-Log "Analyzing MOC: $($moc.Name)" -Level INFO

    # Read MOC content to extract subsections
    # $mocContent: The full text content of the MOC file
    $mocContent = Get-Content -LiteralPath $moc.FullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    if (-not $mocContent) {
        Write-Log "  WARNING: Could not read MOC content" -Level WARNING
        continue
    }

    # $mocSubsections: Array of subsection names extracted from the MOC
    $mocSubsections = Get-MOCSubsections -Content $mocContent

    Write-Log "  Found $($mocSubsections.Count) subsection(s)" -Level INFO -NoConsole

    foreach ($subsection in $mocSubsections) {
        # $subsectionKeywordList: Keywords for this specific subsection
        $subsectionKeywordList = Get-SubsectionKeywords -MOCName $moc.Name -SubsectionName $subsection

        if ($subsectionKeywordList.Count -eq 0) {
            Write-Log "    No keywords defined for: $subsection" -Level INFO -NoConsole
            continue
        }

        # $matchResult: Result of testing the orphan against this subsection
        $matchResult = Test-FileAgainstSubsection -FileName $randomOrphan.Name `
                                                   -Content $orphanContent `
                                                   -Tags $orphanTags `
                                                   -Keywords $subsectionKeywordList `
                                                   -MOCName $moc.Name `
                                                   -SubsectionName $subsection

        if ($matchResult.Match) {
            # $confidenceLabel: Display label indicating match strength
            $confidenceLabel = "[$($matchResult.Confidence)]"
            Write-Log "  MATCH $confidenceLabel $($moc.Name) / $subsection - $($matchResult.Reason)" -Level SUCCESS

            $allMatches += @{
                MOCPath = $moc.RelativePath       # Path for linking
                MOCName = $moc.FileName           # Full MOC filename
                DisplayName = $moc.Name           # Display name
                SubsectionName = $subsection      # The matched subsection
                Reason = $matchResult.Reason      # Why this matched
                Confidence = $matchResult.Confidence  # HIGH or MEDIUM
            }
        }
    }
}

# Filter matches based on confidence level to reduce false positives
# Priority: HIGH > MEDIUM (use highest available)

# $hasHighConfidence: Boolean indicating if at least one HIGH confidence match exists
$hasHighConfidence = ($allMatches | Where-Object { $_.Confidence -eq 'HIGH' }).Count -gt 0

if ($hasHighConfidence) {
    # Keep only HIGH confidence matches
    # $filteredCount: Number of matches being filtered out
    $filteredCount = ($allMatches | Where-Object { $_.Confidence -ne 'HIGH' }).Count

    if ($filteredCount -gt 0) {
        Write-Log "" -Level INFO
        Write-Log "Filtering out $filteredCount MEDIUM-confidence matches (HIGH matches found)" -Level WARNING
    }

    # $matchedSubsections: Final array containing only HIGH confidence matches
    $matchedSubsections = @($allMatches | Where-Object { $_.Confidence -eq 'HIGH' })
} else {
    # Use all matches (including MEDIUM confidence) when nothing better exists
    # $matchedSubsections: Final array containing all matches
    $matchedSubsections = $allMatches

    if ($allMatches.Count -gt 0) {
        Write-Log "" -Level INFO
        Write-Log "Using MEDIUM confidence matches (no HIGH confidence available)" -Level WARNING
    }
}

# Report matching results
if ($matchedSubsections.Count -eq 0) {
    Write-Log "No MOC subsections matched this file." -Level WARNING
    Write-Log "The file may need manual review for appropriate categorization." -Level WARNING
    Write-Log "Skipping to next orphan..." -Level INFO

    # Remove this orphan from the list and continue to next iteration
    $shuffledOrphans.RemoveAt(0)
    continue
}

Write-Log "Found $($matchedSubsections.Count) matching subsection(s)" -Level SUCCESS

# Step 6: Validate matched MOCs exist on disk
Write-LogSection "STEP 6: Validating Matched MOCs Exist"
Write-Log "Verifying all matched MOCs exist on disk..." -Level INFO

# $validatedMatches: Array containing only matches where MOC exists
$validatedMatches = @()

# $invalidCount: Counter for MOCs that failed validation
$invalidCount = 0

foreach ($match in $matchedSubsections) {
    if (Test-MOCExists -MOCRelativePath $match.MOCPath) {
        $validatedMatches += $match
    } else {
        $invalidCount++
        Write-Log "  EXCLUDED: MOC does not exist: $($match.MOCPath)" -Level WARNING
    }
}

if ($invalidCount -gt 0) {
    Write-Log "Excluded $invalidCount non-existent MOC(s) from linking" -Level WARNING
}

if ($validatedMatches.Count -eq 0) {
    Write-Log "No valid MOCs found after existence validation." -Level WARNING
    Write-Log "Skipping to next orphan..." -Level INFO

    # Remove this orphan from the list and continue to next iteration
    $shuffledOrphans.RemoveAt(0)
    continue
}

# Update matchedSubsections to only contain validated matches
# $matchedSubsections: Now contains only validated matches
$matchedSubsections = $validatedMatches

Write-Log "Validated $($matchedSubsections.Count) match(es) for existing MOCs" -Level SUCCESS

# Step 6.5: AI Suitability Check (if enabled)
# This step uses Claude AI to verify that keyword matches are contextually appropriate
# and relocates notes to correct subsections if the AI determines a mismatch
if (-not $SkipAI -and $allAvailableSubsections -and $matchedSubsections.Count -gt 0) {
    Write-LogSection "STEP 6.5: AI Suitability Verification"
    Write-Log "Using Claude AI to verify match suitability..." -Level INFO

    # $aiVerifiedMatches: Array to store matches that passed AI verification or were corrected
    $aiVerifiedMatches = @()

    # $relocatedCount: Counter for matches that were relocated to different subsections
    $relocatedCount = 0

    # $rejectedCount: Counter for matches rejected by AI with no valid alternative
    $rejectedCount = 0

    foreach ($match in $matchedSubsections) {
        Write-Log "AI checking: $($match.DisplayName) / $($match.SubsectionName)" -Level INFO

        # $aiResult: Result of AI suitability check
        $aiResult = Test-SubsectionSuitabilityWithAI -OrphanName $randomOrphan.Name `
                                                      -OrphanContent $orphanContent `
                                                      -ProposedMOC $match.DisplayName `
                                                      -ProposedSubsection $match.SubsectionName `
                                                      -AllSubsections $allAvailableSubsections

        if ($aiResult.IsSuitable) {
            # AI confirms the match is appropriate
            Write-Log "  AI CONFIRMED: $($aiResult.Reason)" -Level SUCCESS
            $aiVerifiedMatches += $match
        }
        else {
            # AI says the match is not suitable
            Write-Log "  AI REJECTED: $($aiResult.Reason)" -Level WARNING

            # Check if AI suggested a correction
            if ($aiResult.CorrectMOC -and $aiResult.CorrectSubsection) {
                Write-Log "  AI SUGGESTS: $($aiResult.CorrectMOC) / $($aiResult.CorrectSubsection)" -Level INFO

                # Find the MOC object for the suggested correction
                # $correctedMOC: The MOC object matching the AI's suggestion
                $correctedMOC = $allMOCs | Where-Object { $_.Name -eq $aiResult.CorrectMOC } | Select-Object -First 1

                if ($correctedMOC) {
                    # Verify the suggested subsection exists in the MOC
                    # $correctedMOCContent: Content of the corrected MOC
                    $correctedMOCContent = Get-Content -LiteralPath $correctedMOC.FullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    # $correctedSubsections: Subsections available in the corrected MOC
                    $correctedSubsections = Get-MOCSubsections -Content $correctedMOCContent

                    if ($correctedSubsections -contains $aiResult.CorrectSubsection) {
                        # Create a corrected match object
                        # $correctedMatch: New match object with AI-suggested location
                        $correctedMatch = @{
                            MOCPath = $correctedMOC.RelativePath
                            MOCName = $correctedMOC.FileName
                            DisplayName = $correctedMOC.Name
                            SubsectionName = $aiResult.CorrectSubsection
                            Reason = "AI relocated: $($aiResult.Reason)"
                            Confidence = 'AI-CORRECTED'
                        }

                        Write-Log "  RELOCATED to: $($aiResult.CorrectMOC) / $($aiResult.CorrectSubsection)" -Level SUCCESS
                        $aiVerifiedMatches += $correctedMatch
                        $relocatedCount++
                    }
                    else {
                        Write-Log "  ERROR: Suggested subsection '$($aiResult.CorrectSubsection)' not found in MOC" -Level WARNING
                        $rejectedCount++
                    }
                }
                else {
                    Write-Log "  ERROR: Suggested MOC '$($aiResult.CorrectMOC)' not found" -Level WARNING
                    $rejectedCount++
                }
            }
            else {
                # AI rejected but no alternative suggested
                Write-Log "  SKIPPED: No valid alternative suggested by AI" -Level WARNING
                $rejectedCount++
            }
        }
    }

    # Update matchedSubsections with AI-verified/corrected matches
    $matchedSubsections = $aiVerifiedMatches

    Write-Log "" -Level INFO
    Write-Log "AI Verification Summary:" -Level INFO
    Write-Log "  Confirmed: $($aiVerifiedMatches.Count - $relocatedCount)" -Level SUCCESS
    Write-Log "  Relocated: $relocatedCount" -Level WARNING
    Write-Log "  Rejected: $rejectedCount" -Level WARNING

    if ($matchedSubsections.Count -eq 0) {
        Write-Log "No valid matches after AI verification. Skipping to next orphan..." -Level WARNING
        $shuffledOrphans.RemoveAt(0)
        continue
    }
}
elseif ($SkipAI) {
    Write-Log "Skipping AI suitability check (-SkipAI flag set)" -Level INFO
}

# Step 7: Create unidirectional links (MOC subsection -> orphan)
Write-LogSection "STEP 7: Creating Unidirectional Links (MOC -> Orphan)"

# $linksCreated: Counter for successfully created links
$linksCreated = 0

# $subsectionsUpdated: Array tracking which subsections were modified
$subsectionsUpdated = @()

foreach ($match in $matchedSubsections) {
    Write-Log "Processing: $($match.DisplayName) / $($match.SubsectionName)" -Level INFO
    Write-Log "  Confidence: $($match.Confidence)" -Level INFO
    Write-Log "  Reason: $($match.Reason)" -Level INFO

    # Add link FROM the MOC subsection TO the orphan file (unidirectional)
    # $linkResult: Boolean indicating if link was added successfully
    $linkResult = Add-LinkToSubsection -MOCPath $match.MOCPath `
                                        -SubsectionName $match.SubsectionName `
                                        -OrphanName $randomOrphan.Name `
                                        -OrphanRelPath $randomOrphan.RelativePath

    if ($linkResult) {
        Write-Log "  -> Added link to $($match.DisplayName) / $($match.SubsectionName)" -Level SUCCESS
        $linksCreated++
        $subsectionsUpdated += "$($match.DisplayName) / $($match.SubsectionName)"

        # Track this successful link globally for final summary
        # Store as hashtable to preserve orphan-to-subsection relationship
        $allLinkedSubsections += @{
            OrphanName = $randomOrphan.Name
            MOCName = $match.DisplayName
            SubsectionName = $match.SubsectionName
        }
    }
}

# Step 8: Per-Orphan Summary
    Write-LogSection "ORPHAN $iteration SUMMARY"

    Write-Log "Orphan file processed: $($randomOrphan.Name)" -Level INFO
    Write-Log "File size: $sizeKB KB" -Level INFO
    Write-Log "Tags found: $($orphanTags -join ', ')" -Level INFO
    Write-Log "Subsections matched: $($matchedSubsections.Count)" -Level INFO
    Write-Log "Links created: $linksCreated" -Level SUCCESS
    if ($linksCreated -gt 0) {
        Write-Log "Subsections updated:" -Level INFO
        foreach ($subsection in $subsectionsUpdated) {
            Write-Log "  - $subsection" -Level INFO
        }
    }

    # Update tracking counters
    # $totalOrphansProcessed: Incremented after each successful orphan processing
    $totalOrphansProcessed++

    # $totalLinksCreated: Add this iteration's links to the running total
    $totalLinksCreated += $linksCreated

    # $allProcessedOrphans: Track the names of all processed orphans for final summary
    $allProcessedOrphans += $randomOrphan.Name

    # Track orphans that actually received at least one successful link
    if ($linksCreated -gt 0) {
        $orphansWithLinks += $randomOrphan.Name
    }

    # Remove the processed orphan from the list so next iteration gets a fresh random selection
    # This ensures we don't process the same orphan twice
    $shuffledOrphans.RemoveAt(0)

    Write-Log "Removed '$($randomOrphan.Name)' from orphan list. $($shuffledOrphans.Count) orphans remaining." -Level INFO

}
#==============================================================================
# END OF MAIN PROCESSING LOOP
#==============================================================================

# Final session summary (after all orphans processed)
Write-LogSection "FINAL SESSION SUMMARY"

Write-Log "Orphans requested: $Count" -Level INFO
Write-Log "Orphans processed: $totalOrphansProcessed" -Level INFO
Write-Log "Orphans successfully linked: $($orphansWithLinks.Count)" -Level SUCCESS
Write-Log "Total links created: $totalLinksCreated" -Level SUCCESS

# Only show successful link details if any links were created
if ($totalLinksCreated -gt 0) {
    Write-Log "Successfully linked files:" -Level INFO
    foreach ($orphanName in $orphansWithLinks) {
        Write-Log "  - $orphanName" -Level INFO
    }
    Write-Log "MOC/Subsections that received links:" -Level INFO
    foreach ($link in $allLinkedSubsections) {
        Write-Log "  - $($link.OrphanName) -> $($link.MOCName) / $($link.SubsectionName)" -Level INFO
    }
}

if ($DryRun) {
    Write-Log "*** DRY RUN - No actual changes were made to files ***" -Level WARNING
}

Write-Log "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO

# Final console output summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OPERATION COMPLETE (v4.1 Multi-Orphan)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Orphans Requested: $Count" -ForegroundColor White
Write-Host "Orphans Processed: $totalOrphansProcessed" -ForegroundColor White
Write-Host "Orphans Successfully Linked: $($orphansWithLinks.Count)" -ForegroundColor Green
Write-Host "Total Links Created: $totalLinksCreated" -ForegroundColor Green

# Only show successful link details if any links were created
if ($totalLinksCreated -gt 0) {
    Write-Host "Successfully Linked Files:" -ForegroundColor White
    foreach ($orphanName in $orphansWithLinks) {
        Write-Host "  - $orphanName" -ForegroundColor Green
    }
    Write-Host "MOC/Subsections Linked:" -ForegroundColor White
    foreach ($link in $allLinkedSubsections) {
        Write-Host "  - $($link.OrphanName) -> $($link.MOCName) / $($link.SubsectionName)" -ForegroundColor Green
    }
}
Write-Host "Link Direction: MOC subsection -> Orphan (unidirectional)" -ForegroundColor Yellow
Write-Host "Log File: $LogPath" -ForegroundColor Gray
Write-Host ""

#endregion Main Execution
