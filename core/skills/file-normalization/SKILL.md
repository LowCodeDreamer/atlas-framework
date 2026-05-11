---
name: file-normalization
description: Transform any file into standardized Atlas markdown with YAML frontmatter. Use when processing inbox files, normalizing documents, or ingesting content into the knowledge system.
user-invocable: false
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Task
---

# File Normalization

Transform any input file into standardized Atlas-compatible markdown.

## Quick Reference

```
Input: Any file (PDF, image, document, text, data)
Output: {date}-{slug}.md with YAML frontmatter
```

## Single File Workflow

### 1. Classify File Type

Detect type from extension and MIME:

| Category | Extensions | Handler |
|----------|------------|---------|
| Text | `.md`, `.txt` | Direct (enhance frontmatter) |
| Document | `.pdf`, `.docx`, `.pptx`, `.xlsx` | Extract text + structure |
| Image | `.jpg`, `.png`, `.gif`, `.webp` | Vision API description |
| Media | `.mp3`, `.mp4`, `.m4a` | Metadata + transcription |
| Data | `.json`, `.csv`, `.sql` | Schema + summary |

### 2. Extract Content

Per-type extraction:

**Text files:** Read directly, parse existing frontmatter if present.

**PDFs:** Extract text with PyPDF2/pdfplumber. Preserve structure (headers, lists).

**Images:** Use Claude Vision API to describe content, extract any text (OCR).

**Documents:** Use python-docx, openpyxl, python-pptx for structured extraction.

**Data files:** Parse schema, generate summary statistics, sample rows.

### 3. AI Analysis

For each extracted content, use Claude to generate:

```yaml
title: [derived from content or filename]
summary: [1-2 sentence summary]
tags: [3-7 relevant tags from registry + new suggestions]
type: [note | reference | artifact | media | data]
related: [suggested links to existing content]
```

**Prompt pattern:**
```
Analyze this content for Atlas knowledge system ingestion:

[extracted content]

Generate:
1. A clear, concise title
2. A 1-2 sentence summary
3. 3-7 relevant tags (check existing: [tag list])
4. Content type classification
5. Suggested relationships to existing knowledge
```

### 4. Generate YAML Frontmatter

Apply the metadata schema:

```yaml
---
id: {date}_{slug}
type: {note | reference | artifact | media | data}
created_at: {ISO 8601}
updated_at: {ISO 8601}
source_file: {original filename}
source_type: {mime type}
title: {AI-generated title}
summary: {AI-generated summary}
tags:
  - {tag1}
  - {tag2}
status: draft
confidence: {high | medium | low}
---
```

See [[references/metadata-schema|Metadata Schema]] for full specification.

### 5. Generate Filename

Format: `{YYYY-MM-DD}-{slug}.md`

Rules:
- Date: File creation date or today if unknown
- Slug: Lowercase, dash-separated, max 40 chars
- Remove special characters
- Truncate intelligently (preserve meaning)
- Handle collisions with `-2`, `-3` suffix

### 6. Determine Storage Location

**All normalized files go to `knowledge/` (flat archive).**

The knowledge archive is:
- **Flat** — All files at root, no type-based subfolders
- **Chronological** — Timestamped filenames enable temporal discovery
- **Immutable** — Append-only; files never deleted or reorganized
- **Metadata-driven** — The `type` field in frontmatter enables filtering, not folder structure

For curated, actively-maintained views of knowledge, use **projects** (e.g., `projects/<domain>/`, `projects/eno/`) which link OUT to knowledge archive entries.

### 7. Write Output

1. Create markdown file at destination
2. Archive original to `knowledge/.originals/`
3. Update tag registry if new tags introduced
4. Log processing result

## Tag Registry

Tags evolve through usage. Registry tracks:
- Tag name
- Usage count
- Last used date
- Parent tag (for hierarchy)
- Suggested consolidations

Location: `knowledge/.system/tag-registry.md`

See [[references/tag-system|Tag System]] for evolution rules.

## Error Handling

| Situation | Action |
|-----------|--------|
| Extraction fails | Log error, keep original, mark for manual review |
| AI analysis fails | Use filename-derived metadata, lower confidence |
| Duplicate filename | Add numeric suffix |
| Unknown file type | Create basic reference with binary link |

## Bundled Resources

- `scripts/classify.py` — File type detection
- `scripts/extract.py` — Content extraction per type
- `scripts/normalize.py` — Main normalization pipeline
- `references/metadata-schema.md` — Full YAML specification
- `references/tag-system.md` — Tag registry and evolution
- `assets/frontmatter-template.yaml` — YAML template

## Roadmap

### V1: File Normalization Pipeline (Current)

```
inbox/ → classify → extract → AI analyze → YAML frontmatter → name → store → archive original
```

**Components:**
- File classifier (MIME type detection)
- Content extractors (per file type)
- AI analyzer (summary, tags, relationships)
- YAML templater (frontmatter generation)
- Filename generator (date-slug convention)
- Tag registry (evolving taxonomy)

### V2: Knowledge Graph (Future)

```
normalized markdown → parse blocks → extract entities → embed → graph → query interface
```

**Design principle:** V1 delivers standalone value, V2 enhances without breaking changes.

## Related

- [[.claude/commands/process-inbox|/process-inbox Command]] — Orchestrates the full pipeline
- [[.claude/agents/file-organizer|File Organizer Agent]] — Triage and cleanup
