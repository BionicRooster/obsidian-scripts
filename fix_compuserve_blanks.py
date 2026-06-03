"""
Second pass: collapse intra-paragraph blank lines in the CompuServe transcript.
Lines within a speaker's paragraph are separated by blank lines due to 80-char
BBS word-wrap. Join them into proper paragraphs.

Rules:
- Keep blank lines before bold speaker markers (**NAME:**)
- Keep blank lines before/after numbered list items (1], 2], -)
- Keep blank lines between distinct paragraphs (heuristic: line ending in
  terminal punctuation . ? ! followed by blank then new sentence)
- Otherwise join lines separated by single blank lines
"""

import re

SRC = 'D:/Obsidian/Main/01/NLP/Transcript of a CompUSERVE THREAD ON THE USE OF NLP IN TRAINING.md'

with open(SRC, 'r', encoding='utf-8') as f:
    content = f.read()

# Split into YAML block (preserve) + body
yaml_match = re.match(r'^(---.*?---\n)(.*)', content, re.DOTALL)
if yaml_match:
    yaml_block = yaml_match.group(1)  # the YAML frontmatter
    body = yaml_match.group(2)        # everything after
else:
    yaml_block = ''
    body = content

# ── Process body ────────────────────────────────────────────────────────────
# Split into paragraphs by blank lines
paragraphs = re.split(r'\n\n', body)

# Markers that should remain isolated (blank lines before/after)
def is_structural(line):
    """Return True if this line is a structural marker that should stay separate."""
    stripped = line.strip()
    return (
        stripped.startswith('**') and stripped.endswith(':**') or  # **SPEAKER:**
        stripped.startswith('**') and ':**' in stripped or          # **SPEAKER:** inline
        stripped.startswith('#') or                                  # headings
        stripped.startswith('- ') or                                 # bullet list
        stripped.startswith('---') or                                # horizontal rule
        re.match(r'^\d[\]\.]', stripped) or                          # numbered list
        stripped.startswith('*Archived') or                          # intro italic
        stripped.startswith('**Participants') or
        stripped.startswith('**Topics')
    )

def ends_sentence(line):
    """Return True if line ends with terminal punctuation."""
    stripped = line.rstrip()
    return stripped.endswith(('.', '?', '!', ':', '>>', ']]'))

def is_continuation(line):
    """Return True if line looks like it continues a previous line (starts lowercase or mid-sentence)."""
    stripped = line.strip()
    if not stripped:
        return False
    # Starts with lowercase or common continuation words after wrap
    return (stripped[0].islower() or
            stripped.startswith(('and ', 'or ', 'but ', 'that ', 'which ', 'the ', 'to ')))

# Join consecutive non-structural paragraphs that are likely wrapped lines
new_paragraphs = []
buffer = ''

for para in paragraphs:
    # A "paragraph" here is the text between double-newlines
    lines = para.splitlines()

    # If this is a single empty string, it's a blank line — keep separator
    if not para.strip():
        if buffer:
            new_paragraphs.append(buffer.strip())
            buffer = ''
        new_paragraphs.append('')
        continue

    # Check if paragraph contains a structural marker
    has_structural = any(is_structural(l) for l in lines)

    if has_structural:
        # Flush buffer first
        if buffer:
            new_paragraphs.append(buffer.strip())
            buffer = ''
        new_paragraphs.append(para)
        continue

    # This is a content paragraph (wrapped line or short paragraph)
    # Collapse internal single blank lines within this para — join its lines
    joined = ' '.join(l.strip() for l in lines if l.strip())

    if buffer:
        # Try to merge with buffer if it looks like a continuation
        # Heuristic: if the buffer doesn't end a sentence, join
        last_line = buffer.rstrip().split('\n')[-1]
        if not ends_sentence(last_line) and not is_structural(joined):
            buffer = buffer.rstrip() + ' ' + joined
        else:
            new_paragraphs.append(buffer.strip())
            buffer = joined
    else:
        buffer = joined

# Flush remaining buffer
if buffer:
    new_paragraphs.append(buffer.strip())

# Rebuild body with double newlines between paragraphs
# But collapse sequences of empty paragraphs to single blank
result_lines = []
prev_empty = False
for para in new_paragraphs:
    if para == '':
        if not prev_empty:
            result_lines.append('')
        prev_empty = True
    else:
        result_lines.append(para)
        prev_empty = False

new_body = '\n\n'.join(result_lines)

# Final cleanup: collapse 3+ newlines to 2
new_body = re.sub(r'\n{3,}', '\n\n', new_body)

final = yaml_block + new_body

with open(SRC, 'w', encoding='utf-8') as f:
    f.write(final)

print(f"Done. {len(final.splitlines())} lines.")
