---
description: Multi-domain strategic analysis with parallel advisor agents
argument-hint: <question> [--domain=<domain>|<domain>|<domain>|atlas|all] [--depth=quick|standard|deep]
---
# Strategy

Run a strategic analysis session using domain advisor agents.

**Loads skill:** `strategy-session`

## Arguments

- `$ARGUMENTS` — The strategic question plus optional flags
- `--domain=<domain>` — Which domains to consult (default: auto-detect from mounted project, falls back to "all")
  - Single: `--domain=<domain>`
  - Multiple: `--domain=<domain>,<domain>`
  - All: `--domain=all`
- `--depth=<level>` — Analysis depth
  - `quick` — Frame + inline synthesis, no advisors, ~1 min
  - `standard` — Parallel advisors + web research, ~3-5 min (default)
  - `deep` — Advisors + extensive research + follow-up analysis, ~5-10 min

## Examples

```
/strategy Should Eno pursue hardware partnerships before software is ready?
/strategy What's the right pricing model for <domain> consulting? --domain=<domain> --depth=deep
/strategy Should Atlas prioritize open-source launch or strategy tooling? --domain=<domain> --depth=quick
/strategy How should we sequence <Client>'s digital transformation phases? --domain=<domain>,<domain>
```

## What Happens

1. **Frame** — Restates question, classifies via Cynefin, assesses reversibility
2. **Analyze** — Spawns strategy-advisor agents per domain (parallel)
3. **Research** — Web search for external context (standard/deep)
4. **Synthesize** — Agreement, tension, blind spots across domains
5. **Present** — Options table, recommendation, reversal criteria
6. **Capture** — Optionally saves as decision record in `knowledge/`

## Decision Records

When you confirm a decision, it's captured as:
```
knowledge/YYYY-MM-DD-decision-{slug}.md
```

With frontmatter: `type: decision`, `domain`, `status`, `reversibility`, `confidence`.

## Related

- `/question` — Quick expert Q&A (single domain, no advisors)
- `/plan` — Task planning and roadmapping
- `/factcheck` — Verify claims with web sources
