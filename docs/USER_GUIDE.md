# Using Campaign tools

[Back to the overview](../README.md) · [Installation and reload](INSTALLATION.md)

## DM combat controls

1. Click **Campaign Tools** in the Plugins toolbar to open the launcher. Turn
   **DM controls: On** locally. In the session map, click **Enable D&D in this world**
   once, then **Open Characters**. All menus start closed.
2. Select an existing character Model and click **Register selected model** in the
   Characters window. Choose its row to open its combat controls in the ledger.
   Single-part tokens also work. Existing registered characters retain their values.
3. During battle, enter an amount beside Health, Mana or Actions, then click
   **Subtract** or **Add**. Presets adjust health/mana by 1 or 5, and AP has −1, +1
   and Refill AP. Values clamp between zero and the character's maximum.
4. Below the combat controls, click **Character details · maximums & settings** to edit permanent
   maximums, restore resources, rename, tune plate height, rebuild or unregister.
   Saving a maximum immediately fills that resource to the entered maximum. It
   leaves the other resources alone; Studio Undo restores the previous values.
5. Resize or dock **Characters** independently of the combat ledger. Its list uses
   the available height; it scrolls only when the entries exceed that space.

Select model now occupies its own padded row below the character name, away from
the scrolling boundary. Long names truncate before overflowing.
The roster and editor live in separate windows. Turn controls and the hover preference
stay fixed. At 330 × 640, close Recovery and Character details to see all combat
controls together; smaller docks need editor scrolling.

Turning **DM controls** off closes Characters/Ledger/D20 and removes their content without
stopping the player turn/hover viewer. Enabling DM controls again keeps the menus
closed until opened from the launcher. The choice is local and remembered for this plugin.
Closing the launcher leaves the turn notice and hover viewer running.

**Characters…** inside the ledger reopens the roster. Clicking a registered model
in the map still selects its combat sheet when the ledger is open. Choosing a
roster row explicitly opens that sheet; selecting models does not pop closed windows open.

## Pose Change

Players and DMs can use **Campaign Tools → Pose Change**, without enabling DM
controls. Save the registration before deleting a model, then paste a new pose.
Pending characters remain in the DM roster with **Waiting for replacement**;
combat edits and recovery still work and carry through to the new pose.
See the [pose replacement checklist](POSE_CHANGE.md) for automatic transfer,
confirmation, cancellation and recovery behavior.

Defaults for a new registration are 100 health, 125 mana and 6 AP, all full. These
defaults apply only to new characters. Updating the plugin preserves existing saved
values, maximums, names, IDs and settings; no re-registration is needed. All maximums are
editable whole numbers from 0 to 9999; these defaults do not implement official D&D
rules. AP refill is independent of whose side has the turn.

**Party turn / Enemy turn / End combat** update the player Turn Watch plugin through
one shared attribute on ReplicatedStorage. These controls work even without selecting
or registering a character. Studio Undo/Redo covers resource and turn edits.

Open **+ Recovery** beneath the turn controls to enter mana and action amounts,
then click **Recover selected** or **Recover all (count)** whenever recovery is due.
The count includes all registered characters, even those hidden by roster search.
It adds the entered amounts up to each maximum, leaves health untouched, and never
switches the turn. Set either amount to 0 to skip that resource. Both cannot be 0.
The initial amounts are 1 each; the last successfully applied amounts are saved
locally. All-character recovery includes every registered character in Workspace,
regardless of roster search, in one undo record. Invalid stats stop the whole batch
before edits begin.

## World isolation and exporting

**Enable / Disable D&D in this world** in the launcher changes a shared setting tied to the saved place ID. Installed viewers
activate automatically when it is enabled; turning it off closes campaign windows and removes active overlays for
installed collaborators without deleting stats or plates. Undo/Redo also updates
activation. The launcher stays available in inactive worlds; its viewer and DM-menu
buttons are disabled until the world is enabled. Individual editors still choose
whether to open their Ledger/D20 windows. DM controls is a workflow preference,
not a DM access restriction.

Export the whole place to keep character data and the world setting. When you
publish the export as a different Roblox place, click **Enable D&D in this world** once there to
bind the setting to its new ID. An unsaved place must be saved to Roblox first.
Copying just a character into another project cannot activate the campaign UI.

Each party member installs **CampaignTools.rbxmx** once on their own computer. It
starts with player features active and DM controls off. Studio
plugins do not install through Team Create, and ordinary map scripts do not supply
this edit-mode plugin UI. Existing installations need this isolation update too;
older copies ignore the new world setting.

## Hover-only stats

Stats appear only while the cursor is over a registered character, enabled by
default for every Studio user. Visible body parts and non-humanoid tokens resolve
to their registered owner. Flat movement bases beneath multi-part figures do not
trigger stats; they remain selectable and draggable in Studio. Invisible helper
parts are skipped, while opaque map geometry blocks targeting behind it.
Leaving the model or viewport hides the plate. The plugin does not activate an exclusive mouse tool. A reported chest-selection
issue remains unresolved; see [known issues](../QA.md#known-issue-at-hover-plates-v1-release).

Turn Watch and the hover viewer activate automatically when the combined plugin
enters an enabled world. There is no initial player setup toggle to switch on.

In the DM ledger, use the fixed bottom control
**Hover plates: On/Off · this window**. Players can open **Campaign Tools** and switch
**Hover-only: On/Off**. Turning hover-only off shows every permitted plate. The preference
is saved locally and shared by the ledger and viewer in the same Studio window.
Each collaborator has their own cursor and preference. **Hide overhead plate**
continues to hide that character in either mode.

**Stat plates: Off** in Campaign Tools completely hides the plugin's overhead
displays on your screen, including on hover. This preference is remembered locally;
it does not change combat stats, turn text or other players' displays. Switching
back on restores your hover-only preference. Original model nametags remain intact.
For an unusual movement handle, set its boolean `CampaignLedgerIgnoreHover`
attribute to true. False overrides automatic base detection for that part.

Repeated registration selects the existing character without resetting it. A limb
selection resolves to its containing rig. Duplicate generated plates collapse to
one display per model; distinct models sharing a name remain independent. Old
overlapping parent/child registrations use the outer registration in the roster
and viewer, preserving the hidden child registration's saved data.

## Names and plate placement

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

To carry stats between maps, copy the whole registered character model. Normal
place saving preserves its values. Removing a character from the ledger preserves
the model; Studio Undo restores the registration and stats.

## D20 Roller

Open **Campaign Tools**, enable **DM controls**, then click **Open D20**. Enter a positive or negative whole-number
modifier and click **Roll D20**. Enter in the modifier field also rolls. Each click
rolls one D20 and adds the modifier. The display shows the total and raw roll
breakdown, flags natural 1/20, and
keeps a short local recent-roll history. A natural 20 is not automatically labelled
success because that depends on the type of check and your table rules.

Rolls are local to the DM and do not modify characters or broadcast to players.
The roller uses one unseeded Roblox Random generator per plugin session.

## Turn Watch

Each player installs **CampaignTools.rbxmx** and joins the same place through
Team Create. **Party turn** or **Enemy turn** automatically appears as plain text at
the top centre of the Studio viewport, without a separate window. **End combat**
hides it completely; unset and unknown states are also hidden. The launcher's
**Turn text: On/Off** switch optionally hides or shows the notice locally. There is no spoken audio
or individual character assignment. The display reads the current side on reload.

## More help

- [Install, reload or turn off the plugins](INSTALLATION.md)
- [Known issues and validation limits](../QA.md)
- [Backups and restoring an older version](../BACKUPS.md)
