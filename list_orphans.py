import json, sys
sys.stdout.reconfigure(encoding='utf-8')

with open('C:/Users/awt/orphan_list.json', encoding='utf-8-sig') as f:
    orphans = json.load(f)

skip_names = {'Orphan Files', 'Dynamic ToDo', 'People Index', 'To-Do List',
              'Truncated Filenames', '10 - Clippings'}
skip_folders = {'', '00 - Journal', '00 - Home Dashboard'}

real = [o for o in orphans
        if o['Name'] not in skip_names
        and not any(o['Folder'].startswith(s) for s in skip_folders)]

# Group by folder
from collections import defaultdict
by_folder = defaultdict(list)
for o in real:
    by_folder[o['Folder']].append(o['Name'])

for folder in sorted(by_folder):
    print(f'\n{folder}:')
    for name in sorted(by_folder[folder]):
        print(f'  {name}')

print(f'\nTotal real orphans: {len(real)}')
