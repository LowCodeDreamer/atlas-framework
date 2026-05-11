# Claim Extraction Guidelines

Reference for identifying fact-checkable claims in blog posts.

## What Makes a Claim Verifiable?

A claim is verifiable if it can be confirmed or refuted using external sources.

### Include: Verifiable Claims

| Category | Signal Words/Patterns | Example |
|----------|----------------------|---------|
| **Historical events** | Dates, "in [year]", named events | "April 20, 1914. Ludlow, Colorado..." |
| **Quantitative facts** | Numbers, $, %, measurements | "$63 billion", "21 people", "90%" |
| **Attribution quotes** | "X said", "X wrote", direct quotes | "Bernays wrote in his memoir..." |
| **Institutional claims** | Organization + position/finding | "WHO classified it as 'probably carcinogenic'" |
| **Research citations** | Study, research, paper + finding | "A 2019 Princeton study examined..." |
| **Timeline claims** | Date + specific action | "In 2018, Bayer acquired Monsanto" |

### Exclude: Non-Verifiable Content

| Category | Example | Why Skip |
|----------|---------|----------|
| **Opinion/analysis** | "You're not paranoid. You're just paying attention" | Subjective interpretation |
| **Rhetorical questions** | "How can I use this to sell things?" | Not a factual claim |
| **Author framing** | "The playbook should sound familiar" | Narrative device |
| **Already cited** | "According to [@bernays1928]..." | Has inline citation |
| **Linked claims** | "[documented in court filings](url)" | Has source link |
| **Vague generalizations** | "Corporations use manipulation" | Too broad to verify |

## Detection Patterns

### High-Confidence Claim Signals

```regex
# Year patterns
\b(18|19|20)\d{2}\b

# Dollar amounts
\$[\d,]+(\s*(million|billion|trillion))?

# Percentages
\d+(\.\d+)?%

# Specific numbers with context
(approximately|about|roughly|over|nearly|almost)?\s*[\d,]+\s*(people|users|deaths|cases|...)

# Named entities with actions
[A-Z][a-z]+\s+(said|wrote|stated|claimed|reported|found|discovered|concluded)

# Study/research references
(study|research|paper|report|survey|analysis)\s+(found|showed|revealed|demonstrated|concluded)
```

### Citation Markers to Skip

```regex
# MDX/rehype-citation
\[@[\w-]+\]

# Markdown links
\[.*?\]\(https?://.*?\)

# Search suggestions
🔍\s*Search:

# Attribution phrases
according to [Source]
```

## Claim Boundaries

### Single-Sentence Claims
Most claims are self-contained in one sentence:
> "Twenty-one people were killed—mostly women and children—including two babies."

### Multi-Sentence Claims
Some claims span multiple sentences when they share evidence:
> "The Ludlow Massacre occurred on April 20, 1914. Twenty-one people were killed, including two babies. The Colorado National Guard attacked the striking miners' camp."

Treat as single claim if sentences are part of same factual assertion.

### Block Quotes
Quoted text is a single claim (verify the attribution):
> "The conscious and intelligent manipulation of the organized habits..."
> — Edward Bernays

Verify: Did Bernays actually write this?

## Section-Based Filtering

Skip claims in these sections:
- `## Sources` / `## References` / `## Bibliography`
- `## Appendix` / `## Evidence`
- `## Further Reading`
- `## Notes`

These sections are already citation/source material.

## Context Extraction

For each claim, extract 1-2 surrounding sentences as context:

**Good context:**
> [Previous sentence providing topic/setup]
> **THE CLAIM**
> [Following sentence if it continues the thought]

**Context helps:**
- Disambiguate vague claims
- Provide search keywords
- Identify the argument being made

## Priority Order

When many claims exist, prioritize:

1. **Central thesis claims** - Core arguments of the piece
2. **Statistical claims** - Numbers are easy to verify
3. **Historical claims** - Dates and events are concrete
4. **Quote attributions** - Did the person actually say this?
5. **Institutional claims** - What did the org actually say?

Lower priority:
- Minor supporting details
- Well-known facts
- Claims already widely documented

## Output Format

For each extracted claim:

```json
{
  "claim_id": "claim_001",
  "claim_text": "Twenty-one people were killed at Ludlow in 1914",
  "claim_context": "The Ludlow Massacre... Colorado National Guard attacked...",
  "line_number": 47,
  "priority": "high",
  "category": "historical_event",
  "has_existing_citation": false
}
```
