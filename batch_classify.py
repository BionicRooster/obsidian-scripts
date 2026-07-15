"""Batch move and tag files for Obsidian vault classification."""
import os
import re
import shutil
from pathlib import Path

VAULT = Path("C:/Users/awt/Sync/Obsidian")
CLIPPINGS = VAULT / "10 - Clippings"

# --- move plan: (source, dest_dir, tags_to_add) ---
moves = [
    # Vault root
    (VAULT / "Rewiring America Go Electric Digital Guide.md",
     VAULT / "01/Home",
     ["electrification", "climate", "home-improvement", "IRA", "energy", "sustainability"]),

    # Bahá'í
    (CLIPPINGS / "Deepening Meeting.md",                 VAULT / "01/Bahá'í", ["bahai", "community"]),
    (CLIPPINGS / "I Am Nothing \u2013 A Hollow Reed.md",      VAULT / "01/Bahá'í", ["bahai", "prayer", "spirituality"]),
    (CLIPPINGS / "Newly Revealed Prayer.md",             VAULT / "01/Bahá'í", ["bahai", "prayer"]),
    (CLIPPINGS / "Online Course on the Baha'i Faith.md", VAULT / "01/Bahá'í", ["bahai", "education", "course"]),
    (CLIPPINGS / "Race Amity Day Planning Meeting.md",   VAULT / "01/Bahá'í", ["bahai", "race-amity", "community"]),
    (CLIPPINGS / "Race Amity Flyer Mockup with border.md", VAULT / "01/Bahá'í", ["bahai", "race-amity"]),
    (CLIPPINGS / "The Religious Mission of the English-Speaking Nations.md",
                                                          VAULT / "01/Bahá'í", ["bahai", "religion"]),
    (CLIPPINGS / "How to Be a Better Ally for Racial Justice - BahaiTeachings.org.md",
                                                          VAULT / "01/Bahá'í", ["bahai", "race-amity", "social-justice"]),

    # Science
    (CLIPPINGS / "Devastating Ice Age Floods That Occurred in the Pacific Northwest Fascinate Scientists.md",
                                                          VAULT / "01/Science", ["geology", "ice-age", "flooding", "pacific-northwest"]),
    (CLIPPINGS / "Ice Age Floods.md",                    VAULT / "01/Science", ["geology", "ice-age", "flooding"]),
    (CLIPPINGS / "The Cataclysmic Flood That Wasn't.md", VAULT / "01/Science", ["geology", "ice-age", "flooding"]),
    (CLIPPINGS / "The Volcanic Explosivity Index (Vei) Comparing Eruptions.md",
                                                          VAULT / "01/Science", ["geology", "volcanoes", "science"]),

    # Social
    (CLIPPINGS / "African-American Community Builders.md",
                                                          VAULT / "01/Social", ["AfricanAmerican", "community", "BlackHistory"]),
    (CLIPPINGS / "First They Ignore You, Then They Ridicule You, Then They Fight You, and Then You Win.md",
                                                          VAULT / "01/Social", ["activism", "social-change", "inspiration"]),
    (CLIPPINGS / "GCCMA Meeting Pictures.md",            VAULT / "01/Social", ["GCCMA", "Georgetown", "community"]),
    (CLIPPINGS / "Gini Coefficient by Country 2026.md",  VAULT / "01/Social", ["economics", "inequality", "data"]),
    (CLIPPINGS / "What If the Typical Worker\u2019s Pay Had Risen Like CEO Salaries.md",
                                                          VAULT / "01/Social", ["economics", "inequality", "labor"]),
    (CLIPPINGS / "Worst of the worst Most US immigrants targeted for deportation in 2025 had no criminal charges, documents reveal.md",
                                                          VAULT / "01/Social", ["immigration", "politics", "social-justice"]),
    (CLIPPINGS / "Backpack discovered as search for Nancy Guthrie reaches Day 22.md",
                                                          VAULT / "01/Social", ["news", "missing-person"]),

    # Health
    (CLIPPINGS / "4 Ways Plant Protein is Healthier Than Animal Protein.md",
                                                          VAULT / "01/Health", ["nutrition", "plant-based", "protein"]),
    (CLIPPINGS / "A Quiet Superpower.md",                VAULT / "01/Health", ["health", "wellness"]),
    (CLIPPINGS / "Anterior Cervical Discectomy & Fusion.md",
                                                          VAULT / "01/Health", ["health", "surgery", "spine"]),
    (CLIPPINGS / "Hearing Consonants.md",                VAULT / "01/Health", ["hearing", "health", "audiology"]),
    (CLIPPINGS / "Hibiclens Uses, Side Effects & Warnings.md",
                                                          VAULT / "01/Health", ["health", "medical", "skincare"]),
    (CLIPPINGS / "How to Tell If Your Fitness Class Is Too Loud.md",
                                                          VAULT / "01/Health", ["health", "hearing", "fitness"]),
    (CLIPPINGS / "How to Use Google Maps to Find Fresher Air.md",
                                                          VAULT / "01/Health", ["health", "air-quality", "environment"]),
    (CLIPPINGS / "The Dyslexie Font Makes Reading Easier for People with Dyslexia.md",
                                                          VAULT / "01/Health", ["dyslexia", "accessibility", "learning"]),
    (CLIPPINGS / "UCLA Study Identifies How the Brain Links Memories _ UCLA Health.md",
                                                          VAULT / "01/Health", ["neuroscience", "memory", "brain"]),
    (CLIPPINGS / "University Dental - Round Rock, TX.md",
                                                          VAULT / "01/Health", ["dental", "healthcare", "local"]),

    # Technology
    (CLIPPINGS / "3 Fixes for Something Went Wrong Error in Gmail.md",
                                                          VAULT / "01/Technology", ["gmail", "troubleshooting", "email"]),
    (CLIPPINGS / "Actural Window Rollup License.md",     VAULT / "01/Technology", ["software", "license", "windows"]),
    (CLIPPINGS / "Creating My First Home Server.md",     VAULT / "01/Technology", ["home-server", "self-hosting", "linux"]),
    (CLIPPINGS / "Email Settings for Google Gmail and GSuite \u2013 Postbox Support.md",
                                                          VAULT / "01/Technology", ["email", "gmail", "settings"]),
    (CLIPPINGS / "Flixeasy Microsoft Project and Visio Purchase.md",
                                                          VAULT / "01/Technology", ["software", "license", "microsoft"]),
    (CLIPPINGS / "MyKeyFinder Output.md",                VAULT / "01/Technology", ["software", "license", "windows"]),
    (CLIPPINGS / "MyKeyFinder Output_2.md",              VAULT / "01/Technology", ["software", "license", "windows"]),
    (CLIPPINGS / "Office Professional Plus.md",          VAULT / "01/Technology", ["software", "microsoft", "license"]),
    (CLIPPINGS / "Your Windows Folder is Full of Old Nvidia and Amd Installers \u2014 Here\u2019s How to Wipe Them.md",
                                                          VAULT / "01/Technology", ["windows", "maintenance", "drivers"]),

    # FOL
    (CLIPPINGS / "2021 Giving Season Summary.md",        VAULT / "01/FOL", ["FOL", "fundraising", "library"]),
    (CLIPPINGS / "FOL Help File.md",                     VAULT / "01/FOL", ["FOL", "library"]),
    (CLIPPINGS / "Friends of the Georgetown Texas Public Library Flixeasy Order.md",
                                                          VAULT / "01/FOL", ["FOL", "library", "software"]),

    # Finance
    (CLIPPINGS / "Accounts to Monitor.md",               VAULT / "01/Finance", ["finance", "accounts"]),
    (CLIPPINGS / "Savings Bond Document.md",             VAULT / "01/Finance", ["finance", "savings-bond"]),
    (CLIPPINGS / "The Daniel Norris Code for Success - The Simple Dollar.md",
                                                          VAULT / "01/Finance", ["finance", "personal-finance", "mindset"]),

    # Genealogy
    (CLIPPINGS / "Egill Aunsson, King of the Sweedes.md",
                                                          VAULT / "01/Genealogy", ["genealogy", "history", "ancestry"]),
    (CLIPPINGS / "How Do I Merge Two Family Trees.md",   VAULT / "01/Genealogy", ["genealogy", "family-tree"]),

    # NLP_Psy
    (CLIPPINGS / "Competence Framework.md",              VAULT / "01/NLP_Psy", ["psychology", "competence", "learning"]),
    (CLIPPINGS / "The Five Laws of Stupidity - Carlo Cipolla.md",
                                                          VAULT / "01/NLP_Psy", ["psychology", "stupidity", "social-theory"]),

    # Home
    (CLIPPINGS / "Aiden Workforce Commission Help.md",   VAULT / "01/Home", ["community", "workforce", "local"]),
    (CLIPPINGS / "Heat H2o Hot Water Recirculation System.md",
                                                          VAULT / "01/Home", ["home-improvement", "plumbing", "energy"]),
    (CLIPPINGS / "People Pictures 1.md",                 VAULT / "01/Home", ["photos", "community"]),
    (CLIPPINGS / "People Pictures 2.md",                 VAULT / "01/Home", ["photos", "community"]),
    (CLIPPINGS / "People Pictures 3.md",                 VAULT / "01/Home", ["photos", "community"]),
    (CLIPPINGS / "San Gabriel Film Proposed Movie List.md",
                                                          VAULT / "01/Home", ["film", "movies", "community"]),
    (CLIPPINGS / "San Gabriel Film Series Meeting.md",   VAULT / "01/Home", ["film", "movies", "community"]),
    (CLIPPINGS / "The Shell Fisherman.md",               VAULT / "01/Home", ["art", "photography"]),
    (CLIPPINGS / "WCWBF Steering Committee Meeting.md",  VAULT / "01/Home", ["community", "meeting", "local"]),

    # Travel
    (CLIPPINGS / "Hop-On Hop-Off Big Bus Chicago Discount Tickets  Go City\u00ae.md",
                                                          VAULT / "01/Travel", ["travel", "chicago", "tourism"]),

    # Recipes
    (CLIPPINGS / "This Baking Chart Helps You Convert Between Pan Sizes.md",
                                                          VAULT / "01/Recipes", ["baking", "cooking", "reference"]),
]


def add_tags_to_file(file_path: Path, new_tags: list) -> bool:
    """Add tags to file frontmatter if not already present. Returns True if modified."""
    content = file_path.read_text(encoding="utf-8")

    if not content.startswith("---"):
        # No frontmatter — prepend minimal block
        tags_yaml = "\n".join(f"  - {t}" for t in new_tags)
        content = f"---\ntags:\n{tags_yaml}\n---\n\n" + content
        file_path.write_text(content, encoding="utf-8")
        return True

    fm_end = content.find("\n---", 3)
    if fm_end == -1:
        return False

    frontmatter = content[3:fm_end]

    tags_match = re.search(r"^tags:\s*\n((?:  - .+\n)*)", frontmatter, re.MULTILINE)
    if tags_match:
        existing_block = tags_match.group(0)
        existing_tags = re.findall(r"  - (.+)", existing_block)
        to_insert = [t for t in new_tags if t not in existing_tags]
        if not to_insert:
            return False
        new_block = existing_block.rstrip("\n") + "\n" + "\n".join(f"  - {t}" for t in to_insert) + "\n"
        new_frontmatter = frontmatter.replace(existing_block, new_block)
    else:
        # Empty "tags:" line or no tags field at all
        tags_empty = re.search(r"^tags:\s*$", frontmatter, re.MULTILINE)
        tags_yaml = "\n".join(f"  - {t}" for t in new_tags)
        if tags_empty:
            new_frontmatter = re.sub(r"^tags:\s*$", f"tags:\n{tags_yaml}", frontmatter, flags=re.MULTILINE)
        else:
            new_frontmatter = frontmatter + f"tags:\n{tags_yaml}\n"

    new_content = "---" + new_frontmatter + "\n---" + content[fm_end + 4:]
    file_path.write_text(new_content, encoding="utf-8")
    return True


moved = []
skipped = []
errors = []

for src, dest_dir, tags in moves:
    if not src.exists():
        # Try to find with similar name (e.g. smart quotes in filename)
        skipped.append(f"NOT FOUND: {src.name}")
        continue
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name
    if dest.exists():
        skipped.append(f"ALREADY EXISTS: {dest_dir.name}/{src.name}")
        continue
    try:
        shutil.move(str(src), str(dest))
        if tags:
            add_tags_to_file(dest, tags)
        moved.append(f"{src.parent.name}/{src.name}  →  01/{dest_dir.name}")
    except Exception as e:
        errors.append(f"ERROR {src.name}: {e}")

print(f"\n=== MOVED ({len(moved)}) ===")
for m in moved:
    print(f"  {m}")

if skipped:
    print(f"\n=== SKIPPED ({len(skipped)}) ===")
    for s in skipped:
        print(f"  {s}")

if errors:
    print(f"\n=== ERRORS ({len(errors)}) ===")
    for e in errors:
        print(f"  {e}")
