# Obsidian Orphan File Linker
# Links orphan files bidirectionally with MOCs and related files

param(
    [switch]$DryRun = $false,
    [int]$MaxFiles = 0  # 0 = no limit
)

# Vault configuration
$vaultPath = 'D:\Obsidian\Main'
$reportPath = 'D:\Obsidian\Main\00 - Home Dashboard\Orphan File Connection Report.md'

# Category definitions with keywords and MOC paths
$categories = @{
    'Recipes' = @{
        MOC = '00 - Home Dashboard/MOC - Recipes'
        Keywords = @('recipe', 'soup', 'salad', 'cake', 'bread', 'cookie', 'muffin', 'stew', 'curry', 'bean', 'lentil', 'tofu', 'vegan', 'vegetable', 'potato', 'rice', 'quinoa', 'pasta', 'noodle', 'sauce', 'dip', 'chutney', 'pie', 'brownie', 'dessert', 'bake', 'cook', 'food', 'meal', 'dinner', 'lunch', 'breakfast', 'snack', 'appetizer', 'ingredient', 'spice', 'herb', 'garlic', 'onion', 'tomato', 'carrot', 'spinach', 'kale', 'chickpea', 'hummus', 'falafel', 'tempeh', 'seitan', 'oat', 'granola', 'smoothie', 'juice', 'tea', 'coffee', 'chocolate', 'vanilla', 'cinnamon', 'ginger', 'turmeric', 'pepper', 'salt', 'oil', 'vinegar', 'mustard', 'mayonnaise', 'ketchup', 'sauerkraut', 'kimchi', 'ferment', 'pickle', 'preserve', 'jam', 'jelly', 'marmalade', 'compote', 'chili', 'burrito', 'taco', 'enchilada', 'quesadilla', 'lasagna', 'risotto', 'polenta', 'couscous', 'millet', 'barley', 'farro', 'bulgur', 'freekeh', 'amaranth', 'teff', 'sorghum', 'buckwheat', 'cornmeal', 'flour', 'yeast', 'sourdough', 'focaccia', 'pita', 'naan', 'roti', 'chapati', 'tortilla', 'wrap', 'sandwich', 'burger', 'patty', 'meatball', 'loaf', 'casserole', 'gratin', 'roast', 'grill', 'sauté', 'steam', 'boil', 'simmer', 'braise', 'fry', 'batter', 'dough', 'pastry', 'crust', 'filling', 'topping', 'frosting', 'glaze', 'syrup', 'honey', 'maple', 'agave', 'stevia', 'sugar-free', 'WFPB', 'plant-based', 'whole food')
        Section = 'Recipes'
    }
    'NLP' = @{
        MOC = '00 - Home Dashboard/MOC - NLP & Psychology'
        Keywords = @('NLP', 'neuro-linguistic', 'neurolinguistic', 'anchoring', 'reframe', 'reframing', 'phobia', 'therapy', 'hypnosis', 'trance', 'rapport', 'modeling', 'strategy', 'submodality', 'timeline', 'belief', 'presupposition', 'meta-model', 'metamodel', 'milton model', 'sleight of mouth', 'parts', 'integration', 'ecology', 'outcome', 'well-formed', 'representational', 'VAK', 'kinesthetic', 'visual', 'auditory', 'olfactory', 'gustatory', 'digital', 'predicates', 'eye patterns', 'calibration', 'pacing', 'leading', 'matching', 'mirroring', 'perceptual positions', 'first position', 'second position', 'third position', 'meta position', 'association', 'dissociation', 'swish', 'collapse anchors', 'circle of excellence', 'resource state', 'state management', 'state elicitation', 'chunking', 'lateral', 'logical levels', 'neurological levels', 'identity', 'values', 'beliefs', 'capabilities', 'behaviors', 'environment', 'sponsor', 'awakener', 'mission', 'vision', 'purpose', 'congruence', 'incongruence', 'secondary gain', 'positive intention', 'ecology check', 'future pace', 'break state', 'change history', 'reimprinting', 'fast phobia cure', 'visual-kinesthetic', 'V-K dissociation', 'movie theater', 'cognitive', 'psychology', 'behavioral', 'thinking', 'mindset', 'mental', 'brain', 'neuroscience', 'consciousness', 'unconscious', 'subconscious', 'attention', 'perception', 'memory', 'learning', 'decision', 'motivation', 'emotion', 'feeling', 'thought', 'pattern')
        Section = 'NLP & Psychology'
    }
    'Bahai' = @{
        MOC = "00 - Home Dashboard/MOC - Bahá'í Faith"
        Keywords = @("Bahá'í", "Bahai", "Baha'i", "Bahá'u'lláh", "Bahaullah", "'Abdu'l-Bahá", "Abdul-Baha", "Abdu'l-Baha", "Shoghi Effendi", "Guardian", "Universal House of Justice", "UHJ", "LSA", "Local Spiritual Assembly", "NSA", "National Spiritual Assembly", "Feast", "Nineteen Day Feast", "Ridván", "Naw-Rúz", "Ayyám-i-Há", "Bab", "Báb", "Tablet", "Kitáb-i-Aqdas", "Kitáb-i-Íqán", "Hidden Words", "Seven Valleys", "Four Valleys", "Gleanings", "Prayers", "devotional", "Ruhi", "institute", "cluster", "teaching", "pioneering", "homefront", "international", "continental", "regional council", "auxiliary board", "counsellor", "continental board", "institute process", "study circle", "children's class", "junior youth", "core activities", "expansion", "consolidation", "intensive program", "reflection meeting", "unit convention", "delegate", "by-election", "consultation", "unity", "oneness", "progressive revelation", "covenant", "administrative order", "world order", "new world order", "lesser peace", "most great peace", "spiritual assembly", "Mashriqu'l-Adhkár", "House of Worship", "Haifa", "Acre", "Akka", "Mount Carmel", "Shrine of the Báb", "Shrine of Bahá'u'lláh", "pilgrimage", "nine year plan", "five year plan", "Divine Plan", "Tablets of the Divine Plan")
        Section = "Bahá'í Faith"
    }
    'Technology' = @{
        MOC = '00 - Home Dashboard/MOC - Technology & Computing'
        Keywords = @('programming', 'code', 'coding', 'software', 'hardware', 'computer', 'laptop', 'desktop', 'server', 'network', 'internet', 'web', 'website', 'app', 'application', 'database', 'SQL', 'API', 'REST', 'JSON', 'XML', 'HTML', 'CSS', 'JavaScript', 'Python', 'Java', 'C#', 'C++', 'Ruby', 'PHP', 'Go', 'Rust', 'Swift', 'Kotlin', 'TypeScript', 'React', 'Angular', 'Vue', 'Node', 'npm', 'git', 'GitHub', 'version control', 'Linux', 'Windows', 'macOS', 'Unix', 'command line', 'terminal', 'shell', 'bash', 'PowerShell', 'script', 'automation', 'DevOps', 'CI/CD', 'Docker', 'Kubernetes', 'cloud', 'AWS', 'Azure', 'Google Cloud', 'virtual machine', 'VM', 'container', 'microservice', 'algorithm', 'data structure', 'machine learning', 'AI', 'artificial intelligence', 'neural network', 'deep learning', 'natural language', 'computer vision', 'robotics', 'IoT', 'Internet of Things', 'embedded', 'Arduino', 'Raspberry Pi', 'sensor', 'actuator', 'circuit', 'PCB', 'electronics', 'microcontroller', 'processor', 'CPU', 'GPU', 'RAM', 'storage', 'SSD', 'HDD', 'USB', 'HDMI', 'Bluetooth', 'WiFi', 'Ethernet', 'TCP/IP', 'HTTP', 'HTTPS', 'SSL', 'TLS', 'encryption', 'security', 'firewall', 'VPN', 'proxy', 'router', 'switch', 'modem', 'access point', 'smartphone', 'tablet', 'wearable', 'smartwatch', 'Android', 'iOS', 'mobile', 'responsive', 'UX', 'UI', 'user experience', 'user interface', 'design', 'prototype', 'wireframe', 'mockup', 'Figma', 'Sketch', 'Adobe', 'Photoshop', 'Illustrator', 'InDesign', 'Premiere', 'After Effects', 'video editing', 'audio editing', 'streaming', 'podcast', 'YouTube', 'Twitch', 'social media', 'SEO', 'analytics', 'marketing', 'e-commerce', 'payment', 'checkout', 'cart', 'order', 'inventory', 'CRM', 'ERP', 'SaaS', 'PaaS', 'IaaS', 'open source', 'license', 'copyright', 'patent', 'trademark', 'intellectual property', 'privacy', 'GDPR', 'CCPA', 'data protection', 'backup', 'recovery', 'disaster recovery', 'high availability', 'scalability', 'performance', 'optimization', 'debugging', 'testing', 'QA', 'quality assurance', 'unit test', 'integration test', 'end-to-end', 'E2E', 'TDD', 'BDD', 'Agile', 'Scrum', 'Kanban', 'sprint', 'backlog', 'user story', 'epic', 'roadmap', 'milestone', 'release', 'deployment', 'production', 'staging', 'development', 'environment', 'configuration', 'settings', 'preferences', 'options', 'parameters', 'arguments', 'command', 'function', 'method', 'class', 'object', 'module', 'package', 'library', 'framework', 'SDK', 'toolkit', 'plugin', 'extension', 'add-on', 'template', 'boilerplate', 'scaffold', 'generator', 'compiler', 'interpreter', 'runtime', 'virtual machine', 'bytecode', 'assembly', 'binary', 'executable', 'installer', 'setup', 'wizard', 'tutorial', 'documentation', 'README', 'wiki', 'forum', 'community', 'support', 'help', 'FAQ', 'troubleshooting', 'error', 'exception', 'bug', 'issue', 'fix', 'patch', 'update', 'upgrade', 'migration', 'deprecation', 'legacy', 'compatibility', 'backward', 'forward', 'cross-platform', 'portable', 'native', 'hybrid', 'PWA', 'progressive web app', 'service worker', 'cache', 'offline', 'sync', 'real-time', 'websocket', 'push notification', 'geolocation', 'camera', 'microphone', 'GPS', 'accelerometer', 'gyroscope', 'biometric', 'fingerprint', 'face recognition', 'voice recognition', 'speech synthesis', 'text-to-speech', 'speech-to-text', 'OCR', 'optical character recognition', 'barcode', 'QR code', 'NFC', 'RFID', 'beacon', 'augmented reality', 'AR', 'virtual reality', 'VR', 'mixed reality', 'MR', '3D', 'graphics', 'rendering', 'animation', 'game', 'gaming', 'Unity', 'Unreal', 'engine', 'physics', 'simulation', 'modeling', 'CAD', 'CAM', '3D printing', 'CNC', 'laser', 'engraving', 'cutting', 'fabrication', 'manufacturing', 'automation', 'industrial', 'PLC', 'SCADA', 'HMI', 'control system', 'process control', 'quality control', 'inspection', 'measurement', 'calibration', 'maintenance', 'repair', 'troubleshooting', 'diagnostics', 'monitoring', 'logging', 'alerting', 'dashboard', 'report', 'visualization', 'chart', 'graph', 'table', 'spreadsheet', 'Excel', 'Google Sheets', 'CSV', 'import', 'export', 'convert', 'transform', 'ETL', 'data pipeline', 'data warehouse', 'data lake', 'big data', 'Hadoop', 'Spark', 'Kafka', 'streaming', 'batch', 'real-time', 'analytics', 'BI', 'business intelligence', 'reporting', 'KPI', 'metric', 'indicator', 'benchmark', 'comparison', 'trend', 'forecast', 'prediction', 'model', 'algorithm', 'statistical', 'regression', 'classification', 'clustering', 'recommendation', 'personalization', 'A/B test', 'experiment', 'hypothesis', 'significance', 'correlation', 'causation')
        Section = 'Technology'
    }
    'Health' = @{
        MOC = '00 - Home Dashboard/MOC - Health & Nutrition'
        Keywords = @('health', 'nutrition', 'diet', 'vegan', 'vegetarian', 'plant-based', 'WFPB', 'whole food', 'organic', 'natural', 'supplement', 'vitamin', 'mineral', 'protein', 'carbohydrate', 'fat', 'fiber', 'calorie', 'macronutrient', 'micronutrient', 'antioxidant', 'phytonutrient', 'enzyme', 'probiotic', 'prebiotic', 'gut', 'digestion', 'metabolism', 'immune', 'inflammation', 'chronic', 'disease', 'prevention', 'treatment', 'therapy', 'medicine', 'medical', 'doctor', 'physician', 'nurse', 'hospital', 'clinic', 'pharmacy', 'prescription', 'drug', 'medication', 'side effect', 'dosage', 'symptom', 'diagnosis', 'condition', 'illness', 'sickness', 'pain', 'ache', 'headache', 'migraine', 'fatigue', 'tired', 'energy', 'sleep', 'insomnia', 'stress', 'anxiety', 'depression', 'mental health', 'emotional', 'psychological', 'physical', 'exercise', 'workout', 'fitness', 'gym', 'yoga', 'meditation', 'mindfulness', 'breathing', 'relaxation', 'stretching', 'flexibility', 'strength', 'endurance', 'cardio', 'aerobic', 'anaerobic', 'HIIT', 'interval', 'walking', 'running', 'jogging', 'cycling', 'swimming', 'hiking', 'climbing', 'weight', 'muscle', 'bone', 'joint', 'posture', 'spine', 'back', 'neck', 'shoulder', 'arm', 'hand', 'leg', 'foot', 'knee', 'hip', 'heart', 'cardiovascular', 'blood', 'pressure', 'cholesterol', 'sugar', 'glucose', 'insulin', 'diabetes', 'obesity', 'overweight', 'BMI', 'body mass index', 'waist', 'circumference', 'body fat', 'lean', 'muscle mass', 'hydration', 'water', 'electrolyte', 'sodium', 'potassium', 'magnesium', 'calcium', 'iron', 'zinc', 'selenium', 'iodine', 'copper', 'manganese', 'chromium', 'molybdenum', 'vitamin A', 'vitamin B', 'vitamin C', 'vitamin D', 'vitamin E', 'vitamin K', 'folate', 'folic acid', 'biotin', 'niacin', 'riboflavin', 'thiamin', 'cobalamin', 'B12', 'omega-3', 'omega-6', 'fatty acid', 'essential', 'amino acid', 'collagen', 'keratin', 'elastin', 'hyaluronic', 'glucosamine', 'chondroitin', 'MSM', 'turmeric', 'curcumin', 'ginger', 'garlic', 'green tea', 'matcha', 'spirulina', 'chlorella', 'wheatgrass', 'barley grass', 'moringa', 'ashwagandha', 'rhodiola', 'ginseng', 'maca', 'adaptogen', 'herb', 'botanical', 'extract', 'tincture', 'capsule', 'tablet', 'powder', 'liquid', 'topical', 'cream', 'lotion', 'oil', 'essential oil', 'aromatherapy', 'massage', 'acupuncture', 'chiropractic', 'naturopathy', 'homeopathy', 'Ayurveda', 'traditional', 'Chinese medicine', 'TCM', 'alternative', 'complementary', 'integrative', 'holistic', 'wellness', 'well-being', 'self-care', 'preventive', 'screening', 'checkup', 'exam', 'test', 'lab', 'blood test', 'urine test', 'imaging', 'X-ray', 'MRI', 'CT scan', 'ultrasound', 'biopsy', 'surgery', 'procedure', 'recovery', 'rehabilitation', 'physical therapy', 'occupational therapy', 'speech therapy', 'counseling', 'psychotherapy', 'cognitive behavioral', 'CBT', 'EMDR', 'trauma', 'PTSD', 'addiction', 'recovery', 'sobriety', '12 step', 'AA', 'NA', 'support group', 'community', 'family', 'caregiver', 'patient', 'advocate', 'navigator', 'coach', 'trainer', 'nutritionist', 'dietitian', 'certified', 'licensed', 'registered', 'board certified', 'specialist', 'generalist', 'primary care', 'specialist', 'referral', 'second opinion', 'consultation', 'telemedicine', 'telehealth', 'virtual', 'remote', 'at-home', 'self-monitoring', 'wearable', 'tracker', 'app', 'digital', 'connected', 'smart', 'Esselstyn', 'Ornish', 'McDougall', 'Barnard', 'Greger', 'Fuhrman', 'Campbell', 'China Study', 'Forks Over Knives', 'Engine 2', 'Blue Zone')
        Section = 'Health & Nutrition'
    }
    'Genealogy' = @{
        MOC = '00 - Home Dashboard/MOC - Home & Practical Life'
        Keywords = @('genealogy', 'ancestry', 'ancestor', 'descendant', 'family tree', 'pedigree', 'lineage', 'heritage', 'DNA', 'genetic', 'chromosome', 'haplogroup', 'mitochondrial', 'Y-DNA', 'autosomal', 'ethnicity', 'origin', 'migration', 'census', 'birth', 'death', 'marriage', 'divorce', 'baptism', 'christening', 'funeral', 'burial', 'cemetery', 'grave', 'headstone', 'obituary', 'will', 'probate', 'estate', 'deed', 'land', 'property', 'record', 'document', 'certificate', 'license', 'registration', 'archive', 'library', 'repository', 'database', 'index', 'catalog', 'collection', 'microfilm', 'microfiche', 'digitized', 'scan', 'transcription', 'translation', 'surname', 'given name', 'maiden name', 'married name', 'nickname', 'alias', 'Jr', 'Sr', 'III', 'IV', 'generation', 'grandparent', 'great-grandparent', 'parent', 'child', 'sibling', 'brother', 'sister', 'aunt', 'uncle', 'cousin', 'nephew', 'niece', 'in-law', 'step', 'half', 'adopted', 'foster', 'orphan', 'widow', 'widower', 'immigrant', 'emigrant', 'naturalization', 'citizenship', 'passport', 'visa', 'Ellis Island', 'Castle Garden', 'ship', 'manifest', 'passenger list', 'port', 'voyage', 'Talbot', 'Horn', 'White', 'Joiner', 'Fillingim', 'Dewey', 'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis', 'Wilson', 'Anderson', 'Taylor', 'Thomas', 'Jackson', 'Martin', 'Lee', 'family history', 'family research', 'FamilySearch', 'Ancestry', 'FindMyPast', 'MyHeritage', 'GEDmatch', 'FTDNA', '23andMe', 'AncestryDNA')
        Section = 'Home & Practical Life - Genealogy'
    }
    'Travel' = @{
        MOC = '00 - Home Dashboard/MOC - Travel & Exploration'
        Keywords = @('travel', 'trip', 'vacation', 'holiday', 'journey', 'adventure', 'exploration', 'destination', 'itinerary', 'route', 'map', 'GPS', 'navigation', 'direction', 'flight', 'airline', 'airport', 'plane', 'airplane', 'boarding', 'luggage', 'baggage', 'suitcase', 'backpack', 'packing', 'hotel', 'motel', 'hostel', 'Airbnb', 'VRBO', 'accommodation', 'lodging', 'resort', 'campground', 'camping', 'tent', 'RV', 'motorhome', 'camper', 'caravan', 'trailer', 'narrowboat', 'canal', 'waterway', 'lock', 'mooring', 'marina', 'boat', 'yacht', 'sailing', 'cruise', 'ferry', 'ship', 'ocean', 'sea', 'lake', 'river', 'stream', 'waterfall', 'beach', 'coast', 'island', 'peninsula', 'bay', 'harbor', 'port', 'mountain', 'valley', 'canyon', 'gorge', 'cliff', 'cave', 'forest', 'jungle', 'desert', 'prairie', 'savanna', 'tundra', 'glacier', 'volcano', 'national park', 'state park', 'nature reserve', 'wildlife', 'safari', 'zoo', 'aquarium', 'museum', 'gallery', 'monument', 'landmark', 'attraction', 'sightseeing', 'tour', 'guide', 'excursion', 'activity', 'hiking', 'trekking', 'walking', 'cycling', 'biking', 'kayaking', 'canoeing', 'rafting', 'surfing', 'diving', 'snorkeling', 'fishing', 'hunting', 'photography', 'birdwatching', 'stargazing', 'sunrise', 'sunset', 'scenery', 'landscape', 'view', 'panorama', 'vista', 'overlook', 'observation', 'deck', 'tower', 'bridge', 'tunnel', 'road', 'highway', 'freeway', 'interstate', 'route', 'path', 'trail', 'track', 'Europe', 'Asia', 'Africa', 'Australia', 'North America', 'South America', 'Antarctica', 'UK', 'England', 'Scotland', 'Wales', 'Ireland', 'France', 'Germany', 'Italy', 'Spain', 'Portugal', 'Greece', 'Turkey', 'Egypt', 'Morocco', 'South Africa', 'Kenya', 'Tanzania', 'India', 'China', 'Japan', 'Thailand', 'Vietnam', 'Indonesia', 'Australia', 'New Zealand', 'Canada', 'Mexico', 'Brazil', 'Argentina', 'Peru', 'Chile', 'Texas', 'California', 'Florida', 'New York', 'Washington', 'Oregon', 'Colorado', 'Arizona', 'Nevada', 'Utah', 'National Mall', 'Yellowstone', 'Grand Canyon', 'Yosemite', 'Zion', 'Bryce', 'Arches', 'Canyonlands', 'Rocky Mountain', 'Great Smoky', 'Acadia', 'Olympic', 'Glacier', 'Denali', 'Grand Teton', 'Joshua Tree', 'Death Valley', 'Sequoia', 'Kings Canyon', 'Redwood', 'Crater Lake', 'Mount Rainier', 'North Cascades', 'Badlands', 'Theodore Roosevelt', 'Wind Cave', 'Mammoth Cave', 'Carlsbad Caverns', 'Big Bend', 'Guadalupe Mountains', 'Saguaro', 'Petrified Forest', 'Mesa Verde', 'Black Canyon', 'Great Sand Dunes', 'Capitol Reef', 'Canyonlands', 'Bryce Canyon', 'Zion', 'Grand Staircase')
        Section = 'Travel & Exploration'
    }
    'Science' = @{
        MOC = '00 - Home Dashboard/MOC - Science & Nature'
        Keywords = @('science', 'scientific', 'research', 'study', 'experiment', 'hypothesis', 'theory', 'law', 'principle', 'discovery', 'invention', 'innovation', 'breakthrough', 'publication', 'journal', 'peer review', 'citation', 'reference', 'biology', 'chemistry', 'physics', 'astronomy', 'geology', 'meteorology', 'oceanography', 'ecology', 'botany', 'zoology', 'microbiology', 'genetics', 'evolution', 'paleontology', 'archaeology', 'anthropology', 'sociology', 'psychology', 'economics', 'political science', 'history', 'geography', 'mathematics', 'statistics', 'calculus', 'algebra', 'geometry', 'trigonometry', 'number theory', 'logic', 'philosophy', 'ethics', 'epistemology', 'metaphysics', 'ontology', 'cell', 'molecule', 'atom', 'element', 'compound', 'reaction', 'bond', 'ion', 'electron', 'proton', 'neutron', 'nucleus', 'orbital', 'periodic table', 'organic', 'inorganic', 'biochemistry', 'molecular', 'protein', 'DNA', 'RNA', 'gene', 'chromosome', 'mutation', 'heredity', 'inheritance', 'natural selection', 'adaptation', 'species', 'genus', 'family', 'order', 'class', 'phylum', 'kingdom', 'domain', 'taxonomy', 'classification', 'ecosystem', 'biome', 'habitat', 'niche', 'food chain', 'food web', 'predator', 'prey', 'producer', 'consumer', 'decomposer', 'symbiosis', 'mutualism', 'parasitism', 'commensalism', 'competition', 'population', 'community', 'biodiversity', 'conservation', 'endangered', 'extinct', 'fossil', 'rock', 'mineral', 'crystal', 'sediment', 'metamorphic', 'igneous', 'sedimentary', 'volcano', 'earthquake', 'plate tectonics', 'continental drift', 'mountain', 'valley', 'river', 'lake', 'ocean', 'atmosphere', 'weather', 'climate', 'temperature', 'precipitation', 'humidity', 'wind', 'storm', 'hurricane', 'tornado', 'flood', 'drought', 'fire', 'erosion', 'deposition', 'sedimentation', 'fossilization', 'carbon dating', 'radioactive', 'isotope', 'half-life', 'decay', 'radiation', 'electromagnetic', 'spectrum', 'wavelength', 'frequency', 'amplitude', 'energy', 'force', 'mass', 'velocity', 'acceleration', 'momentum', 'gravity', 'electromagnetism', 'nuclear', 'quantum', 'relativity', 'space', 'time', 'matter', 'antimatter', 'dark matter', 'dark energy', 'black hole', 'star', 'planet', 'moon', 'asteroid', 'comet', 'meteor', 'meteorite', 'micrometeorite', 'galaxy', 'universe', 'cosmos', 'big bang', 'solar system', 'sun', 'mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto', 'telescope', 'microscope', 'spectroscopy', 'chromatography', 'electrophoresis', 'centrifuge', 'pipette', 'beaker', 'flask', 'test tube', 'petri dish', 'incubator', 'autoclave', 'lab', 'laboratory', 'bench', 'hood', 'safety', 'PPE', 'goggles', 'gloves', 'coat', 'apron', 'Smithsonian', 'NASA', 'NOAA', 'USGS', 'EPA', 'NIH', 'CDC', 'WHO', 'nature', 'natural', 'environment', 'environmental', 'green', 'sustainable', 'renewable', 'solar', 'wind', 'hydro', 'geothermal', 'biomass', 'fossil fuel', 'coal', 'oil', 'gas', 'carbon', 'emission', 'pollution', 'waste', 'recycle', 'compost', 'gardening', 'plant', 'tree', 'flower', 'fruit', 'vegetable', 'seed', 'root', 'stem', 'leaf', 'branch', 'bark', 'soil', 'fertilizer', 'pesticide', 'herbicide', 'organic', 'permaculture', 'hydroponics', 'aquaponics', 'greenhouse', 'garden', 'landscape', 'lawn', 'grass', 'weed', 'mulch', 'compost', 'rain', 'irrigation', 'drip', 'sprinkler', 'hose', 'watering', 'pruning', 'trimming', 'harvesting', 'canning', 'preserving', 'drying', 'freezing', 'storing')
        Section = 'Science & Nature'
    }
    'Music' = @{
        MOC = '00 - Home Dashboard/MOC - Music & Recorders'
        Keywords = @('music', 'musical', 'song', 'melody', 'harmony', 'rhythm', 'beat', 'tempo', 'measure', 'bar', 'note', 'rest', 'pitch', 'scale', 'key', 'chord', 'progression', 'interval', 'octave', 'staff', 'clef', 'treble', 'bass', 'alto', 'tenor', 'soprano', 'baritone', 'time signature', 'key signature', 'accidental', 'sharp', 'flat', 'natural', 'dynamics', 'forte', 'piano', 'crescendo', 'decrescendo', 'articulation', 'legato', 'staccato', 'accent', 'slur', 'tie', 'fermata', 'repeat', 'coda', 'da capo', 'dal segno', 'fine', 'recorder', 'flute', 'clarinet', 'oboe', 'bassoon', 'saxophone', 'trumpet', 'trombone', 'horn', 'tuba', 'violin', 'viola', 'cello', 'bass', 'guitar', 'ukulele', 'banjo', 'mandolin', 'harp', 'piano', 'keyboard', 'organ', 'synthesizer', 'drums', 'percussion', 'xylophone', 'marimba', 'vibraphone', 'timpani', 'snare', 'bass drum', 'cymbal', 'tambourine', 'triangle', 'woodwind', 'brass', 'string', 'orchestra', 'band', 'ensemble', 'choir', 'chorus', 'solo', 'duet', 'trio', 'quartet', 'quintet', 'sextet', 'septet', 'octet', 'symphony', 'concerto', 'sonata', 'suite', 'overture', 'prelude', 'fugue', 'rondo', 'theme', 'variation', 'movement', 'opus', 'composer', 'conductor', 'performer', 'musician', 'singer', 'vocalist', 'instrumentalist', 'soloist', 'accompanist', 'arranger', 'orchestrator', 'baroque', 'classical', 'romantic', 'modern', 'contemporary', 'jazz', 'blues', 'rock', 'pop', 'folk', 'country', 'bluegrass', 'gospel', 'soul', 'R&B', 'hip hop', 'rap', 'electronic', 'techno', 'house', 'trance', 'ambient', 'new age', 'world', 'Latin', 'reggae', 'ska', 'punk', 'metal', 'alternative', 'indie', 'grunge', 'emo', 'acoustic', 'unplugged', 'live', 'studio', 'recording', 'album', 'single', 'EP', 'LP', 'vinyl', 'CD', 'cassette', 'digital', 'streaming', 'download', 'playlist', 'shuffle', 'repeat', 'volume', 'equalizer', 'bass', 'treble', 'mid', 'speaker', 'headphone', 'earphone', 'amplifier', 'mixer', 'microphone', 'cable', 'jack', 'plug', 'adapter', 'stand', 'case', 'strap', 'pick', 'bow', 'mute', 'tuner', 'metronome', 'practice', 'rehearsal', 'performance', 'concert', 'recital', 'show', 'gig', 'festival', 'venue', 'stage', 'audience', 'applause', 'encore', 'setlist', 'repertoire', 'sheet music', 'score', 'part', 'lead sheet', 'fake book', 'real book', 'method book', 'etude', 'exercise', 'lesson', 'tutorial', 'course', 'workshop', 'masterclass', 'clinic', 'camp', 'school', 'conservatory', 'academy', 'degree', 'diploma', 'certificate', 'grade', 'level', 'beginner', 'intermediate', 'advanced', 'professional', 'amateur', 'hobbyist', 'enthusiast', 'fan', 'listener', 'collector')
        Section = 'Music & Recorders'
    }
    'Reading' = @{
        MOC = '00 - Home Dashboard/MOC - Reading & Literature'
        Keywords = @('book', 'novel', 'fiction', 'non-fiction', 'literature', 'author', 'writer', 'reader', 'reading', 'chapter', 'page', 'paragraph', 'sentence', 'word', 'vocabulary', 'dictionary', 'thesaurus', 'grammar', 'syntax', 'punctuation', 'spelling', 'writing', 'prose', 'poetry', 'poem', 'verse', 'stanza', 'rhyme', 'meter', 'haiku', 'sonnet', 'limerick', 'epic', 'ballad', 'ode', 'elegy', 'short story', 'novella', 'saga', 'trilogy', 'series', 'sequel', 'prequel', 'spinoff', 'adaptation', 'translation', 'edition', 'hardcover', 'paperback', 'audiobook', 'e-book', 'Kindle', 'Nook', 'Kobo', 'library', 'bookstore', 'publisher', 'publication', 'manuscript', 'draft', 'revision', 'editing', 'proofreading', 'typesetting', 'layout', 'cover', 'jacket', 'spine', 'binding', 'ISBN', 'Dewey', 'genre', 'mystery', 'thriller', 'suspense', 'horror', 'fantasy', 'science fiction', 'romance', 'historical', 'biography', 'autobiography', 'memoir', 'essay', 'article', 'blog', 'journal', 'diary', 'letter', 'correspondence', 'speech', 'transcript', 'interview', 'review', 'critique', 'analysis', 'summary', 'synopsis', 'outline', 'annotation', 'highlight', 'note', 'margin', 'bookmark', 'quote', 'citation', 'reference', 'bibliography', 'index', 'appendix', 'glossary', 'preface', 'foreword', 'introduction', 'conclusion', 'epilogue', 'prologue', 'character', 'protagonist', 'antagonist', 'narrator', 'voice', 'point of view', 'first person', 'third person', 'omniscient', 'setting', 'plot', 'conflict', 'climax', 'resolution', 'theme', 'motif', 'symbol', 'metaphor', 'simile', 'allegory', 'irony', 'satire', 'parody', 'foreshadowing', 'flashback', 'dialogue', 'monologue', 'soliloquy', 'stream of consciousness', 'clipping', 'article', 'news', 'magazine', 'newspaper', 'periodical', 'journal')
        Section = 'Reading & Literature'
    }
    'Finance' = @{
        MOC = '00 - Home Dashboard/MOC - Finance & Investment'
        Keywords = @('finance', 'financial', 'money', 'currency', 'dollar', 'euro', 'pound', 'yen', 'bitcoin', 'crypto', 'cryptocurrency', 'stock', 'share', 'equity', 'bond', 'treasury', 'municipal', 'corporate', 'mutual fund', 'ETF', 'index fund', 'hedge fund', 'private equity', 'venture capital', 'angel investor', 'IPO', 'dividend', 'yield', 'return', 'gain', 'loss', 'profit', 'revenue', 'income', 'expense', 'cost', 'price', 'value', 'market', 'exchange', 'NYSE', 'NASDAQ', 'Dow', 'S&P', 'Russell', 'bull', 'bear', 'volatility', 'risk', 'reward', 'diversification', 'allocation', 'portfolio', 'rebalancing', 'strategy', 'analysis', 'fundamental', 'technical', 'chart', 'trend', 'pattern', 'indicator', 'moving average', 'RSI', 'MACD', 'Bollinger', 'support', 'resistance', 'breakout', 'breakdown', 'consolidation', 'accumulation', 'distribution', 'volume', 'liquidity', 'spread', 'bid', 'ask', 'order', 'limit', 'market', 'stop', 'trailing', 'margin', 'leverage', 'short', 'long', 'put', 'call', 'option', 'futures', 'derivative', 'commodity', 'gold', 'silver', 'oil', 'natural gas', 'wheat', 'corn', 'soybean', 'coffee', 'cocoa', 'sugar', 'cotton', 'real estate', 'REIT', 'property', 'mortgage', 'loan', 'interest', 'rate', 'APR', 'APY', 'compound', 'simple', 'principal', 'amortization', 'refinance', 'equity', 'down payment', 'closing', 'escrow', 'title', 'deed', 'appraisal', 'inspection', 'insurance', 'premium', 'deductible', 'claim', 'coverage', 'liability', 'asset', 'net worth', 'balance sheet', 'income statement', 'cash flow', 'P/E', 'EPS', 'ROI', 'ROE', 'EBITDA', 'debt', 'credit', 'score', 'report', 'bureau', 'Equifax', 'Experian', 'TransUnion', 'FICO', 'VantageScore', 'budget', 'spending', 'saving', 'emergency fund', 'sinking fund', 'retirement', '401k', 'IRA', 'Roth', 'traditional', 'SEP', 'SIMPLE', 'pension', 'annuity', 'Social Security', 'Medicare', 'Medicaid', 'tax', 'income tax', 'capital gains', 'estate tax', 'gift tax', 'property tax', 'sales tax', 'deduction', 'credit', 'exemption', 'filing', 'return', 'refund', 'withholding', 'W-2', '1099', 'Schedule', 'Form', 'IRS', 'CPA', 'accountant', 'advisor', 'planner', 'broker', 'dealer', 'fiduciary', 'fee', 'commission', 'expense ratio', 'load', 'no-load', 'Vanguard', 'Fidelity', 'Schwab', 'TD Ameritrade', 'E-Trade', 'Robinhood', 'Buffett', 'Graham', 'value investing', 'growth investing', 'income investing', 'index investing', 'passive', 'active', 'USAA')
        Section = 'Finance & Investment'
    }
    'Soccer' = @{
        MOC = '00 - Home Dashboard/MOC - Soccer'
        Keywords = @('soccer', 'football', 'futbol', 'match', 'game', 'goal', 'score', 'assist', 'save', 'tackle', 'pass', 'shot', 'header', 'cross', 'corner', 'free kick', 'penalty', 'foul', 'yellow card', 'red card', 'offside', 'VAR', 'referee', 'linesman', 'goalkeeper', 'keeper', 'defender', 'midfielder', 'forward', 'striker', 'winger', 'fullback', 'center back', 'sweeper', 'libero', 'holding', 'attacking', 'defensive', 'formation', '4-3-3', '4-4-2', '3-5-2', 'tactics', 'strategy', 'press', 'counter', 'possession', 'tiki-taka', 'gegenpressing', 'catenaccio', 'total football', 'wing play', 'overlap', 'underlap', 'through ball', 'one-two', 'give and go', 'nutmeg', 'dribble', 'skill', 'trick', 'rabona', 'bicycle kick', 'overhead', 'volley', 'chip', 'lob', 'curler', 'knuckleball', 'free kick', 'set piece', 'corner kick', 'throw in', 'goal kick', 'kick off', 'half time', 'full time', 'extra time', 'stoppage time', 'injury time', 'added time', 'overtime', 'shootout', 'aggregate', 'away goals', 'home', 'away', 'neutral', 'stadium', 'pitch', 'field', 'grass', 'turf', 'artificial', 'natural', 'touchline', 'byline', 'goal line', 'penalty area', 'box', '18 yard', '6 yard', 'center circle', 'spot', 'arc', 'league', 'cup', 'tournament', 'championship', 'title', 'trophy', 'medal', 'promotion', 'relegation', 'playoff', 'final', 'semifinal', 'quarterfinal', 'round of 16', 'group stage', 'knockout', 'draw', 'seeding', 'pot', 'fixture', 'schedule', 'table', 'standings', 'points', 'wins', 'draws', 'losses', 'goal difference', 'head to head', 'tiebreaker', 'champion', 'runner up', 'third place', 'relegation zone', 'safe', 'World Cup', 'Euro', 'Copa America', 'Champions League', 'Europa League', 'Premier League', 'La Liga', 'Serie A', 'Bundesliga', 'Ligue 1', 'MLS', 'Liga MX', 'Brasileirao', 'J-League', 'A-League', 'FA Cup', 'EFL Cup', 'Copa del Rey', 'DFB Pokal', 'Coppa Italia', 'Coupe de France', 'US Open Cup', 'Supporters Shield', 'MLS Cup', 'Concacaf', 'UEFA', 'FIFA', 'AFC', 'CAF', 'CONMEBOL', 'OFC', 'Manchester United', 'Liverpool', 'Chelsea', 'Arsenal', 'Tottenham', 'Manchester City', 'Real Madrid', 'Barcelona', 'Atletico', 'Bayern Munich', 'Borussia Dortmund', 'Juventus', 'Inter Milan', 'AC Milan', 'PSG', 'Ajax', 'Benfica', 'Porto', 'Celtic', 'Rangers', 'LAFC', 'LA Galaxy', 'NYCFC', 'Atlanta United', 'Seattle Sounders', 'Portland Timbers', 'FC Dallas', 'Houston Dynamo', 'Austin FC', 'San Jose', 'Colorado Rapids', 'Sporting KC', 'Minnesota United', 'Chicago Fire', 'Columbus Crew', 'Philadelphia Union', 'DC United', 'New England', 'Orlando City', 'Nashville', 'Charlotte', 'Miami', 'Ted Lasso', 'AFC Richmond', 'Roy Kent', 'Jamie Tartt', 'Keeley', 'Rebecca', 'Nate', 'Coach Beard', 'Trent Crimm', 'believe', 'diamond dogs', 'Lasso way', 'goldfish', 'biscuits', 'tea')
        Section = 'Soccer'
    }
    'Social' = @{
        MOC = '00 - Home Dashboard/MOC - Social Issues & Culture'
        Keywords = @('social', 'society', 'community', 'culture', 'cultural', 'race', 'racism', 'racial', 'ethnicity', 'ethnic', 'minority', 'majority', 'discrimination', 'prejudice', 'bias', 'stereotype', 'privilege', 'oppression', 'marginalized', 'underrepresented', 'diversity', 'inclusion', 'equity', 'equality', 'justice', 'injustice', 'civil rights', 'human rights', 'voting rights', 'suffrage', 'democracy', 'freedom', 'liberty', 'constitution', 'amendment', 'law', 'legislation', 'policy', 'reform', 'activism', 'activist', 'advocate', 'advocacy', 'protest', 'march', 'demonstration', 'rally', 'boycott', 'strike', 'sit-in', 'civil disobedience', 'nonviolent', 'peaceful', 'resistance', 'movement', 'campaign', 'petition', 'lobby', 'lobbying', 'grassroots', 'organizing', 'coalition', 'alliance', 'solidarity', 'unity', 'Black Lives Matter', 'BLM', 'NAACP', 'ACLU', 'SPLC', 'ADL', 'HRC', 'NOW', 'AARP', 'Sierra Club', 'Greenpeace', 'Amnesty', 'Red Cross', 'Doctors Without Borders', 'Habitat for Humanity', 'United Way', 'Salvation Army', 'Goodwill', 'nonprofit', 'charity', 'philanthropy', 'donation', 'volunteer', 'service', 'outreach', 'engagement', 'empowerment', 'education', 'awareness', 'training', 'workshop', 'seminar', 'conference', 'summit', 'forum', 'dialogue', 'conversation', 'discussion', 'debate', 'discourse', 'narrative', 'story', 'testimony', 'witness', 'experience', 'perspective', 'voice', 'representation', 'visibility', 'recognition', 'acknowledgment', 'apology', 'reparation', 'reconciliation', 'healing', 'trauma', 'grief', 'loss', 'resilience', 'hope', 'change', 'progress', 'setback', 'backlash', 'resistance', 'opposition', 'challenge', 'obstacle', 'barrier', 'systemic', 'structural', 'institutional', 'individual', 'interpersonal', 'internalized', 'explicit', 'implicit', 'unconscious', 'microaggression', 'macroaggression', 'hate crime', 'hate speech', 'harassment', 'bullying', 'intimidation', 'violence', 'brutality', 'abuse', 'neglect', 'exploitation', 'trafficking', 'slavery', 'segregation', 'integration', 'desegregation', 'affirmative action', 'quota', 'diversity program', 'DEI', 'anti-racism', 'allyship', 'accomplice', 'bystander', 'upstander', 'intervention', 'interruption', 'confrontation', 'accountability', 'responsibility', 'complicity', 'silence', 'speaking up', 'speaking out', 'calling in', 'calling out', 'cancel culture', 'woke', 'politically correct', 'PC', 'identity politics', 'intersectionality', 'feminist', 'feminism', 'womanism', 'masculinity', 'toxic', 'patriarchy', 'matriarchy', 'gender', 'transgender', 'nonbinary', 'LGBTQ', 'queer', 'gay', 'lesbian', 'bisexual', 'pansexual', 'asexual', 'heterosexual', 'cisgender', 'pronoun', 'coming out', 'closeted', 'Pride', 'Stonewall', 'marriage equality', 'same-sex', 'adoption', 'family', 'parenting', 'childhood', 'adolescence', 'youth', 'elder', 'aging', 'disability', 'ableism', 'accessibility', 'accommodation', 'ADA', 'mental health', 'addiction', 'homelessness', 'poverty', 'wealth', 'income', 'class', 'socioeconomic', 'inequality', 'gap', 'divide', 'mobility', 'opportunity', 'meritocracy', 'bootstrap', 'welfare', 'assistance', 'benefit', 'entitlement', 'safety net', 'minimum wage', 'living wage', 'universal basic income', 'UBI', 'healthcare', 'education', 'housing', 'food security', 'nutrition', 'environment', 'climate', 'sustainability', 'green', 'renewable', 'fossil fuel', 'pollution', 'conservation', 'preservation', 'stewardship', 'indigenous', 'Native American', 'First Nations', 'Aboriginal', 'tribal', 'reservation', 'treaty', 'sovereignty', 'land rights', 'water rights', 'sacred', 'tradition', 'heritage', 'ancestry', 'immigration', 'immigrant', 'migrant', 'refugee', 'asylum', 'deportation', 'detention', 'border', 'wall', 'DACA', 'Dreamer', 'citizenship', 'naturalization', 'green card', 'visa', 'undocumented', 'illegal', 'sanctuary', 'Muslim', 'Islamophobia', 'antisemitism', 'xenophobia', 'nativism', 'nationalism', 'patriotism', 'globalism', 'isolationism', 'interventionism', 'imperialism', 'colonialism', 'postcolonial', 'decolonization')
        Section = 'Social Issues & Culture'
    }
}

# Initialize tracking variables
$changes = @{
    FilesProcessed = 0
    LinksAdded = 0
    MOCsUpdated = @{}
    Connections = @()
    Errors = @()
}

# Function to determine file category based on content/name
function Get-FileCategory {
    param([string]$FilePath, [string]$Content)

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $searchText = "$fileName $Content".ToLower()

    $matchedCategories = @()

    foreach ($catName in $categories.Keys) {
        $cat = $categories[$catName]
        foreach ($keyword in $cat.Keywords) {
            if ($searchText -match [regex]::Escape($keyword.ToLower())) {
                $matchedCategories += @{
                    Name = $catName
                    MOC = $cat.MOC
                    Section = $cat.Section
                    Keyword = $keyword
                }
                break  # Found a match for this category
            }
        }
    }

    return $matchedCategories
}

# Function to add a link to a file
function Add-RelatedLink {
    param(
        [string]$FilePath,
        [string]$LinkTarget,
        [string]$LinkText
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        if (-not $content) { return $false }

        # Check if link already exists
        $linkPattern = [regex]::Escape("[[$LinkTarget")
        if ($content -match $linkPattern) {
            return $false  # Link already exists
        }

        # Find or create Related Notes section
        $relatedSection = "`n`n---`n## Related Notes`n- [[$LinkTarget|$LinkText]]"

        if ($content -match '## Related Notes') {
            # Add to existing section
            $content = $content -replace '(## Related Notes[^\n]*\n)', "`$1- [[$LinkTarget|$LinkText]]`n"
        } else {
            # Add new section at end
            $content = $content.TrimEnd() + $relatedSection
        }

        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        }

        return $true
    }
    catch {
        return $false
    }
}

# Function to add backlink to MOC
function Add-BacklinkToMOC {
    param(
        [string]$MOCPath,
        [string]$OrphanName,
        [string]$OrphanPath,
        [string]$Section
    )

    $fullMOCPath = Join-Path $vaultPath "$MOCPath.md"

    if (-not (Test-Path $fullMOCPath)) {
        return $false
    }

    try {
        $content = Get-Content -Path $fullMOCPath -Raw -Encoding UTF8
        if (-not $content) { return $false }

        # Check if link already exists
        $linkPattern = [regex]::Escape("[[$OrphanName")
        if ($content -match $linkPattern) {
            return $false
        }

        # Calculate relative path
        $relativePath = $OrphanPath.Replace($vaultPath + '\', '').Replace('\', '/').Replace('.md', '')

        # Add to Orphan Connections section
        $orphanSection = "## Recently Connected Orphans"
        if ($content -notmatch [regex]::Escape($orphanSection)) {
            $content = $content.TrimEnd() + "`n`n---`n$orphanSection`n"
        }

        $newLink = "- [[$relativePath|$OrphanName]]"
        $content = $content -replace "($([regex]::Escape($orphanSection))[^\n]*\n)", "`$1$newLink`n"

        if (-not $DryRun) {
            Set-Content -Path $fullMOCPath -Value $content -Encoding UTF8 -NoNewline
        }

        return $true
    }
    catch {
        return $false
    }
}

# Main processing
Write-Host "=== Obsidian Orphan File Linker ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Read filtered orphan list
$orphanList = Get-Content 'C:\Users\awt\orphan_filtered.txt'
Write-Host "Found $($orphanList.Count) orphan files to process" -ForegroundColor Gray

if ($MaxFiles -gt 0) {
    $orphanList = $orphanList | Select-Object -First $MaxFiles
    Write-Host "Processing first $MaxFiles files" -ForegroundColor Yellow
}

$processed = 0
foreach ($orphanPath in $orphanList) {
    $fullPath = Join-Path $vaultPath $orphanPath

    if (-not (Test-Path $fullPath)) {
        $changes.Errors += "File not found: $orphanPath"
        continue
    }

    $processed++
    Write-Progress -Activity "Processing orphan files" -Status $orphanPath -PercentComplete (($processed / $orphanList.Count) * 100)

    # Read file content
    $content = Get-Content -Path $fullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { $content = "" }

    # Determine categories
    $matchedCategories = Get-FileCategory -FilePath $fullPath -Content $content

    if ($matchedCategories.Count -eq 0) {
        # No category match - skip or add to general
        continue
    }

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $orphanPath -Leaf))
    $connections = @()

    foreach ($match in $matchedCategories) {
        # Add link from orphan to MOC
        $mocName = Split-Path $match.MOC -Leaf
        if (Add-RelatedLink -FilePath $fullPath -LinkTarget $match.MOC -LinkText $mocName) {
            $changes.LinksAdded++
            $connections += $mocName
        }

        # Add backlink from MOC to orphan
        if (Add-BacklinkToMOC -MOCPath $match.MOC -OrphanName $fileName -OrphanPath $fullPath -Section $match.Section) {
            $changes.LinksAdded++
            if (-not $changes.MOCsUpdated.ContainsKey($match.MOC)) {
                $changes.MOCsUpdated[$match.MOC] = @()
            }
            $changes.MOCsUpdated[$match.MOC] += $fileName
        }
    }

    if ($connections.Count -gt 0) {
        $changes.Connections += @{
            File = $orphanPath
            Categories = ($matchedCategories | ForEach-Object { $_.Name }) -join ', '
            MOCs = $connections -join ', '
        }
    }

    $changes.FilesProcessed++
}

Write-Progress -Activity "Processing orphan files" -Completed

# Generate report
Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Files processed: $($changes.FilesProcessed)" -ForegroundColor White
Write-Host "Links added: $($changes.LinksAdded)" -ForegroundColor Green
Write-Host "MOCs updated: $($changes.MOCsUpdated.Count)" -ForegroundColor Green
Write-Host "Connections made: $($changes.Connections.Count)" -ForegroundColor Green

if ($changes.Errors.Count -gt 0) {
    Write-Host "Errors: $($changes.Errors.Count)" -ForegroundColor Red
}

# Generate markdown report
$reportContent = @"
# Orphan File Connection Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Mode:** $(if ($DryRun) { "Dry Run (no changes made)" } else { "Live Run" })

## Summary

| Metric | Count |
|--------|-------|
| Files Processed | $($changes.FilesProcessed) |
| Links Added | $($changes.LinksAdded) |
| MOCs Updated | $($changes.MOCsUpdated.Count) |
| Connections Made | $($changes.Connections.Count) |
| Errors | $($changes.Errors.Count) |

---

## MOCs Updated

"@

foreach ($moc in $changes.MOCsUpdated.Keys | Sort-Object) {
    $files = $changes.MOCsUpdated[$moc]
    $reportContent += "`n### $moc`n"
    $reportContent += "Connected $($files.Count) orphan files:`n"
    foreach ($file in $files | Select-Object -First 20) {
        $reportContent += "- [[$file]]`n"
    }
    if ($files.Count -gt 20) {
        $reportContent += "- ... and $($files.Count - 20) more`n"
    }
}

$reportContent += @"

---

## All Connections

| Orphan File | Categories | Connected MOCs |
|-------------|------------|----------------|
"@

foreach ($conn in $changes.Connections | Select-Object -First 100) {
    $fileName = Split-Path $conn.File -Leaf
    $reportContent += "| [[$($conn.File.Replace('.md',''))|$fileName]] | $($conn.Categories) | $($conn.MOCs) |`n"
}

if ($changes.Connections.Count -gt 100) {
    $reportContent += "`n*... and $($changes.Connections.Count - 100) more connections*`n"
}

if ($changes.Errors.Count -gt 0) {
    $reportContent += @"

---

## Errors

"@
    foreach ($err in $changes.Errors) {
        $reportContent += "- $err`n"
    }
}

$reportContent += @"

---

*Report generated by Obsidian Orphan Linker*
"@

# Save report
if (-not $DryRun) {
    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    Write-Host "`nReport saved to: $reportPath" -ForegroundColor Cyan
} else {
    Write-Host "`nReport would be saved to: $reportPath" -ForegroundColor Yellow
    Write-Host $reportContent
}
