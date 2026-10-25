# Backups and rollback

This repository backs up the combined Campaign Tools plugin and the legacy
Campaign Ledger, Campaign D20 and Campaign Turn Watch builds.
The `baseline-before-hover` tag preserves the implementation before the
hover-only display work. The approved hover display is released as `hover-plates-v1`.
Approved builds are in `main`; development checkpoints may be on a feature branch
or tag. Each version's `dist/` contains its installable plugins. Published releases
and the Roblox asset may lag behind these checkpoints. Check QA.md for validation
boundaries and known issues.

## Version checkpoints

| Version | What it preserves |
| --- | --- |
| [checkpoint-2026-10-24-session-fixes](https://github.com/boBananaa/campaign-ledger/tree/checkpoint-2026-10-24-session-fixes) | Body hover with movement bases excluded, master plate visibility, duplicate-plate reconciliation, new-character defaults and refill-on-maximum. 517 automated checks pass; full native/multi-user validation pending. |
| [checkpoint-2026-10-24-launcher](https://github.com/boBananaa/campaign-ledger/tree/checkpoint-2026-10-24-launcher) | Ash/burgundy UI, world isolation, combined Campaign Tools, single-button launcher and simplified D20. 473 automated checks pass; the new launcher still needs native Studio validation. |
| [hover-plates-v1](https://github.com/boBananaa/campaign-ledger/tree/hover-plates-v1) | Approved hover-only stats release. |
| [baseline-before-hover](https://github.com/boBananaa/campaign-ledger/tree/baseline-before-hover) | Original behavior before hover-only stats. |

The user has authorized continued GitHub backups after completed updates. Push the
development branch after each coherent change, and add a new named checkpoint for
feature milestones. Preserve every earlier checkpoint. This is a development
workflow, not a background sync service; Roblox publication remains separate.

## Save a milestone

1. Build with `python3 scripts/build.py --no-sync` and run the documented checks.
   This leaves other Studio projects and Script Sync files alone.
2. Review `git diff` and `git status`.
3. Commit the intended files and push the branch to GitHub. Local commits reach
   the online backup only after pushing.
4. Create a unique annotated milestone tag, note its validation limits and push
   the tag. Never move an existing backup tag to a different commit.

Keep `main` for approved changes. Use a feature branch for development and merge
after review. The `hover-plates-test-1` prerelease preserves the original test build;
`baseline-before-hover` remains available for rollback.

## Install an older plugin version

1. On GitHub, select the desired tag and download `dist/CampaignTools.rbxmx` for a
   combined-plugin checkpoint. Older standalone versions have their individual
   `.rbxmx` files and `dist/CampaignLedger.zip` in `dist/`.
2. Open Roblox Studio's Plugins Folder and replace the corresponding local plugin
   file with the downloaded version.
3. Reload that plugin through PluginDebugService, or reopen Studio once.

For a Roblox-installed copy, publish the older tag's CampaignTools Script as an
update to the same Roblox plugin asset, then update installed copies. Downloading
a GitHub checkpoint alone does not change the published Roblox asset.

This restores plugin code. It does not rewind character stats or undo map edits.
To roll back hover-only display, install the baseline Ledger and Turn Watch plugins
and reload them. The baseline Ledger migrates its saved plates back to the previous
visible style; keep a full place backup for independent map/stat recovery.
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
