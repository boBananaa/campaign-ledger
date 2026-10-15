# Backups and rollback

This repository backs up Campaign Ledger, Campaign D20 and Campaign Turn Watch.
The `baseline-before-hover` tag preserves the current implementation before the
planned hover-only display work. Check QA.md for the exact validation boundaries.

## Save a milestone

1. Build with `python3 scripts/build.py` and run the documented checks.
2. Review `git diff` and `git status`.
3. Commit the intended files and push the branch to GitHub. Local commits reach
   the online backup only after pushing.
4. For a tested milestone, create a new tag and push it. Never move an existing
   backup tag to a different commit.

Keep `main` for tested changes. Use a feature branch for development. The initial
`feature/hover-plates` branch starts at the baseline and contains no hover changes.

## Install an older plugin version

1. On GitHub, select the desired tag and download `dist/CampaignLedger.zip`, or
   download the needed `.rbxmx` file from `dist/`.
2. Open Roblox Studio's Plugins Folder and replace the corresponding local plugin
   file with the downloaded version.
3. Reload that plugin through PluginDebugService, or reopen Studio once.

This restores plugin code. It does not rewind character stats or undo map edits.
If you want to inspect old source locally, use a separate checkout or branch;
restoring the active Script Sync folder can immediately update Studio's scripts.
Script Sync is bidirectional and code-only. Installed plugins are separate copies.

## Full Roblox place backups

Save a separate `.rbxl` copy from Studio to retain character models, maps,
registered stats and persisted overhead objects. This repository contains only a
small synthetic test fixture, not a backup of the session place. Keep real place
backups in a separately backed-up folder; `/backups/` and `.rbxl` are ignored here.

The repository includes source, tests, build scripts and built plugin packages.
Local lock files, logs, credentials and operating-system metadata are excluded.
