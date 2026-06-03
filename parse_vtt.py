"""
Parse a YouTube auto-generated VTT subtitle file into clean timestamped text.
Auto-generated VTTs repeat lines as each word is added — we deduplicate
by keeping only the 'final' version of each cue (the one with no inline
word-level <c> tags, which is the completed line).
"""

import re
import sys

VTT_PATH = r"C:\Users\awt\AppData\Local\Temp\ytdl\Tuesday Talks with Britin and Ann.en.vtt"
OUT_PATH  = r"C:\Users\awt\AppData\Local\Temp\ytdl\transcript_clean.txt"

def ts_to_seconds(ts):
    """Convert HH:MM:SS.mmm timestamp to float seconds."""
    h, m, s = ts.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s)

def clean_line(text):
    """Remove VTT word-level timing tags and trim."""
    text = re.sub(r"<[^>]+>", "", text)   # remove all HTML/VTT tags
    text = text.strip()
    return text

def parse_vtt(path):
    """
    Returns list of (start_seconds, text) tuples.
    Only keeps cues whose text has no <c> tags (i.e. the 'finished' line).
    """
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    # Split into blocks separated by blank lines
    blocks = re.split(r"\n\n+", raw.strip())

    entries = []
    for block in blocks:
        lines = block.strip().splitlines()
        if not lines:
            continue
        # Find the timing line
        timing_line = None
        text_lines = []
        for line in lines:
            if "-->" in line:
                timing_line = line
            elif line and not line.startswith("WEBVTT") and not line.startswith("Kind:") \
                 and not line.startswith("Language:") and not re.match(r"^\d+$", line):
                text_lines.append(line)

        if not timing_line or not text_lines:
            continue

        # Only keep cues whose text lines contain NO <c> tags (the final form)
        combined = " ".join(text_lines)
        if "<c>" in combined or "<00:" in combined:
            continue  # skip intermediate word-level cues

        # Parse start time
        start_str = timing_line.split("-->")[0].strip()
        start_sec = ts_to_seconds(start_str)

        text = clean_line(combined)
        if text and text != " ":
            entries.append((start_sec, text))

    return entries

def seconds_to_hms(s):
    """Convert float seconds to HH:MM:SS string."""
    s = int(s)
    h = s // 3600
    m = (s % 3600) // 60
    sec = s % 60
    return f"{h:02d}:{m:02d}:{sec:02d}"

def group_into_paragraphs(entries, gap_seconds=4.0):
    """
    Group consecutive entries into paragraphs when there's a gap >= gap_seconds.
    Returns list of (start_seconds, paragraph_text) tuples.
    """
    if not entries:
        return []

    paragraphs = []
    current_start = entries[0][0]
    current_lines = [entries[0][1]]

    for i in range(1, len(entries)):
        prev_start = entries[i-1][0]
        curr_start = entries[i][0]
        gap = curr_start - prev_start

        if gap >= gap_seconds:
            paragraphs.append((current_start, " ".join(current_lines)))
            current_start = curr_start
            current_lines = [entries[i][1]]
        else:
            current_lines.append(entries[i][1])

    paragraphs.append((current_start, " ".join(current_lines)))
    return paragraphs

entries = parse_vtt(VTT_PATH)
print(f"Total cues parsed: {len(entries)}")

paragraphs = group_into_paragraphs(entries, gap_seconds=3.0)
print(f"Total paragraphs: {len(paragraphs)}")

with open(OUT_PATH, "w", encoding="utf-8") as out:
    for start, text in paragraphs:
        out.write(f"[{seconds_to_hms(start)}] {text}\n\n")

print(f"Written to: {OUT_PATH}")

# Also print first 20 paragraphs to console for verification
for start, text in paragraphs[:20]:
    print(f"[{seconds_to_hms(start)}] {text[:100]}")
