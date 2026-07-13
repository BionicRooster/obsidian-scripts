---
name: workflow-fix-image-links
description: Scripts and procedure for finding and fixing broken image embeds in the Obsidian vault
metadata: 
  node_type: memory
  type: reference
  originSessionId: 60c405b8-8c2b-4b8f-9074-e80d2873b489
---

## Trigger
"Fix broken image links"

## Scripts
- `C:\Users\awt\find_broken_images.ps1` — finds broken `![[image.jpg]]` embeds, locates the actual file in vault, updates the path
- `C:\Users\awt\fix_backslash_paths.ps1` — converts backslashes to forward slashes in all image paths

## Procedure

1. Run `find_broken_images.ps1` with `-Fix` parameter:
   ```
   powershell -ExecutionPolicy Bypass -File "C:\Users\awt\find_broken_images.ps1" -Limit 100 -Fix
   ```
2. Run `fix_backslash_paths.ps1` after fixing to ensure all paths use forward slashes:
   ```
   powershell -ExecutionPolicy Bypass -File "C:\Users\awt\fix_backslash_paths.ps1"
   ```

**Critical:** Obsidian requires forward slashes (`/`) in image embed paths, not backslashes (`\`). Always run the backslash fix after the main repair pass.
