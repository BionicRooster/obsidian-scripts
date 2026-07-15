# -*- coding: utf-8 -*-
"""
Fix 8 malformed Daily Quotes files where the YAML frontmatter is broken:
  - tags written inline: "tags: - Bahai - BahaiScripture" (should be multi-line)
  - closing --- is concatenated with body content on the same line
  - day separators ("--- ### DayName") are embedded mid-line instead of on their own lines

Repairs applied:
  1. Reconstruct proper multi-line tags block
  2. Add nav property
  3. Separate closing --- from body content
  4. Insert MOC backlink as first body line
  5. Fix inline "--- ### DayName" separators throughout body
"""
import re
import sys

# Force UTF-8 output so Windows terminal doesn't choke on diacriticals
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ---------------------------------------------------------------------------
# Constants — built with chr() to avoid source-file encoding issues
# ---------------------------------------------------------------------------
ACUTE_A = chr(0xE1)   # á
ACUTE_I = chr(0xED)   # í
APOS    = chr(0x27)   # standard apostrophe '

BAHAI = f"Bah{ACUTE_A}{APOS}{ACUTE_I}"   # Bahá'í (filesystem spelling)
NAV   = f"MOC - {BAHAI} Faith"            # nav property value (without [[ ]])

DIR = f"C:\\Users\\awt\\Sync\\Obsidian\\01\\{BAHAI}\\Daily Quotes"

# The 8 files identified as malformed
FILES = [
    "2024-05.md",
    "2025-04.md",
    "2025-05.md",
    "2025-12.md",
    "2026-02.md",
    "2026-03.md",
    "2026-04.md",
    "2026-05.md",
]


def fix_file(path: str, fname: str) -> bool:
    """
    Read one malformed Daily Quotes file, repair it, and write it back.
    Returns True on success, False if the file doesn't match the expected pattern.
    """
    raw = open(path, encoding="utf-8-sig").read()   # utf-8-sig strips BOM if present
    lines = raw.split("\n")   # split on LF; preserve CR if present

    # Verify the file starts with a frontmatter opener
    if not lines or lines[0].strip() != "---":
        print(f"  SKIP — unexpected first line: {lines[0]!r}")
        return False

    # -----------------------------------------------------------------
    # Find the index of the malformed closing ---
    # It's the first line after line 0 that starts with "---" and has
    # additional content on the same line (i.e., len > 3).
    # -----------------------------------------------------------------
    body_line_idx = None
    for i in range(1, min(10, len(lines))):   # it should be within the first 10 lines
        if lines[i].startswith("---") and len(lines[i]) > 3:
            body_line_idx = i
            break

    if body_line_idx is None:
        print(f"  SKIP — could not locate malformed closing ---")
        return False

    # -----------------------------------------------------------------
    # Extract the created date from the lines between the two ---
    # markers (the frontmatter block).
    # -----------------------------------------------------------------
    fm_block = "\n".join(lines[1:body_line_idx])   # frontmatter content (excl. --- delimiters)
    created_m = re.search(r"created:\s*(\S+)", fm_block)
    created = created_m.group(1) if created_m else "2026-06-04"

    # -----------------------------------------------------------------
    # Extract the body:
    #   • body_head: everything after the leading "--- " on body_line_idx
    #   • rest:      all lines after body_line_idx (already have proper newlines)
    # -----------------------------------------------------------------
    body_head = lines[body_line_idx][3:].lstrip()    # strip leading "---" + whitespace
    rest_lines = lines[body_line_idx + 1:]           # remaining lines (may be empty)
    body = body_head + ("\n" + "\n".join(rest_lines) if rest_lines else "")

    # -----------------------------------------------------------------
    # Fix the body:
    #
    # 1. "# Title ### First Day" → "# Title\n\n### First Day"
    #    Applies to the very first line where the h1 title and first day
    #    heading are crammed together.
    #
    # 2. "* --- ### Next Day" → "*\n\n---\n\n### Next Day"
    #    All subsequent day separators embedded mid-line.
    # -----------------------------------------------------------------
    # Fix h1 title immediately followed by a day heading (first occurrence only)
    body = re.sub(
        r"^(# .+?)\s+(#{1,4} )",
        r"\1\n\n\2",
        body,
        count=1,
        flags=re.MULTILINE,
    )

    # Fix inline "--- ### Day" (or "--- ## " or "--- # ") separators
    # Replace any run of whitespace + --- + whitespace + heading-marker
    # with a clean paragraph break + horizontal rule + new heading line
    body = re.sub(
        r"\s*---\s+(#{1,4} )",
        lambda m: "\n\n---\n\n" + m.group(1),
        body,
    )

    # -----------------------------------------------------------------
    # Rebuild the file with correct frontmatter + MOC backlink
    # -----------------------------------------------------------------
    new_content = (
        f"---\n"
        f"tags:\n"
        f"  - Bahai\n"
        f"  - BahaiScripture\n"
        f"created: {created}\n"
        f'nav: "[[{NAV}]]"\n'
        f"---\n"
        f"\n"
        f"[[{NAV}]]\n"
        f"\n"
        f"{body.lstrip()}"
    )

    open(path, "w", encoding="utf-8").write(new_content)

    # Diagnostic: show first heading and first day heading to confirm split
    first_lines = new_content.split("\n")[:14]
    print(f"  created: {created}")
    for line in first_lines:
        print(f"    {line!r}")
    return True


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
def main():
    fixed   = 0   # count of successfully fixed files
    skipped = 0   # count of files that did not match expected pattern

    for fname in FILES:
        path = f"{DIR}\\{fname}"
        print(f"\nProcessing: {fname}")
        ok = fix_file(path, fname)
        if ok:
            fixed += 1
            print(f"  → Fixed")
        else:
            skipped += 1
            print(f"  → Skipped")

    print(f"\nDone: {fixed} fixed, {skipped} skipped.")


if __name__ == "__main__":
    main()
