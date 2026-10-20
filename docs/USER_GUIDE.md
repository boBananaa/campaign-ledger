# Using Campaign tools

[Back to the overview](../README.md) · [Installation and reload](INSTALLATION.md)

## DM combat controls

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
5. Drag the **three-mark divider grip** between the roster and editor to give either section more
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

## Hover-only stats

Stats appear only while the cursor is over a registered character, enabled by
default for every Studio user. Any queried descendant part, including nested
accessories, weapons and non-humanoid tokens, resolves to its registered owner.
Leaving the model or viewport hides the plate. The plugin does not activate an exclusive mouse tool. A reported chest-selection
issue remains unresolved; see [known issues](../QA.md#known-issue-at-hover-plates-v1-release).

In the DM ledger, scroll to the bottom of the editor and toggle
**Hover-only plates: On/Off**. Players can use **Plugins → Campaign Turn Watch →
Hover plates**. Turning hover-only off shows every permitted plate. The preference
is saved locally, and both plugins in the same Studio window share that preference.
Each collaborator has their own cursor and preference. **Hide overhead plate**
continues to hide that character in either mode.

## Names and plate placement

Human rigs anchornear the head, ignoring raised weapons and tall accessories.
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

Open **Plugins → Campaign D20 → D20 Roller**. Set a modifier, select Normal,
Advantage or Disadvantage, and click **Roll D20**. Enter in the modifier field also
rolls. Advantage/disadvantage roll two independent D20s and keep the higher/lower
result. The display shows the total and raw roll breakdown, flags natural 1/20, and
keeps a short local recent-roll history. A natural 20 is not automatically labelled
success because that depends on the type of check and your table rules.

Rolls are local to the DM and do not modify characters or broadcast to players.
The roller uses one unseeded Roblox Random generator per plugin session.

## Turn Watch

Each player installs **CampaignTurnWatch.rbxmx** and joins the same place through
Team Create. **Party turn** or **Enemy turn** automatically appears as plain text at
the top centre of the Studio viewport, without a separate window. **End combat**
hides it completely; unset and unknown states are also hidden. The toolbar's
**Turn Watch** button optionally hides or shows the notice. There is no spoken audio
or individual character assignment. The display reads the current side on reload.

## More help

- [Install, reload or turn off the plugins](INSTALLATION.md)
- [Known issues and validation limits](../QA.md)
- [Backups and restoring an older version](../BACKUPS.md)
