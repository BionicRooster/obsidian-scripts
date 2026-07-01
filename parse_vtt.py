"""
Parse a YouTube auto-generated VTT subtitle file into clean timestamped text.
Auto-generated VTTs repeat lines as each word is added -- we deduplicate
by keeping only the 'final' version of each cue (the one with no inline
word-level <c> tags, which is the completed line).

Usage:
    py parse_vtt.py <input.vtt>               # prints to stdout
    py parse_vtt.py <input.vtt> <output.txt>  # writes to file
"""

import re
import sys

# --- Validate arguments ---
if len(sys.argv) < 2:
    print("Usage: py parse_vtt.py <input.vtt> [output.txt]", file=sys.stderr)
    sys.exit(1)

VTT_PATH = sys.argv[1]                                     # path to the .vtt file from yt-dlp
OUT_PATH = sys.argv[2] if len(sys.argv) > 2 else None      # optional output file; None = stdout


def ts_to_seconds(ts):
    """Convert HH:MM:SS.mmm or MM:SS.mmm timestamp string to float seconds."""
    parts = ts.split(":")
    if len(parts) == 3:
        h, m, s = parts
        return int(h) * 3600 + int(m) * 60 + float(s)
    else:
        m, s = parts
        return int(m) * 60 + float(s)


def clean_line(text):
    """Strip all VTT/HTML inline tags and surrounding whitespace."""
    return re.sub(r"<[^>]+>", "", text).strip()


def parse_vtt(path):
    """
    Read a VTT file and return list of (start_seconds, text) tuples.
    Discards intermediate word-by-word cues (those containing <c> or inline
    timestamp tags) and keeps only the completed final form of each cue.
    """
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    # Split on blank lines to get individual cue blocks
    blocks = re.split(r"\n\n+", raw.strip())

    entries = []
    for block in blocks:
        lines = block.strip().splitlines()
        if not lines:
            continue

        # Locate the --> timing line and collect text lines
        timing_line = None
        text_lines = []
        for line in lines:
            if "-->" in line:
                timing_line = line
            elif (line
                  and not line.startswith("WEBVTT")
                  and not line.startswith("Kind:")
                  and not line.startswith("Language:")
                  and not re.match(r"^\d+$", line)):
                text_lines.append(line)

        if not timing_line or not text_lines:
            continue

        # Skip intermediate cues -- they contain word-level <c> or inline time tags
        combined = " ".join(text_lines)
        if "<c>" in combined or "<00:" in combined:
            continue

        # Parse start time and clean text
        start_str = timing_line.split("-->")[0].strip()
        start_sec = ts_to_seconds(start_str)
        text = clean_line(combined)
        if text:
            entries.append((start_sec, text))

    return entries


def seconds_to_mmss(s):
    """Convert seconds to MM:SS string, e.g. 5432 -> '90:32'."""
    s = int(s)
    return f"{s // 60:02d}:{s % 60:02d}"


def group_into_paragraphs(entries, gap_seconds=3.0):
    """
    Merge consecutive cues into paragraphs whenever the gap between adjacent
    cues is less than gap_seconds.  A gap >= gap_seconds starts a new paragraph.
    Returns list of (start_seconds, paragraph_text) tuples.
    """
    if not entries:
        return []

    paragraphs = []
    current_start = entries[0][0]    # timestamp of the current paragraph's first cue
    current_lines = [entries[0][1]]  # text lines accumulated so far

    for i in range(1, len(entries)):
        gap = entries[i][0] - entries[i - 1][0]  # seconds between this cue and the previous

        if gap >= gap_seconds:
            # Close the current paragraph and open a new one
            paragraphs.append((current_start, " ".join(current_lines)))
            current_start = entries[i][0]
            current_lines = [entries[i][1]]
        else:
            current_lines.append(entries[i][1])

    # Flush the final paragraph
    paragraphs.append((current_start, " ".join(current_lines)))
    return paragraphs


# --- Main ---
entries    = parse_vtt(VTT_PATH)
paragraphs = group_into_paragraphs(entries, gap_seconds=3.0)

# Build output lines: [MM:SS] text
lines_out   = [f"[{seconds_to_mmss(start)}] {text}" for start, text in paragraphs]
output_text = "\n\n".join(lines_out)

if OUT_PATH:
    # Write to file when an explicit output path is provided
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write(output_text + "\n")
    print(f"Written {len(paragraphs)} paragraphs to: {OUT_PATH}", file=sys.stderr)
else:
    # Default: print to stdout so Claude can read it directly
    print(output_text)
    print(f"\n--- Total paragraphs: {len(paragraphs)} ---", file=sys.stderr)
