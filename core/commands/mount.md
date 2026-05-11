Mount a project into a workstation.

Usage: /mount <project-path> <workstation>

Either argument can be `here` to auto-detect from the current directory.

```bash
bash ${INSTANCE_HOME}/scripts/atlas-mount.sh $ARGUMENTS
```

After mounting:
1. Read the workstation's CLAUDE.md for environment context
2. Read the project's `_domain.md` for domain-specific context
3. Summarize what's mounted and ready
