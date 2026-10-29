# Campaign Tools handoff

Prepared 2026-10-29. Read this before continuing; do not restart the project or
rebuild the approved design from scratch. Historical dates in checkpoint names
are retained as originally created.

## Purpose

Help the user develop, maintain, test and distribute **Campaign Tools**, a Roblox
Studio plugin for their D&D sessions. Sessions run in **Studio edit mode / Team
Create**, with custom maps and movable character models, rather than a running
Roblox game. The plugin combines character resources, hovered overhead displays,
combat turn text, DM controls, a D20 roller and pose replacement.

## User-provided context and preferences

- The original Studio workspace held copies of character models. Session maps may
  be exported later; do not assume a particular open map is the final destination.
- Players commonly delete a model and paste another pose of the same character.
  They need to retain registration and resource values through that operation.
- Players need Pose Change **without enabling DM controls**.
- The user may run another Roblox development project alongside this one. They
  explicitly prefer terminal, direct files and connectors over moving their screen.
- Reuse the intended Studio session. One extra session is allowed only if genuinely
  needed, and must be tracked and closed safely. Do not open a collection of Studios
  or discard unsaved work.
- Plan significant UI/workflow changes for review before building when asked.
  Once approved (for example, “Full send” or “Oki doki begin”), carry the work through.
- Explain controls and publishing steps plainly. Give concise progress updates and
  concrete next steps; do not repeatedly ask for already-granted permission.
- Keep GitHub updated with fallback versions. The checked-in `AGENTS.md` defines
  that authorization and its limits.
- Avoid bland, rounded, generic UI. The user explicitly rejected rounded edges,
  the decorative gold DM badge, “your table at a glance,” and toolbar clutter.
  They chose palette **C, Ash & burgundy**, after reviewing alternatives.

These facts come from the user's requests. Implementation details and validation
claims below come from repository inspection and prior work, not user testimony.
No unrelated personal profile information is needed for this project.

## Established workflow and boundaries

1. Read `AGENTS.md`, check `git status --short --branch`, remotes and recent commits.
   Treat `src/` as authoritative source; edit it rather than generated bundles.
2. Clarify only materially ambiguous behavior. Make reasonable implementation choices
   within approved scope. For redesigns, use the local `roblox-gui` skill and the
   existing design decisions; `frontend-design` was also used earlier.
3. Work on a `codex/` feature branch. Preserve existing model data and old checkpoints.
4. Build with **`python3 scripts/build.py --no-sync`**. The default command also
   writes `DnD Test Scripts/`, which may be connected bidirectionally to Studio.
   Do not touch Script Sync without explicit authorization.
5. Run checks appropriate to the change, inspect the diff, and update relevant docs
   and `QA.md`. State separately what was checked offline and what was tested live.
6. Commit the intended source, tests, docs and generated `.rbxmx` files, then push
   the feature branch. For feature milestones, create and push a unique annotated
   tag, record validation limits and update `BACKUPS.md`. Never force-push or move
   an existing checkpoint. Merge to `main` only after user approval.
7. **GitHub backup, local plugin installation, Studio reload and Roblox publication
   are separate actions.** Backup authorization does not authorize those other actions.
   Do not install/reload/remove plugins or edit a live place just to make a checkpoint.

For live work, discover connected Studios first and explicitly target the intended
returned `studio_id`. Old IDs are not reusable evidence of the current session.
Prefer read-only inspection before any change. Do not change existing stats for a
test without a reversible plan and restoration. A single Studio is not a multiplayer test.

There is no formal design scoring rubric. The actual review routine uses planned
layouts, optional mockups, compact-width checks, offline constructor previews and,
when authorized, native Studio checks. A design subagent and a Luna user-perspective
review were requested earlier; do not assume those agents remain active or rerun
delegation automatically.

## Current state: verified locally on 2026-10-29

- Repository: `/Users/apples.j/Desktop/Gen Projects/dnd scripts`.
- Remote configured as `https://github.com/boBananaa/campaign-ledger.git`.
- Branch: `codex/pose-change-roster`, tracking `origin/codex/pose-change-roster`.
- Feature commit: `b1e5514628c51e9769593cabf1a6aa3d21b9596c`,
  **Add player pose transfers and an independent character roster**.
- Feature tag: `checkpoint-2026-10-25-pose-roster`.
- The working tree was clean before creating this handoff. This documentation
  update may add a later commit; inspect HEAD rather than assuming it stays at b1e5514.
- Built `dist/CampaignTools.rbxmx`, `.luau` and `.zip` exist in the checkout.
- A fresh `git ls-remote` check confirmed the remote feature branch and annotated
  checkpoint tag both resolve to b1e5514 before this handoff's documentation commit.
  The feature tag will stay there; a later documentation push advances only the branch.
- The local Plugins directory `/Users/apples.j/Documents/Roblox/Plugins` was empty
  of plugin files in this inspection. This does **not** establish whether a cloud
  plugin is installed or running. No Studio connection or cloud asset was inspected
  during the handoff task.

### Built behavior to retain

| Area | Current implementation |
| --- | --- |
| Entry point | One **Campaign Tools** toolbar button opens the launcher. |
| Defaults | Player mode first; Ledger/D20/Characters/Pose windows start closed. DM mode is a local opt-in remembered preference. |
| Player displays | Turn Watch and hover stats activate in enabled worlds by default. Turn text is plain top-of-viewport text and disappears outside combat. |
| Resources | New registrations start full at **100 Health / 125 Mana / 6 AP**. Existing saved values are preserved. Saving a maximum fills only that resource. |
| Combat | Party turn, Enemy turn, End combat, quick resource adjustments and expandable maximum/settings controls. Mana/AP recovery is an explicit DM action, not an automatic consequence of changing turn. |
| D20 | One die plus signed modifier and local history. Advantage/Disadvantage controls were removed at the user's request. |
| Plates | Hover-only by default; optional always-visible mode and local **Stat plates: Off** master switch. Native model names remain. |
| Targeting | Hover actual visible character geometry, excluding the flat movement base beneath it and invisible helpers; keep normal picking/physics. `CampaignLedgerIgnoreHover` is an explicit boolean override. |
| Identity | Stable `CampaignLedgerId` UUIDs and exact instance ownership, never display-name keys. Same-name characters remain independent. Duplicate owned templates are reconciled. |
| Selection | Selecting a model updates an already-open combat sheet. Choosing a Characters row opens its sheet; ordinary map selection does not force a closed ledger open. |
| Scope | Explicit saved world enable flag and matching place ID. Plugins are installed per editor; joining Team Create cannot install a plugin automatically. Re-enable in a new destination place after export. |

### Latest completed feature: Pose Change and detached Characters window

Both are implemented and packaged; **not installed or published by that feature update**.

Player workflow: select the registered model → **Campaign Tools → Pose Change** →
wait for **Registration saved** → delete the old model if desired → paste one new
model. A recognized local paste followed by selection may transfer automatically.
Otherwise select the replacement and click **Use selected model**.

- `PoseStore` saves a pending snapshot under owned
  `ReplicatedStorage.CampaignToolsPoseChanges` before detaching the original's
  active registration. It retains the exact saved state, stable ID, spent/current
  resources, maxima, display name and plate settings.
- The plugin does not delete, move or rename model geometry. A pose-name override
  preserves the character's displayed name even if the prefab name differs.
- DM edits and recovery can operate on the pending entry; the replacement receives
  those latest values. Removing a normal ledger row cannot discard pending data.
- Ordinary selections and other editors' arbitrary model additions must not consume
  a pending transfer. Automatic transfer needs recognized local paste evidence;
  manual selection is the fallback, not a failure requiring re-registration.
- An already-registered replacement needs a second **Confirm replacement** click;
  its previous registration is archived. This guard is an implemented design choice,
  not a claim that the user separately specified every conflict rule.
- Cancel restores the latest snapshot to an unchanged surviving original. After the
  original is deleted, cancellation is disabled and the snapshot remains available.
- Pending state survives UI closure, role changes and plugin reload. **Save the place**
  for persistence across closing Studio. Records are tied to the place ID; finish
  transfers before exporting to a different place.
- Per-editor ownership and write-boundary conflict checks exist, but this is **not
  a distributed lock** or security boundary for simultaneous Team Create edits.
- **Characters** now owns search, roster and registration in a separate native dock
  widget, independently resizable from the combat ledger. The old integrated
  draggable divider was superseded, not accidentally lost.

## Validation and unfinished work

`QA.md` records **506 passing automated checks** for the feature checkpoint, all
four generated sources compiling, pure-module analysis, XML/source/archive matching,
one installable plugin in the primary ZIP, and unchanged Script Sync files. These
are prior recorded results; tests were **not rerun for this documentation task**.

The former CLI location `/tmp/dnd-luau-tools/` no longer exists. Obtain/locate the
official Luau CLI before rerunning; do not claim an old temporary tool is available.
The documented test commands, substituting the actual CLI path, are:

```sh
luau tests/state.spec.luau tests/names.spec.luau tests/combat.spec.luau tests/identity.spec.luau tests/hover.spec.luau
python3 scripts/test_identity.py /path/to/luau
python3 scripts/test_hover.py /path/to/luau
python3 scripts/test_ui.py /path/to/luau --snapshots /tmp/campaign-ui
python3 scripts/test_scope.py /path/to/luau
python3 scripts/test_suite.py /path/to/luau
python3 scripts/test_pose.py /path/to/luau
python3 scripts/build.py --no-sync
```

Use `docs/DEVELOPMENT.md` for static analysis, compilation and preview details.
Offline previews approximate native text metrics/input/layering; do not label them
Studio screenshots or live-tested releases.

Still pending for the latest feature: native docking/resize, real keyboard and menu
paste event ordering, Studio undo/redo and save/reopen, and simultaneous multi-editor
Team Create behavior. Historical successful checks in older QA sections do not
validate the current build. An older chest-selection complaint is recorded in QA;
later hover changes exist, but broad body-part selection must still be checked live.

Recurring difficulties: stale/closed native dialogs, automation errors such as
`windowNotFoundAtPosition`, unreliable reload clicks, and accidental confusion between
imported source, installed source and published source. After a small number of failed
UI attempts, pivot to files/connectors and report the exact runtime gap instead of
repeatedly asking the user to refocus or opening another Studio.

## Important decisions and superseded approaches

- Keep square Ash/burgundy controls, serif headings and restrained fantasy detailing.
  Earlier parchment/gold styling and other palette proposals were superseded by C.
  Deepwoken and D&D Beyond were references, not instructions to clone their UI.
- Use one combined installable plugin/toolbar entry; retain legacy standalone builds
  as rollback resources. Do not run standalone and combined versions together.
- The user asked to **keep** their old `CampaignLedger`, `CampaignD20` and
  `CampaignTurnWatch` files. Do not delete backups under the assumption they are unwanted.
- Preserve state schema **version 1**. It is a data-format number, not a release version.
  Do not migrate valid 30/12/3 characters to the new defaults or require re-registration.
- The old-defaults incident was resolved when the user enabled Roblox plugin
  **Auto Update**. Correct imported source does not establish which plugin is running.
  Check that setting and installed source before suggesting repeated reinstalls.
- No automatic per-character initiative system: user chose **Party turn / Enemy turn**.
- No automatic mana/AP refill on turn change: user wanted a deliberate DM refill button.
- Duplicate registration fixes preserve hidden legacy state rather than deleting it.
  Same-name models are valid; names are presentation, not identity.

## Resources and authoritative artifacts

Paths below are relative to the verified repository root unless absolute.

| Resource | Authority / purpose |
| --- | --- |
| `AGENTS.md` | Current project workflow and authorization boundaries. |
| `src/*.luau` | Editable source. `SuiteMain` bootstraps the combined plugin; `LedgerSession`, `ViewerSession`, `DiceSession` manage features. |
| `src/PoseStore.luau`, `PoseSession.luau`, `PosePanel.luau` | Saved transfer data, lifecycle/paste/conflict handling, player UI. |
| `src/RosterPanel.luau`, `Panel.luau`, `LauncherPanel.luau` | Independent roster, combat editor, single-button launcher. |
| `State`, `Registry`, `Names`, `Plate`, `Hover`, `WorldScope`, `Theme`, `Layout` under `src/` | Compatibility, ownership, naming, world-space rendering, scope and design rules. |
| `dist/CampaignTools.rbxmx` | Primary installable/publishable generated Script. Absolute path: `/Users/apples.j/Desktop/Gen Projects/dnd scripts/dist/CampaignTools.rbxmx`. |
| `dist/CampaignTools.luau`, `CampaignTools.zip` | Generated source and distribution archive; ZIP is not the plugin to upload. |
| `docs/POSE_CHANGE.md`, `USER_GUIDE.md`, `INSTALLATION.md` | Actual user workflows, migration and publishing. |
| `docs/DEVELOPMENT.md`, `QA.md`, `DESIGN.md` | Checks, validation limits, current and historical design decisions. |
| `BACKUPS.md` | Checkpoint links and rollback steps. Plugin rollback does not rewind map/stat edits. |
| `scripts/`, `tests/` | Build and production-code regression harnesses; tiny synthetic fixture only. |
| `DnD Test Scripts/` | Potentially connected Script Sync copies; may be stale. Not the release authority. |

Repository: https://github.com/boBananaa/campaign-ledger

Feature checkpoint:
https://github.com/boBananaa/campaign-ledger/tree/checkpoint-2026-10-25-pose-roster

Older checkpoints retained: `checkpoint-2026-10-24-heading-spacing`,
`checkpoint-2026-10-24-session-fixes`, `checkpoint-2026-10-24-launcher`,
`hover-plates-v1`, `baseline-before-hover`. Do not move or delete them.

Historical published CampaignTools asset ID: **136015129461071**,
https://create.roblox.com/store/asset/136015129461071 . This was identified earlier;
its current contents, availability and account ownership were not reverified here.
The user reported publishing/installing it and enabling Auto Update. Do not assume
the new pose/roster build is already distributed.

Previously used update route: import current `dist/CampaignTools.rbxmx` into
ServerStorage with **Insert → Import Roblox Model**, select the imported Script,
then **Publish as Plugin → Overwrite existing asset → CampaignTools**. Importing
does not install/run it. Verify current Studio menus if guiding a new publication.
For local reload, use **Reload Plugin**, not **Save and Reload Plugin** with stale
in-memory source. Do not publish or reload solely because these instructions exist.

Old screenshots were in temporary paths and may be gone. Full session maps are
not attached to this handoff and are not backed up by GitHub. Save `.rbxl` backups
separately; ignored `/backups/` may contain local historical copies but is not a
remote backup. Never commit credentials, session logs or personal maps.

## Automation and integrations

- **No scheduled task, background GitHub backup daemon or auto-publishing job is
  established by this workflow.** Checkpointing is performed by the assistant after
  completed updates under `AGENTS.md`.
- Git/`gh` terminal workflows are preferred. GitHub CLI sign-in was completed earlier;
  verify current authentication without printing credentials. Do not retain past
  device codes or request tokens in this document.
- Roblox Studio MCP was used previously; availability and connected instance must
  be discovered anew. Tool availability is not evidence of a live Studio session.
- Roblox Auto Update is a user-reported enabled setting, separate from our build,
  GitHub push and Roblox publication. Each party member installs the plugin.
- Script Sync is an existing bidirectional integration; it is intentionally excluded
  from ordinary builds using `--no-sync`.

## Next action

First check `git status --short --branch` and read the current `AGENTS.md` and top
of `QA.md`. Continue from the existing pose/roster implementation. **Do not rebuild
the feature or install/publish anything automatically.** The latest request is this
handoff; there is no additional approved redesign waiting to be implemented.

When the user resumes feature verification, establish whether they want live testing,
installation or publication, then discover the intended Studio instance. Start with
read-only version/scope inspection and a saved-place backup before reversible testing.
Prioritize one player Pose Change (including spent resources and DM edits while pending),
the manual fallback, independent Characters sizing, and a second-editor Team Create
check. Record what actually passed, checkpoint any coherent fixes, and keep main and
the published asset unchanged until the corresponding action is authorized.
