# Metadata Schema

YAML frontmatter specification for normalized Atlas files.

## Required Fields

```yaml
---
id: {date}_{slug}              # Unique identifier
type: {type}                    # Content classification
created_at: {ISO 8601}          # Creation timestamp
updated_at: {ISO 8601}          # Last modification
title: {string}                 # Human-readable title
---
```

### Field Specifications

**id:** `{YYYY-MM-DD}_{slug}`
- Date of creation
- Slug derived from title (lowercase, dashes, max 40 chars)
- Example: `2025-12-26_quarterly-planning-notes`

**type:** One of:
| Type | Description | Use For |
|------|-------------|---------|
| `note` | Original thinking, observations | Meeting notes, ideas, reflections |
| `reference` | External knowledge captured | Articles, docs, quotes |
| `artifact` | Created outputs | Reports, plans, designs |
| `media` | Visual/audio content | Images, recordings, videos |
| `data` | Structured data | CSVs, JSON, exports |

**created_at / updated_at:** ISO 8601 format
- `2025-12-26T14:30:00Z`
- Always UTC

**title:** Clear, descriptive title
- Sentence case
- No special characters
- Max 100 chars

## Optional Fields

```yaml
summary: {string}               # 1-2 sentence summary
tags:                           # Categorization
  - {tag1}
  - {tag2}
status: {status}                # Processing state
confidence: {level}             # Metadata quality
source_file: {filename}         # Original file name
source_type: {mime}             # Original MIME type
source_url: {url}               # If from web
author: {string}                # If known
area: {area}                    # PARA area
project: {project}              # PARA project
related:                        # Links to other content
  - {id1}
  - {id2}
---
```

### Field Specifications

**summary:** 1-2 sentences capturing essence
- What is this?
- Why does it matter?

**tags:** List of categorization tags
- Lowercase, dash-separated
- 3-7 tags typical
- Reference tag registry for consistency
- New tags allowed (will be registered)

**status:** Processing/review state
| Status | Meaning |
|--------|---------|
| `draft` | Needs review/refinement |
| `active` | Current, in use |
| `archived` | Historical, preserved |
| `deprecated` | Superseded, see replacement |

**confidence:** Metadata quality indicator
| Level | Meaning |
|-------|---------|
| `high` | Human-verified or high-quality extraction |
| `medium` | AI-generated, reasonable confidence |
| `low` | Fallback/heuristic metadata, needs review |

**source_file:** Original filename before normalization
- Preserves provenance

**source_type:** MIME type of original
- `application/pdf`
- `image/png`
- `text/markdown`

**area:** PARA methodology area
- `personal`
- `professional`
- `atlas` (system)

**project:** Active project association
- Links to project domain

**related:** IDs of related content
- For building knowledge graph
- Bi-directional preferred

## Examples

### Note

```yaml
---
id: 2025-12-26_weekly-planning-thoughts
type: note
created_at: 2025-12-26T10:00:00Z
updated_at: 2025-12-26T10:00:00Z
title: Weekly Planning Thoughts
summary: Reflections on improving weekly review process with time-blocking.
tags:
  - productivity
  - planning
  - weekly-review
status: active
confidence: high
area: personal
---
```

### Reference (from PDF)

```yaml
---
id: 2025-12-26_building-second-brain-summary
type: reference
created_at: 2025-12-26T14:30:00Z
updated_at: 2025-12-26T14:30:00Z
title: Building a Second Brain - Key Concepts
summary: Tiago Forte's PARA method and progressive summarization approach.
tags:
  - pkm
  - para-method
  - note-taking
  - tiago-forte
status: active
confidence: medium
source_file: building-second-brain-ch3.pdf
source_type: application/pdf
author: Tiago Forte
---
```

### Media (Image)

```yaml
---
id: 2025-12-26_whiteboard-architecture-diagram
type: media
created_at: 2025-12-26T15:00:00Z
updated_at: 2025-12-26T15:00:00Z
title: Atlas Architecture Whiteboard Sketch
summary: Hand-drawn diagram showing file flow from inbox through normalization to knowledge graph.
tags:
  - atlas
  - architecture
  - diagram
  - whiteboard
status: draft
confidence: medium
source_file: IMG_1234.jpg
source_type: image/jpeg
---

[Image description from Vision API]

![Original image](../archive/inbox/2025-12/IMG_1234.jpg)
```

### Data (CSV)

```yaml
---
id: 2025-12-26_client-engagement-metrics
type: data
created_at: 2025-12-26T16:00:00Z
updated_at: 2025-12-26T16:00:00Z
title: Q4 Client Engagement Metrics
summary: Quarterly metrics export with 47 records across 12 clients.
tags:
  - metrics
  - clients
  - q4-2025
  - <domain>
status: active
confidence: high
source_file: engagement_q4_2025.csv
source_type: text/csv
project: <domain>-reporting
---

## Schema

| Column | Type | Description |
|--------|------|-------------|
| client_id | string | Client identifier |
| date | date | Metric date |
| hours | number | Hours logged |
| revenue | number | Revenue USD |

## Summary Statistics

- Records: 47
- Date range: 2025-10-01 to 2025-12-26
- Total hours: 1,247
- Total revenue: $186,450

## Sample Data

| client_id | date | hours | revenue |
|-----------|------|-------|---------|
| CLT001 | 2025-10-01 | 24 | 3,600 |
| CLT002 | 2025-10-01 | 16 | 2,400 |
```

## Validation Rules

1. **id** must be unique across all files
2. **type** must be from allowed values
3. **dates** must be valid ISO 8601
4. **tags** should prefer existing registry tags
5. **confidence** should be `low` if AI-generated without verification

## Migration Notes

When enhancing existing markdown files:
1. Preserve existing frontmatter fields
2. Add missing required fields
3. Set `confidence: low` if inferring metadata
4. Keep `updated_at` as current time
5. Preserve `created_at` if present, else use file mtime
