"""
MOC Cleanup — remove misplaced, duplicate, and truncated links.
Each removal is accompanied by where the correct link already exists.
"""
from pathlib import Path

MOC_DIR = Path("C:/Users/awt/Sync/Obsidian/00 - Home Dashboard")

# (moc_file, link_line_to_remove, reason)
REMOVALS = [

    # ── Bahá'í Faith MOC ──────────────────────────────────────────────
    # "Can computers be racist" is a technology/AI topic — already in Technology MOC > AI & Machine Learning
    (MOC_DIR / "MOC - Bah\xe1'\xed Faith.md",
     "- [[Can computers be racist]]",
     "Tech topic -> already in Technology MOC > AI & Machine Learning"),

    # "Major causes of disunity" is duplicated — also exists in Core Teachings (correct location)
    # Remove the duplicate from Social Issues & Unity
    (MOC_DIR / "MOC - Bah\xe1'\xed Faith.md",
     "- [[Major causes of disunity]]",
     "Duplicate — already in Core Teachings section",
     "## Social Issues & Unity"),   # only remove from this section, not Core Teachings

    # "The Bab" is duplicated — already in Central Figures (correct location)
    # Remove the duplicate from Related Topics
    (MOC_DIR / "MOC - Bah\xe1'\xed Faith.md",
     "- [[The Bab]]",
     "Duplicate — already in Central Figures section",
     "## Related Topics"),

    # ── Health & Nutrition MOC — truncated/old duplicate links ─────────
    # Full name "University Dental - Round Rock, TX" already exists in the MOC
    (MOC_DIR / "MOC - Health & Nutrition.md",
     "- [[University Dental]]",
     "Truncated — full name [[University Dental - Round Rock, TX]] already in MOC"),

    # Full name "Hibiclens Uses, Side Effects & Warnings" already exists in the MOC
    (MOC_DIR / "MOC - Health & Nutrition.md",
     "- [[Hibiclens Uses, Side Effects]]",
     "Truncated — full name [[Hibiclens Uses, Side Effects & Warnings]] already in MOC"),

    # Full name "How to Tell If Your Fitness Class Is Too Loud" already exists in the MOC
    (MOC_DIR / "MOC - Health & Nutrition.md",
     "- [[How to Tell if Your]]",
     "Truncated — full name [[How to Tell If Your Fitness Class Is Too Loud]] already in MOC"),

    # ── Home & Practical Life MOC ─────────────────────────────────────
    # Finance item in Practical Tips — already in Finance MOC > Financial Management
    (MOC_DIR / "MOC - Home & Practical Life.md",
     "- [[Savings Bond Document]]",
     "Finance item -> already in Finance MOC > Financial Management"),

    # Genealogy item in Practical Tips — already in Genealogy MOC > Resources & How-Tos
    (MOC_DIR / "MOC - Home & Practical Life.md",
     "- [[How do I merge two family trees]]",
     "Genealogy item -> already in Genealogy MOC > Resources & How-Tos"),

    # Truncated Finance link in Entertainment & Film — already in Finance MOC
    (MOC_DIR / "MOC - Home & Practical Life.md",
     "- [[The Daniel Norris Co]]",
     "Truncated Finance link -> already in Finance MOC > Resources & Books"),

    # Technology/Privacy topic in Home Projects — already in Technology MOC > Digital Privacy
    (MOC_DIR / "MOC - Home & Practical Life.md",
     "- [[How to Erase Yourself]]",
     "Tech/privacy topic -> already in Technology MOC > Digital Privacy & Security"),

    # ── Technology & Computers MOC ────────────────────────────────────
    # FOL item in Software & Tools — already in FOL MOC > FOL Operations
    (MOC_DIR / "MOC - Technology & Computers.md",
     "- [[PersonalWeb - FOL help file]]",
     "FOL item -> already in FOL MOC > FOL Operations & Procedures"),

    # ── Social Issues MOC ─────────────────────────────────────────────
    # "'Anything that can be built can be taken down'" is duplicated
    # Exists in Human Rights & Social Justice AND Environment & Sustainability
    # Keep it in Human Rights, remove from Environment
    (MOC_DIR / "MOC - Social Issues.md",
     "- [['Anything that can be built can be taken down']]",
     "Duplicate — already in Human Rights & Social Justice section",
     "## Environment & Sustainability"),
]


def remove_line_from_section(moc_path: Path, line_to_remove: str,
                              reason: str, section_hint: str = None) -> str:
    """
    Remove a specific bullet line from a MOC file.
    If section_hint is given, only remove from that section (handles duplicates).
    Returns status string.
    """
    if not moc_path.exists():
        return f"MOC NOT FOUND: {moc_path.name}"

    content = moc_path.read_text(encoding="utf-8")
    lines = content.split("\n")

    occurrences = [i for i, l in enumerate(lines) if l.strip() == line_to_remove.strip()]

    if not occurrences:
        return f"NOT FOUND: {line_to_remove.strip()[:60]}"

    if section_hint and len(occurrences) > 1:
        # Find which occurrence is in the target section
        target_idx = None
        for occ in occurrences:
            # Walk backwards to find the section header
            for j in range(occ, -1, -1):
                if lines[j].startswith("## "):
                    if lines[j].strip() == section_hint.strip():
                        target_idx = occ
                    break
            if target_idx is not None:
                break
        if target_idx is None:
            return f"SECTION '{section_hint}' not found for: {line_to_remove.strip()[:50]}"
        remove_idx = target_idx
    elif section_hint and len(occurrences) == 1:
        # Only one occurrence — verify it's in the right section
        occ = occurrences[0]
        for j in range(occ, -1, -1):
            if lines[j].startswith("## "):
                if lines[j].strip() != section_hint.strip():
                    return f"SKIP — only occurrence is NOT in '{section_hint}'"
                break
        remove_idx = occ
    else:
        remove_idx = occurrences[0]

    # Remove the line (and trailing blank if it leaves two consecutive blanks)
    del lines[remove_idx]
    # Clean up double blank lines
    cleaned = []
    prev_blank = False
    for l in lines:
        if l.strip() == "":
            if prev_blank:
                continue
            prev_blank = True
        else:
            prev_blank = False
        cleaned.append(l)

    moc_path.write_text("\n".join(cleaned), encoding="utf-8")
    return f"REMOVED — {reason[:80]}"


print("=== MOC CLEANUP ===\n")

results = []
for entry in REMOVALS:
    if len(entry) == 3:
        moc_path, line, reason = entry
        section_hint = None
    else:
        moc_path, line, reason, section_hint = entry

    status = remove_line_from_section(moc_path, line, reason, section_hint)
    short_moc = moc_path.name.replace("MOC - ", "").replace(".md", "")
    print(f"[{short_moc}] {line.strip()[:55]}")
    print(f"  -> {status}")
    results.append((short_moc, line.strip(), status))

removed = sum(1 for _, _, s in results if s.startswith("REMOVED"))
skipped = sum(1 for _, _, s in results if "NOT FOUND" in s or "SKIP" in s)
print(f"\nSummary: {removed} removed, {skipped} not found/skipped")
