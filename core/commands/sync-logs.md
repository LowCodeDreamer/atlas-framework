---
description: Extract Claude Code sessions to Supabase for analysis
allowed-tools: Bash(source:*), Bash(python3:*), mcp__supabase__execute_sql
---

Sync Claude Code session transcripts to the Atlas Logger database and generate AI summaries.

## Step 1: Run Extraction

Execute this command:
```bash
source ~/.secrets/master.env && cd ~/Workspace/atlas-logger && python3 scripts/extract_sessions.py -v
```

## Step 2: Generate Session Summaries

After extraction, generate AI summaries for new sessions (uses Gemini via OpenRouter):
```bash
source ~/.secrets/master.env && cd ~/Workspace/atlas-logger && python3 scripts/generate_summaries.py --limit 20 -v
```

Note: `--limit 20` processes up to 20 unsummarized sessions per run. For bulk backfill, use `--limit 100` or omit limit.

## Step 3: Report Results

Query Supabase for totals:
```sql
SELECT
  (SELECT COUNT(*) FROM sessions) as sessions,
  (SELECT COUNT(*) FROM messages) as messages,
  (SELECT COUNT(*) FROM tool_calls) as tool_calls,
  (SELECT COUNT(*) FROM component_snapshots) as snapshots,
  (SELECT COUNT(*) FROM session_summaries) as summaries;
```

## Step 4: Show Coverage

Check summary coverage:
```sql
SELECT
  COUNT(*) as total_sessions,
  (SELECT COUNT(*) FROM session_summaries) as summarized,
  ROUND(100.0 * (SELECT COUNT(*) FROM session_summaries) / COUNT(*), 1) as coverage_pct
FROM sessions;
```

Present results showing extraction totals, summaries generated, and coverage percentage.
