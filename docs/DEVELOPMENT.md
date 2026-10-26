# Developer guide

[Back to the overview](../README.md) · [Design](../DESIGN.md) · [Validation record](../QA.md)

## Build and checks

Run `python3 scripts/build.py` to build **CampaignTools**, the single publishable
plugin, plus the three legacy standalone variants. It also updates Script Sync.
`dist/CampaignTools.zip` contains exactly one installable plugin plus source, docs
and tests. `CampaignLedger.zip` retains the legacy standalone package for compatibility.

When another Studio project is open, use `python3 scripts/build.py --no-sync`.
This updates only dist and its archive, leaving `DnD Test Scripts/` untouched.
Neither build command installs or reloads local plugins. Installing a local plugin
is a separate step that affects all Studio places on this Mac.

Run each tests/*.spec.luau using the official Luau CLI, then run
`python3 scripts/test_identity.py /path/to/luau` and
`python3 scripts/test_hover.py /path/to/luau` and
`python3 scripts/test_ui.py /path/to/luau` and
`python3 scripts/test_scope.py /path/to/luau` and
`python3 scripts/test_suite.py /path/to/luau` and
`python3 scripts/test_pose.py /path/to/luau`. The current set contains
506 passing checks: 54 resource, 25 name, 101 combat/layout/placement/dice/turn,
25 identity/ownership, 28 controller/cleanup, 25 hover rules, 48 hover-controller,
57 UI workflow/layout, 50 world-isolation/bootstrap, 48 combined-suite and 45 pose-transfer checks. Obsolete integrated-divider checks were replaced by the detached combat layout checks. These include rotated and translated geometry, off-centre heads, compact
vertical clearance, custom add/subtract amounts, maximum-only edits, independent roster sizing,
selection-button padding, advantage/disadvantage, manual recovery amounts, skipped
resources, health preservation and hiding inactive turns.
All four generated plugin sources compile. Pure rule modules pass static analysis.

The controller regression harness executes the production LedgerSession callbacks and Plate
owner/cleanup functions against a small Studio API fake. It checks both removal
orders, same-name survivors, cloned IDs, preserved stats, moved/duplicate plates and
anchor cleanup. The fixture is harness input, not a standalone test or place script.

The hover harness executes the real local controller with deterministic engine API
fakes. It checks local-only visibility, default and opt-out behavior, same-name
owners, automatic-name refresh, template replacement, viewport/focus exit,
preference persistence, shared renderer ownership, takeover and unload cleanup.

The UI harness executes the production Panel, RosterPanel, PosePanel, Theme, LauncherPanel and DicePanel constructors,
button callbacks and layout functions with engine fakes. It covers compact sizing,
independent resizing, recovery scope, same-name selection, input preservation,
Enter-to-save/roll, zero maxima and four-digit values, dice result bounds and cleanup.
It does not model engine text metrics, native input routing or CoreGui layering.
For a read-only offline preview, run `python3 scripts/test_ui.py /path/to/luau
--snapshots /tmp/campaign-ui` (on one line), then
`python3 scripts/preview_ui.py /tmp/campaign-ui`. Open the resulting review.html.
The companion launcher.html, roster.html and pose.html show their corresponding states.
Fonts and layout in this preview are approximate; the real Studio check remains required.

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

Hover uses a passive viewport surface and camera raycast, sampled up to 60 Hz with
immediate pointer events and a current pointer read each sample. It skips nearly
invisible parts with a bounded exclusion raycast and stops at opaque map geometry.
Thin horizontal movement bases below the visible multi-part figure are excluded
from activation without changing picking/physics properties. The
`CampaignLedgerIgnoreHover` boolean attribute on a part/group can override that heuristic.
Shared templates are reconciled at most every 0.2 seconds and when added/removed.
Copies update after stat rebuilds and automatic name changes; removed characters
lose their local copies. Local UI is removed when the last viewer unloads.
One template per exact owner is chosen before rendering; keyed duplicate winners
are independent of arrival order. A separate local `CampaignLedgerPlatesVisible`
preference gates every copy without changing shared visibility or combat state.

Generated plates now carry `CampaignLedgerPlateId`. Ledger reconciliation prunes
same-owner duplicates using that shared key and preserves the winner's attachment.
Selecting a body part canonicalizes to its rig before registration, with a second
saved-state check inside the edit transaction. Parent/child registration overlaps
are suppressed in the roster/viewer/recovery, without deleting either saved state.
This repairs converged duplicate displays; it is not a distributed edit lock.

State remains schema version 1. Loading valid existing attributes never applies
new registration defaults. Only explicit registration uses 100/125/6; only an
explicit maximum-save action fills the chosen resource to its new maximum.

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

Registration saves a CampaignLedgerState JSON attribute and CampaignLedgerCharacter
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


## World-scoped lifecycle

WorldScope owns shared opt-in via ReplicatedStorage attributes
`CampaignLedgerEnabled = true` and `CampaignLedgerPlaceId = game.PlaceId`.
Positive integer IDs and explicit booleans are required. There is no implicit
activation from registered characters or copied plates. Exporting under a new
place ID requires explicit re-enabling; the saved old marker alone is inactive.

Each plugin starts its session only inside that scope and returns its cleanup
function. Scope changes are coalesced/deferred so constructors and automatic plate
migration run after the enable recording finishes. Disable/Undo/ID changes tear
sessions down; unload disconnects observers and cancels queued reactivation.
The combined plugin leaves its closed launcher available outside the gate, without
starting feature sessions. The legacy Ledger leaves a setup toolbar; legacy viewer
and D20 create no UI outside scope. No plugin files, network downloads or settings are propagated to other
computers. Party members install the bundled viewer themselves.

All dock constructors use InitialEnabled=false and
InitialEnabledShouldOverrideRestore=true. Session cleanup clears widget content, hides cached native widget handles, disables
cached buttons and releases hover viewers/listeners. Native toolbars, actions and
widget handles are reused for the plugin lifetime because Studio reserves their
IDs after Destroy. Plugin unload destroys those handles once.
The scope harness exercises the production module and all three entry points.
It does not prove multi-user networking or native window restoration.


## Combined plugin

SuiteMain runs one WorldScope lifecycle for the plugin. ViewerSession always starts
in enabled worlds. LedgerSession/DiceSession start only when the local
`CampaignToolsDMEnabled` preference is explicitly true; fresh installation defaults
false. The shared world flag never grants or changes that local role preference.
All DM windows still start closed, including when restoring an explicit DM preference.

SuiteMain creates exactly one toolbar and button for the plugin lifetime. It opens
LauncherPanel, which routes player preferences, the local DM role, shared world
activation and explicit Ledger/D20 opens. Session modules accept `launcher = true`
to suppress their standalone toolbars and return controllers alongside cleanup.
The launcher starts closed and remains available outside the world scope. Closing
it does not stop the viewer or change the role/world settings.

Standalone entry files call the same session modules. Hover.start leases one real
controller per plugin Instance, so Ledger and ViewerSession share one renderer and
preference stream in the combined build. Releasing the Ledger lease leaves the player
viewer active; the last lease tears down its controller. Native IDs remain cached
by WorldScope across role/world changes. No additional external dependencies or
network-based runtime loading are introduced.

The suite harness executes the production bootstrap/session/hover code with engine
fakes. It covers fresh player defaults, automatic party text and hover reveal,
unchanged stats in player mode, DM toggles, preference persistence, a single pointer
surface, one toolbar button in both roles, launcher settings/actions, closed menus,
world/export gating, cached native IDs and complete unload. Native combined
plugin installation and a multi-user check remain separate validation steps.

## Pose storage and independent roster

PoseStore owns pending registrations under the owned ReplicatedStorage folder
`CampaignToolsPoseChanges`. Each record has a saved place ID, editor user ID,
stable character ID, exact state string, original-state guard and SourceModel
reference. Starting a transfer saves this record before detaching the source tag
and generated plate; it does not delete geometry. DM edits use the record's state
as authority while pending, including selected/all-character recovery.

PoseSession runs alongside the player viewer inside WorldScope, independently of
DM mode. Its lazy native pose widget remains closed until an explicit action.
Selection plus recently added instances is insufficient to auto-transfer: it also
requires a recognized local paste recording or a recent Command/Control-V gesture.
Unrecognized/native menu ordering falls back to explicit Use selected model.
Occupied replacements require a second confirmation and get a saved archive before
replacement. Validation runs again inside the undo recording; precondition failures
never restore stale data over a newer external edit. Failed writes restore only
objects this operation actually touched, keeping the pending record.

The original ID and raw state transfer without applying defaults. A model-level
`CampaignLedgerPoseName` override keeps automatic names stable across differently
named pose prefabs; explicitly switching name mode clears it. State schema remains
version 1. Generated content is scrubbed only inside the selected replacement, so
copied stale owner references cannot delete a different model's plate.

RosterPanel owns search/rows/registration in its own cached native widget; Panel
owns combat/recovery/details. The integrated split/drag preference is no longer
used. Choosing a row explicitly opens combat controls, but SelectionChanged only
updates selection and never forces a closed window open. SuiteMain retains one
toolbar button. World/role teardown clears both DM surfaces; pending data persists.
Snapshots and archives are world content and require place backups; Script Sync
and GitHub checkpoints do not back up their live character data.
