# Validation record

## Automated checks

233 checks pass with the official Luau CLI: 52 combat-state, 23 name-resolver,
75 combat/layout/placement/dice/turn, 23 identity/ownership, 13 controller/cleanup,
22 hover-rule and 25 hover-controller checks. All three standalone plugins compile.
The pure modules pass static analysis. Archive integrity and bundle/source matching
are checked by the build workflow.

## Studio checks completed in the user's existing session

- Campaign Ledger loaded and migrated previously registered plates, preserving
  the displayed health/mana/AP values.
- The selected character's long name and Select model button occupy separate rows.
  The button border is visible without clipping into the divider.
- Quick health Add changed the dog's health from 1 to 2; Subtract restored it to 1.
  The roster, editor summary and overhead plate updated together.
- The DM Party turn button changed the shared side and the ledger's status label.
- D20 Roller loaded as an independent plugin. A normal roll showed 17 + 0 = 17.
  Advantage rolled 10 and 9 and correctly kept 10. Raw dice, total and local history
  were visible. The test window was closed afterward.
- Human plates were initially too high. Their bounds were changed to use the head
  instead of tall held weapons, and a lower placement was visually checked above
  the original white name labels.
- Turn Watch loaded as an independent plugin and displayed Party turn, then Enemy
  turn after the shared side changed. This was a same-session check, not a second
  Team Create editor. The player display window was closed afterward.
- Dog inspection found an actual DogHead part and no ordinary Head part. The final
  source targets custom head names and uses camera-relative clearance for low rigs.

- The final native UIDragDetector moved the divider upward and downward in Studio;
  the original split was restored after the check. The earlier custom input handler
  was replaced after it failed this live check.
- The maximums/settings toggle expanded and exposed the advanced section, including
  height tuning. Saving maximum values is covered by the pure combat-state checks;
  existing maximums were not altered during live QA.
- The final dog plate was visually checked above DogHead, clear of the dog's body.
  Human plates stayed close to the heads while preserving the original white names.
- Temporary party/enemy turn state was removed after testing. The dog's tested
  health returned to 1; the other existing health/mana/AP values were preserved.

## Remaining validation boundaries

Multi-user replication, save/reopen persistence and a broad camera-angle sweep
require separate validation; a single Studio session and pure geometry checks do
not prove these behaviours. Unusual figures can be calibrated with the height
controls and rebuilt after geometry/pose changes.

No extra Studio process or test place was created for this revision. Existing model
geometry, names and saved maximum values were not changed by QA.

## Manual recovery and viewport notice revision

- Both updated plugins were reloaded in the existing Studio window.
- Turn Watch appeared as plain top-centred viewport text for Party turn, changed to
  Enemy turn, and disappeared completely after clicking End combat.
- The initial shared phase for this revision was Party turn; it was restored.
- The manual recovery inputs and both target buttons were visibly accessible by
  scrolling the editor. Clicking Refill all characters with amounts 1/1 changed
  the currently registered character from 2 to 3 mana. Actions remained capped at
  3/3 and health stayed at 6. The turn remained Party turn.
- Studio Undo restored the character to 6 health, 2 mana and 3 actions, including
  the overhead plate. No extra Studio session was created.
- Pure checks cover differing recovery amounts, either resource skipped, maximum
  caps, health/maximum preservation, immutable input and invalid amounts. Selected
  targeting and multiple-character batching were reviewed in code; this live place
  contained one registered character during the recovery test.

## Duplicate-name removal revision

- Inspection found no registered characters and an owned legacy plate directly
  under Workspace, still adorned to a real Assata Leaphart rig. The original cause
  of that reparenting was not established; the user reported using Remove from ledger.
- The updated plugin recovered that character's registration and reattached its
  plate with the displayed 6/30 health, 12/12 mana and 3/3 actions preserved.
- A temporary two-character fixture was created far from the scene in the existing
  Studio session. Cloning a registered character copied its ID initially; the
  plugin assigned the clone a different ID and preserved the original ID and stats.
  Both identically named rows were visibly present in the DM roster.
- Live assertions verified the cloned plate's ObjectValue owner points to the clone.
- The computer-control tool then rejected coordinate clicks/scrolls with
  windowNotFoundAtPosition, including after the user refocused Studio and the
  tool connection was reset. A live click on Remove from ledger was not completed.
- The fallback harness runs the real Main removal callbacks and real Plate owner/
  cleanup functions. Thirteen checks pass for removing either same-name instance,
  preserving the survivor, removing moved and duplicate owned GUIs, clearing the
  target anchor, preserving the model, and automatic cloned-ID repair.
- All temporary fixture models and their moved GUI copies were removed. The final
  Studio screenshot shows only the restored Assata entry. No extra Studio session
  was opened. Same-session cloning/recovery is not evidence of multi-user replication.

## Hover-only test build

- Work is isolated on feature/hover-plates; main and baseline-before-hover remain
  unchanged. Both local test plugins were installed and reloaded in the existing
  Studio session, without starting another Studio process or opening another place.
- Default local preference was true. CoreGui's passive surface measured exactly
  the same size as the active camera viewport, with origin (0,0).
- Hovering the registered Groot character visibly revealed its stats. Normal
  Studio selection still selected the character; no exclusive plugin activation
  is used. Moving the pointer into Explorer hid the stats even while selected.
- Both new plugins were loaded, then the original owner plugin was reloaded. The
  remaining player plugin took over the local renderer successfully.
- Opt-out was checked through the local preference API: three registered
  characters produced exactly three enabled local plates. All shared templates
  stayed disabled and every captured combat-state attribute stayed identical.
  The renderer's saved plugin preference was false, confirming persistence.
- Default hover-only preference was restored to true afterward, hiding the plates
  with the cursor outside the viewport. No character stats or geometry were changed.
- The native Plugins submenu produced stale accessibility responses, so its button
  click was not verified. Toggle handlers compile; behavior and same-window
  preference synchronization are covered by the production-controller harness.
- The harness also covers nested parts/accessories, duplicate names, non-humanoid
  targets, camera/model hit changes with a stationary cursor, focus loss, explicit
  hidden plates, automatic-name updates, replaced templates, unregister cleanup,
  preference restart, renderer takeover and final unload cleanup.
- Live dog hover, a full Studio restart, a broad camera sweep and a second Team
  Create editor remain outside this test build's live validation. Existing placement
  tests remain applicable because this change reuses the original attachments/layout.
