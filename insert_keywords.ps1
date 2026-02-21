# Insert approved keywords into link_largest_orphan.ps1
# This script adds new keywords to each subsection

$scriptPath = "C:\Users\awt\link_largest_orphan.ps1"

# Define new keywords for each MOC/Subsection
# Structure: "MOC|Subsection" => @("keyword1", "keyword2", ...)
$newKeywords = @{
    # Bahá'í Faith
    "Bahá'í Faith|Central Figures" = @(
        "Mírzá Husayn-Alí Núrí", "Siyyid Alí-Muhammad", "Mírzá Mihdí", "Navváb", "Bahíyyih Khánum",
        "Greatest Holy Leaf", "Purest Branch", "Herald", "Promised One", "Revelation",
        "Apostle of Bahá'u'lláh", "Letters of the Living", "Declaration of the Báb"
    )
    "Bahá'í Faith|Core Teachings" = @(
        "unity of mankind", "unity of God", "unity of religion", "Manifestation of God",
        "Most Great Peace", "Lesser Peace", "World Order", "New World Order",
        "elimination of extremes of wealth and poverty", "universal auxiliary language",
        "harmony of science and religion", "independent investigation of truth",
        "elimination of all forms of prejudice", "universal compulsory education"
    )
    "Bahá'í Faith|Administrative Guidance" = @(
        "Feast", "Nineteen Day Feast", "delegates", "electoral process", "no nominations",
        "no campaigning", "spiritual assembly jurisdiction", "cluster agency",
        "Area Teaching Committee", "regional Bahá'í council", "annual convention",
        "unit convention", "electoral unit", "electoral district"
    )
    "Bahá'í Faith|Bahá'í Institutions" = @(
        "International Teaching Centre", "Continental Board of Counsellors", "Auxiliary Board member",
        "assistant to Auxiliary Board", "Bahá'í International Community", "Office of External Affairs",
        "Bahá'í World Centre", "Arc buildings", "Seat of the Universal House of Justice",
        "Institution of the Learned", "Institution of the Rulers", "twin pillars"
    )
    "Bahá'í Faith|Nine Year Plan" = @(
        "society-building power", "protagonists of change", "Milestone 3 cluster",
        "intensive programme of growth", "movement of populations", "educational process",
        "community-building process", "release of society-building power", "protagonists",
        "home-front pioneer", "international pioneer", "25-year series of plans"
    )
    "Bahá'í Faith|Ridván Messages" = @(
        "King of Festivals", "Most Great Festival", "Garden of Ridván", "Najíbíyyih Garden",
        "first day of Ridván", "ninth day of Ridván", "twelfth day of Ridván",
        "annual Ridván message", "Declaration of Bahá'u'lláh", "April 21", "twelve-day period"
    )
    "Bahá'í Faith|Community & Service" = @(
        "tutor", "animator", "facilitator", "core activity", "neighbourhood",
        "home visit", "expansion phase", "consolidation phase", "reflection meeting",
        "cluster coordinator", "institute coordinator", "accompaniment", "capacity building"
    )
    "Bahá'í Faith|Social Issues & Unity" = @(
        "elimination of prejudice", "unity in diversity", "oneness of humanity",
        "organic unity", "world citizenship", "global civilization", "collective security",
        "world tribunal", "world parliament", "world executive", "federalism"
    )
    "Bahá'í Faith|Bahá'í Books & Resources" = @(
        "Tablets of Bahá'u'lláh", "Kitáb-i-Íqán", "Book of Certitude", "Epistle to the Son of the Wolf",
        "Proclamation of Bahá'u'lláh", "Summons of the Lord of Hosts", "Gems of Divine Mysteries",
        "Call of the Divine Beloved", "Tabernacle of Unity", "Days of Remembrance"
    )
    "Bahá'í Faith|Clippings & Resources" = @(
        "Bahá'í World News Service", "BWNS", "Bahá'í International Community",
        "BIC statement", "One Country newsletter", "Bahá'í World magazine",
        "persecution in Iran", "Yaran", "imprisoned Bahá'ís", "human rights violations"
    )
    "Bahá'í Faith|Related Topics" = @(
        "Parliament of the World's Religions", "interfaith dialogue", "United Religions Initiative",
        "comparative religion", "world peace conference", "disarmament", "collective security",
        "global governance", "sustainable development", "climate change ethics"
    )

    # Finance & Investment
    "Finance & Investment|Investing Strategies" = @(
        "price-to-earnings ratio", "P/E ratio", "market capitalization", "blue chip stocks",
        "small cap", "mid cap", "large cap", "sector rotation", "momentum investing",
        "contrarian investing", "FIRE movement", "financial independence", "total return",
        "risk tolerance", "asset class", "equity", "fixed income", "alternative investments"
    )
    "Finance & Investment|Resources & Books" = @(
        "A Random Walk Down Wall Street", "The Little Book of Common Sense Investing",
        "One Up on Wall Street", "Peter Lynch", "John Bogle", "Jack Bogle",
        "The Psychology of Money", "Morgan Housel", "The Millionaire Next Door",
        "Your Money or Your Life", "I Will Teach You to Be Rich", "Ramit Sethi"
    )
    "Finance & Investment|Financial Management" = @(
        "50/30/20 rule", "zero-based budgeting", "envelope system", "sinking fund",
        "high-yield savings account", "money market account", "certificate of deposit", "CD ladder",
        "debt avalanche", "debt snowball", "FICO score", "credit utilization",
        "liquid assets", "net worth statement", "personal balance sheet"
    )
    "Finance & Investment|Tax Software" = @(
        "Form 1040", "Schedule A", "Schedule C", "itemized deduction", "standard deduction",
        "adjusted gross income", "AGI", "MAGI", "earned income tax credit", "EITC",
        "child tax credit", "FreeTaxUSA", "IRS Free File", "IRS Direct File",
        "quarterly estimated tax", "Form 1099", "tax bracket", "marginal tax rate"
    )
    "Finance & Investment|Insurance" = @(
        "bodily injury liability", "property damage liability", "comprehensive coverage",
        "collision coverage", "uninsured motorist", "underinsured motorist", "PIP",
        "personal injury protection", "umbrella policy", "declarations page",
        "actual cash value", "replacement cost", "bundling discount", "claims history"
    )

    # Health & Nutrition
    "Health & Nutrition|Plant-Based Nutrition" = @(
        "whole food", "minimally processed", "SOS-free", "no added oil",
        "nutrient density", "caloric density", "fiber intake", "phytonutrients",
        "antioxidants", "plant protein sources", "complete protein", "amino acids",
        "B12 supplementation", "vitamin D", "omega-3 fatty acids", "flaxseed"
    )
    "Health & Nutrition|Key Research & Books" = @(
        "T. Colin Campbell", "Caldwell Esselstyn", "Dean Ornish", "Joel Fuhrman",
        "Michael Greger", "NutritionFacts.org", "heart disease reversal",
        "lifestyle medicine", "Blue Zones", "Dan Buettner", "longevity diet",
        "Adventist Health Study", "EPIC-Oxford study", "Nurses Health Study"
    )
    "Health & Nutrition|Medical & Health" = @(
        "primary care physician", "specialist referral", "preventive care", "screening",
        "diagnostic imaging", "MRI", "CT scan", "blood panel", "lipid panel",
        "hemoglobin A1C", "blood pressure", "BMI", "body mass index",
        "chronic disease management", "acute care", "outpatient", "inpatient"
    )
    "Health & Nutrition|Exercise & Wellness" = @(
        "aerobic exercise", "anaerobic exercise", "resistance training", "HIIT",
        "functional fitness", "flexibility training", "mobility work", "range of motion",
        "resting heart rate", "target heart rate zone", "VO2 max", "metabolic equivalent",
        "active recovery", "overtraining", "progressive overload", "periodization"
    )
    "Health & Nutrition|Health Articles & Clippings" = @(
        "clinical trial results", "peer-reviewed", "meta-analysis", "systematic review",
        "epidemiological study", "cohort study", "randomized controlled trial", "RCT",
        "public health guidelines", "CDC recommendations", "WHO guidelines",
        "health policy", "medical breakthrough", "drug approval"
    )
    "Health & Nutrition|WFPB Resources" = @(
        "Forks Over Knives", "PlantPure Nation", "What the Health", "Game Changers",
        "Dr. McDougall's Health & Medical Center", "TrueNorth Health Center",
        "Physicians Committee for Responsible Medicine", "PCRM", "21-Day Kickstart",
        "starch-based diet", "low-fat vegan", "high-carb low-fat", "HCLF"
    )
    "Health & Nutrition|Clippings & Resources" = @(
        "Happy Cow", "vegan dining guide", "plant-based meal delivery",
        "vegan meal kit", "plant-based food trends", "vegan market growth",
        "alternative protein", "plant-based meat", "dairy alternatives", "oat milk"
    )
    "Health & Nutrition|Resources & Indexes" = @(
        "nutrition database", "USDA FoodData Central", "Cronometer", "MyFitnessPal",
        "calorie tracking", "macro tracking", "micronutrient analysis",
        "glycemic index", "glycemic load", "anti-inflammatory foods"
    )

    # Home & Practical Life
    "Home & Practical Life|Genealogy" = @(
        "autosomal DNA", "Y-DNA", "mtDNA", "mitochondrial DNA", "haplogroup",
        "centiMorgan", "genetic distance", "DNA match", "shared DNA", "chromosome browser",
        "endogamy", "pedigree collapse", "genetic genealogy", "FamilySearch",
        "Find A Grave", "Ancestry.com", "23andMe", "MyHeritage", "GEDCOM"
    )
    "Home & Practical Life|Home Projects & Repairs" = @(
        "load-bearing wall", "stud finder", "drywall repair", "spackle", "joint compound",
        "primer", "caulking", "weatherstripping", "HVAC filter", "circuit breaker",
        "GFCI outlet", "PEX plumbing", "shut-off valve", "water heater maintenance",
        "grout cleaning", "tile replacement", "wood filler", "wood putty"
    )
    "Home & Practical Life|Sustainable Building & Alternative Homes" = @(
        "thermal mass", "passive solar design", "photovoltaic panels", "solar thermal",
        "greywater recycling", "rainwater harvesting", "composting toilet",
        "natural insulation", "hemp-lime", "hempcrete", "adobe construction",
        "rammed earth", "living roof", "green roof", "net-zero energy"
    )
    "Home & Practical Life|Gardening & Urban Farming" = @(
        "companion planting", "crop rotation", "succession planting", "no-till gardening",
        "hugelkultur", "lasagna gardening", "sheet mulching", "cover crops",
        "seed starting", "hardening off", "transplanting", "USDA hardiness zone",
        "microgreens", "vertical gardening", "hydroponics", "aquaponics"
    )
    "Home & Practical Life|RV & Mobile Living" = @(
        "full-time RVing", "workamping", "boondocking", "dry camping", "shore power",
        "dump station", "black water", "grey water", "fresh water tank",
        "slide-out", "fifth wheel", "Class A", "Class B", "Class C",
        "travel trailer", "toy hauler", "tow vehicle", "weight distribution hitch"
    )
    "Home & Practical Life|Entertainment & Film" = @(
        "streaming service", "watchlist", "film genre", "documentary film",
        "limited series", "miniseries", "anthology series", "binge-watching",
        "film score", "cinematography", "screenplay", "director's cut",
        "Criterion Collection", "arthouse cinema", "foreign film", "subtitle"
    )
    "Home & Practical Life|Life Productivity & Organization" = @(
        "time blocking", "Pomodoro Technique", "batch processing", "deep work",
        "shallow work", "energy management", "decision fatigue", "context switching",
        "morning routine", "evening routine", "habit stacking", "atomic habits",
        "friction reduction", "activation energy", "keystone habit"
    )
    "Home & Practical Life|Practical Tips & Life Hacks" = @(
        "life optimization", "problem-solving", "troubleshooting guide",
        "maintenance schedule", "home inventory", "important documents organization",
        "password manager", "digital declutter", "email management", "inbox zero",
        "meal prep", "batch cooking", "emergency preparedness", "go bag"
    )
    "Home & Practical Life|Sketchplanations" = @(
        "visual thinking", "concept illustration", "explanatory diagram",
        "visual learning", "graphic explanation", "mental model", "visual metaphor",
        "knowledge visualization", "information design", "educational graphics"
    )

    # Music & Record
    "Music & Record|Recorder Resources" = @(
        "fipple flute", "windway", "labium", "voicing", "block",
        "consort of recorders", "SATB ensemble", "Ganassi fingering", "historical fingering",
        "Mollenhauer", "Moeck", "Yamaha recorder", "Aulos", "Zen-On",
        "recorder method book", "recorder repertoire", "descant recorder"
    )
    "Music & Record|Music Theory & Performance" = @(
        "diatonic scale", "chromatic scale", "major mode", "minor mode", "modal scales",
        "Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian",
        "interval", "tritone", "perfect fifth", "diminished chord", "augmented chord",
        "cadence", "authentic cadence", "plagal cadence", "deceptive cadence"
    )
    "Music & Record|Songs & Hymns" = @(
        "sacred music", "congregational singing", "four-part harmony", "SATB",
        "hymnal", "hymnody", "gospel music", "spiritual", "Negro spiritual",
        "choral anthem", "a cappella", "madrigal", "part song", "round", "canon"
    )
    "Music & Record|Record Labels & Resources" = @(
        "indie record label", "independent music", "music distribution",
        "vinyl pressing", "LP", "EP", "single", "album release",
        "music streaming", "Bandcamp", "SoundCloud", "music discovery"
    )
    "Music & Record|Index" = @(
        "music catalog", "discography", "music library", "listening log",
        "music journal", "album notes", "liner notes", "track listing"
    )
    "Music & Record|Clippings & Resources" = @(
        "early music", "period instrument", "historically informed performance", "HIP",
        "baroque performance practice", "ornamentation", "trills", "mordents",
        "music article", "instrument review", "concert review", "album review"
    )
    "Music & Record|Music Performances & Articles" = @(
        "live performance", "concert hall", "recital", "chamber music",
        "world music", "folk tradition", "ethnomusicology", "musical anthropology",
        "musical improvisation", "jazz improvisation", "call and response",
        "polyrhythm", "syncopation", "groove"
    )

    # NLP & Psychology
    "NLP & Psychology|Core NLP Concepts" = @(
        "representational systems", "VAK", "visual", "auditory", "kinesthetic",
        "submodalities", "predicates", "sensory acuity", "state management",
        "map of reality", "territory", "presuppositions of NLP", "well-formedness conditions"
    )
    "NLP & Psychology|Techniques & Patterns" = @(
        "swish pattern", "visual squash", "parts integration", "belief change pattern",
        "Disney strategy", "new behavior generator", "spelling strategy",
        "motivation strategy", "decision-making strategy", "future pacing"
    )
    "NLP & Psychology|Reframing" = @(
        "context reframing", "content reframing", "meaning reframing", "outframing",
        "preframing", "deframing", "counter-example", "chunk up", "chunk down",
        "lateral chunking", "hierarchy of ideas", "logical levels of change"
    )
    "NLP & Psychology|Phobia & Trauma Work" = @(
        "visual-kinesthetic dissociation", "VK dissociation", "double dissociation",
        "fast phobia model", "reimprinting", "timeline therapy", "core transformation",
        "eye movement integration", "EMDR-like techniques", "resource anchoring"
    )
    "NLP & Psychology|Change Work" = @(
        "personal breakthrough", "limiting belief", "limiting decision",
        "significant emotional event", "SEE", "gestalt", "reimprint",
        "integration", "generative change", "remedial change", "unconscious mind"
    )
    "NLP & Psychology|Anchoring & States" = @(
        "resource anchor", "collapse anchors", "stacking anchors", "chaining anchors",
        "sliding anchor", "spatial anchor", "tonal anchor", "kinesthetic anchor",
        "positive state", "resourceful state", "break state", "neutral state"
    )
    "NLP & Psychology|Logical Levels" = @(
        "Robert Dilts", "neurological levels", "alignment process", "congruence",
        "mission", "vision", "purpose", "spiritual level", "identity level",
        "beliefs and values level", "capabilities level", "behavior level", "environment level"
    )
    "NLP & Psychology|Language Patterns" = @(
        "Milton Model", "artfully vague", "nominalization", "unspecified verb",
        "modal operator", "universal quantifier", "lost performative",
        "tag question", "double bind", "embedded suggestion", "temporal predicate"
    )
    "NLP & Psychology|Strategies & Modeling" = @(
        "elicitation", "strategy elicitation", "eye accessing cues",
        "eye patterns", "lead system", "reference system", "internal dialogue",
        "representational sequence", "decision point", "exit point", "test"
    )
    "NLP & Psychology|Outcomes & Ecology" = @(
        "well-formed outcome", "SMART goals", "positive outcome", "sensory evidence",
        "self-initiated", "self-maintained", "resources identified", "first step",
        "ecology check", "secondary gain", "systemic thinking", "consequences"
    )
    "NLP & Psychology|Communication & Influence" = @(
        "pacing", "leading", "matching", "mirroring", "cross-over mirroring",
        "backtracking", "perceptual positions", "first position", "second position",
        "third position", "meta position", "associated", "dissociated"
    )
    "NLP & Psychology|Cognitive Science" = @(
        "System 1 and System 2", "cognitive bias", "confirmation bias", "anchoring bias",
        "availability heuristic", "representativeness heuristic", "loss aversion",
        "prospect theory", "framing effect", "sunk cost fallacy", "endowment effect"
    )
    "NLP & Psychology|Learning & Memory" = @(
        "encoding", "storage", "retrieval", "working memory", "long-term memory",
        "episodic memory", "semantic memory", "procedural memory", "spaced repetition",
        "interleaving", "elaboration", "dual coding", "chunking", "mnemonic"
    )
    "NLP & Psychology|Meta Model & Language" = @(
        "deletions", "distortions", "generalizations", "deep structure", "surface structure",
        "transformational grammar", "nominalization recovery", "referential index",
        "comparative deletion", "mind reading", "complex equivalence", "cause-effect"
    )
    "NLP & Psychology|NLP Technique Overview" = @(
        "intervention design", "presenting problem", "desired state", "resources",
        "leverage point", "pattern interrupt", "installation", "testing", "calibration"
    )
    "NLP & Psychology|NLP for Programmers & Technical Applications" = @(
        "cognitive load", "debugging mindset", "problem decomposition",
        "state machine", "pattern matching", "refactoring thinking",
        "API for the mind", "mental debugging", "cognitive optimization"
    )
    "NLP & Psychology|Historical NLP Resources (CompuServe Era)" = @(
        "alt.psychology.nlp", "NLP newsgroup", "NLP mailing list",
        "early NLP community", "NLP pioneers", "Richard Bandler", "John Grinder",
        "Leslie Cameron-Bandler", "David Gordon", "Robert Dilts origins"
    )
    "NLP & Psychology|Andrew Moreno Series" = @(
        "NLP practitioner journal", "skill development", "practice log",
        "NLP exercises", "daily practice", "integration exercises"
    )
    "NLP & Psychology|NLP Theory Discussions" = @(
        "epistemology of NLP", "modeling methodology", "structure of subjective experience",
        "representational tracking", "minimal cues", "utilization", "rapport building"
    )
    "NLP & Psychology|Related Resources" = @(
        "somatic experiencing", "body-based therapy", "polyvagal theory",
        "Stephen Porges", "Peter Levine", "nervous system regulation",
        "vagal tone", "window of tolerance", "co-regulation"
    )

    # Personal Knowledge Management
    "Personal Knowledge Management|Vault Analysis & Structure" = @(
        "graph analysis", "node degree", "orphan notes", "hub notes",
        "backlink analysis", "link density", "cluster analysis", "vault statistics",
        "file naming convention", "folder structure", "flat structure", "nested folders"
    )
    "Personal Knowledge Management|PKM Systems & Methods" = @(
        "PARA method", "Projects Areas Resources Archives", "CODE framework",
        "Capture Organize Distill Express", "progressive summarization",
        "evergreen notes", "atomic notes", "literature notes", "permanent notes",
        "reference notes", "fleeting notes", "concept notes", "hub notes"
    )
    "Personal Knowledge Management|Obsidian Integration" = @(
        "Obsidian plugin", "community plugin", "core plugin", "Dataview",
        "Templater", "QuickAdd", "Periodic Notes", "Calendar plugin",
        "Excalidraw", "Kanban", "Tasks plugin", "graph view", "local graph"
    )
    "Personal Knowledge Management|Note-Taking & Learning" = @(
        "Cornell method", "outline method", "mapping method", "charting method",
        "sentence method", "active recall", "elaborative interrogation",
        "self-explanation", "retrieval practice", "testing effect", "generation effect"
    )
    "Personal Knowledge Management|Productivity Philosophy" = @(
        "essentialism", "Greg McKeown", "digital minimalism", "attention management",
        "time affluence", "chronotype", "ultradian rhythm", "circadian rhythm",
        "maker's schedule", "manager's schedule", "flow state", "peak performance"
    )
    "Personal Knowledge Management|GTD & Productivity Methods" = @(
        "capture", "clarify", "organize", "reflect", "engage", "weekly review",
        "someday/maybe", "waiting for", "reference material", "tickler file",
        "natural planning model", "runway", "10,000 feet", "30,000 feet", "50,000 feet"
    )
    "Personal Knowledge Management|Writing Tools" = @(
        "journaling practice", "morning pages", "bullet journal", "BuJo",
        "rapid logging", "signifiers", "collections", "migration",
        "pen rotation", "ink collection", "fountain pen maintenance", "nib types"
    )
    "Personal Knowledge Management|Indexes & Tags" = @(
        "folksonomy", "controlled vocabulary", "hierarchical tags", "nested tags",
        "tag taxonomy", "ontology", "metadata", "properties", "frontmatter",
        "YAML frontmatter", "aliases", "MOC", "Map of Content", "index note"
    )
    "Personal Knowledge Management|Templates" = @(
        "note template", "daily note template", "meeting notes template",
        "project template", "book notes template", "article template",
        "Templater syntax", "dynamic templates", "template variables", "date formatting"
    )
    "Personal Knowledge Management|Resources" = @(
        "PKM community", "Obsidian Discord", "Obsidian forum", "PKM newsletter",
        "digital garden", "public Zettelkasten", "Learn in Public", "working with the garage door up"
    )

    # Reading & Literature
    "Reading & Literature|Key Books by Topic" = @(
        "book annotation", "marginalia", "reading notes", "book summary",
        "key takeaways", "actionable insights", "book club", "reading group",
        "bestseller", "Pulitzer Prize", "National Book Award", "Booker Prize"
    )
    "Reading & Literature|Productivity & Learning" = @(
        "speed reading", "meta-learning", "ultralearning", "Scott Young",
        "learning how to learn", "deliberate practice", "Anders Ericsson",
        "10000 hour rule", "skill acquisition", "mastery", "expertise"
    )
    "Reading & Literature|Psychology & Thinking" = @(
        "behavioral economics", "Dan Ariely", "Richard Thaler", "nudge theory",
        "choice architecture", "bounded rationality", "Herbert Simon",
        "mental models", "Shane Parrish", "Farnam Street", "first principles"
    )
    "Reading & Literature|Health & Nutrition" = @(
        "nutrition book", "health memoir", "medical narrative", "patient story",
        "health transformation", "lifestyle change", "healing journey",
        "chronic illness narrative", "recovery story"
    )
    "Reading & Literature|Spirituality & Religion" = @(
        "contemplative literature", "mystical writing", "sacred texts",
        "wisdom literature", "spiritual memoir", "pilgrimage narrative",
        "religious history", "comparative theology", "interfaith reading"
    )
    "Reading & Literature|Social Issues" = @(
        "social commentary", "investigative journalism", "longform journalism",
        "narrative nonfiction", "creative nonfiction", "literary journalism",
        "reportage", "immersion journalism", "New Journalism"
    )
    "Reading & Literature|Technology" = @(
        "tech book", "programming book", "computer science", "AI book",
        "technology ethics", "digital society", "future of technology",
        "tech history", "Silicon Valley", "startup culture"
    )
    "Reading & Literature|Travel & Adventure" = @(
        "travel memoir", "adventure narrative", "expedition account",
        "travelogue", "travel writing", "place-based writing",
        "nature writing", "outdoor literature", "wilderness narrative"
    )
    "Reading & Literature|Science & Nature" = @(
        "popular science", "science communication", "science writing",
        "nature essay", "environmental writing", "climate literature",
        "cli-fi", "ecological writing", "natural history"
    )
    "Reading & Literature|Crafts & Making" = @(
        "maker movement", "craftspersonship", "artisan skills", "handmade",
        "traditional crafts", "folk arts", "craft revival", "slow making",
        "workshop book", "how-to guide", "project book"
    )
    "Reading & Literature|Fiction & Literature" = @(
        "literary fiction", "contemporary fiction", "genre fiction",
        "short story collection", "novella", "novel", "saga", "series",
        "debut novel", "award-winning fiction", "book-to-film adaptation"
    )
    "Reading & Literature|Organization & Lifestyle" = @(
        "decluttering", "minimalism", "simple living", "intentional living",
        "hygge", "lagom", "wabi-sabi", "slow living", "mindful living",
        "home organization", "life design", "lifestyle design"
    )
    "Reading & Literature|All Book Notes" = @(
        "reading tracker", "book log", "reading journal", "Goodreads",
        "StoryGraph", "LibraryThing", "reading statistics", "books read",
        "reading goal", "reading challenge", "TBR pile", "to be read"
    )
    "Reading & Literature|Kindle Clippings" = @(
        "Kindle highlights", "Kindle notes", "clippings.txt", "Readwise",
        "highlight export", "annotation sync", "digital marginalia",
        "ebook annotation", "highlight organization", "quote collection"
    )
    "Reading & Literature|Chrome/Web Clippings" = @(
        "web clipper", "Pocket", "Instapaper", "Raindrop.io", "Notion Web Clipper",
        "article save", "read later", "offline reading", "web archive",
        "Wayback Machine", "article distillation", "reader mode"
    )
    "Reading & Literature|Book Index" = @(
        "personal library", "home library", "book catalog", "library catalog",
        "Libib", "book database", "ISBN", "book metadata", "library organization"
    )

    # Recipes
    "Recipes|Related" = @(
        "meal planning", "weekly menu", "batch cooking", "food prep",
        "recipe scaling", "ingredient substitution", "dietary modification",
        "allergy-friendly", "nut-free", "gluten-free", "soy-free"
    )
    "Recipes|Soups & Stews" = @(
        "minestrone", "gazpacho", "borscht", "pho", "ramen broth",
        "miso soup", "posole", "pozole", "ribollita", "mulligatawny",
        "split pea soup", "butternut squash soup", "corn chowder", "hot and sour soup"
    )
    "Recipes|Main Dishes" = @(
        "Buddha bowl", "grain bowl", "power bowl", "nourish bowl",
        "stir-fry", "one-pot meal", "sheet pan dinner", "skillet dinner",
        "stuffed pepper", "stuffed squash", "veggie lasagna", "eggplant parmesan",
        "jackfruit pulled pork", "cauliflower steak", "portobello burger"
    )
    "Recipes|Sides & Salads" = @(
        "grain salad", "pasta salad", "bean salad", "slaw", "coleslaw",
        "roasted vegetables", "glazed carrots", "maple roasted", "balsamic roasted",
        "garlic mashed", "twice-baked", "hasselback", "gratin", "au gratin"
    )
    "Recipes|Breads & Baked Goods" = @(
        "artisan bread", "no-knead bread", "sourdough starter", "levain",
        "poolish", "biga", "autolyse", "bulk fermentation", "proofing",
        "scoring", "dutch oven bread", "pullman loaf", "enriched dough"
    )
    "Recipes|Desserts & Sweets" = @(
        "vegan baking", "egg replacer", "flax egg", "chia egg", "aquafaba",
        "coconut whipped cream", "cashew cream", "date sweetened", "maple syrup",
        "nice cream", "frozen banana", "energy balls", "bliss balls", "raw dessert"
    )
    "Recipes|Fermented Foods" = @(
        "wild fermentation", "lacto-fermentation", "brine", "starter culture",
        "fermentation vessel", "airlock", "fermentation weight", "kombucha",
        "water kefir", "milk kefir alternative", "tempeh making", "miso making"
    )
    "Recipes|Sauces, Dips & Condiments" = @(
        "tahini sauce", "cashew sauce", "nutritional yeast sauce", "cheese sauce",
        "pesto", "chimichurri", "harissa", "zhug", "romesco", "aioli",
        "baba ganoush", "muhammara", "tzatziki alternative", "raita"
    )
    "Recipes|Beverages" = @(
        "plant milk", "oat milk homemade", "almond milk", "cashew milk",
        "green smoothie", "protein smoothie", "açaí bowl", "smoothie bowl",
        "infused water", "herbal infusion", "nut milk bag", "cold brew"
    )
    "Recipes|Basics & Staples" = @(
        "vegetable broth", "homemade stock", "spice blend", "seasoning mix",
        "salad dressing", "vinaigrette", "nut butter", "seed butter",
        "plant-based milk", "vegan butter", "flax meal", "chia pudding base"
    )
    "Recipes|Sweet Potato Collection" = @(
        "baked sweet potato", "mashed sweet potato", "sweet potato fries",
        "sweet potato casserole", "sweet potato pie", "sweet potato soup",
        "stuffed sweet potato", "sweet potato hash", "sweet potato toast",
        "spiralized sweet potato", "sweet potato noodles"
    )

    # Science & Nature
    "Science & Nature|Micrometeorites" = @(
        "cosmic spherule", "interplanetary dust particle", "IDP", "zodiacal dust",
        "micrometeoroid", "ablation sphere", "barred olivine", "porphyritic",
        "S-type spherule", "I-type spherule", "G-type spherule", "unmelted micrometeorite",
        "Jon Larsen", "Project Stardust", "urban micrometeorites", "rooftop collecting"
    )
    "Science & Nature|Earth Sciences & Geology" = @(
        "plate tectonics", "subduction zone", "volcanic activity", "seismology",
        "stratigraphy", "sedimentary rock", "igneous rock", "metamorphic rock",
        "mineral identification", "rock cycle", "erosion", "weathering",
        "geomorphology", "glaciology", "hydrology", "paleoclimatology"
    )
    "Science & Nature|Archaeology & Anthropology" = @(
        "excavation", "stratigraphy", "provenience", "context", "artifact",
        "assemblage", "ecofact", "biofact", "feature", "midden",
        "radiocarbon dating", "carbon-14", "dendrochronology", "thermoluminescence",
        "paleoanthropology", "hominid", "lithic analysis", "zooarchaeology"
    )
    "Science & Nature|Gardening & Nature" = @(
        "phenology", "first frost date", "last frost date", "growing season",
        "pollinator garden", "native plants", "xeriscaping", "rain garden",
        "wildlife habitat", "bird-friendly garden", "butterfly garden",
        "integrated pest management", "IPM", "beneficial insects"
    )
    "Science & Nature|Travel & Natural Wonders" = @(
        "geological formation", "natural landmark", "UNESCO World Heritage",
        "geopark", "biosphere reserve", "scenic overlook", "vista point",
        "geological survey", "natural monument", "wilderness area"
    )
    "Science & Nature|Life Sciences" = @(
        "cell biology", "molecular biology", "genetics", "genomics", "proteomics",
        "evolutionary biology", "ecology", "biodiversity", "taxonomy",
        "phylogenetics", "cladistics", "speciation", "adaptation", "natural selection"
    )
    "Science & Nature|Space & Planetary Science" = @(
        "exoplanet", "astrobiology", "habitability", "Goldilocks zone",
        "solar system", "asteroid belt", "Kuiper belt", "Oort cloud",
        "space telescope", "James Webb", "Hubble", "planetary exploration",
        "Mars rover", "Perseverance", "Curiosity", "lunar exploration"
    )
    "Science & Nature|Weather" = @(
        "meteorology", "atmospheric science", "weather pattern", "pressure system",
        "front", "cold front", "warm front", "precipitation", "humidity",
        "dew point", "wind chill", "heat index", "severe weather", "storm system"
    )
    "Science & Nature|Index" = @(
        "scientific classification", "taxonomy", "species list", "biodiversity index",
        "field guide", "identification key", "natural history collection"
    )

    # Soccer
    "Soccer|Soccer Books & Literature" = @(
        "Zonal Marking", "Michael Cox", "The Mixer", "Jonathan Wilson",
        "The Numbers Game", "Chris Anderson", "Soccernomics", "Simon Kuper",
        "Brilliant Orange", "David Winner", "Fear and Loathing in La Liga"
    )
    "Soccer|Ted Lasso & English Football Culture" = @(
        "Richmond FC", "Nate Shelley", "Roy Kent", "Keeley Jones", "Rebecca Welton",
        "Diamond Dogs", "believe sign", "biscuits with the boss", "football is life",
        "relegation battle", "promotion race", "Championship", "FA Cup"
    )
    "Soccer|Learning the Game" = @(
        "Laws of the Game", "IFAB", "offside rule", "advantage rule", "VAR",
        "yellow card", "red card", "penalty kick", "free kick", "corner kick",
        "throw-in", "goal kick", "first touch", "ball control", "passing accuracy"
    )
    "Soccer|Positions & Formations" = @(
        "false nine", "inverted winger", "box-to-box midfielder", "holding midfielder",
        "regista", "trequartista", "sweeper keeper", "wingback", "fullback",
        "center back", "defensive midfielder", "attacking midfielder", "playmaker"
    )
    "Soccer|Teams & Leagues" = @(
        "top flight", "first division", "second division", "Champions League",
        "Europa League", "Conference League", "domestic cup", "league cup",
        "transfer window", "deadline day", "loan deal", "buyout clause"
    )
    "Soccer|Major League Soccer (MLS)" = @(
        "Designated Player", "DP rule", "salary cap", "Supporters Shield",
        "MLS Cup", "playoff format", "expansion team", "SuperDraft",
        "Homegrown Player", "allocation money", "TAM", "GAM"
    )
    "Soccer|World Cup & International Football" = @(
        "FIFA ranking", "continental confederation", "CONCACAF", "UEFA", "CONMEBOL",
        "qualifying round", "group stage", "knockout round", "round of 16",
        "quarterfinal", "semifinal", "third-place playoff", "final"
    )
    "Soccer|2022 Qatar World Cup" = @(
        "Lusail Stadium", "Al Bayt Stadium", "Argentina champion", "Lionel Messi",
        "Kylian Mbappé", "Morocco semifinal", "Japan upset", "Germany elimination",
        "penalty shootout", "golden boot", "golden ball", "young player award"
    )
    "Soccer|Soccer Culture & Values" = @(
        "beautiful game", "joga bonito", "tiki-taka", "gegenpressing",
        "total football", "catenaccio", "calcio", "football culture",
        "supporter culture", "tifo", "ultras", "matchday atmosphere"
    )
    "Soccer|Related MOCs" = @(
        "sports psychology", "athletic performance", "team dynamics",
        "coaching philosophy", "leadership in sports", "sports analytics"
    )

    # Social Issues
    "Social Issues|Race & Equity" = @(
        "systemic racism", "structural racism", "implicit bias", "unconscious bias",
        "microaggression", "colorism", "redlining", "housing discrimination",
        "school-to-prison pipeline", "mass incarceration", "restorative justice",
        "reparations", "affirmative action", "equal opportunity"
    )
    "Social Issues|Justice & Politics" = @(
        "social democracy", "progressive politics", "grassroots organizing",
        "community organizing", "civic engagement", "voter registration",
        "gerrymandering", "electoral reform", "ranked choice voting",
        "campaign finance", "lobbying", "political polarization"
    )
    "Social Issues|Religion & Society" = @(
        "secularism", "separation of church and state", "religious pluralism",
        "religious freedom", "faith-based initiative", "religious exemption",
        "megachurch", "prosperity gospel", "fundamentalism", "evangelical"
    )
    "Social Issues|Cultural Commentary" = @(
        "cultural criticism", "media literacy", "propaganda", "misinformation",
        "disinformation", "fact-checking", "media bias", "echo chamber",
        "filter bubble", "cancel culture", "call-out culture", "accountability"
    )
    "Social Issues|Cult Awareness" = @(
        "high-demand group", "undue influence", "thought reform", "love bombing",
        "information control", "BITE model", "Steven Hassan", "exit counseling",
        "recovery from cults", "spiritual abuse", "coercive control"
    )
    "Social Issues|Peace & Unity" = @(
        "nonviolence", "conflict transformation", "peacebuilding", "reconciliation",
        "restorative circles", "community mediation", "dialogue facilitation",
        "truth and reconciliation", "transitional justice", "healing circles"
    )
    "Social Issues|Culture" = @(
        "cultural identity", "cultural heritage", "cultural preservation",
        "multiculturalism", "cross-cultural communication", "cultural competency",
        "cultural humility", "intercultural dialogue", "cultural exchange"
    )

    # Technology & Computing
    "Technology & Computing|Software & Applications" = @(
        "productivity software", "office suite", "project management tool",
        "collaboration software", "version control", "Git", "GitHub",
        "cloud storage", "file sync", "backup solution", "automation tool",
        "Zapier", "IFTTT", "macro", "scripting"
    )
    "Technology & Computing|System Administration" = @(
        "Active Directory", "Group Policy", "PowerShell scripting", "bash scripting",
        "cron job", "scheduled task", "service management", "systemd",
        "container", "Docker", "Kubernetes", "virtualization", "hypervisor",
        "load balancing", "high availability", "disaster recovery"
    )
    "Technology & Computing|Retro Computing & Hardware" = @(
        "vintage computer", "8-bit", "6502", "Z80", "CP/M", "BASIC",
        "retrocomputing", "emulator", "FPGA", "single-board computer",
        "Arduino", "ESP32", "maker electronics", "breadboard", "soldering"
    )
    "Technology & Computing|Media & Entertainment" = @(
        "home theater PC", "HTPC", "media server", "Plex", "Jellyfin",
        "digital media", "media streaming", "codec", "transcoding",
        "audio format", "FLAC", "video format", "4K", "HDR"
    )
    "Technology & Computing|Programming & Development" = @(
        "integrated development environment", "IDE", "code editor", "VS Code",
        "debugger", "profiler", "unit testing", "test-driven development", "TDD",
        "continuous integration", "CI/CD", "DevOps", "agile methodology",
        "API design", "REST", "GraphQL", "microservices"
    )

    # Travel & Exploration
    "Travel & Exploration|Narrowboat & Canal Travel" = @(
        "British Waterways", "Canal & River Trust", "CRT license", "continuous cruiser",
        "winding hole", "pound", "summit level", "tunnel", "bridge hole",
        "tow path", "gongoozler", "boat handling", "stern gear", "prop shaft",
        "engine hours", "boat safety scheme", "BSS"
    )
    "Travel & Exploration|RV & Alternative Living" = @(
        "nomadic lifestyle", "location independence", "remote work travel",
        "digital nomad", "van life", "skoolie", "bus conversion", "tiny living",
        "minimalist travel", "slow travel", "overlanding", "expedition vehicle"
    )
    "Travel & Exploration|National Parks & Nature" = @(
        "park pass", "America the Beautiful pass", "backcountry permit",
        "wilderness permit", "Leave No Trace", "trail etiquette",
        "summit", "trailhead", "switchback", "elevation gain",
        "scramble", "bushwhack", "cairn", "blaze", "trail marker"
    )
    "Travel & Exploration|Specific Locations" = @(
        "destination guide", "travel itinerary", "points of interest", "POI",
        "off the beaten path", "hidden gem", "local favorite", "must-see",
        "day trip", "road trip", "scenic drive", "scenic route"
    )
    "Travel & Exploration|Washington State" = @(
        "Olympic Peninsula", "San Juan Islands", "Mount Rainier", "North Cascades",
        "Columbia River Gorge", "Puget Sound", "Spokane", "Palouse",
        "wine country", "Walla Walla", "Leavenworth", "Whidbey Island"
    )
    "Travel & Exploration|Santa Fe" = @(
        "adobe architecture", "Pueblo style", "Canyon Road", "Georgia O'Keeffe",
        "Native American art", "turquoise jewelry", "chile culture", "Hatch chile",
        "high desert", "Sangre de Cristo Mountains", "Bandelier National Monument"
    )
    "Travel & Exploration|Atlanta" = @(
        "MLK National Historic Site", "Atlanta BeltLine", "Piedmont Park",
        "Georgia Aquarium", "World of Coca-Cola", "Centennial Olympic Park",
        "Ponce City Market", "Krog Street Market", "Little Five Points"
    )
    "Travel & Exploration|Moscow" = @(
        "Red Square", "Kremlin", "St. Basil's Cathedral", "Bolshoi Theatre",
        "Moscow Metro", "Gorky Park", "Tretyakov Gallery", "Pushkin Museum"
    )
    "Travel & Exploration|Japan" = @(
        "Shinkansen", "bullet train", "ryokan", "onsen", "tatami",
        "zen garden", "temple", "shrine", "torii gate", "sake brewery",
        "izakaya", "ramen shop", "convenience store", "konbini", "JR Pass"
    )
    "Travel & Exploration|Pilgrimage" = @(
        "Camino de Santiago", "Camino Francés", "pilgrim passport", "credencial",
        "albergue", "pilgrim hostel", "Buen Camino", "Way of St. James",
        "spiritual walk", "walking meditation", "labyrinth walk", "sacred site"
    )
    "Travel & Exploration|Travel Index" = @(
        "travel planning", "trip planner", "packing list", "travel checklist",
        "travel journal", "trip report", "destination research", "travel resources"
    )
}

# Read the script file
$content = Get-Content $scriptPath -Raw

# Track changes
$insertCount = 0

# For each subsection, find it and add new keywords
foreach ($key in $newKeywords.Keys) {
    $parts = $key -split "\|"
    $moc = $parts[0]
    $subsection = $parts[1]
    $keywords = $newKeywords[$key]

    # Escape special regex characters in subsection name
    $escapedSubsection = [regex]::Escape($subsection)

    # Pattern to find the subsection's closing parenthesis
    # We look for the subsection name followed by its array, then find the closing )
    $pattern = '("' + $escapedSubsection + '"\s*=\s*@\([^)]+)'

    if ($content -match $pattern) {
        $match = $Matches[0]

        # Format new keywords as a comma-separated string
        $formattedKeywords = ($keywords | ForEach-Object { "`"$_`"" }) -join ",`n            "

        # Add the new keywords before the closing parenthesis
        $newContent = $match + ",`n            " + $formattedKeywords

        $content = $content -replace [regex]::Escape($match), $newContent
        $insertCount++
        Write-Host "Added $($keywords.Count) keywords to: $moc / $subsection" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Could not find subsection: $moc / $subsection" -ForegroundColor Yellow
    }
}

# Write the modified content back
$content | Set-Content $scriptPath -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Completed! Modified $insertCount subsections." -ForegroundColor Cyan
