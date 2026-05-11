---
name: image-generation
description: AI-powered image generation using Google Gemini. Use when creating logos, brand assets, concept art, or visual mockups. Two-phase workflow with parallel API exploration and interactive browser refinement.
user-invocable: true
context: fork
agent: sonnet
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
  - mcp__claude-in-chrome__*
---
# Image Generation

AI-powered image generation using Google Gemini (Nano Banana). Two-phase workflow: parallel API exploration via subagents, then interactive browser refinement.

## When to Use

- Logo and brand asset creation
- Concept art exploration
- Visual mockups and variations
- Any task requiring multiple image options with iterative refinement

## Workflow Overview

```
┌─────────────────────────────────────────────────────────┐
│  PHASE 1: Exploration (API + Subagents)                 │
│  ─────────────────────────────────────────              │
│  • Batch generate many concepts in parallel             │
│  • Use subagents to maximize throughput                 │
│  • Review outputs, identify promising directions        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  PHASE 2: Refinement (Browser + Claude-in-Chrome)       │
│  ─────────────────────────────────────────              │
│  • Upload best candidates to Gemini web UI              │
│  • Iteratively refine with conversational prompts       │
│  • Download final versions                              │
└─────────────────────────────────────────────────────────┘
```

## Phase 1: Parallel API Generation

### Subagent Strategy

Launch multiple subagents to generate images in parallel:

```
For each creative direction:
  Spawn subagent with:
    - Direction name
    - List of prompts (3-5 per direction)
    - Output folder path
    - API credentials (from env)

  Subagent executes generate-images.py with direction-specific prompts
  Returns: file paths of generated images
```

### Example Subagent Invocation

```
Task tool with subagent_type="Bash":
"Run the image generation script for direction '{direction}' with these prompts:
1. {prompt_1}
2. {prompt_2}
3. {prompt_3}

Save outputs to: {project}/concepts/{direction}/
Use GEMINI_API_KEY from environment."
```

### Parallel Execution Pattern

```python
# Conceptual pattern - spawn multiple at once
directions = ["geometric", "organic", "network", "typographic"]

# Launch all directions in parallel via Task tool
for direction in directions:
    # Each becomes a separate subagent
    Task(subagent_type="Bash", prompt=f"python generate-images.py --direction {direction}")
```

### API Configuration

```python
# Gemini Image Generation
MODEL = "gemini-2.5-flash-image"  # Fast, good quality
# MODEL = "gemini-3-pro-image-preview"  # Higher quality, slower

API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

# Environment variable
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
```

### Script Template

See `assets/generate-images.py` for the full async parallel generation script.

Key features:
- Async/await with aiohttp for parallel requests
- Configurable prompts per direction
- Automatic file naming and organization
- Error handling and retry logic

## Phase 2: Browser Refinement

### When to Use Browser

- After selecting top candidates from Phase 1
- When precise iterative control is needed
- For "almost right" images that need tweaking

### Refinement Workflow

1. **Open Gemini:** Navigate to `gemini.google.com`
2. **Upload Base Image:** Use the image upload feature
3. **Describe Changes:** Be specific about what to modify
4. **Iterate:** Continue refining until satisfied
5. **Download:** Use the download button for final versions

### Effective Refinement Prompts

```
# Structural changes
"Remove the base - make it floating in space"
"Change from angled to upright front-facing view"
"Make the circle complete, not cut off"

# Style changes
"Make it glass/crystal with light refraction"
"Dark background with glowing elements"
"Product photography style with studio lighting"

# Specific fixes
"The symmetry is off on the bottom right - fix that"
"Keep the multi-colored nodes from the original"
"Add the tagline below: 'Your Compute. Your Data. Your AI.'"
```

### Constraints That Work

Always include explicit constraints:
- `NO TEXT` (when you don't want text)
- `white background` / `dark background`
- `upright front-facing view`
- `no additional elements`

## Prompt Engineering Patterns

### Logo Generation

```
Brand Context Block:
"{Project} is a {description}. Core concepts:
- {concept_1}
- {concept_2}
The logo should convey: {qualities}"

Design Prompt:
"Create a {style} logo mark: {description}.
Style: {aesthetic qualities}
Constraints: NO TEXT. {background}."
```

### Variation Generation

```
"Create a {variation_type} version:
- {specific_change_1}
- {specific_change_2}
Keep everything else the same."
```

### 3D Rendering

```
"Create a 3D rendered version:
- {material}: glass/metallic/glossy
- {lighting}: soft studio/dramatic/cinematic
- {background}: white/dark/gradient
- {angle}: front-facing/isometric/floating"
```

## File Organization

```
{project}/
├── concepts/                    # Phase 1 outputs
│   ├── direction-a/
│   │   ├── direction-a-01.png
│   │   └── direction-a-02.png
│   └── direction-b/
├── refinements/                 # Phase 2 iterations
│   └── {concept}-v1.png
├── final/                       # Approved assets
│   ├── {name}-primary.png
│   ├── {name}-variant.png
│   └── BRAND-KIT.md
└── generate-images.py           # Generation script
```

## Naming Conventions

```
# Phase 1 (exploration)
{direction}-{index:02d}.png
Example: direction-a-01.png

# Phase 2 (refinement)
{concept}-{version}.png
Example: logo-v3.png

# Final (organized)
{project}-{variant}.png
Example: eno-logo-primary.png, eno-3d-metallic.png
```

## Integration with Atlas

### Project Setup

```bash
# Create project structure
mkdir -p projects/{project}/brand/{concepts,refinements,final}

# Copy script template
cp .claude/skills/image-generation/assets/generate-images.py projects/{project}/brand/
```

### Environment

Ensure API key is available:
```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

## Tips

1. **Start broad, narrow fast** — Generate many concepts in Phase 1, be selective about what enters Phase 2

2. **Save your winners early** — Download promising results immediately; browser sessions can be lost

3. **Be explicit about constraints** — "NO TEXT" works better than hoping it won't add text

4. **Iterate on one thing at a time** — Change material OR angle OR color, not all at once

5. **Use reference language** — "Like the original but..." helps maintain consistency

6. **Document decisions** — Update project README as you make choices

## Limitations

- **No API iteration:** API is stateless; can't say "make that bluer"
- **Browser is manual:** Can't fully automate the refinement phase
- **Generation variability:** Same prompt can produce different results
- **Text rendering:** AI image gen struggles with text; add text in post

---

*Two phases, parallel exploration, iterative refinement. The magic is in the combination.*
