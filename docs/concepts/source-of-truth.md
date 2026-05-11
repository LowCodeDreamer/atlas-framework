# Source of Truth

Where canonical state lives, and who can write to it.

## Principle

**The instance filesystem is the source of truth.** Git remote (Forgejo, GitHub, GitLab) is for backup, history, and team contribution — not stricter canonicality.

## Why filesystem-as-canonical (not git-as-canonical)

Most teams put the git remote at the top of the truth hierarchy: edit a branch, PR, merge, deploy from main. That's correct when:
- Many people edit the same code
- Production state is risky to mutate directly
- The remote enforces tests/review

Framework instances often look different:
- Single operator (or small team) editing directly on the runtime
- "Production" IS the filesystem; there's no separate deploy
- Edits and deploys are the same thing

In this mode, requiring a git round-trip per edit adds friction without buying safety. Edit the file, the change is live, commit when you reach a coherent state.

This works because:
- All authoritative writers (humans, Claude Code sessions, the `/promote` command) end up at the same filesystem
- Autonomous routines (Hermes, n8n, cron) cannot write canonical directly — they propose via `system/proposals/` and humans `/promote`
- Git is sync/backup, not gate

## What this means in practice

- **No PR required for edits.** Open Claude Code, edit, commit when ready, push when convenient.
- **Multi-machine sync via git pull/push.** If you edit on Mac mini and Hermes runs on the VPS, push from one and pull from the other. The filesystems stay aligned via git.
- **Autonomous changes always go through proposal pipeline.** This is the only authority gate: Hermes can't sneak edits into canonical state.
- **Working directories don't need git.** `working/`, `logs/`, `tmp/` are routinely written to by everything; gitignore them or commit infrequently.

## When git-as-canonical is right after all

Switch to PR-required if:
- Multiple humans regularly edit the same instance
- Some changes need pre-merge testing (e.g., a CI job)
- Compliance requires audit trail of every change before it lands
- The instance becomes mission-critical infra that risks downtime per edit

In those cases:
1. Make the working tree on the runtime a git checkout
2. Disable direct writes (file permissions, or pre-commit hook that blocks non-CI commits)
3. Require all changes through PRs against the remote
4. CI deploys merged commits back to the runtime

This is heavier and more cautious. Adopt only when the risk justifies it. Most framework instances don't need it.

## Drift

If someone edits the runtime filesystem directly while git-as-canonical is in effect, that's drift. The remote thinks state X; runtime is in state Y. To detect:

```bash
cd ${INSTANCE_HOME} && git status
```

A clean working tree means no drift. Untracked files or modified files mean drift.

To prevent drift in filesystem-as-canonical mode: commit often. Drift becomes "uncommitted work," which is normal.

## Forgejo / GitHub / GitLab

Choice of git host doesn't affect the source-of-truth model. Pick based on:
- Sovereignty (Forgejo self-hosted = full control)
- Convenience (GitHub = easy PR review, GitHub Actions, public visibility)
- Team conventions (whatever your collaborators already use)

For Eno: Forgejo at `git.eno.foundation` is the eventual home (sovereignty thesis). For v0.1, GitHub is acceptable.

## Backup

Filesystem-as-canonical means you need real backups. Options:
- **Git push** (frequent, easy, version-controlled — primary backup)
- **rsync to second host** (fast, full state including untracked)
- **Snapshot the disk** (whole-VPS, periodic)
- **`/sync` command** wraps stage-commit-push (use multiple times per day)

The framework doesn't impose a backup policy. Pick one and write it into your instance's CLAUDE.md.

## See also

- [`three-layer-model.md`](three-layer-model.md) — what counts as the instance layer
- [`workstations-vs-projects-vs-services.md`](workstations-vs-projects-vs-services.md) — what's canonical inside the instance
- [`hermes-bridge.md`](hermes-bridge.md) — the proposal pipeline that protects canonical from autonomous writes
