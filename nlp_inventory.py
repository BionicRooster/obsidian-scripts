"""
Compare D:\Documents\NLP (flat) against D:\Obsidian\Main\01\NLP (vault).
Extract a title hint from each source file and find vault matches.
Output: list of files likely NOT yet converted.
"""

import os, re, glob

SRC_DIR  = 'D:/Documents/NLP'
VAULT_DIR = 'D:/Obsidian/Main/01/NLP'

# ── Vault file inventory ──────────────────────────────────────────────────
vault_files = []
for root, dirs, files in os.walk(VAULT_DIR):
    # Only top-level NLP folder, not subdirs (NLP Master Class etc.)
    if root == VAULT_DIR:
        for f in files:
            vault_files.append(f.lower().replace('.md','').replace(' ','').replace('-','').replace('_',''))

def normalize(s):
    return re.sub(r'[^a-z0-9]', '', s.lower())

vault_norms = set(vault_files)

# ── Source file inventory ─────────────────────────────────────────────────
skip_exts = {'.flo', '.wmf', '.wri'}  # already done or binary images
skip_files = {'ren', 'dilbert', 'visusl'}  # dilbert done; visusl is binary

# Known conversions: src_stem → vault_stem (approximate)
KNOWN_DONE = {
    'wiredin': 'whatswiredin',
    'catalogu': 'nlpcompuservelibrary',
    'week1': 'nlptrainingweek1',
    'week2': 'nlptrainingweek2',
    'week3': 'nlptrainingweek3',
    'week4': 'nlptrainingweek4',
    'week5': 'nlptrainingweek5',
    'maryann': 'nlpsessionnotes',
    'phobia': 'fastphobiacure',
    'phobia2': 'fastphobiacurev2',
    'mmiii': 'metamodeliii',
    'mmiii2': 'metamodeliii',
    'mmiii3': 'metamodeliii',
    'mmiii4': 'metamodeliii',
    'presup': 'presuppositions',
    'presup2': 'presuppositions',
    'sxstbc': 'sixstepreframe',
    'sxstbc2': 'sixstepreframe',
    'sixstep': 'sixstepreframe',
    'rapportw': 'rapportwithself',
    'score': 'scoreinbusiness',
    'quiz': 'quiztime',
    'profile': 'quickprofiling',
    'programm': 'nlpforprogrammers',
    'program2': 'nlpforprogrammers',
    'programr': 'nlpforprogrammers',
    'prove1': 'provethetheorem',
    'prove2': 'provethetheorem',
    'prove3': 'provethetheorem',
    'prove4': 'provethetheorem',
    'prover': 'provethetheorem',
    'provethe': 'provethetheorem',
    'reframes': 'reframingpatterns',
    'metaphor': 'discussionofnlp',
    'spence': 'gerryspence',
    'timeseri': 'multipletimeseries',
    'themes': 'sixthemes',
    'aiexpert': 'nlpcompuserve',
    'aiexpe': 'nlpcompuserve',
    'moreno': 'andrewmoreno',
    'moreno2': 'andrewmoreno',
    'moreno3': 'andrewmoreno',
    'moreno31': 'andrewmoreno',
    'moreno5': 'andrewmoreno',
    'moreno55': 'andrewmoreno',
    'moreno56': 'andrewmoreno',
    'moreno57': 'andrewmoreno',
    'moreno7': 'andrewmoreno',
    'moreno8': 'andrewmoreno',
    'moreno81': 'andrewmoreno',
    'moreno83': 'andrewmoreno',
    'moreno84': 'andrewmoreno',
    'moreno85': 'andrewmoreno',
    'outcome': 'outcomespecificatio',
    'langpat': 'languagepatterns',
    'langchg': 'makingchanges',
    'langchg': 'makingchanges',
    'metapgho': 'nlpmetaprograms',
    'metaprogram': 'nlpmetaprograms',
    'mission': 'discussion',
}

src_files = [f for f in os.listdir(SRC_DIR)
             if os.path.isfile(os.path.join(SRC_DIR, f))]

print(f"{'FILE':<30} {'SIZE':>8}  STATUS")
print("-" * 65)

new_files = []
for fname in sorted(src_files):
    ext = os.path.splitext(fname)[1].lower()
    stem = os.path.splitext(fname)[0].lower()
    size = os.path.getsize(os.path.join(SRC_DIR, fname))
    norm_stem = normalize(stem)

    if fname.lower() in skip_files or ext in skip_exts or size == 0:
        print(f"{fname:<30} {size:>8}  SKIP")
        continue

    # Check known done map
    known = KNOWN_DONE.get(norm_stem) or KNOWN_DONE.get(stem.replace('-','').replace('_',''))
    if known:
        print(f"{fname:<30} {size:>8}  KNOWN DONE → {known}")
        continue

    # Check vault fuzzy match
    matched = None
    for vf in vault_files:
        if norm_stem in vf or vf in norm_stem or (len(norm_stem) >= 5 and norm_stem[:5] in vf):
            matched = vf
            break

    if matched:
        print(f"{fname:<30} {size:>8}  VAULT MATCH → {matched}")
    else:
        print(f"{fname:<30} {size:>8}  *** NEW ***")
        new_files.append(fname)

print()
print(f"Potentially new files ({len(new_files)}):")
for f in new_files:
    size = os.path.getsize(os.path.join(SRC_DIR, f))
    print(f"  {f:<30} {size:>8} bytes")
