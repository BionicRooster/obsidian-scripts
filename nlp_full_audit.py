# Full audit of D:/Documents/NLP vs vault D:/Obsidian/Main/01/NLP.
# Checks every source file (all subdirs) against vault content.
import os, re

SRC = 'D:/Documents/NLP'
VAULT = 'D:/Obsidian/Main/01/NLP'


# Binary/unreadable extensions to skip
SKIP_EXTS = {'.flo', '.wmf', '.wri', '.ini', '.sni'}
# Known zero/tiny files
SKIP_NAMES = {'ren', 'dilbert', 'visusl', 'wincim'}  # dilbert=image, visusl=binary

def normalize(s):
    """Strip all non-alphanumeric, lowercase."""
    return re.sub(r'[^a-z0-9]', '', s.lower())

# ── Build vault index ──────────────────────────────────────────────────────────
# Walk all of 01/NLP including subdirectories
vault_norms = {}  # norm_stem -> filename
for root, dirs, files in os.walk(VAULT):
    for f in files:
        if f.endswith('.md'):
            stem = os.path.splitext(f)[0]
            vault_norms[normalize(stem)] = stem

# ── Known mappings (source stem -> vault note fragment) ────────────────────────
# These are approximate prefix/keyword matches to vault notes
KNOWN = {
    # Forum threads already converted
    'aiexpe':    'nlpcompuserve',
    'aiexpert':  'nlpcompuserve',
    'banking':   'nlpinvestmentbanking',
    'catalogu':  'nlpcompuservelibrary',
    'cologne':   'richardbandlerdheseminar',
    'commerce':  'commercializationofnlp',
    'deaf':      'nlpanddeafness',
    'deeptran':  'deeptranceidentification',
    'deriv':     'transderivationalsearch',
    'derivati':  'transderivationalsearch',
    'derivtrn':  'transderivationalsearch',
    'dheartic':  'dhearticle',
    'dhedivin':  'dheseminarexperience',
    'dhefutur':  'thefutureofnlp',
    'dhevsnlp':  'nlpvsdhethreeschools',
    'dherc':     'isdhearockconcert',
    'dhetrai':   'dhetraining',
    'dhe3':      'dheseminarexperience',
    'dhe4':      'dheagain',
    'disappoi':  'disappointmentrequiresadequateplanning',
    'expensi2':  'whyisnlpsoexpensivepart2',
    'expensiv':  'whyisnlpsoexpensive',
    'feldenkr':  'moshefeldenkrais',
    'flame':     'rexandonlineflaming',
    'flame2':    'strategiesfornonflaming',
    'gaster':    'davidgasterandtoddepstein',
    'gems':      'gemsfromaltpsychnlp',
    'health':    'nlpandhealthapplications',
    'idsbas':    'intensifyingrepsystem',
    'image':     'nlpspublicimage',
    'inttool':   'internettoolsfor',
    'intensif':  'intensifyingrepsystem',
    'killpart':  'killingparts',
    'labeling':  'theproblemwithdiagnostic',
    'langchg':   'makingchanges',
    'langpat':   'languagepatterns',
    'lngpat':    'languagepatterns',
    'magic':     'makinglifemagical',
    'market':    'marketrapport',
    'maryann':   'nlpsessionnotes',
    'metamodl':  'metamodelpatterns',
    'metapgho':  'nlpmetaprograms',
    'metaphor':  'discussionofnlp',
    'mission':   'discussionofmissio',
    'mmiii':     'metamodeliii',
    'mmiii2':    'metamodeliii',
    'mmiii3':    'metamodeliii',
    'mmiii4':    'metamodeliii',
    'moreno':    'andrewmoreno',
    'moreno2':   'andrewmoreno',
    'moreno3':   'andrewmoreno',
    'moreno31':  'andrewmoreno',
    'moreno5':   'andrewmoreno',
    'moreno55':  'andrewmoreno',
    'moreno56':  'andrewmoreno',
    'moreno57':  'andrewmoreno',
    'moreno7':   'andrewmoreno',
    'moreno8':   'andrewmoreno',
    'moreno81':  'andrewmoreno',
    'moreno83':  'andrewmoreno',
    'moreno84':  'andrewmoreno',
    'moreno85':  'andrewmoreno',
    'moscow':    'teachingnlpinmoscow',
    'nlpfaq':    'nlpfaq',
    'nlpfrum':   'nlpforumscienceandnlpdecember1994',  # the big forum file
    'outcome':   'outcomespecificatio',
    'phobia':    'fastphobiacure',
    'phobia2':   'fastphobiacurev2',
    'phobia3':   'fastphobiacurev3',
    'presup':    'presuppositions',
    'presup2':   'presuppositions',
    'procrast':  'procrastinationstrate',
    'product':   'productor',
    'product2':  'productordiscipline',
    'profile':   'quickprofiling',
    'program2':  'nlpforprogrammers',
    'programm':  'nlpforprogrammers',
    'programr':  'nlpforprogrammers',
    'prover':    'provethetheorem',
    'prove1':    'provethetheorem',
    'prove2':    'provethetheorem',
    'prove3':    'provethetheorem',
    'prove4':    'provethetheorem',
    'provethe':  'provethetheorem',
    'quiz':      'quiztime',
    'rapportw':  'rapportwithself',
    'reframes':  'reframingpatterns',
    'score':     'scoreinbusiness',
    'sixstep':   'sixstepreframe',
    'sxstbc':    'nlpsixstep',
    'sxstbc2':   'nlpsixstep',
    'spence':    'gerryspence',
    'surety2':   'nlpinterventionandsurety',
    'themes':    'sixthemes',
    'timeseri':  'multipletimeseries',
    'visual':    'visualreadingstrategy',
    'webacces':  'webaccessviacompuserve',
    'week1':     'nlpmasterclassweek1',
    'week2':     'nlpmasterclassweek2',
    'week3':     'nlpmasterclassweek3',
    'week4':     'nlpmasterclassweek4',
    'week5':     'nlpmasterclassweek5',
    'week6':     'nlpmasterclassweek6',
    'week7':     'nlpmasterclassweek7',
    'wiredin':   'whatswiredin',
    'cofe':      'circleofexcellence',
    'chphis':    'changepersonalhistory',
    'chart2':    'nlpchart2',
    'develop':   'childhooddevelopmental',
    'ecology':   'nlpecologycheck',
    'elicbel':   'elicitingbeliefs',
    'tdsrch':    'transderivationalsearch',
    'train1':    'transcriptofacompuserve',
    'metamodl':  'metamodelpatterns',
    'nlpfaq':    'nlpfaq',
    'presup':    'presuppositions',
    'dheartic':  'dhearticle',
}

# Collect all source files
src_files = []
for root, dirs, files in os.walk(SRC):
    for f in files:
        path = os.path.join(root, f)
        rel = os.path.relpath(path, SRC)
        ext = os.path.splitext(f)[1].lower()
        stem_raw = os.path.splitext(f)[0]
        stem = normalize(stem_raw)
        size = os.path.getsize(path)
        src_files.append((rel, stem_raw, stem, ext, size, path))

# Check each file
results = {'skip': [], 'done': [], 'vault_match': [], 'new': []}

for rel, stem_raw, stem, ext, size, path in sorted(src_files):
    # Skip binary/image/system files
    if ext in SKIP_EXTS or stem_raw.lower() in SKIP_NAMES or size == 0:
        results['skip'].append((rel, ext, size, 'binary/system/empty'))
        continue

    # Skip .asc files (tiny presup files)
    if ext == '.asc':
        results['skip'].append((rel, ext, size, 'ascii supplement'))
        continue

    # Check KNOWN map
    known_vault = KNOWN.get(stem)
    if known_vault:
        # Verify vault note exists
        vault_match = None
        for vn, vf in vault_norms.items():
            if known_vault in vn or vn in known_vault:
                vault_match = vf
                break
        if vault_match:
            results['done'].append((rel, size, f'-> {vault_match}'))
        else:
            results['done'].append((rel, size, f'-> {known_vault} (presumed)'))
        continue

    # Fuzzy vault match
    matched = None
    for vn, vf in vault_norms.items():
        if len(stem) >= 5 and (stem in vn or vn[:len(stem)] == stem or stem[:5] in vn):
            matched = vf
            break
    if matched:
        results['vault_match'].append((rel, size, matched or '?'))
    else:
        results['new'].append((rel, size, stem))

print(f"{'='*70}")
print(f"AUDIT: D:/Documents/NLP -> D:/Obsidian/Main/01/NLP")
print(f"{'='*70}")
print(f"\nSKIPPED (binary/system/empty): {len(results['skip'])}")
for rel, ext, size, reason in results['skip']:
    print(f"  {size:>8}  {rel}  [{reason}]")

print(f"\nKNOWN DONE (mapped to vault): {len(results['done'])}")
for rel, size, info in results['done']:
    print(f"  {size:>8}  {rel}  {info}")

print(f"\nVAULT FUZZY MATCH: {len(results['vault_match'])}")
for rel, size, match in results['vault_match']:
    print(f"  {size:>8}  {rel}  -> {match}")

print(f"\n*** POTENTIALLY NEW (not in vault): {len(results['new'])} ***")
for rel, size, stem in results['new']:
    print(f"  {size:>8}  {rel}  [stem: {stem}]")
