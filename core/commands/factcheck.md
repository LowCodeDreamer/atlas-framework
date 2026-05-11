---
description: Verify factual claims in a blog post and generate citations
argument-hint: <file-path> [--dry-run] [--limit=N] [--skip-cited] [--apply]
---

# Factcheck Command

Verify claims in blog posts, store results for human review, and apply approved citations.

## Three-Phase Workflow

1. **Verify:** `/factcheck post.mdx` → checks claims → stores in Supabase
2. **Review:** Open review URL → click sources → accept/reject claims
3. **Apply:** `/factcheck post.mdx --apply` → adds citations to document

## Arguments

| Argument | Description |
|----------|-------------|
| `$1` | Path to MDX/MD file (required) |
| `--dry-run` | Show extracted claims without verifying |
| `--limit=N` | Max claims to verify (default: 20) |
| `--skip-cited` | Skip claims with existing citations |
| `--apply` | Apply previously approved changes |

## Examples

```bash
# Verify claims in a post
/factcheck projects/everyday-economist/content/posts/my-post.mdx

# Preview what would be checked
/factcheck path/to/post.md --dry-run

# Check only 5 claims
/factcheck path/to/post.mdx --limit=5

# Skip already-cited claims
/factcheck path/to/post.mdx --skip-cited

# Apply approved changes
/factcheck path/to/post.mdx --apply
```

## What Gets Checked

**Verified:**
- Historical events with dates
- Statistics and percentages
- Dollar amounts
- Named quotes and attributions
- Research/study citations

**Skipped:**
- Opinions and analysis
- Rhetorical questions
- Claims with existing citations
- Content in Sources/References sections

## Output

After verification:
```
## Factcheck Complete

Post: projects/everyday-economist/content/posts/my-post.mdx
Run ID: abc-123

Summary:
- Total claims: 15
- Verified: 12 ✓
- Partial: 2 ~
- Unverifiable: 1 ?

Review at: https://[project].supabase.co/functions/v1/factcheck-review?run=abc-123

Once reviewed, run:
/factcheck projects/everyday-economist/content/posts/my-post.mdx --apply
```

## Review Process

1. Click the review URL
2. For each claim:
   - See the claim text and confidence score
   - Click source links to verify
   - Click Accept or Reject
3. Run `--apply` when done

## Skills Used

This command loads the `fact-checking` skill which orchestrates:
- Document parsing and claim extraction
- Parallel fact-checker agents (haiku model)
- Supabase storage for review workflow
- Citation formatting and document updates
