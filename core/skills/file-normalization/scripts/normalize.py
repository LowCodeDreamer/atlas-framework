#!/usr/bin/env python3
"""
normalize.py - Main pipeline orchestration

Orchestrates the full normalization workflow:
1. Classify file type
2. Extract content
3. Prepare for AI analysis
4. Generate output structure

Part of the Atlas file normalization pipeline.
"""

import json
import os
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# Import sibling modules
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

from classify import classify_file
from extract import extract_content

# Atlas paths
ATLAS_ROOT = Path.home() / 'Documents' / 'Atlas'
KNOWLEDGE_ROOT = ATLAS_ROOT / 'knowledge'
ARCHIVE_ROOT = KNOWLEDGE_ROOT / '.originals'
TAG_REGISTRY = KNOWLEDGE_ROOT / '.system' / 'tag-registry.md'

# Handler to suggested type mapping (for frontmatter, not directory)
HANDLER_TYPE_MAP = {
    'text': 'note',
    'structured_data': 'data',
    'document': 'reference',
    'spreadsheet': 'data',
    'presentation': 'reference',
    'image': 'media',
    'audio': 'media',
    'video': 'media',
}


def generate_slug(title: str) -> str:
    """Generate URL-friendly slug from title."""
    slug = title.lower()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s_]+', '-', slug)
    slug = re.sub(r'-+', '-', slug)
    slug = slug.strip('-')
    return slug[:50]  # Limit length


def generate_filename(date: str, title: str) -> str:
    """Generate standardized filename: YYYY-MM-DD-slug.md"""
    slug = generate_slug(title)
    return f"{date}-{slug}.md"


def get_destination() -> str:
    """Return the flat knowledge archive directory."""
    return str(KNOWLEDGE_ROOT)


def generate_frontmatter(
    doc_id: str,
    doc_type: str,
    title: str,
    summary: str,
    tags: list,
    source_file: str,
    source_type: str,
    confidence: str = 'medium',
    **extra
) -> str:
    """Generate YAML frontmatter string."""
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    lines = [
        '---',
        f'id: {doc_id}',
        f'type: {doc_type}',
        f'created_at: {now}',
        f'updated_at: {now}',
        f'title: "{title}"',
        f'summary: "{summary}"',
        'tags:',
    ]

    for tag in tags:
        lines.append(f'  - {tag}')

    lines.extend([
        'status: draft',
        f'confidence: {confidence}',
        f'source_file: "{source_file}"',
        f'source_type: "{source_type}"',
        '---',
    ])

    return '\n'.join(lines)


def normalize_file(
    file_path: str,
    destination: Optional[str] = None,
    tags: Optional[list] = None,
    title: Optional[str] = None,
    summary: Optional[str] = None,
    doc_type: Optional[str] = None,
    dry_run: bool = False
) -> dict:
    """
    Run the full normalization pipeline on a file.

    Args:
        file_path: Path to source file
        destination: Override destination directory
        tags: Pre-specified tags
        title: Override AI-generated title
        summary: Override AI-generated summary
        doc_type: Override detected document type
        dry_run: If True, don't write files

    Returns:
        dict with:
            - success: Boolean
            - classification: File classification result
            - extraction: Content extraction result
            - needs_ai: Whether AI processing is required
            - ai_prompt: Suggested prompt for AI analysis
            - output_path: Where file would be/was written
            - frontmatter: Generated frontmatter (if title/summary provided)
            - error: Error message if failed
    """
    result = {
        'success': False,
        'file_path': file_path,
        'dry_run': dry_run,
    }

    # Step 1: Classify
    classification = classify_file(file_path)
    result['classification'] = classification

    if not classification['supported']:
        result['error'] = classification['error']
        return result

    # Step 2: Extract
    extraction = extract_content(file_path, classification['extractor'])
    result['extraction'] = extraction

    if not extraction['success']:
        result['error'] = extraction['error']
        return result

    # Step 3: Determine if AI is needed
    needs_ai = classification['needs_ai'] or not (title and summary)
    result['needs_ai'] = needs_ai

    # Step 4: Prepare AI prompt if needed
    if needs_ai:
        content_preview = ''
        if extraction.get('content'):
            content_preview = extraction['content'][:2000]
            if len(extraction['content']) > 2000:
                content_preview += '\n\n[Content truncated...]'

        if classification['handler'] in ['image', 'audio', 'video']:
            result['ai_prompt'] = f"""Analyze this {classification['handler']} file and provide:

1. **Title**: A concise, descriptive title (3-8 words)
2. **Summary**: A 1-2 sentence summary of the content
3. **Tags**: 3-5 relevant tags from these categories:
   - Topic tags (what it's about)
   - Type tags (note, reference, media, data)
   - Domain tags (atlas, personal, <domain>, etc.)
4. **Document Type**: One of: note, reference, artifact, media, data
5. **Confidence**: high, medium, or low (based on clarity of content)

File: {classification['filename']}
Type: {classification['handler']}"""
        else:
            result['ai_prompt'] = f"""Analyze this content and provide:

1. **Title**: A concise, descriptive title (3-8 words)
2. **Summary**: A 1-2 sentence summary of the content
3. **Tags**: 3-5 relevant tags from these categories:
   - Topic tags (what it's about)
   - Type tags (note, reference, media, data)
   - Domain tags (atlas, personal, <domain>, etc.)
4. **Document Type**: One of: note, reference, artifact, media, data
5. **Confidence**: high, medium, or low (based on clarity of content)

Content:
```
{content_preview}
```"""

    # Step 5: Calculate output path (flat knowledge archive)
    date = datetime.now().strftime('%Y-%m-%d')
    final_type = doc_type or HANDLER_TYPE_MAP.get(classification['handler'], 'note')
    final_dest = destination or get_destination()

    if title:
        filename = generate_filename(date, title)
    else:
        # Temporary filename until AI provides title
        base_name = Path(file_path).stem
        filename = generate_filename(date, base_name)

    result['suggested_destination'] = final_dest
    result['suggested_filename'] = filename
    result['output_path'] = str(Path(final_dest) / filename)

    # Step 6: Generate frontmatter if we have all metadata
    if title and summary:
        doc_id = f"{date}_{generate_slug(title)}"
        result['frontmatter'] = generate_frontmatter(
            doc_id=doc_id,
            doc_type=final_type,
            title=title,
            summary=summary,
            tags=tags or [],
            source_file=classification['filename'],
            source_type=classification['mime_type'] or 'unknown',
        )

        # Generate full output content
        content = extraction.get('content') or ''

        # For media files with no extracted content, generate appropriate body
        if not content and classification['handler'] in ['image', 'audio', 'video']:
            # Create media reference body (relative path from knowledge/ to .originals/)
            archive_rel_path = f".originals/{classification['filename']}"
            if classification['handler'] == 'image':
                content = f"![{title}]({archive_rel_path})\n\n{summary}"
            else:
                content = f"**Source:** [{classification['filename']}]({archive_rel_path})\n\n{summary}"

        result['output_content'] = f"{result['frontmatter']}\n\n{content}"

        # Step 7: Write file if not dry run
        if not dry_run:
            output_path = Path(result['output_path'])
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(result['output_content'], encoding='utf-8')

            # Archive original
            archive_path = ARCHIVE_ROOT / classification['filename']
            archive_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(file_path, archive_path)
            result['archive_path'] = str(archive_path)

    result['success'] = True
    return result


def main():
    """CLI interface for file normalization."""
    if len(sys.argv) < 2:
        print("Usage: normalize.py <file_path> [options]", file=sys.stderr)
        print("\nOptions:", file=sys.stderr)
        print("  --dry-run         Don't write files", file=sys.stderr)
        print("  --json            Output as JSON", file=sys.stderr)
        print("  --title=TITLE     Override title", file=sys.stderr)
        print("  --summary=TEXT    Override summary", file=sys.stderr)
        print("  --tags=a,b,c      Comma-separated tags", file=sys.stderr)
        print("  --dest=PATH       Override destination", file=sys.stderr)
        print("  --type=TYPE       Override document type", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]
    args = sys.argv[2:]

    # Parse options
    dry_run = '--dry-run' in args
    json_output = '--json' in args
    title = None
    summary = None
    tags = None
    destination = None
    doc_type = None

    for arg in args:
        if arg.startswith('--title='):
            title = arg.split('=', 1)[1]
        elif arg.startswith('--summary='):
            summary = arg.split('=', 1)[1]
        elif arg.startswith('--tags='):
            tags = arg.split('=', 1)[1].split(',')
        elif arg.startswith('--dest='):
            destination = arg.split('=', 1)[1]
        elif arg.startswith('--type='):
            doc_type = arg.split('=', 1)[1]

    result = normalize_file(
        file_path,
        destination=destination,
        tags=tags,
        title=title,
        summary=summary,
        doc_type=doc_type,
        dry_run=dry_run
    )

    if json_output:
        # Truncate content for JSON output
        output = result.copy()
        if output.get('output_content') and len(output['output_content']) > 2000:
            output['output_content_preview'] = output['output_content'][:1000] + '...'
            del output['output_content']
        if output.get('extraction', {}).get('content'):
            if len(output['extraction']['content']) > 2000:
                output['extraction']['content_preview'] = output['extraction']['content'][:1000] + '...'
                del output['extraction']['content']
        print(json.dumps(output, indent=2, default=str))
    else:
        if result['success']:
            print(f"📄 File: {result['classification']['filename']}")
            print(f"📁 Type: {result['classification']['handler']}")
            print(f"📍 Destination: {result['output_path']}")

            if result['needs_ai']:
                print("\n⚠️  AI analysis required")
                print("Run with --title and --summary after AI review, or use /normalize command")

            if result.get('archive_path'):
                print(f"📦 Archived: {result['archive_path']}")

            if dry_run:
                print("\n(Dry run - no files written)")
        else:
            print(f"❌ Error: {result['error']}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
