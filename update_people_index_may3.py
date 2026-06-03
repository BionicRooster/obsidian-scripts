# -*- coding: utf-8 -*-
"""
Update D:\\Obsidian\\Main\\People Index.md for the 2026-05-03 box score.
  1. Append box score link to all existing ATX player entries
  2. Update Vazquez and Wolff status (returned from injury; debuted May 3)
  3. Add new STL player + official entries in alphabetical order
"""
import sys
import re

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PEOPLE_INDEX = "D:\\Obsidian\\Main\\People Index.md"
# The box score bullet line to add
BOX = "- [[2026-05-03 - Austin FC vs St. Louis City SC Box Score]]"

with open(PEOPLE_INDEX, "r", encoding="utf-8") as f:
    content = f.read()
content = content.replace("\r\n", "\n")   # normalize line endings
original_len = len(content)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def append_to_entry(text, header, new_line):
    """
    Find the section starting with `header` (a ### line) whose body consists
    only of bullet lines (`- ...`), then append new_line after the last one.
    Skips silently if new_line is already present.
    """
    escaped = re.escape(header)
    # Match header + one-or-more bullet lines
    pat = re.compile(r"(" + escaped + r"(?:\n- [^\n]+)+)", re.MULTILINE)
    m = pat.search(text)
    if not m:
        print(f"  WARNING: not found  {header!r}")
        return text
    full = m.group(1)
    if new_line in full:
        print(f"  Already present    {header}")
        return text
    replacement = full + "\n" + new_line
    print(f"  Updated            {header}")
    return text[: m.start()] + replacement + text[m.end() :]


def insert_before(text, anchor, insertion):
    """Insert `insertion` immediately before the first occurrence of `anchor`."""
    idx = text.find(anchor)
    if idx == -1:
        print(f"  WARNING: anchor not found  {anchor[:60]!r}")
        return text
    return text[:idx] + insertion + text[idx:]


def insert_after(text, anchor, insertion):
    """Insert `insertion` immediately after the first occurrence of `anchor`."""
    idx = text.find(anchor)
    if idx == -1:
        print(f"  WARNING: anchor not found  {anchor[:60]!r}")
        return text
    end = idx + len(anchor)
    return text[:end] + insertion + text[end:]


# ---------------------------------------------------------------------------
# PART 1  –  Append May 3 box score to existing ATX player entries
# ---------------------------------------------------------------------------
print("\n=== Part 1: existing ATX entries ===")

atx_players = [
    "### Bell, Jon",
    "### Biro, Guilherme",
    "### Burton, Micah",
    "### Desler, Mikkel",
    "### Djordjevic, Mateja",
    "### Dubersarsky, Nicolas",
    "### Fodrey, CJ",
    "### Gallagher, Jon",
    "### Hines-Ike, Brendan",
    "### Kolmanic, Zan",
    "### Las, Damian",
    "### Nelson, Jayden",
    "### Pereira, Dani",
    "### Ramirez, Christian",
    "### Rosales, Joseph",
    "### Sabovic, Besard",
    "### Sanchez, Ilie",
    "### Stuver, Brad",
    "### Svatok, Oleksandr",
    "### Taylor, Robert",
    "### Thomas, Riley",
    "### Torres, Ervin",
    "### Torres, Facundo",
    "### Uzuni, Myrto",
]

for hdr in atx_players:
    content = append_to_entry(content, hdr, BOX)

# Vazquez – update status note and add box score
OLD_VZQ = "### Vazquez, Brandon\n- Austin FC 2026 roster (out injured - knee)"
NEW_VZQ = (
    "### Vazquez, Brandon\n"
    "- Austin FC 2026 roster (returned from knee injury; 2026 MLS season debut May 3 as late sub)\n"
    + BOX
)
if OLD_VZQ in content:
    content = content.replace(OLD_VZQ, NEW_VZQ)
    print("  Updated status     ### Vazquez, Brandon")
else:
    print("  WARNING: Vazquez old text not found")

# Wolff – update status note and add box score
OLD_WLF = "### Wolff, Owen\n- Austin FC 2026 roster (out injured - sports hernia)"
NEW_WLF = (
    "### Wolff, Owen\n"
    "- Austin FC 2026 roster (returned from sports hernia; 2026 MLS season debut May 3 as late sub)\n"
    + BOX
)
if OLD_WLF in content:
    content = content.replace(OLD_WLF, NEW_WLF)
    print("  Updated status     ### Wolff, Owen")
else:
    print("  WARNING: Wolff old text not found")


# ---------------------------------------------------------------------------
# PART 2  –  New STL player and official entries (alphabetical insertions)
# ---------------------------------------------------------------------------
print("\n=== Part 2: new STL entries ===")

# chr() codes for non-ASCII characters used below
# 0xfc = ü   0xf3 = ó   0xf6 = ö   0xe9 = é   0xe1 = á   0x161 = š

# B – Baumgartl, Timo  (B-A-U, after Bates, before Baumgartner)
content = insert_after(
    content,
    "### Bates, Joseph\n- [[19th Century Religious Movements]]",
    "\n### Baumgartl, Timo\n" + BOX,
)
print("  Added  Baumgartl, Timo")

# B – Becher, Simon  (B-E-C, before Beers)
content = insert_before(
    content,
    "### Beers, Kylene",
    "### Becher, Simon\n" + BOX + "\n",
)
print("  Added  Becher, Simon")

# B – Bürki, Roman  (B-U-R-K-I, between Burke and Burton)
content = insert_before(
    content,
    "### Burton, Micah",
    "### B" + chr(0xFC) + "rki, Roman\n" + BOX + "\n",
)
print("  Added  Bürki, Roman")

# C – Córdova, Sergio  (C-O-R-D, between Cordes and Cortesi)
content = insert_before(
    content,
    "### Cortesi, David E.",
    "### C" + chr(0xF3) + "rdova, Sergio\n" + BOX + "\n",
)
print("  Added  Córdova, Sergio")

# D – Durkin, Christopher  (D-U-R-K, between Durden and Dwyer)
content = insert_before(
    content,
    "### Dwyer, Linda",
    "### Durkin, Christopher\n" + BOX + "\n",
)
print("  Added  Durkin, Christopher")

# E – Edelman, Daniel  (E-D-E-L, before Eden)
content = insert_before(
    content,
    "### Eden, Guinevere",
    "### Edelman, Daniel\n" + BOX + "\n",
)
print("  Added  Edelman, Daniel")

# F – Fall, Fallou and Fall, Mbacke  (F-A-L, before Farkarlun)
content = insert_before(
    content,
    "### Farkarlun, Jimmy",
    "### Fall, Fallou\n" + BOX + "\n### Fall, Mbacke\n" + BOX + "\n",
)
print("  Added  Fall, Fallou; Fall, Mbacke")

# F – Freemon, Jon  (F-R-E, between Francis and Frisk) — referee
content = insert_before(
    content,
    "### Frisk, Howard",
    "### Freemon, Jon\n" + BOX + "\n",
)
print("  Added  Freemon, Jon")

# G – Glover, Caden  (G-L, between Giridharadas and Goatskin)
content = insert_before(
    content,
    "### Goatskin, Peat Brown Oasis",
    "### Glover, Caden\n" + BOX + "\n",
)
print("  Added  Glover, Caden")

# H – Hartel, Marcel  (H-A-R-T, between Harrison and Hatcher)
content = insert_before(
    content,
    "### Hatcher, John S.",
    "### Hartel, Marcel\n" + BOX + "\n",
)
print("  Added  Hartel, Marcel")

# H – Hassan, Muhammad  (H-A-S, after Hartel, before Hatcher) — 4th official
content = insert_before(
    content,
    "### Hatcher, John S.",
    "### Hassan, Muhammad\n" + BOX + "\n",
)
print("  Added  Hassan, Muhammad")

# H – Hiebert, Kyle  (H-I-E, between Hepburn and Hinds)
content = insert_before(
    content,
    "### Hinds, Takane",
    "### Hiebert, Kyle\n" + BOX + "\n",
)
print("  Added  Hiebert, Kyle")

# J – Jeong, Sang-bin  (J-E-O, between Jensen and Jessup) — Korean name: surname Jeong
content = insert_before(
    content,
    "### Jessup, Henry H.",
    "### Jeong, Sang-bin\n" + BOX + "\n",
)
print("  Added  Jeong, Sang-bin")

# J – Joyner, Mykhi  (J-O-Y, between Jones and Junod)
content = insert_before(
    content,
    "### Junod, Tom",
    "### Joyner, Mykhi\n" + BOX + "\n",
)
print("  Added  Joyner, Mykhi")

# J – Jurisevic, Edvin  (J-U-R, between Junod and Juskowski) — VAR official
content = insert_before(
    content,
    "### Juskowski, Amanda",
    "### Jurisevic, Edvin\n" + BOX + "\n",
)
print("  Added  Jurisevic, Edvin")

# K – Kieso, Jeremy  (K-I-E, between Khonsari and Kindle) — AR1 official
content = insert_before(
    content,
    "### Kindle, Josie sent",
    "### Kieso, Jeremy\n" + BOX + "\n",
)
print("  Added  Kieso, Jeremy")

# L – Löwen, Eduard  (L-O-W, between Lowe and Lower — ö treated as o)
content = insert_before(
    content,
    "### Lower, Claire",
    "### L" + chr(0xF6) + "wen, Eduard\n" + BOX + "\n",
)
print("  Added  Löwen, Eduard")

# L – Lundt, Ben  (L-U-N, between Lu and Lyons)
content = insert_before(
    content,
    "### Lyons, Bobbi",
    "### Lundt, Ben\n" + BOX + "\n",
)
print("  Added  Lundt, Ben")

# M – MacNaughton, Lukas  (M-A-C-N, between Macario and Madeleine)
content = insert_before(
    content,
    "### Madeleine, Sophie",
    "### MacNaughton, Lukas\n" + BOX + "\n",
)
print("  Added  MacNaughton, Lukas")

# M – McSorley, Brendan  (M-C-S, between McRae and Meetings)
content = insert_before(
    content,
    "### Meetings, Cluster",
    "### McSorley, Brendan\n" + BOX + "\n",
)
print("  Added  McSorley, Brendan")

# O – Orozco, Jaziel  (O-R-O-Z, after Orona, before Ouellette)
content = insert_before(
    content,
    "### Ouellette, Mary",
    "### Orozco, Jaziel\n" + BOX + "\n",
)
print("  Added  Orozco, Jaziel")

# O – Ostrák, Tomáš  (O-S-T, after Orozco, before Ouellette — á=0xe1 š=0x161)
content = insert_before(
    content,
    "### Ouellette, Mary",
    "### Ostr" + chr(0xE1) + "k, Tom" + chr(0xE1) + chr(0x161) + "\n" + BOX + "\n",
)
print("  Added  Ostrák, Tomáš")

# P – Patlak, Joshua  (P-A-T-L, between Parents and Patterson) — AVAR official
content = insert_before(
    content,
    "### Patterson, Jody",
    "### Patlak, Joshua\n" + BOX + "\n",
)
print("  Added  Patlak, Joshua")

# P – Pearce, Tyson  (P-E-A, between Patterson and Peek)
content = insert_before(
    content,
    "### Peek, Bill",
    "### Pearce, Tyson\n" + BOX + "\n",
)
print("  Added  Pearce, Tyson")

# P – Perez, Miguel  (P-E-R, after Perez, Carmen Marie)
content = insert_after(
    content,
    "### Perez, Carmen Marie\n- [[BE174]]",
    "\n### Perez, Miguel\n" + BOX,
)
print("  Added  Perez, Miguel")

# P – Polvara, Dante and Pompeu, Célio  (P-O-L and P-O-M, before Pool)
content = insert_before(
    content,
    "### Pool, Diana Bowden's",
    "### Polvara, Dante\n" + BOX + "\n"
    + "### Pompeu, C" + chr(0xE9) + "lio\n" + BOX + "\n",
)
print("  Added  Polvara, Dante; Pompeu, Célio")

# S – Santos, Rafael  (S-A-N-T, between Sandlin and Sarah)
content = insert_before(
    content,
    "### Sarah, Aziz Abu",
    "### Santos, Rafael\n" + BOX + "\n",
)
print("  Added  Santos, Rafael")

# S – Savage, Bennett  (S-A-V, between Sassi and Scapes) — AR2 official
content = insert_before(
    content,
    "### Scapes, Art",
    "### Savage, Bennett\n" + BOX + "\n",
)
print("  Added  Savage, Bennett")

# T – Teuchert, Cedric  (T-E-U, between Terry and Theme)
content = insert_before(
    content,
    "### Theme, Aesop",
    "### Teuchert, Cedric\n" + BOX + "\n",
)
print("  Added  Teuchert, Cedric")

# T – Totland, Tomas  (T-O-T, between Torres and Touvier)
content = insert_before(
    content,
    "### Touvier, Mathilde",
    "### Totland, Tomas\n" + BOX + "\n",
)
print("  Added  Totland, Tomas")

# W – Wallem, Conrad  (W-A-L-L, between Walk and Wallen)
content = insert_before(
    content,
    "### Wallen, Jack",
    "### Wallem, Conrad\n" + BOX + "\n",
)
print("  Added  Wallem, Conrad")

# Y – Yaro, Josh  (Y-A-R, between Yankelovich and Yocco)
content = insert_before(
    content,
    "### Yocco, Victor",
    "### Yaro, Josh\n" + BOX + "\n",
)
print("  Added  Yaro, Josh")


# ---------------------------------------------------------------------------
# Write result
# ---------------------------------------------------------------------------
with open(PEOPLE_INDEX, "w", encoding="utf-8") as f:
    f.write(content)

delta = len(content) - original_len
print(f"\n=== Done ===")
print(f"  Original : {original_len:,} chars")
print(f"  Updated  : {len(content):,} chars")
print(f"  Delta    : +{delta:,} chars")
