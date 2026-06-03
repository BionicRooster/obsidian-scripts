"""
Link moved notes to their MOCs:
1. Add nav properties to moved files pointing back to their MOC
2. Add missing wikilinks to MOC subsections
"""
import re
from pathlib import Path

VAULT = Path("D:/Obsidian/Main")
MOC_DIR = VAULT / "00 - Home Dashboard"
BAHAI_DIR = VAULT / "01" / "Bah\xe1'\xed"  # Bahá'í

# ─────────────────────────────────────────────
# Part 1: Files that need nav properties added
# ─────────────────────────────────────────────

# (file_path, nav_value)
NAV_UPDATES = [
    # Bahá'í
    *[(BAHAI_DIR / f, '"[[MOC - Bahá\'í Faith]]"') for f in [
        "Deepening Meeting.md",
        "I Am Nothing \u2013 A Hollow Reed.md",
        "Newly Revealed Prayer.md",
        "Online Course on the Baha'i Faith.md",
        "Race Amity Day Planning Meeting.md",
        "Race Amity Flyer Mockup with border.md",
        "The Religious Mission of the English-Speaking Nations.md",
        "How to Be a Better Ally for Racial Justice - BahaiTeachings.org.md",
    ]],
    # Science
    *[(VAULT / "01/Science" / f, '"[[MOC - Science & Nature]]"') for f in [
        "Devastating Ice Age Floods That Occurred in the Pacific Northwest Fascinate Scientists.md",
        "The Cataclysmic Flood That Wasn't.md",
        "The Volcanic Explosivity Index (Vei) Comparing Eruptions.md",
        # Ice Age Floods.md already has nav
    ]],
    # Social
    *[(VAULT / "01/Social" / f, '"[[MOC - Social Issues]]"') for f in [
        "African-American Community Builders.md",
        "First They Ignore You, Then They Ridicule You, Then They Fight You, and Then You Win.md",
        "GCCMA Meeting Pictures.md",
        "Gini Coefficient by Country 2026.md",
        "What If the Typical Worker\u2019s Pay Had Risen Like CEO Salaries.md",
        "Worst of the worst Most US immigrants targeted for deportation in 2025 had no criminal charges, documents reveal.md",
        "Backpack discovered as search for Nancy Guthrie reaches Day 22.md",
    ]],
    # Health
    *[(VAULT / "01/Health" / f, '"[[MOC - Health & Nutrition]]"') for f in [
        "4 Ways Plant Protein is Healthier Than Animal Protein.md",
        "A Quiet Superpower.md",
        "Anterior Cervical Discectomy & Fusion.md",
        "Hearing Consonants.md",
        "Hibiclens Uses, Side Effects & Warnings.md",
        "How to Tell If Your Fitness Class Is Too Loud.md",
        "How to Use Google Maps to Find Fresher Air.md",
        "The Dyslexie Font Makes Reading Easier for People with Dyslexia.md",
        "UCLA Study Identifies How the Brain Links Memories _ UCLA Health.md",
        "University Dental - Round Rock, TX.md",
    ]],
    # Technology
    *[(VAULT / "01/Technology" / f, '"[[MOC - Technology & Computers]]"') for f in [
        "3 Fixes for Something Went Wrong Error in Gmail.md",
        "Actural Window Rollup License.md",
        "Creating My First Home Server.md",
        "Email Settings for Google Gmail and GSuite \u2013 Postbox Support.md",
        "Flixeasy Microsoft Project and Visio Purchase.md",
        "MyKeyFinder Output.md",
        "MyKeyFinder Output_2.md",
        "Office Professional Plus.md",
        "Your Windows Folder is Full of Old Nvidia and Amd Installers \u2014 Here's How to Wipe Them.md",
    ]],
    # FOL
    *[(VAULT / "01/FOL" / f, '"[[MOC - Friends of the Georgetown Public Library]]"') for f in [
        "2021 Giving Season Summary.md",
        "FOL Help File.md",
        "Friends of the Georgetown Texas Public Library Flixeasy Order.md",
    ]],
    # Finance
    *[(VAULT / "01/Finance" / f, '"[[MOC - Finance & Investment]]"') for f in [
        "Accounts to Monitor.md",
        "Savings Bond Document.md",
        "The Daniel Norris Code for Success - The Simple Dollar.md",
    ]],
    # Genealogy
    *[(VAULT / "01/Genealogy" / f, '"[[MOC - Genealogy]]"') for f in [
        "Egill Aunsson, King of the Sweedes.md",
        "How Do I Merge Two Family Trees.md",
    ]],
    # NLP_Psy
    *[(VAULT / "01/NLP_Psy" / f, '"[[MOC - NLP & Psychology]]"') for f in [
        "Competence Framework.md",
        "The Five Laws of Stupidity - Carlo Cipolla.md",
    ]],
    # Home
    *[(VAULT / "01/Home" / f, '"[[MOC - Home & Practical Life]]"') for f in [
        "Aiden Workforce Commission Help.md",
        "Heat H2o Hot Water Recirculation System.md",
        "People Pictures 1.md",
        "People Pictures 2.md",
        "People Pictures 3.md",
        "Rewiring America Go Electric Digital Guide.md",
        "San Gabriel Film Proposed Movie List.md",
        "San Gabriel Film Series Meeting.md",
        "The Shell Fisherman.md",
        "WCWBF Steering Committee Meeting.md",
    ]],
    # Travel
    (VAULT / "01/Travel" / "Hop-On Hop-Off Big Bus Chicago Discount Tickets  Go City\u00ae.md",
     '"[[MOC - Travel & Exploration]]"'),
    # Recipes
    (VAULT / "01/Recipes" / "This Baking Chart Helps You Convert Between Pan Sizes.md",
     '"[[MOC - Recipes]]"'),
]


def add_or_update_nav(file_path: Path, nav_value: str) -> str:
    """Add or update the nav property in frontmatter. Returns status string."""
    if not file_path.exists():
        return f"NOT FOUND: {file_path.name[:50]}"

    content = file_path.read_text(encoding="utf-8")

    # Check if nav already exists with same value
    if f'nav: {nav_value}' in content:
        return f"SKIP (nav exists): {file_path.name[:50]}"

    if content.startswith("---"):
        fm_end = content.find("\n---", 3)
        if fm_end != -1:
            frontmatter = content[3:fm_end]
            if "nav:" in frontmatter:
                # Replace existing nav line
                new_frontmatter = re.sub(r'^nav:.*$', f'nav: {nav_value}', frontmatter, flags=re.MULTILINE)
                new_content = "---" + new_frontmatter + "\n---" + content[fm_end + 4:]
            else:
                # Add nav before first non-empty key (after opening ---)
                new_frontmatter = f"\nnav: {nav_value}" + frontmatter
                new_content = "---" + new_frontmatter + "\n---" + content[fm_end + 4:]
            file_path.write_text(new_content, encoding="utf-8")
            return f"nav added: {file_path.name[:50]}"

    # No frontmatter — prepend minimal block
    new_content = f"---\nnav: {nav_value}\n---\n\n" + content
    file_path.write_text(new_content, encoding="utf-8")
    return f"frontmatter+nav added: {file_path.name[:50]}"


# ─────────────────────────────────────────────
# Part 2: MOC wikilink additions
# ─────────────────────────────────────────────
# (moc_file, section_header, wikilinks_to_add_if_missing)

MOC_ADDITIONS = [
    # Bahá'í MOC
    (MOC_DIR / "MOC - Bah\xe1'\xed Faith.md",
     "## Community & Service",
     ["[[Race Amity Day Planning Meeting]]",
      "[[Race Amity Flyer Mockup with border]]"]),

    # Social Issues MOC
    (MOC_DIR / "MOC - Social Issues.md",
     "## Georgetown & Local Community",
     ["[[GCCMA Meeting Pictures]]",
      "[[Backpack discovered as search for Nancy Guthrie reaches Day 22]]"]),

    (MOC_DIR / "MOC - Social Issues.md",
     "## Human Rights & Social Justice",
     ["[[Worst of the worst Most US immigrants targeted for deportation in 2025 had no criminal charges, documents reveal]]"]),

    # Health MOC
    (MOC_DIR / "MOC - Health & Nutrition.md",
     "## Plant-Based Nutrition",
     ["[[4 Ways Plant Protein is Healthier Than Animal Protein]]"]),

    (MOC_DIR / "MOC - Health & Nutrition.md",
     "## Medical & Health",
     ["[[Anterior Cervical Discectomy & Fusion]]",
      "[[Hearing Consonants]]",
      "[[How to Use Google Maps to Find Fresher Air]]",
      "[[Hibiclens Uses, Side Effects & Warnings]]",
      "[[The Dyslexie Font Makes Reading Easier for People with Dyslexia]]",
      "[[UCLA Study Identifies How the Brain Links Memories _ UCLA Health]]",
      "[[University Dental - Round Rock, TX]]"]),

    (MOC_DIR / "MOC - Health & Nutrition.md",
     "## Exercise & Wellness",
     ["[[How to Tell If Your Fitness Class Is Too Loud]]"]),

    # Technology MOC
    (MOC_DIR / "MOC - Technology & Computers.md",
     "## Software & Tools",
     ["[[3 Fixes for Something Went Wrong Error in Gmail]]",
      "[[Email Settings for Google Gmail and GSuite \u2013 Postbox Support]]",
      "[[MyKeyFinder Output]]",
      "[[MyKeyFinder Output_2]]",
      "[[Office Professional Plus]]"]),

    (MOC_DIR / "MOC - Technology & Computers.md",
     "## Software Licenses & Purchases",
     ["[[Actural Window Rollup License]]",
      "[[Flixeasy Microsoft Project and Visio Purchase]]"]),

    # FOL MOC
    (MOC_DIR / "MOC - Friends of the Georgetown Public Library.md",
     "## FOL Operations & Procedures",
     ["[[Friends of the Georgetown Texas Public Library Flixeasy Order]]"]),

    # Finance MOC
    (MOC_DIR / "MOC - Finance & Investment.md",
     "## Financial Management",
     ["[[Accounts to Monitor]]",
      "[[Savings Bond Document]]"]),

    (MOC_DIR / "MOC - Finance & Investment.md",
     "## Resources & Books",
     ["[[The Daniel Norris Code for Success - The Simple Dollar]]"]),

    # Genealogy MOC
    (MOC_DIR / "MOC - Genealogy.md",
     "## Talbot Heredity & Noble Lines",
     ["[[Egill Aunsson, King of the Sweedes]]"]),

    (MOC_DIR / "MOC - Genealogy.md",
     "## Resources & How-Tos",
     ["[[How Do I Merge Two Family Trees]]"]),

    # Home MOC
    (MOC_DIR / "MOC - Home & Practical Life.md",
     "## Home Projects & Repairs",
     ["[[Rewiring America Go Electric Digital Guide]]"]),

    (MOC_DIR / "MOC - Home & Practical Life.md",
     "## San Gabriel Film Series",
     ["[[San Gabriel Film Proposed Movie List]]"]),

    (MOC_DIR / "MOC - Home & Practical Life.md",
     "## Entertainment & Film",
     ["[[The Shell Fisherman]]"]),

    # Travel MOC
    (MOC_DIR / "MOC - Travel & Exploration.md",
     "## Travel Tips & Resources",
     ["[[Hop-On Hop-Off Big Bus Chicago Discount Tickets  Go City\u00ae]]"]),

    # Recipes MOC
    (MOC_DIR / "MOC - Recipes.md",
     "## Reference",
     ["[[This Baking Chart Helps You Convert Between Pan Sizes]]"]),
]


def add_links_to_section(moc_path: Path, section_header: str, links: list) -> list:
    """Add missing wikilinks after the given section header. Returns list of status strings."""
    if not moc_path.exists():
        return [f"MOC NOT FOUND: {moc_path.name}"]

    content = moc_path.read_text(encoding="utf-8")
    results = []
    modified = False

    for link in links:
        link_text = link.strip("[]").strip()
        # Check if the link (or any variation) already exists
        if link in content:
            results.append(f"  SKIP (exists): {link_text[:60]}")
            continue

        # Find the section header
        header_pos = content.find(f"\n{section_header}")
        if header_pos == -1:
            results.append(f"  SECTION NOT FOUND ({section_header}): {link_text[:40]}")
            continue

        # Find where this section's content ends (next ## heading or end of file or ---)
        search_from = header_pos + len(section_header) + 1
        next_section = re.search(r'\n##+ ', content[search_from:])
        next_divider = content.find("\n---", search_from)

        if next_section:
            section_end = search_from + next_section.start()
        elif next_divider != -1:
            section_end = next_divider
        else:
            section_end = len(content)

        section_content = content[search_from:section_end]

        # Find the last bullet point in this section
        last_bullet = section_content.rfind("\n- ")
        if last_bullet != -1:
            insert_pos = search_from + last_bullet + len("\n- " + section_content[last_bullet + 3:].split("\n")[0])
        else:
            # No bullets yet, insert after the header line
            end_of_header_line = content.find("\n", header_pos + 1)
            insert_pos = end_of_header_line

        insert_text = f"\n- {link}"
        content = content[:insert_pos] + insert_text + content[insert_pos:]
        modified = True
        results.append(f"  ADDED to {section_header}: {link_text[:60]}")

        # Update search positions for next link (content has changed)

    if modified:
        moc_path.write_text(content, encoding="utf-8")

    return results


# ─────────────────────────────────────────────
# Run everything
# ─────────────────────────────────────────────

print("=== ADDING NAV PROPERTIES ===")
nav_added = 0
nav_skipped = 0
nav_missing = 0
for file_path, nav_value in NAV_UPDATES:
    result = add_or_update_nav(file_path, nav_value)
    print(f"  {result}")
    if "SKIP" in result:
        nav_skipped += 1
    elif "NOT FOUND" in result:
        nav_missing += 1
    else:
        nav_added += 1

print(f"\n  Summary: {nav_added} added, {nav_skipped} already had nav, {nav_missing} not found")

print("\n=== ADDING MOC LINKS ===")
for moc_path, section, links in MOC_ADDITIONS:
    print(f"\n{moc_path.name} > {section}")
    results = add_links_to_section(moc_path, section, links)
    for r in results:
        print(r)

print("\nDone.")
