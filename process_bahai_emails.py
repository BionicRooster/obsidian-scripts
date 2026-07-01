#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
process_bahai_emails.py

Filters the Bahá'í-cluster email JSON dump down to community-only senders
and creates one vault note per surviving email under:
    D:\\Obsidian\\Main\\01\\Bahá'í\\

Source JSON: C:\\Users\\awt\\AppData\\Local\\Temp\\bahai_cluster_emails_v2.json
Each record has keys: date, subject, from_name, from_addr, preview

Filtering rules (per task spec):
  1. Keep if from_addr contains one of the community domain strings.
  2. Keep if from_addr is a personal-email-provider address AND the
     subject or preview contains at least one of a list of community
     keywords (cluster, ruhi, junior youth, etc).
  3. Discard everything else (e.g. unrelated marketing/newsletter mail
     that happened to get swept into the original 602-email cluster).
"""

import json
import os
import re
import sys

# Force stdout to UTF-8 so console printing of diacritics (Bahá'í, etc.)
# never raises a UnicodeEncodeError under Windows' default cp1252 console.
sys.stdout.reconfigure(encoding="utf-8")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Path to the source JSON dump produced by the earlier email-search step.
SOURCE_JSON = r"C:\Users\awt\AppData\Local\Temp\bahai_cluster_emails_v2.json"

# Destination vault folder for the new community-email notes. Verified via
# os.listdir that this is the CORRECT diacritical folder (B-a-h-á-'-í), not
# the typo duplicate "Bah'á'í" (stray apostrophe after "Bah") found
# alongside it.
VAULT_FOLDER = r"D:\Obsidian\Main\01\Bahá'í"

# Domain strings that, if found anywhere in from_addr (case-insensitive),
# qualify the email as community-sourced regardless of subject/preview.
COMMUNITY_DOMAINS = [
    "austinbahai.org",
    "usbnc.org",
    "bahaigeorgetowntx.org",
    "austincluster.com",
    "bodfolgeorgetown.org",
    "bahai.us",
    "bahai.org",
    "bahaiteaching.org",
]

# Personal email providers — addresses on these domains are only kept if
# the subject/preview also contains a community keyword (avoids sweeping in
# personal correspondence that isn't actually about Bahá'í community life).
PERSONAL_DOMAINS = [
    "gmail.com",
    "yahoo.com",
    "aol.com",
    "hotmail.com",
    "outlook.com",
    "icloud.com",
    "me.com",
]

# Keywords that indicate genuine community/cluster content when found in a
# personal-domain sender's subject or preview text. Matched case-insensitive.
COMMUNITY_KEYWORDS = [
    "cluster",
    "ruhi",
    "junior youth",
    "study circle",
    "reflection",
    "program of growth",
    "core activities",
    "institute",
    "enrollment",
    "area teaching",
    "tx-323",
    "milestone",
]

# Characters that are illegal (or risky) in Windows filenames; replaced with
# a single space during filename sanitization.
ILLEGAL_FILENAME_CHARS = r'<>:"/\|?*'

# Maximum total filename length (including the date prefix and the trailing
# " [email].md" suffix), per task spec.
MAX_FILENAME_LEN = 160


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def is_community_domain(from_addr: str) -> bool:
    """True if from_addr contains any of the known community org domains."""
    addr_lower = from_addr.lower()
    return any(domain in addr_lower for domain in COMMUNITY_DOMAINS)


def is_personal_domain(from_addr: str) -> bool:
    """True if from_addr's domain matches one of the personal-email providers."""
    addr_lower = from_addr.lower()
    return any(domain in addr_lower for domain in PERSONAL_DOMAINS)


def has_community_keyword(subject: str, preview: str) -> bool:
    """True if subject or preview contains at least one community keyword."""
    haystack = f"{subject} {preview}".lower()
    return any(keyword in haystack for keyword in COMMUNITY_KEYWORDS)


def passes_filter(record: dict) -> bool:
    """
    Apply Step 1 filtering logic to a single email record.
    record: dict with keys date, subject, from_name, from_addr, preview.
    Returns True if the record should be kept (community-only sender).
    """
    from_addr = record.get("from_addr") or ""
    subject = record.get("subject") or ""
    preview = record.get("preview") or ""

    if is_community_domain(from_addr):
        return True

    if is_personal_domain(from_addr) and has_community_keyword(subject, preview):
        return True

    return False


def sanitize_filename_component(text: str) -> str:
    """
    Sanitize a string for safe use in a Windows filename:
      - Replace illegal characters (< > : " / \\ | ? *) with a space.
      - Replace smart/curly apostrophes (' ') with a standard apostrophe (').
      - Collapse the result of replacements but otherwise preserve spacing.
    """
    # result accumulates the sanitized text as we walk the input characters.
    result = text
    for ch in ILLEGAL_FILENAME_CHARS:
        result = result.replace(ch, " ")
    # Smart/curly single quotes -> standard apostrophe, per global file
    # naming convention (never leave curly apostrophes in filenames).
    result = result.replace("‘", "'").replace("’", "'")
    return result


def build_filename(date_str: str, subject: str) -> str:
    """
    Construct the target filename per the task's exact recipe:
      1. date (YYYY-MM-DD)
      2. space + sanitized subject
      3. strip leading/trailing spaces and dots, truncate to 160 chars
         (including the date prefix, BEFORE the " [email]" suffix is added)
      4. append " [email]"
      5. add ".md"
    """
    # raw_stem is the unsanitized "date subject" combination.
    raw_stem = f"{date_str} {subject}"
    # sanitized_stem has illegal chars and smart quotes normalized.
    sanitized_stem = sanitize_filename_component(raw_stem)
    # Strip leading/trailing whitespace and dots (Windows disallows trailing
    # dots/spaces in filenames).
    sanitized_stem = sanitized_stem.strip(" .")
    # Truncate the date+subject portion to MAX_FILENAME_LEN characters,
    # per spec ("truncate to 160 chars total (including date prefix)") —
    # this truncation happens BEFORE the " [email].md" suffix is appended.
    truncated_stem = sanitized_stem[:MAX_FILENAME_LEN]
    # Re-strip in case truncation cut mid-trailing-space.
    truncated_stem = truncated_stem.strip(" .")
    filename = f"{truncated_stem} [email].md"
    return filename


def build_note_content(record: dict) -> str:
    """
    Build the full markdown note body for one email record, matching the
    exact template specified in the task (YAML frontmatter + body).
    """
    date_str = record.get("date") or ""
    subject = record.get("subject") or ""
    from_name = record.get("from_name") or ""
    from_addr = record.get("from_addr") or ""
    preview = record.get("preview") or ""

    # from_display combines display name and address as "Name <addr>",
    # matching the template's "from" field and body "**From:**" line.
    from_display = f"{from_name} <{from_addr}>" if from_name else from_addr

    # Escape any double quotes in the subject so the YAML frontmatter
    # title field remains valid (subject is wrapped in double quotes).
    subject_yaml_safe = subject.replace('"', '\\"')

    content = (
        "---\n"
        f'title: "{subject_yaml_safe}"\n'
        f"date: {date_str}\n"
        f'from: "{from_display}"\n'
        "tags:\n"
        "  - Bahai\n"
        "  - email\n"
        "  - cluster\n"
        "nav: \"[[MOC - Bahá'í Faith]]\"\n"
        "---\n"
        "\n"
        "[[MOC - Bahá'í Faith]]\n"
        "\n"
        f"# {subject}\n"
        "\n"
        f"**Date:** {date_str}\n"
        f"**From:** {from_display}\n"
        "\n"
        "---\n"
        "\n"
        f"{preview}\n"
    )
    return content


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Load the full 602-record source dump.
    with open(SOURCE_JSON, encoding="utf-8") as f:
        all_records = json.load(f)

    # filtered holds every record that passes the community-sender filter.
    filtered = [r for r in all_records if passes_filter(r)]

    # Ensure destination folder exists (it does, per pre-check, but this
    # makes the script safely re-runnable in a fresh vault clone too).
    os.makedirs(VAULT_FOLDER, exist_ok=True)

    created_filenames = []  # filenames actually written this run
    skipped_filenames = []  # filenames that already existed (left untouched)

    for record in filtered:
        date_str = record.get("date") or ""
        subject = record.get("subject") or "(no subject)"

        filename = build_filename(date_str, subject)
        full_path = os.path.join(VAULT_FOLDER, filename)

        if os.path.exists(full_path):
            skipped_filenames.append(filename)
            continue

        note_content = build_note_content(record)
        # Write as UTF-8 explicitly (no BOM) to preserve all diacriticals
        # exactly as sourced, per the global Obsidian encoding rule.
        with open(full_path, "w", encoding="utf-8") as out_f:
            out_f.write(note_content)
        created_filenames.append(filename)

    # ------------------------------------------------------------------
    # Summary report
    # ------------------------------------------------------------------
    print("=== Bahá'í Community Email Note Creation — Summary ===")
    print(f"Total records after filtering: {len(filtered)}")
    print(f"Total notes created: {len(created_filenames)}")
    print(f"Total skipped (already existed): {len(skipped_filenames)}")
    print()
    print("Filenames created:")
    for name in created_filenames:
        print(f"  - {name}")
    if skipped_filenames:
        print()
        print("Filenames skipped (already existed):")
        for name in skipped_filenames:
            print(f"  - {name}")


if __name__ == "__main__":
    main()
