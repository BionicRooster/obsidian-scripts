"""
Add BahaiScripture tag to all Daily Quotes notes in the vault.
Inserts '  - BahaiScripture' after the existing '  - Bahai' tag line.
Skips files that already have the tag.
"""

import os
import re

# Path with diacritical characters — written to file to avoid shell encoding issues
QUOTES_DIR = r"C:\Users\awt\Sync\Obsidian\01\Bahá'í\Daily Quotes"

tagged = []    # files successfully updated
skipped = []   # files already having the tag
no_match = []  # files where the pattern wasn't found

for filename in sorted(os.listdir(QUOTES_DIR)):
    if not filename.endswith('.md'):
        continue

    filepath = os.path.join(QUOTES_DIR, filename)

    # Read with UTF-8 to preserve all diacritical characters
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already tagged
    if 'BahaiScripture' in content:
        skipped.append(filename)
        continue

    # Insert BahaiScripture tag immediately after the '  - Bahai' line
    # count=1 ensures we only touch the frontmatter occurrence, not any body text
    new_content = re.sub(
        r'(  - Bahai)(\r?\n)',
        r'\1\2  - BahaiScripture\2',
        content,
        count=1
    )

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        tagged.append(filename)
    else:
        no_match.append(filename)

# Report results
print(f"Tagged {len(tagged)} files:")
for f in tagged:
    print(f"  {f}")

if skipped:
    print(f"\nAlready had BahaiScripture tag ({len(skipped)}):")
    for f in skipped:
        print(f"  {f}")

if no_match:
    print(f"\nWARNING — pattern not found in ({len(no_match)}):")
    for f in no_match:
        print(f"  {f}")
