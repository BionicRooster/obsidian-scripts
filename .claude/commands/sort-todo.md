Sort the Obsidian To-Do List: uncompleted tasks first, then completed tasks sorted by most recent completion date descending.

## Parameters

No arguments. Always operates on `C:\Users\awt\Sync\Obsidian\To-Do List.md`.

---

## Step 1 — Read the File

Read `C:\Users\awt\Sync\Obsidian\To-Do List.md` with UTF-8 encoding, preserving BOM if present.

---

## Step 2 — Parse Structure

The file has three sections separated by `---` markers:

```
[YAML frontmatter and header content]
---
[task lines]
---
## Related Notes
[footer content]
```

Extract only the task lines between the first `---` and the `--- ## Related Notes` footer. Preserve the header and footer exactly as-is.

---

## Step 3 — Classify Tasks

- **Uncompleted:** lines containing `[ ]`
- **Completed:** lines containing `[x]`

Do not alter any task text. Preserve all characters exactly, including mojibake characters (`°¸"`, `³`, `«`, etc.) — these are intentional encoding artifacts in the original content, not errors.

---

## Step 4 — Extract Completion Dates

For each completed task, extract the completion date using these patterns (check in order):

1. `✅ YYYY-MM-DD` — emoji checkmark followed by date
2. `" YYYY-MM-DD` — closing quote followed by date
3. Trailing `YYYY-MM-DD` — date at end of line

Tasks with no extractable date sort to the **bottom** of the completed section.

---

## Step 5 — Sort

- Uncompleted tasks: preserve their original relative order (do not sort)
- Completed tasks: sort by completion date **descending** (most recent first); dateless completed tasks go after all dated ones

---

## Step 6 — Reconstruct and Write

Rebuild the file in this order:
1. Header content (everything before the first `---`)
2. `---`
3. Uncompleted tasks (original order)
4. Blank line
5. Completed tasks (sorted by date descending, dateless at bottom)
6. `---`
7. `## Related Notes` and footer content

Write back to `C:\Users\awt\Sync\Obsidian\To-Do List.md` with UTF-8 encoding.

---

## Output

Report:
- Count of uncompleted tasks
- Count of completed tasks
- Count of completed tasks with no extractable date (sorted to bottom)
