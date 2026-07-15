import re, sys

# Ensure UTF-8 output to console (avoids Windows cp1252 crash on diacritical chars)
sys.stdout.reconfigure(encoding='utf-8')

# Use Unicode escapes for diacriticals in the file path
filepath = "C:\\Users\\awt\\Sync\\Obsidian\\09 - eBooks\\Bahá'í Sacred Writings - Bahá'í Reference Library.md"

# ── READ ──────────────────────────────────────────────────────────────────────
with open(filepath, 'r', encoding='utf-8', newline='') as f:
    raw = f.read()

# Detect original line-ending style so we can preserve it on write
crlf = '\r\n' in raw

# Normalise to LF for processing
lines = raw.replace('\r\n', '\n').split('\n')

# Track whether the file ended with a newline (so we can restore it)
trailing_newline = lines and lines[-1] == ''
if trailing_newline:
    lines = lines[:-1]

original_count = len(lines)

# ── LOCATE SECTION II ─────────────────────────────────────────────────────────
section2_start = None
for i, line in enumerate(lines):
    if re.match(r'^## II\.', line):
        section2_start = i
        break

if section2_start is None:
    print("ERROR: Section II not found"); sys.exit(1)

print(f"Section II at line {section2_start + 1} (of {original_count} total)")

# ── PROCESS ───────────────────────────────────────────────────────────────────
result = list(lines[:section2_start])   # Section I is left completely unchanged
chapter_changes = []   # Log of chapter-heading merges for verification
para_fixes = 0         # Count of paragraph-number spacing fixes
i = section2_start     # Current position in the source lines array

def fix_para_spacing(text):
    """Add a space between a paragraph reference and the first character of text.
    E.g. '1.1Know' -> '1.1 Know'  (only fires when there is no space already)."""
    return re.sub(r'^(\d+\.\d+)(\S)', r'\1 \2', text)

while i < len(lines):
    line = lines[i]

    # A "lone number" is a line consisting solely of digits (e.g. '10', '17')
    is_lone_number = bool(re.fullmatch(r'\d+', line.strip()))

    # ── TYPE A CHAPTER HEADING ────────────────────────────────────────────────
    # Current format:   N              Target format:   N  Title
    #                   (blank)                         (blank)
    #                   Title                           ---
    #                   (blank)
    #                   ---
    if (is_lone_number
            and i + 4 < len(lines)
            and lines[i+1] == ''
            and lines[i+2].strip() != ''
            and not re.match(r'^\d+\.\d+', lines[i+2])
            and lines[i+3] == ''
            and lines[i+4] == '---'):

        num   = line.strip()
        title = lines[i+2]
        combined = f"{num}  {title}"
        chapter_changes.append(f"  TypeA line {i+1}: '{num}' + '{title}'")
        result.append(combined)
        # Advance past: number(i), blank(i+1), title(i+2) — leave blank(i+3) and ---(i+4) for normal processing
        i += 3
        continue

    # ── TYPE B CHAPTER HEADING ────────────────────────────────────────────────
    # Current format:   N              Target format:   N  Title
    #                   Title                           (blank)
    #                   ________...                     ---
    #                   SubsectionTitle                 (blank)
    #                   1.1Para...                      SubsectionTitle
    #                   2.1Para...                      (blank)
    #                   SubsectionTitle                 1.1 Para...
    #                   3.1Para...                      (blank)
    #                   ...                             2.1 Para...
    #                                                   ...
    if (is_lone_number
            and i + 2 < len(lines)
            and lines[i+1].strip() != ''
            and not re.match(r'^\d+\.\d+', lines[i+1])
            and re.fullmatch(r'_+', lines[i+2].strip())):

        num   = line.strip()
        title = lines[i+1]
        combined = f"{num}  {title}"
        chapter_changes.append(f"  TypeB line {i+1}: '{num}' + '{title}' (underscore divider replaced with ---)")
        result.append(combined)
        result.append('')        # blank line after combined heading
        result.append('---')     # replace the underscore divider with ---
        i += 3                   # advance past: number, title, underscores

        # ── Process the Type B chapter body ───────────────────────────────────
        # Rules:
        #   • Every non-blank content line (paragraph or subsection title) is
        #     preceded by a blank line in the output
        #   • Paragraph-number spacing is fixed (e.g. '1.1Para' -> '1.1 Para')
        #   • Stop when we hit the start of the next chapter
        while i < len(lines):
            curr = lines[i]

            # Detect the start of the NEXT chapter (Type A or Type B)
            if re.fullmatch(r'\d+', curr.strip()) and curr.strip() != '':
                nxt = lines[i+1] if i + 1 < len(lines) else ''
                # Type A next: blank follows the number
                # Type B next: non-blank non-paragraph text follows the number
                if nxt == '' or (nxt.strip() != '' and not re.match(r'^\d+\.\d+', nxt)):
                    break   # leave i pointing at the next chapter number; outer loop handles it

            if curr != '':
                # Ensure a blank line precedes every non-blank content line
                if result and result[-1] != '':
                    result.append('')
                # Fix paragraph-number spacing
                if re.match(r'^\d+\.\d+\S', curr):
                    fixed = fix_para_spacing(curr)
                    if fixed != curr:
                        para_fixes += 1
                    curr = fixed
            result.append(curr)
            i += 1
        continue   # back to outer while loop (i already positioned at next chapter or EOF)

    # ── GENERAL SECTION II (Type A body and everything else) ─────────────────
    # Only change: fix paragraph-number spacing
    if re.match(r'^\d+\.\d+\S', line):
        fixed = fix_para_spacing(line)
        if fixed != line:
            para_fixes += 1
        line = fixed

    result.append(line)
    i += 1

# ── REPORT ────────────────────────────────────────────────────────────────────
print(f"\nChapter heading merges ({len(chapter_changes)}):")
for c in chapter_changes:
    print(c)
print(f"\nParagraph spacing fixes: {para_fixes}")
print(f"Lines: {original_count} → {len(result)} (delta: {len(result) - original_count})")

# ── WRITE ─────────────────────────────────────────────────────────────────────
le = '\r\n' if crlf else '\n'
output = le.join(result)
if trailing_newline:
    output += le

with open(filepath, 'w', encoding='utf-8', newline='') as f:
    f.write(output)

print("\nFile written successfully.")
