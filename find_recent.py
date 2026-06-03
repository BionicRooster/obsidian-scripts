import os, datetime

vault = 'D:/Obsidian/Main'
cutoff = datetime.datetime.now() - datetime.timedelta(days=2)
excludes = ['/People/', '/Journals/', '/00 - Journal/', '/Templates/', '/images/',
            '/Attachments/', '/00 - Home Dashboard/', '/.resources/']

results = []
for root, dirs, files in os.walk(vault):
    norm_root = root.replace('\\', '/')
    skip = any(e in norm_root for e in excludes)
    if skip:
        continue
    for f in files:
        if not f.endswith('.md') or f == 'Orphan Files.md':
            continue
        path = os.path.join(root, f)
        ctime = datetime.datetime.fromtimestamp(os.path.getctime(path))
        if ctime > cutoff:
            results.append((ctime, path))

results.sort(reverse=True)
for ctime, path in results:
    print(f'{ctime.strftime("%Y-%m-%d %H:%M")}  {path}')
print(f'\nTotal: {len(results)} files')
