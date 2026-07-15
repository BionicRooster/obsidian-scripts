#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_grinder_paragraphs.py
Phase 2: AI-assisted paragraph breaking for remaining collapsed prose lines.

After the structural fixes in fix_grinder_formatting.py, prose paragraphs from
the same page are still collapsed onto single lines. This script sends each
long line to Claude Haiku to restore paragraph breaks.
"""

import re
import sys
import time
import anthropic

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# File to fix
FILE = r"C:\Users\awt\Sync\Obsidian\09 - Full eBooks\On Deletion Phenomena in English - Grinder 1976.md"

# Lines shorter than this are left alone
MIN_LENGTH = 500

# Lines that are pure structural elements — skip these entirely
PURE_STRUCTURAL = [
    r'^!\[\[',           # Image embed only
    r'^---\s*$',         # HR separator
]

def needs_reformatting(line):
    """Return True if this line is long enough and not a pure structural element."""
    if len(line) < MIN_LENGTH:
        return False
    for pattern in PURE_STRUCTURAL:
        if re.match(pattern, line):
            return False
    return True


SYSTEM_PROMPT = """You are reformatting OCR output from a 1971 linguistics PhD dissertation
(Grinder, "On Deletion Phenomena in English"). The OCR pipeline collapsed paragraph breaks,
merging multiple paragraphs onto a single line.

Your only task: restore paragraph breaks by inserting a blank line (\\n\\n) between each distinct paragraph.

Rules:
- Do NOT change any words, punctuation, markdown formatting, or content
- Do NOT add, remove, or reword any text
- Each numbered linguistic example (like "(1a)", "(2b)", "(10)") should be on its own line
- Numbered notes (like "1.", "2.") at the end should each be on their own line
- If this line is a single heading or short structural element, return it unchanged
- Return ONLY the reformatted text — no explanation, no preamble"""


def add_paragraph_breaks(client, text):
    """Use Claude Haiku to restore paragraph breaks in collapsed prose."""
    # Estimate output tokens: input chars / 4 * 1.3 buffer, minimum 1024
    est_tokens = max(1024, int(len(text) / 4 * 1.3) + 256)
    est_tokens = min(est_tokens, 4096)  # cap at 4096

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=est_tokens,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": text}]
    )
    return response.content[0].text.strip()


def main():
    print(f"Reading: {FILE}")
    with open(FILE, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    print(f"Total lines: {len(lines)}")

    # Identify line indices that need reformatting
    targets = [(i, line.rstrip('\n')) for i, line in enumerate(lines)
               if needs_reformatting(line.rstrip('\n'))]
    print(f"Lines to reformat: {len(targets)}")

    if not targets:
        print("Nothing to reformat.")
        return

    # Initialize Anthropic client
    client = anthropic.Anthropic()

    # Process each long line
    changes = 0
    errors = 0
    for idx, (line_num, line_text) in enumerate(targets):
        label = f"[{idx+1:3d}/{len(targets)}] Line {line_num+1:4d} ({len(line_text):5d} chars)"
        print(f"{label}...", end=' ', flush=True)

        try:
            reformatted = add_paragraph_breaks(client, line_text)

            # Count output paragraphs
            out_lines = reformatted.count('\n') + 1

            if reformatted != line_text:
                # Replace the original line with the reformatted multiline version
                lines[line_num] = reformatted + '\n'
                changes += 1
                print(f"→ {out_lines} lines")
            else:
                print("unchanged")

        except anthropic.RateLimitError:
            print("rate limit — waiting 60s...")
            time.sleep(60)
            # Retry once
            try:
                reformatted = add_paragraph_breaks(client, line_text)
                if reformatted != line_text:
                    lines[line_num] = reformatted + '\n'
                    changes += 1
                    print(f"  retry OK → {reformatted.count(chr(10))+1} lines")
                else:
                    print("  retry: unchanged")
            except Exception as e2:
                print(f"  retry failed: {e2}")
                errors += 1

        except Exception as e:
            print(f"ERROR: {e}")
            errors += 1

        # Brief pause between API calls
        time.sleep(0.5)

    print(f"\nReformatted: {changes} lines | Errors: {errors}")

    # Write the updated file
    print("Writing file...")
    with open(FILE, 'w', encoding='utf-8') as f:
        f.writelines(lines)

    # Final statistics
    with open(FILE, 'r', encoding='utf-8') as f:
        final = f.read()
    final_line_count = final.count('\n')
    final_long = sum(1 for l in final.split('\n') if len(l) > MIN_LENGTH)
    print(f"Final: {final_line_count} lines | {final_long} still over {MIN_LENGTH} chars")
    print("Done.")


if __name__ == '__main__':
    main()
