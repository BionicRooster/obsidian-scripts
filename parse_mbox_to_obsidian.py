# parse_mbox_to_obsidian.py
# Parses Gmail mbox export into Obsidian markdown files
# Creates recipe files in 01/Recipes when recipe content is detected

import mailbox
import os
import re
import email
from email.utils import parsedate_to_datetime
from datetime import datetime
from html.parser import HTMLParser
from html import unescape
import urllib.request
import urllib.error
import ssl

# ==================== CONFIGURATION ====================
# Path to the mbox file to parse
MBOX_PATH = r"C:\Users\awt\takeout-20260203T200710Z-3-001\Takeout\Mail\Receipts.mbox"
# Output directory for general email markdown files
GMAIL_OUTPUT_DIR = r"C:\Users\awt\Sync\Obsidian\04 - GMail"
# Output directory for recipe markdown files
RECIPE_OUTPUT_DIR = r"C:\Users\awt\Sync\Obsidian\01\Recipes"

# ==================== HTML TO TEXT CONVERTER ====================
class HTMLToText(HTMLParser):
    """
    Custom HTML parser that converts HTML to plain text.
    Preserves paragraph breaks and handles common HTML entities.
    """
    def __init__(self):
        super().__init__()
        # Accumulates the parsed text content
        self.text = []
        # Tracks if we're inside a tag that should be ignored (script, style)
        self.ignore = False

    def handle_starttag(self, tag, attrs):
        """Handle opening HTML tags"""
        # Skip script and style content entirely
        if tag in ('script', 'style'):
            self.ignore = True
        # Add line breaks for block-level elements
        elif tag in ('p', 'div', 'br', 'tr', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
            self.text.append('\n')

    def handle_endtag(self, tag):
        """Handle closing HTML tags"""
        # Resume parsing after script/style blocks
        if tag in ('script', 'style'):
            self.ignore = False
        # Add line breaks after paragraphs and divs
        elif tag in ('p', 'div'):
            self.text.append('\n')

    def handle_data(self, data):
        """Handle text content between tags"""
        if not self.ignore:
            self.text.append(data)

    def get_text(self):
        """Return the accumulated plain text, cleaned up"""
        # Join all text pieces, unescape HTML entities, normalize whitespace
        result = unescape(''.join(self.text))
        # Collapse multiple newlines to max 2
        result = re.sub(r'\n{3,}', '\n\n', result)
        return result.strip()

def html_to_text(html_content):
    """
    Convert HTML content to plain text.
    Args:
        html_content: HTML string to convert
    Returns:
        Plain text string with formatting preserved
    """
    parser = HTMLToText()
    try:
        parser.feed(html_content)
        return parser.get_text()
    except:
        # Fallback: strip tags with regex if parser fails
        text = re.sub(r'<[^>]+>', ' ', html_content)
        return unescape(text).strip()

# ==================== EMAIL CONTENT EXTRACTION ====================
def get_email_body(message):
    """
    Extract the body text from an email message.
    Handles multipart messages and various content types.
    Args:
        message: email.message.Message object
    Returns:
        Tuple of (plain_text_body, html_body_converted_to_text)
    """
    plain_body = ""
    html_body = ""

    if message.is_multipart():
        # Walk through all message parts
        for part in message.walk():
            content_type = part.get_content_type()
            content_disposition = str(part.get("Content-Disposition", ""))

            # Skip attachments
            if "attachment" in content_disposition:
                continue

            try:
                # Decode the payload with proper charset handling
                payload = part.get_payload(decode=True)
                if payload:
                    # Try UTF-8 first, fall back to latin-1
                    charset = part.get_content_charset() or 'utf-8'
                    try:
                        text = payload.decode(charset)
                    except:
                        text = payload.decode('latin-1', errors='replace')

                    if content_type == "text/plain":
                        plain_body = text
                    elif content_type == "text/html":
                        html_body = text
            except Exception as e:
                continue
    else:
        # Single-part message
        content_type = message.get_content_type()
        try:
            payload = message.get_payload(decode=True)
            if payload:
                charset = message.get_content_charset() or 'utf-8'
                try:
                    text = payload.decode(charset)
                except:
                    text = payload.decode('latin-1', errors='replace')

                if content_type == "text/plain":
                    plain_body = text
                elif content_type == "text/html":
                    html_body = text
        except:
            pass

    # Prefer plain text, fall back to converted HTML
    if plain_body:
        return plain_body, False
    elif html_body:
        return html_to_text(html_body), True
    else:
        return "", False

# ==================== RECIPE DETECTION ====================
# Keywords that strongly indicate recipe content
RECIPE_KEYWORDS = [
    # Measurement terms
    'cup', 'cups', 'tablespoon', 'tablespoons', 'tbsp', 'teaspoon', 'teaspoons', 'tsp',
    'ounce', 'ounces', 'oz', 'pound', 'pounds', 'lb', 'lbs',
    # Recipe structure terms
    'ingredients', 'directions', 'instructions', 'preheat', 'bake', 'cook',
    'simmer', 'stir', 'mix', 'combine', 'serving', 'servings', 'prep time',
    'cook time', 'yield', 'makes', 'serves',
    # Common cooking actions
    'chop', 'dice', 'mince', 'slice', 'saute', 'fry', 'roast', 'grill',
    'marinate', 'whisk', 'fold', 'knead', 'dough'
]

def is_recipe_content(text, subject=""):
    """
    Determine if text content appears to be a recipe.
    Uses keyword matching and pattern detection.
    Args:
        text: The body text to analyze
        subject: Email subject line for additional context
    Returns:
        Boolean indicating if content is likely a recipe
    """
    if not text:
        return False

    text_lower = text.lower()
    subject_lower = subject.lower() if subject else ""

    # Check if subject explicitly mentions recipe
    if 'recipe' in subject_lower:
        return True

    # Count recipe-related keywords found
    keyword_count = sum(1 for kw in RECIPE_KEYWORDS if kw in text_lower)

    # Look for measurement patterns like "2 cups", "1/2 tsp", etc.
    measurement_pattern = r'\d+\s*(?:cup|tbsp|tsp|oz|lb|pound|ounce|tablespoon|teaspoon)'
    measurements_found = len(re.findall(measurement_pattern, text_lower))

    # Require multiple recipe indicators to avoid false positives
    # Need at least 5 keywords OR 3+ measurements
    return keyword_count >= 5 or measurements_found >= 3

# ==================== URL EXTRACTION AND FETCHING ====================
def extract_urls(text):
    """
    Extract all URLs from text content.
    Args:
        text: Text to search for URLs
    Returns:
        List of URL strings found
    """
    # Match http/https URLs
    url_pattern = r'https?://[^\s<>"\')\]]+[^\s<>"\')\].,]'
    urls = re.findall(url_pattern, text)
    return urls

def fetch_url_content(url):
    """
    Fetch content from a URL and convert to text.
    Args:
        url: URL to fetch
    Returns:
        Tuple of (text_content, is_recipe_boolean)
    """
    try:
        # Create SSL context that doesn't verify certificates (for compatibility)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        # Set up request with browser-like headers
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        )

        # Fetch with timeout
        with urllib.request.urlopen(req, timeout=10, context=ctx) as response:
            html = response.read().decode('utf-8', errors='replace')
            text = html_to_text(html)

            # Check if page content looks like a recipe
            is_recipe = is_recipe_content(text)

            # Also check for recipe-related URLs/domains
            recipe_domains = ['allrecipes', 'food.com', 'epicurious', 'bonappetit',
                            'seriouseats', 'foodnetwork', 'tasty', 'delish',
                            'simplyrecipes', 'budgetbytes', 'minimalistbaker']
            if any(domain in url.lower() for domain in recipe_domains):
                is_recipe = True

            return text, is_recipe
    except Exception as e:
        print(f"  Failed to fetch {url}: {e}")
        return None, False

# ==================== FILE NAME SANITIZATION ====================
def sanitize_filename(name, max_length=80):
    """
    Create a safe filename from arbitrary text.
    Removes invalid characters and limits length.
    Args:
        name: Original text to use as filename
        max_length: Maximum filename length
    Returns:
        Sanitized filename string
    """
    # Replace smart apostrophes with standard apostrophes (per CLAUDE.md)
    name = name.replace("'", "'").replace("'", "'")
    # Remove characters invalid in Windows filenames
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '', name)
    # Replace multiple spaces/underscores with single space
    name = re.sub(r'[\s_]+', ' ', name)
    # Truncate to max length while preserving word boundaries
    if len(name) > max_length:
        name = name[:max_length].rsplit(' ', 1)[0]
    return name.strip() or "Untitled"

# ==================== MARKDOWN FILE CREATION ====================
def create_markdown_file(output_dir, filename, yaml_frontmatter, content, is_recipe=False):
    """
    Write a markdown file with YAML frontmatter.
    Args:
        output_dir: Directory to write file to
        filename: Name for the file (without extension)
        yaml_frontmatter: Dict of YAML frontmatter fields
        content: Markdown body content
        is_recipe: Whether this is a recipe file (adds recipe tag)
    Returns:
        Path to created file, or None if failed
    """
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Build the file path
    safe_filename = sanitize_filename(filename)
    filepath = os.path.join(output_dir, f"{safe_filename}.md")

    # Handle filename collisions by appending counter
    counter = 1
    while os.path.exists(filepath):
        filepath = os.path.join(output_dir, f"{safe_filename} {counter}.md")
        counter += 1

    # Build YAML frontmatter section
    yaml_lines = ["---"]
    for key, value in yaml_frontmatter.items():
        if value:
            # Escape special characters in values
            if isinstance(value, str) and any(c in value for c in ':#[]{}'):
                value = f'"{value}"'
            yaml_lines.append(f"{key}: {value}")

    # Add recipe tag if this is a recipe
    if is_recipe:
        yaml_lines.append("tags:")
        yaml_lines.append("  - recipe")
        yaml_lines.append("  - email-import")
    else:
        yaml_lines.append("tags:")
        yaml_lines.append("  - email-import")

    yaml_lines.append("---")

    # Combine frontmatter and content
    full_content = '\n'.join(yaml_lines) + '\n\n' + content

    # Write file with UTF-8 encoding (per CLAUDE.md requirements)
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(full_content)
        return filepath
    except Exception as e:
        print(f"  Error writing {filepath}: {e}")
        return None

# ==================== MAIN PROCESSING ====================
def process_mbox():
    """
    Main function to process the mbox file and create Obsidian markdown files.
    Iterates through all messages, extracts content, detects recipes,
    and creates appropriate markdown files.
    """
    print(f"Opening mbox file: {MBOX_PATH}")

    # Open the mbox file
    mbox = mailbox.mbox(MBOX_PATH)

    # Counters for summary
    total_messages = 0
    gmail_files_created = 0
    recipe_files_created = 0
    urls_checked = 0

    # Process each message
    for key, message in mbox.items():
        total_messages += 1

        # Extract email headers
        subject = message.get('Subject', 'No Subject')
        # Decode encoded subject lines
        if subject:
            try:
                decoded_parts = email.header.decode_header(subject)
                subject = ''.join(
                    part.decode(charset or 'utf-8') if isinstance(part, bytes) else part
                    for part, charset in decoded_parts
                )
            except:
                pass

        from_addr = message.get('From', 'Unknown')
        to_addr = message.get('To', '')
        date_str = message.get('Date', '')
        message_id = message.get('Message-ID', '')
        gmail_labels = message.get('X-Gmail-Labels', '')

        # Parse date into ISO format
        date_iso = ""
        if date_str:
            try:
                dt = parsedate_to_datetime(date_str)
                date_iso = dt.strftime('%Y-%m-%d')
            except:
                date_iso = date_str

        print(f"\n[{total_messages}] Processing: {subject[:60]}...")

        # Get email body content
        body, was_html = get_email_body(message)

        # Build YAML frontmatter dictionary
        yaml_data = {
            'from': from_addr,
            'to': to_addr,
            'date': date_iso,
            'subject': subject,
            'gmail_labels': gmail_labels
        }

        # Check if body content is a recipe
        is_recipe = is_recipe_content(body, subject)

        # If body is mostly just URLs, try to fetch recipe content
        body_stripped = body.strip()
        urls = extract_urls(body_stripped)

        # Check if message is primarily a URL (short body with URL)
        if not is_recipe and urls and len(body_stripped) < 500:
            print(f"  Found {len(urls)} URL(s), checking for recipes...")
            for url in urls[:3]:  # Limit to first 3 URLs
                urls_checked += 1
                fetched_content, url_is_recipe = fetch_url_content(url)
                if url_is_recipe and fetched_content:
                    print(f"  Recipe found at: {url[:60]}...")
                    is_recipe = True
                    # Append fetched content to body
                    body = f"Source: {url}\n\n{fetched_content}"
                    yaml_data['source_url'] = url
                    break

        # Determine output directory and create file
        if is_recipe:
            output_dir = RECIPE_OUTPUT_DIR
            filepath = create_markdown_file(output_dir, subject, yaml_data, body, is_recipe=True)
            if filepath:
                recipe_files_created += 1
                print(f"  Created RECIPE: {os.path.basename(filepath)}")
        else:
            output_dir = GMAIL_OUTPUT_DIR
            filepath = create_markdown_file(output_dir, subject, yaml_data, body, is_recipe=False)
            if filepath:
                gmail_files_created += 1
                print(f"  Created email: {os.path.basename(filepath)}")

    # Print summary
    print("\n" + "="*60)
    print("PROCESSING COMPLETE")
    print("="*60)
    print(f"Total messages processed: {total_messages}")
    print(f"Gmail files created:      {gmail_files_created}")
    print(f"Recipe files created:     {recipe_files_created}")
    print(f"URLs checked for recipes: {urls_checked}")
    print(f"\nGmail output:  {GMAIL_OUTPUT_DIR}")
    print(f"Recipe output: {RECIPE_OUTPUT_DIR}")

if __name__ == "__main__":
    process_mbox()
