# Campaign tools for Roblox Studio

Three independent local plugins for D&D sessions in **Studio edit mode / Team Create**.
All use the Crew of Northwatch parchment, rust-red and brown palette with square edges.

## Campaign Ledger: DM combat controls

1. Open **Plugins → Campaign Ledger → DM Ledger**.
2. Select an existing character Model and click **Register selected character**.
   Single-part tokens also work. Existing registered characters retain their values.
3. During battle, enter an amount beside Health, Mana or Actions, then click
   **Subtract** or **Add**. Presets adjust health/mana by 1 or 5, and AP has Spend 1,
   Refund 1 and Refill AP. Values clamp between zero and the character's maximum.
4. Below the combat controls, click **Expand maximums and settings** to edit permanent
   maximums, restore resources, rename, tune plate height, rebuild or unregister.
   Increasing a maximum preserves the current amount; lowering it clamps the current
   amount if necessary. Saving a maximum never resubmits a stale current value.
5. Drag **Drag to resize** between the roster and editor to give either section more
   room. The split is bounded so both remain accessible, and is saved locally.

Select model now occupies its own padded row below the character name, away from
both the divider and the scrolling boundary. Long names truncate before overflowing.
The editor and full panel scroll when Studio makes the dock small.

Defaults for a new registration are 30 health, 12 mana and 3 AP. All maximums are
editable whole numbers from 0 to 9999; these defaults do not implement official D&D
rules. AP refill is independent of whose side has the turn.

**Party turn / Enemy turn / End combat** update the player Turn Watch plugin through
one shared attribute on ReplicatedStorage. These controls work even without selecting
or registering a character. Studio Undo/Redo covers resource and turn edits.

Below these controls, **Turn recovery** lets the DM enter mana and action amounts
and click **Refill selected** or **Refill all characters** whenever recovery is due.
It adds the entered amounts up to each maximum, leaves health untouched, and never
switches the turn. Set either amount to 0 to skip that resource. Both cannot be 0.
The initial amounts are 1 each; the last successfully applied amounts are saved
locally. All-character recovery includes every registered character in Workspace,
regardless of roster search, in one undo record. Invalid stats stop the whole batch
before edits begin.

## Hover-only plates

Stats appear only while the cursor is over a registered character, enabled by
default for every Studio user. Any queried descendant part, including nested
accessories, weapons and non-humanoid tokens, resolves to its registered owner.
Leaving the model or viewport hides the plate. Studio selection and movement
tools continue to work; the plugin never activates an exclusive mouse tool.

In the DM ledger, scroll to **Display settings for this Studio window** and toggle
**Hover-only plates: On/Off**. Players can use **Plugins → Campaign Turn Watch →
Hover plates**. Turning hover-only off shows every permitted plate. The preference
is saved locally, and both plugins in the same Studio window share that preference.
Each collaborator has their own cursor and preference. **Hide overhead plate**
continues to hide that character in either mode.

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

## Overhead plates and naming

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

Human rigs anchor near the head, ignoring raised weapons and tall accessories.
Animal rigs prefer a custom head part such as DogHead. Other tokens use their
visible geometry's world-space bounds, accounting for part rotation. An owned attachment follows model movement. Low animal/token plates use camera-
relative clearance so a steep viewing angle does not put the box over the head. The dog
placement no longer depends on the first arbitrary descendant or an upright Head.
Invisible helper parts are excluded from bounds unless the model has no visible parts.

The plate sits above existing overhead name displays with a compact gap, rather
than covering the original name. In expanded settings, **Lower / Raise** changes a
character's plate height in quarter-stud steps; **Auto** restores automatic placement.
Rebuild after replacing body geometry, scaling parts or substantially changing a
pose. A whole-model move carries the attachment with it. Existing plates upgrade on
plugin reload, preserving combat values. Studio Undo can revert a style migration.

Plates are 3.8 studs wide, shrink naturally with distance, cap at 228 × 116 pixels up
close and disappear past 160 studs. They render above map geometry. All child layout
and text scale with the plate; there are no per-frame replicated camera-size writes.

Names follow an existing visible name-labelled custom BillboardGui, then a visible
Humanoid DisplayName, then the model name. Numeric stat labels and generated plates
are ignored. Changes to external names are observed while the ledger runs. Saving
Character name switches to manual naming; **Use model’s overhead name** restores
automatic naming. The plugin does not change the original nametag or Humanoid name.

Registration saves a CampaignLedgerState JSON attribute and CampaignLedgerCharacter
collection tag. Copy the whole registered model between maps to carry its own stats
and plate. No particular Workspace folder layout is required. Unregister removes only
plugin-owned data and anchors; it preserves character geometry. Stats are independent
of Humanoid.Health and persist through normal place saving, without DataStores.

## D20 Roller: a separate DM plugin

Open **Plugins → Campaign D20 → D20 Roller**. Set a modifier, select Normal,
Advantage or Disadvantage, and click **Roll D20**. Enter in the modifier field also
rolls. Advantage/disadvantage roll two independent D20s and keep the higher/lower
result. The display shows the total and raw roll breakdown, flags natural 1/20, and
keeps a short local recent-roll history. A natural 20 is not automatically labelled
success because that depends on the type of check and your table rules.

Rolls are local to the DM and do not modify characters or broadcast to players.
The roller uses one unseeded Roblox Random generator per plugin session.

## Turn Watch: a separate player plugin

Each player installs **CampaignTurnWatch.rbxmx** and joins the same place through
Team Create. **Party turn** or **Enemy turn** automatically appears as plain text at
the top centre of the Studio viewport, without a separate window. **End combat**
hides it completely; unset and unknown states are also hidden. The toolbar's
**Turn Watch** button optionally hides or shows the notice. There is no spoken audio
or individual character assignment. The display reads the current side on reload.

The overlay lives in local [CoreGui](https://create.roblox.com/docs/reference/engine/classes/CoreGui),
which Roblox supports for Studio plugins, and is removed when the plugin unloads.
It does not add UI to the map or require Play mode.

The player's plugin only reads shared state. Studio collaborators with Edit access
can still change place data: this is a DM workflow, not an access-control system.

## Install, reload and share

The three .rbxmx files in dist/ are independent installable plugins. They have been
copied to the local Studio Plugins folder on this Mac. On another computer, use
**Plugins → Plugins Folder**, copy the desired .rbxmx into it and reopen Studio once
if the plugin does not load. Players only need CampaignTurnWatch.rbxmx.

For a source-based install, select the corresponding synced Script under
**ServerScriptService → DnD Test Scripts**, then **Plugins → Save as Local Plugin**.
To reload an installed plugin, enable Studio Settings → Studio → Plugin Debugging
Enabled, find it under PluginDebugService, and use Reload Plugin. When changing
source files, rebuild and update the installed copy first; avoid saving an older
in-memory plugin over a newer disk version.

Script Sync is bidirectional and transfers scripts/folders, not model geometry or
plates. Keep Studio retains Studio code at a conflict; Keep Disk applies disk code.
Avoid editing the same synced script concurrently. The original Hello world Script
was preserved. There are no remote requires, external UI assets or network requests.

## Build and validation

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

## Versioned backups

See [BACKUPS.md](BACKUPS.md) for saving milestones, restoring a tagged plugin
package and keeping separate Roblox place backups. Hover-only plates are implemented
on `feature/hover-plates` as a test build. The `baseline-before-hover` tag preserves
the previous implementation, and `main` remains at that baseline pending review.
