#!/usr/bin/env python3
"""
classify.py - File type detection and handler routing

Detects MIME types and maps files to processing handlers.
Part of the Atlas file normalization pipeline.
"""

import mimetypes
import os
import sys
import json
from pathlib import Path
from typing import Optional

# Initialize mimetypes with additional mappings
mimetypes.init()
mimetypes.add_type('text/markdown', '.md')
mimetypes.add_type('text/markdown', '.markdown')
mimetypes.add_type('application/x-yaml', '.yaml')
mimetypes.add_type('application/x-yaml', '.yml')

# Handler categories and their MIME type mappings
HANDLER_MAP = {
    'text': {
        'mimes': [
            'text/plain',
            'text/markdown',
            'text/csv',
            'text/tab-separated-values',
        ],
        'extensions': ['.txt', '.md', '.markdown', '.csv', '.tsv', '.log'],
        'extractor': 'text',
        'needs_ai': False,
    },
    'structured_data': {
        'mimes': [
            'application/json',
            'application/x-yaml',
            'application/xml',
            'text/xml',
        ],
        'extensions': ['.json', '.yaml', '.yml', '.xml'],
        'extractor': 'structured',
        'needs_ai': False,
    },
    'document': {
        'mimes': [
            'application/pdf',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/msword',
            'application/rtf',
            'application/vnd.oasis.opendocument.text',
        ],
        'extensions': ['.pdf', '.docx', '.doc', '.rtf', '.odt'],
        'extractor': 'document',
        'needs_ai': True,
    },
    'spreadsheet': {
        'mimes': [
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-excel',
            'application/vnd.oasis.opendocument.spreadsheet',
        ],
        'extensions': ['.xlsx', '.xls', '.ods'],
        'extractor': 'spreadsheet',
        'needs_ai': True,
    },
    'presentation': {
        'mimes': [
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/vnd.ms-powerpoint',
            'application/vnd.oasis.opendocument.presentation',
        ],
        'extensions': ['.pptx', '.ppt', '.odp'],
        'extractor': 'presentation',
        'needs_ai': True,
    },
    'image': {
        'mimes': [
            'image/png',
            'image/jpeg',
            'image/gif',
            'image/webp',
            'image/svg+xml',
            'image/tiff',
            'image/bmp',
        ],
        'extensions': ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.tiff', '.tif', '.bmp'],
        'extractor': 'vision',
        'needs_ai': True,
    },
    'audio': {
        'mimes': [
            'audio/mpeg',
            'audio/wav',
            'audio/mp4',
            'audio/x-m4a',
            'audio/ogg',
            'audio/webm',
        ],
        'extensions': ['.mp3', '.wav', '.m4a', '.ogg', '.webm'],
        'extractor': 'audio',
        'needs_ai': True,
    },
    'video': {
        'mimes': [
            'video/mp4',
            'video/quicktime',
            'video/x-msvideo',
            'video/webm',
            'video/x-matroska',
        ],
        'extensions': ['.mp4', '.mov', '.avi', '.webm', '.mkv'],
        'extractor': 'video',
        'needs_ai': True,
    },
}


def get_mime_type(file_path: str) -> Optional[str]:
    """Detect MIME type using mimetypes library."""
    mime_type, _ = mimetypes.guess_type(file_path)
    return mime_type


def get_handler_by_mime(mime_type: str) -> Optional[str]:
    """Find handler category by MIME type."""
    if not mime_type:
        return None
    for handler, config in HANDLER_MAP.items():
        if mime_type in config['mimes']:
            return handler
    return None


def get_handler_by_extension(file_path: str) -> Optional[str]:
    """Fallback: find handler by file extension."""
    ext = Path(file_path).suffix.lower()
    for handler, config in HANDLER_MAP.items():
        if ext in config['extensions']:
            return handler
    return None


def classify_file(file_path: str) -> dict:
    """
    Classify a file and return routing information.

    Returns:
        dict with keys:
            - path: Original file path
            - filename: Base filename
            - extension: File extension
            - mime_type: Detected MIME type
            - handler: Handler category (text, document, image, etc.)
            - extractor: Extraction method to use
            - needs_ai: Whether AI analysis is required
            - supported: Whether this file type is supported
            - error: Error message if classification failed
    """
    path = Path(file_path)

    # Basic validation
    if not path.exists():
        return {
            'path': str(path),
            'supported': False,
            'error': f'File not found: {file_path}'
        }

    if not path.is_file():
        return {
            'path': str(path),
            'supported': False,
            'error': f'Not a file: {file_path}'
        }

    # Get file info
    filename = path.name
    extension = path.suffix.lower()
    mime_type = get_mime_type(str(path))

    # Determine handler
    handler = get_handler_by_mime(mime_type)
    if not handler:
        handler = get_handler_by_extension(str(path))

    if not handler:
        return {
            'path': str(path),
            'filename': filename,
            'extension': extension,
            'mime_type': mime_type,
            'handler': None,
            'supported': False,
            'error': f'Unsupported file type: {extension} ({mime_type})'
        }

    config = HANDLER_MAP[handler]

    return {
        'path': str(path.absolute()),
        'filename': filename,
        'extension': extension,
        'mime_type': mime_type,
        'handler': handler,
        'extractor': config['extractor'],
        'needs_ai': config['needs_ai'],
        'supported': True,
        'error': None
    }


def main():
    """CLI interface for file classification."""
    if len(sys.argv) < 2:
        print("Usage: classify.py <file_path> [--json]", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]
    json_output = '--json' in sys.argv

    result = classify_file(file_path)

    if json_output:
        print(json.dumps(result, indent=2))
    else:
        if result['supported']:
            print(f"File: {result['filename']}")
            print(f"Type: {result['handler']}")
            print(f"MIME: {result['mime_type']}")
            print(f"Extractor: {result['extractor']}")
            print(f"Needs AI: {result['needs_ai']}")
        else:
            print(f"Error: {result['error']}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
