Audit all available Claude Code skills for visibility, determinism, and composability. Produce a prioritized findings table and changelog.

## Step 1 — Inventory skills

List all skills currently available in this session. Sources:
- Built-in skills visible in the system-reminder block (listed under "available skills")
- Custom commands in `~/.claude/commands/` — read each `.md` file

For each skill record: name, one-line description, file path (or "built-in"), and whether it appears in the `/menu`.

## Step 2 — Visibility audit

For each skill, evaluate:

**High-risk side effects** (deploy, commit, push, post messages, modify shared config, create scheduled jobs, expand permissions):
- Flag these skills
- Recommend adding `disable-model-invocation: true` to frontmatter so Claude cannot auto-invoke them without explicit user action

**Pure background knowledge** (skills users would never type `/name` to invoke directly — documentation loaders, domain context, debugging aids):
- Flag these skills
- Recommend adding `user-invocable: false` to hide them from `/menu`

## Step 3 — Deterministic vs non-deterministic audit

For each skill (especially custom commands where you can read the source), identify steps that are:

**Fixed/repeatable operations** (file existence checks, path resolution, index reads, line-length checks, regex matches, counts):
- These always produce the same output for the same input — no AI judgment needed
- Flag them: recommend replacing with a script saved in the skill's folder (PowerShell `.ps1`, Python `.py`, or Bash `.sh`)
- Code = same result every time, no token cost, faster

**Judgment operations** (relevance evaluation, staleness assessment, conflict resolution, ranking, synthesis, interpretation):
- These require AI reasoning
- Keep these as AI steps — do not script them

Output per skill: which steps should be scripted vs kept as AI, with a suggested script name.

## Step 4 — Composability audit

Compare all skills for:

**Duplicate logic**: two or more skills that implement the same sub-task (e.g., "read memory indexes", "run the app", "analyze a diff"):
- Flag the duplication
- Suggest extracting shared logic into a callable script or a smaller composable skill that others invoke

**Near-duplicate skills**: two skills that are essentially the same workflow with one flag difference:
- Flag them
- Suggest collapsing into one skill with a parameter, or making one a thin alias of the other

## Step 5 — Report

Produce two outputs:

**Findings table** — one row per finding:

| Skill | Audit Area | Finding | Recommendation |
|-------|------------|---------|----------------|
| /skill-name | Visibility / Determinism / Composability | What was found | What to change and why |

**Changelog** — if any custom skill files were actually modified during this audit, list:

| File | Change type | Description |
|------|-------------|-------------|
| path/to/skill.md | Updated / Created / Deleted | Brief description |

If no files were modified (findings are recommendations only), say so explicitly and invite the user to approve specific changes before applying them.
