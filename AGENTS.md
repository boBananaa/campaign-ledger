# Campaign Tools project workflow

## GitHub checkpoints

The user has authorized keeping this project's GitHub repository updated with
rollback versions as development continues.

- After each completed, coherent update, run appropriate checks, review the diff,
  commit the intended source, tests, documentation and generated plugin files,
  then push the working branch to `origin`. A local commit alone is not a backup.
- Create and push a descriptive, unique annotated tag for feature milestones.
  Describe validation limits in the tag message and QA.md; do not call an
  automated-only checkpoint a live-tested release.
- Preserve older commits, tags and releases. Never force-push or move an existing
  checkpoint tag. Keep development on a feature branch; merge into main only after
  the user approves that update. Use the `codex/` prefix for new branches.
- Include built `.rbxmx` files in each checkpoint so rollback does not require a
  rebuild. Keep BACKUPS.md current and report the pushed checkpoint link.
- Never commit credentials, logs, personal session maps or ignored backups.
  GitHub backup authorization does not authorize publishing a Roblox asset.

## Studio isolation

- Prefer terminal, direct files and connectors over screen automation.
- Build with `python3 scripts/build.py --no-sync` unless the user explicitly asks
  to update Script Sync. Other Roblox projects may be open at the same time.
- Do not install, reload or remove local plugin copies as part of a GitHub backup.
- Reuse the intended Studio session. Only open an extra session when necessary,
  track it and close it without discarding the user's work.
