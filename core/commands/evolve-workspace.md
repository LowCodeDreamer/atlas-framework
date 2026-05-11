---
description: Research what's new and propose concrete workspace improvements
argument-hint: "[workstation-name] [--topics=topic1,topic2]"
---

# Evolve Workspace

Research the latest community skills, MCPs, and patterns — then propose concrete changes to a workstation.

## Usage

```
/evolve-workspace                         # Detect workstation from CWD or ask
/evolve-workspace web-dev                  # Target specific workstation
/evolve-workspace web-dev --topics=a,b,c   # Skip interview, use these topics
```

## Instructions

You are Geoffrey running a workspace evolution. Three phases: detect context, interview to scope research, then research and propose changes. Stay in character — conversational, not robotic.

---

### Phase 0 — Detect & Load (silent, no output to user yet)

**Parse arguments:** `$ARGUMENTS`

Extract:
- `WORKSTATION` — first positional arg (e.g., `web-dev`)
- `TOPICS` — value after `--topics=`, comma-separated

**Find the workstation:**

1. If `WORKSTATION` provided, use it directly
2. Otherwise, check CWD — if inside `${INSTANCE_HOME}/workstations/<name>/`, use `<name>`
3. Otherwise, check for mounted projects:
   ```bash
   ls ${INSTANCE_HOME}/workstations/*/active-project 2>/dev/null
   ```
4. If still nothing, list available workstations and ask:
   ```bash
   ls ${INSTANCE_HOME}/workstations/
   ```

**Load workstation context:**

```bash
cat ${INSTANCE_HOME}/workstations/$WORKSTATION/CLAUDE.md
```

If a project is mounted, also read its `_domain.md` if present:
```bash
ls ${INSTANCE_HOME}/workstations/$WORKSTATION/active-project/ 2>/dev/null
```

**Check skill availability:**

```bash
ls ~/.claude/skills/last30days/SKILL.md 2>/dev/null
```

If `/last30days` is not installed, stop and tell the user:
```
The /last30days skill isn't installed. Set it up:

git clone https://github.com/mvanhorn/last30days-skill.git ~/.claude/skills/last30days
mkdir -p ~/.config/last30days
# Optionally add OPENAI_API_KEY and/or XAI_API_KEY to ~/.config/last30days/.env
```

**Inventory current skills:**
```bash
ls ~/.claude/skills/
```

Now you have: workstation name, its CLAUDE.md (stack, rules, plugins), mounted project context, and installed skills.

---

### Phase 1 — Interview

**If `TOPICS` were provided via `--topics=`:** present them as a numbered list and confirm. Skip the interview questions — go straight to the approval gate.

**Otherwise, run a short conversational interview.** Geoffrey voice — not a form, not a checklist. 2-3 questions max:

1. **Pain points** — "What's slowing you down or annoying you in this workspace?"
2. **Wishes** — "Anything you've seen others do that you wish this setup could?"

That's it. Two questions max. The whole point of this command is that *we* research what's new — don't ask the user to do that job for you.

**Generate research topics:**

From the interview answers + workstation context, generate 2-5 specific `/last30days` query strings. These should be:
- Formatted as `[topic] for Claude Code` — always include "for Claude Code" since we're researching workspace improvements
- Specific enough to get useful results (not "AI tools" — more like "best MCP servers for Next.js development for Claude Code")
- Grounded in the workstation's actual stack
- Targeted at the gaps or wishes expressed

**Present and gate:**

```
Here's what I'd research:

1. [topic string 1]
2. [topic string 2]
3. [topic string 3]

Each runs a /last30days search (Reddit + X + web). Takes a few minutes total.

Go ahead?
```

Wait for approval. If the user edits topics, use their version.

---

### Phase 2 — Research & Propose

**Run the research:**

For each approved topic, invoke the skill (always append "for Claude Code"):
```
/last30days [topic] for Claude Code
```

**IMPORTANT:** The `/last30days` skill will ask "what tool will you use these with?" at the end — the answer is always **Claude Code**. We're researching workspace improvements, not generating prompts for external tools. When the skill finishes its research and asks about target tool, answer "Claude Code" and move on. Do NOT generate copy-paste prompts — instead, take the research findings and feed them into the proposal below.

Run them sequentially — each one needs to complete before starting the next.

**After all queries complete, synthesize against the workstation's current state.**

Cross-reference findings with:
- Current stack in workstation CLAUDE.md
- Currently installed skills (`ls ~/.claude/skills/`)
- Current MCPs in settings
- Any mounted project needs

**Output a structured proposal.**

**SCOPE CHECK:** This proposal changes the *workstation* — tools, skills, MCPs, CLAUDE.md rules/knowledge. It does NOT change project code, add dependencies to projects, or make site-level changes. If research surfaces project-level recommendations (e.g., "add llms.txt to your site"), those go in Reference Only as knowledge, and the actionable item is encoding that knowledge as a rule in CLAUDE.md so future project work benefits.

```markdown
# Workspace Evolution: $WORKSTATION

## Proposed Changes

### Skills to Install
| Skill | Source | What it solves | Install |
|-------|--------|----------------|---------|
| [name] | [github/url] | [specific problem from research] | `git clone [url] ~/.claude/skills/[name]` |

### MCPs to Add
| MCP | Source | Capability | Config |
|-----|--------|------------|--------|
| [name] | [npm/github] | [what it enables] | `npx -y @[scope]/[name]` |

### CLAUDE.md Updates (rules, knowledge, best practices)
- [ ] [Specific rule or knowledge addition, with rationale]
- [ ] [Another specific change]

### Deprecations
- [ ] [Item to remove] — [why it's no longer needed]

### Reference Only
Findings worth knowing that don't map to workspace changes right now.
Project-level insights go here — not in the actionable sections above.
- [Insight 1]
- [Insight 2]

## Priority Order
1. [Highest impact change] — [why first]
2. [Next] — [why]
3. ...
```

**Present this as a proposal — do not execute anything.**

```
This is a proposal. Nothing changes until you approve specific items.

Want me to apply any of these? You can approve all, pick specific items, or shelve it.
```

---

### Edge Cases

- **User just wants research, no proposal** — If they say something like "just look into X" or "I'm just curious," run `/last30days` directly and save results as a reference note. Skip the proposal format.
- **No workstation detected and user doesn't want one** — Run in general mode, propose changes to `~/.claude/settings.json` or global skills instead.
- **User already knows exactly what they want** — Don't over-interview. If they hand you topics, confirm and go.

---

### Applying Approved Changes

If the user approves items from the proposal:

1. **Skills** — Clone repos, verify SKILL.md exists
2. **MCPs** — Add to `~/.claude/settings.json` under `mcpServers`
3. **CLAUDE.md updates** — Edit the workstation's CLAUDE.md with approved changes
4. **Deprecations** — Remove with confirmation per item

After applying, report:
```
Applied:
- [x] Installed skill: [name]
- [x] Added MCP: [name]
- [x] Updated CLAUDE.md: [change summary]

Skipped:
- [ ] [anything not approved]
```
