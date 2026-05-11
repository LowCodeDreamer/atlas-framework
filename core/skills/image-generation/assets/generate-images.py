#!/usr/bin/env python3
"""
Gemini Image Generation Script
Template for parallel image generation via Google Gemini API

Usage:
    python generate-images.py [--direction NAME]

Environment:
    GEMINI_API_KEY or GOOGLE_API_KEY must be set
"""

import os
import sys
import asyncio
import aiohttp
import base64
from pathlib import Path
from datetime import datetime

# =============================================================================
# CONFIGURATION
# =============================================================================

# Get API key from environment
API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
if not API_KEY:
    print("Error: Set GEMINI_API_KEY or GOOGLE_API_KEY environment variable")
    sys.exit(1)

# Model selection
# "gemini-2.5-flash-image" - Fast, good quality (recommended for exploration)
# "gemini-3-pro-image-preview" - Higher quality, slower (for final renders)
MODEL = "gemini-2.5-flash-image"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

# Output directory (override via command line or modify here)
OUTPUT_DIR = Path(__file__).parent / "concepts"

# =============================================================================
# PROMPTS - Customize for your project
# =============================================================================

# Optional: Brand context to prepend to all prompts
BRAND_CONTEXT = """
[Your project description here]
Core concepts: [concept 1], [concept 2], [concept 3]
"""

# Prompts organized by creative direction
# Each direction gets its own subfolder
PROMPTS = {
    "direction-a": [
        "Create a minimalist logo: [description]. Style: clean, geometric. NO TEXT. White background.",
        "Design a simple mark: [description]. Style: modern, scalable. NO TEXT. White background.",
    ],
    "direction-b": [
        "Create a logo featuring [element]: [description]. Style: [aesthetic]. NO TEXT. White background.",
        "Design a mark with [element]: [description]. Style: [aesthetic]. NO TEXT. White background.",
    ],
    # Add more directions as needed
}

# =============================================================================
# GENERATION LOGIC
# =============================================================================

async def generate_image(session: aiohttp.ClientSession, prompt: str, direction: str, index: int) -> dict:
    """Generate a single image via Gemini API"""

    # Optionally prepend brand context
    full_prompt = f"{BRAND_CONTEXT}\n\n{prompt}" if BRAND_CONTEXT.strip() else prompt

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": API_KEY
    }

    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }]
    }

    try:
        async with session.post(API_URL, json=payload, headers=headers) as response:
            if response.status != 200:
                error_text = await response.text()
                return {
                    "success": False,
                    "error": f"API error {response.status}: {error_text}",
                    "direction": direction,
                    "index": index
                }

            result = await response.json()

            # Extract image from response
            candidates = result.get("candidates", [])
            if not candidates:
                return {
                    "success": False,
                    "error": "No candidates in response",
                    "direction": direction,
                    "index": index
                }

            parts = candidates[0].get("content", {}).get("parts", [])

            for part in parts:
                if "inlineData" in part:
                    image_data = part["inlineData"]["data"]
                    mime_type = part["inlineData"]["mimeType"]

                    # Save image
                    output_dir = OUTPUT_DIR / direction
                    output_dir.mkdir(parents=True, exist_ok=True)

                    ext = "png" if "png" in mime_type else "jpg"
                    filename = f"{direction}-{index:02d}.{ext}"
                    filepath = output_dir / filename

                    with open(filepath, "wb") as f:
                        f.write(base64.b64decode(image_data))

                    return {
                        "success": True,
                        "path": str(filepath),
                        "direction": direction,
                        "index": index
                    }

            return {
                "success": False,
                "error": "No image data in response",
                "direction": direction,
                "index": index
            }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "direction": direction,
            "index": index
        }


async def generate_direction(direction: str, prompts: list) -> list:
    """Generate all images for a single direction"""
    results = []

    async with aiohttp.ClientSession() as session:
        tasks = [
            generate_image(session, prompt, direction, i + 1)
            for i, prompt in enumerate(prompts)
        ]
        results = await asyncio.gather(*tasks)

    return results


async def generate_all() -> list:
    """Generate all images across all directions in parallel"""

    print(f"Starting image generation at {datetime.now().isoformat()}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Model: {MODEL}")
    print("-" * 50)

    all_results = []

    async with aiohttp.ClientSession() as session:
        tasks = []

        for direction, prompts in PROMPTS.items():
            for i, prompt in enumerate(prompts):
                task = generate_image(session, prompt, direction, i + 1)
                tasks.append(task)

        print(f"Generating {len(tasks)} images across {len(PROMPTS)} directions...")
        all_results = await asyncio.gather(*tasks)

    # Summary
    print("-" * 50)
    successes = [r for r in all_results if r["success"]]
    failures = [r for r in all_results if not r["success"]]

    print(f"Generated: {len(successes)}/{len(all_results)} images")

    if successes:
        print("\nGenerated files:")
        for r in sorted(successes, key=lambda x: (x["direction"], x["index"])):
            print(f"  {r['path']}")

    if failures:
        print("\nFailed:")
        for r in failures:
            print(f"  {r['direction']}-{r['index']}: {r['error']}")

    return all_results


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Generate images via Gemini API")
    parser.add_argument("--direction", "-d", help="Generate only this direction")
    parser.add_argument("--output", "-o", help="Output directory")
    args = parser.parse_args()

    global OUTPUT_DIR
    if args.output:
        OUTPUT_DIR = Path(args.output)

    if args.direction:
        if args.direction not in PROMPTS:
            print(f"Error: Unknown direction '{args.direction}'")
            print(f"Available: {list(PROMPTS.keys())}")
            sys.exit(1)

        # Generate single direction
        results = asyncio.run(generate_direction(args.direction, PROMPTS[args.direction]))
    else:
        # Generate all directions
        results = asyncio.run(generate_all())

    # Exit with error code if any failures
    failures = [r for r in results if not r["success"]]
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
