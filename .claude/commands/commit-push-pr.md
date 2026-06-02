Analyze the current git diff, write a meaningful commit message, stage and commit changes, push to remote, and open a pull request — all in one command.

## Parameters

`$ARGUMENTS` — all optional:
- `/commit-push-pr` — fully automatic; analyzes diff, writes commit message and PR body, executes
- `/commit-push-pr dry-run` — previews commit message and PR body; asks for confirmation before executing
- `/commit-push-pr "hint text"` — uses the hint to steer the commit message focus (e.g., "fix encoding bug in classify workflow")
- `/commit-push-pr dry-run "hint text"` — preview mode with a steering hint

---

## Step 1 — Gather Git State

Run these in parallel:

```powershell
git status
git diff HEAD
git log --oneline -10
git branch --show-current
```

From the output, collect:
- **Branch name** — current branch
- **Base branch** — `main` unless branch name implies otherwise
- **Staged vs. unstaged files** — list both; note any untracked files that look relevant
- **Recent commit style** — subject line length, tense (imperative vs. past), use of prefixes like `fix:` / `feat:` / `Add` / `Update`

---

## Step 2 — Analyze the Diff

Read the full diff carefully. Identify:

1. **What changed** — files touched, functions/sections modified, lines added/removed
2. **Why it changed** — infer from context: bug fix, new feature, refactor, config update, workflow addition, documentation
3. **Scope** — is this one logical change or several? If several, note the primary change and summarize secondaries

Match the commit message tense and style to the repo's recent history (from `git log`).

If a steering hint was provided in `$ARGUMENTS`, use it to frame the message — don't override it with your own interpretation.

---

## Step 3 — Draft Commit Message and PR Body

### Commit message format:

```
<imperative subject line, ≤72 chars>

<optional body: 1–3 sentences on WHY, not what; include non-obvious
context, constraints, or prior incident that motivated the change>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Rules:
- Subject line: imperative mood ("Add X", "Fix Y", "Remove Z") — not "Added" or "Adds"
- Body only if the subject line doesn't fully explain the motivation
- Never describe what the diff shows line-by-line — the diff is already there

### PR body format:

```markdown
## Summary
- <bullet 1>
- <bullet 2>
- <bullet 3 if needed>

## Test plan
- [ ] <specific thing to verify>
- [ ] <another specific check>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

PR title: same as commit subject line (truncate to 70 chars if needed).

---

## Step 4 — Dry-Run Gate

**If `dry-run` was in `$ARGUMENTS`:**

Print the proposed commit message and PR body, then stop and ask:
> "Proceed with commit, push, and PR? (yes / edit / cancel)"

- **yes** → continue to Step 5
- **edit** → ask what to change, revise, re-display, ask again
- **cancel** → stop; do not modify any files

**If no `dry-run`:** proceed directly to Step 5.

---

## Step 5 — Safety Checks

Before staging, verify:

- No `.env`, `*.key`, `*.pem`, `credentials*`, or `secrets*` files are in the diff — if found, exclude them and warn
- No files in `09 - Attachments\` or binary files (`*.exe`, `*.dll`, `*.db`) — exclude and warn
- If the current branch is `main` or `master`: **stop and warn** — ask the user to confirm they intend to push directly to the default branch

---

## Step 6 — Stage, Commit, Push

Stage files by name (never `git add -A`):

```powershell
git add <file1> <file2> ...
```

Commit using HEREDOC format:

```powershell
git commit -m @'
<subject line>

<body if present>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
'@
```

Push:

```powershell
git push -u origin <branch>
```

If the push fails due to a pre-commit hook: fix the underlying issue (do not use `--no-verify`), then re-stage and commit fresh — never amend.

---

## Step 7 — Create Pull Request

```powershell
gh pr create --title "<PR title>" --body @'
## Summary
- <bullet>

## Test plan
- [ ] <check>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
'@
```

If `gh pr create` fails because the branch already has an open PR: report the existing PR URL instead.

---

## Step 8 — Report

Print:
- Commit hash (short)
- Branch pushed to
- PR URL

One line each. No narrative padding.

---

## Key Rules

- Never use `--no-verify`, `--force`, or `--no-gpg-sign` unless the user explicitly requests it
- Never amend a published commit — create a new one
- Never push to `main`/`master` without explicit user confirmation
- Excluded files (secrets, binaries) must be reported to the user even if not blocking
