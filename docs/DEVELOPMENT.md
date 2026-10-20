# Developer guide

[Back to the overview](../README.md) · [Design](../DESIGN.md) · [Validation record](../QA.md)

## Build and checks

Run `python3 scripts/build.py` to regenerate all three Luau bundles, all three .rbxmx
files, synced Scripts and dist/CampaignLedger.zip. The archive contains the whole
suite, source, documentation and tests; it excludes logs and temporary lock files.

Run each tests/*.spec.luau using the official Luau CLI, then run
`python3 scripts/test_identity.py /path/to/luau` and
`python3 scripts/test_hover.py /path/to/luau`. The current set contains
233 passing checks: 52 resource, 23 name, 75 combat/layout/placement/dice/turn,
23 identity/ownership, 13 controller/cleanup, 22 hover rules and 25 hover-controller
checks. These include rotated and translated geometry, off-centre heads, compact
vertical clearance, custom add/subtract amounts, maximum-only edits, divider limits,
selection-button padding, advantage/disadvantage, manual recovery amounts, skipped
resources, health preservation and hiding inactive turns.
All three generated plugin sources compile. Pure rule modules pass static analysis.

The controller regression harness executes the production Main callbacks and Plate
owner/cleanup functions against a small Studio API fake. It checks both removal
orders, same-name survivors, cloned IDs, preserved stats, moved/duplicate plates and
anchor cleanup. The fixture is harness input, not a standalone test or place script.

The hover harness executes the real local controller with deterministic engine API
fakes. It checks local-only visibility, default and opt-out behavior, same-name
owners, automatic-name refresh, template replacement, viewport/focus exit,
preference persistence, shared renderer ownership, takeover and unload cleanup.

Live Studio QA is recorded separately in QA.md. Multi-user replication requires a
second Team Create editor; a single local window is not evidence of that check.

Roblox references: [Studio plugins](https://create.roblox.com/docs/studio/plugins),
[BillboardGui](https://create.roblox.com/docs/reference/engine/classes/BillboardGui),
[native UI dragging](https://create.roblox.com/docs/reference/engine/classes/UIDragDetector),
[Random](https://create.roblox.com/docs/reference/engine/datatypes/Random),
[undo recordings](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService),
and [Script Sync](https://create.roblox.com/docs/scripting/sync).

## Script Sync

Script Sync is bidirectional and transfers scripts/folders, not model geometry or
plates. Keep Studio retains Studio code at a conflict; Keep Disk applies disk code.
Avoid editing the same synced script concurrently. The original Hello world Script
was preserved. There are no remote requires, external UI assets or network requests.

## Hover rendering

The saved BillboardGuis are disabled templates with a separate saved visibility
attribute. The viewer creates local CoreGui copies, using the original attachments
and geometry; hovering never writes shared Enabled properties or combat state.
Either the new Ledger or the new Turn Watch provides the viewer. Players must
install the updated Turn Watch to see these templates. Installing both produces
one renderer, with takeover when its owning plugin reloads or unloads.

Hover uses a passive viewport surface and camera raycast, sampled at 20 Hz.
Shared templates are reconciled at most every 0.2 seconds and when added/removed.
Copies update after stat rebuilds and automatic name changes; removed characters
lose their local copies. Local UI is removed when the last viewer unloads.

## Character identity and migration

Each registered model has a persistent `CampaignLedgerId` UUID, separate from its
display name. Copies carrying an existing ID receive a new one without changing
either character's stats. Same-name rows sort by ID, and all edits/removal target
the actual selected instance. Generated plates retain an explicit owner reference;
removal clears every owned plate for that character, even if moved out of the model,
while preserving the neighbouring character's registration and GUI.

On upgrade, a recognizable orphaned legacy plate can restore a missing registration
from its anchored rig and exact displayed resource values. This never matches by
name or treats Workspace as a character. Registration targets the actual humanoid
rig inside a wrapper and rejects groups containing multiple humanoids.

## Saved character data

Registration savesa CampaignLedgerState JSON attribute and CampaignLedgerCharacter
collection tag. Copy the whole registered model between maps to carry its own stats
and plate. No particular Workspace folder layout is required. Unregister removes only
plugin-owned data and anchors; it preserves character geometry. Stats are independent
of Humanoid.Health and persist through normal place saving, without DataStores.

## Turn display implementation

The overlay lives in local [CoreGui](https://create.roblox.com/docs/reference/engine/classes/CoreGui),
which Roblox supports for Studio plugins, and is removed when the plugin unloads.
It does not add UI to the map or require Play mode.

The player's plugin only reads shared state. Studio collaborators with Edit access
can still change place data: this is a DM workflow, not an access-control system.

## Backups

See [BACKUPS.md](../BACKUPS.md). Plugin source control and release ZIPs do not replace
separate `.rbxl` backups of maps, models and saved combat data.
