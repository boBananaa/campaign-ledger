# Validation record

## Automated checks

473 checks pass with the official Luau CLI: 52 combat-state, 23 name-resolver,
171 combat/layout/placement/dice/turn, 23 identity/ownership, 17 controller/cleanup,
22 hover-rule, 30 hover-controller, 43 UI workflow/layout, 50 world-isolation/bootstrap
and 42 combined-suite checks. All four generated plugins compile.
The pure modules pass static analysis. Archive integrity and bundle/source matching
are checked by the build workflow.

## Single-button launcher revision · 2026-10-24

- Combined Campaign Tools now creates exactly one native toolbar/button. Its closed
  launcher holds turn/hover switches, the local DM toggle, shared world activation
  and Open Ledger/Open D20. Standalone variants retain their own toolbars.
- Production bootstrap checks assert one toolbar/button in player and DM modes,
  explicit menu opens, closed startup/re-enable, local role persistence, world
  isolation, settings actions and cleanup. Closing the launcher leaves the viewer
  active; DM remains off on first install and player features auto-start in scope.
- Constructor checks cover disabled actions, player/DM/inactive states and the
  minimum 320 × 420 content area. An offline rendering of these states was inspected;
  it approximates text/layout and does not establish native Studio input or font fit.
- Built without Script Sync, installation, publication or changes to live places.
  No installed plugin files were removed or replaced by this revision. Republish the updated
  CampaignTools Script over the existing asset to distribute this revision.

## Simplified D20 revision · 2026-10-24

- Removed the Normal/Advantage/Disadvantage selector and moved the remaining controls
  upward. Each roll uses one D20 plus the signed modifier. The default roller window
  and content are 45px shorter; recent rolls omit the redundant normal-mode prefix.
- Updated the existing production-UI checks to verify positive/negative modifiers,
  exactly one random draw per roll, Enter-to-roll and natural-20 display.
- Rebuilt the combined publishing file and legacy variants. Installed plugins and
  the published Roblox asset are unchanged until the owner updates that asset.

## Combined publishing build · 2026-10-24

- CampaignTools.rbxmx contains one Script with Ledger, D20 and Turn Watch bundled
  together. The primary ZIP has one installable plugin, plus sources/docs/tests.
  It is prepared for one Roblox asset upload; no upload or publication was performed.
- Fresh installation defaults to player mode: Turn Watch and the hover renderer
  start automatically in an enabled world. DM Ledger/D20 sessions are absent until
  DM controls is enabled locally. Both DM windows then start closed.
- Refactored the existing controllers into LedgerSession, DiceSession and
  ViewerSession, reused by the combined and legacy entry points. No resource/identity
  formats or shared world flags changed. Hover now leases one controller per plugin
  Instance so combined features cannot create duplicate pointer surfaces.
- Production-code harnesses check player startup, hovered stats, turn text,
  read-only player state, DM role changes, remembered preference, shared hover
  ownership, cached native IDs, scope/export changes and unload. All 456 checks pass.
- Existing installed standalone plugins, Script Sync and live Studio places remain
  untouched for this packaging change. The combined plugin has not been installed
  or visually tested in native Studio. Migration requires unloading/removing the old
  standalone copies; multi-user behavior and the chest-selection report remain unverified.

## World-isolation revision · 2026-10-24

- Root cause in source: Ledger and D20 used InitialEnabled=true and allowed Studio
  to restore previous widget visibility. Both now start closed and override restore.
- WorldScope gates all three entry points on explicit shared activation matching
  the saved place ID. Registered models alone cannot opt in a place. Only a small
  DM setup button is created outside scope; the viewer/D20 create no UI there.
- Production-controller checks simulate restored-open menus, world enable/disable,
  copied characters, new place IDs, re-enabling after export, no duplicate startup,
  Undo-style scope changes, unloading and queued changes after cleanup. All 417 checks
  pass. Constructors/entry points are engine fakes; this is not a native multi-window
  or multi-user Studio check.
- Installed all three updated local plugins with byte-for-byte dist verification;
  previous copies are backed up under ignored backups/plugins-before-world-isolation-20261024-201420.
  Script Sync files and global settings are unchanged. No extra Studio was opened.
- At the user's request, enabled the current test place 99379788858744 with a
  dedicated undo recording. Direct readback confirms explicit enable and matching
  place ID. All three character state strings/IDs and the idle phase are unchanged.
- The initial command could not nest an undo recording inside the connector's command
  recording. A short deferred task acquired its own recording after that command
  finished; no edit was made when recording was unavailable.
- First native disable/re-enable found that Studio reserves toolbar button IDs even
  after the controls are destroyed. Explicit button destruction did not free them in
  a temporary native probe. The corrected design caches native toolbar, action and
  widget handles for the plugin lifetime, disables/clears them while inactive and
  destroys them on unload. The fakes now retain IDs to reproduce this constraint.
- After the user's second reload, all three running sources matched the corrected
  lifecycle. Both native DockWidgetPluginGuis were present with Enabled=false.
- A reversible live disable removed the hover root and turn overlay; both cached
  widgets had Enabled=false and zero children. Re-enable restored one content root
  in each widget and the shared hover viewer while both menus stayed closed.
- Final direct readback confirms the test world remains enabled for place ID
  99379788858744, with every character state string/ID and the idle phase unchanged.
  Separate-instance startup and multi-user replication remain unverified.

## Palette C installation · 2026-10-23

- At the user's request, replaced all three local plugin files with the approved
  Ash & burgundy build. Previous copies and hashes are saved under the ignored
  backups/plugins-before-ash-burgundy-20261023-215955 folder.
- Studio reconnected to the same place (99379788858744). Direct inspection confirmed
  all three loaded plugin sources contain the approved palette, and all three owned
  overhead plates use style 11. A screenshot visibly confirmed the new overhead
  palette and updated Turn Watch text in the existing place.
- Exact state strings and IDs for all three characters were compared before/after;
  health, mana, AP, maximums, names, offsets and visibility are unchanged. The shared
  phase remains enemy. Both same-name Assata entries are still present.
- Automated native clicks could not trigger the reload menu; installation was
  confirmed only after Studio reconnected with the new running sources. No extra
  Studio session was launched by this task. Script Sync and global settings were
  left unchanged. No Git commit or publication was performed.
- This confirms installation and the observed overhead/turn display. Full live
  interaction, panel text-fit, camera sweep and multi-user checks remain pending.

## Medieval UI test build · 2026-10-23

- Initial source/dist verification ran on `codex/medieval-combat-ui` before
  installation. At that stage the connector returned no instances and installed
  plugins were untouched. The later installation is recorded above.
- Approved palette C (Ash & burgundy) is applied to Ledger, D20, Turn Watch
  and style 11 overhead plates. Selection fills are separated from pale text and
  resource colors. Twelve text/background combinations were calculated above 5.3:1
  contrast; disabled text and borders are outside that check.
- The updated compact/wide/recovery/D20 constructor-tree preview was rendered and
  inspected after applying C. This remains an approximation, not a Studio check.
- The production Panel/Theme/DicePanel constructors and callbacks run in an engine
  fake. Checks cover global turns without selection; manual recovery targeting;
  duplicate-name selection; quick/custom deltas; focused input preservation;
  details, maximum save, Enter-to-roll, natural 20, resize/divider bounds and unload.
- At 330 × 640, the calculated content fits with both disclosures closed. Layout
  checks cover 480/640/760/1000px heights and collapsed/expanded Recovery. At minimum
  height the editor scrolls; expanded Recovery leaves a smaller editor viewport.
- Offline snapshots of compact/wide, recovery, details, empty and long-name /
  9999 / zero-maximum states were rendered and inspected. These export the real
  constructor tree but approximate fonts and engine layout; they are not Studio screenshots.
- Luna performed a simulated DM walkthrough. Its findings led to shorter AP presets,
  a custom amount cue, an explicit selection arrow and the all-recovery count.
  A second pass found no blocking issue in the approximation. This is not human testing.
- Pending: real Studio font/text-fit, clicks/tab focus, drag and scrolling, overhead
  plate close/far placement, native model selection and Turn Watch layering. Prior
  live checks below apply to earlier revisions, not this build. The reported chest
  selection issue remains unresolved. No claim of new multi-user validation.

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

- The feature was developed on feature/hover-plates and approved for main.
  baseline-before-hover remains unchanged. Both local test plugins were installed and reloaded in the existing
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

## Known issue at hover-plates-v1 release

- The user reports being unable to select while hovering over a character chest.
  This remains unresolved; the earlier successful Groot selection check does not
  establish selection works over every body part. The cause has not been confirmed.

## Parchment UI test build

- Built on `feature/parchment-ui`; the released main branch stays unchanged pending
  review. A design subagent reviewed palette, hierarchy and narrow-width geometry.
- The existing 233 automated checks passed; all three generated sources compiled,
  pure modules passed analysis, and the release archive passed integrity checks.
- Reloaded all three existing local plugins in the same Studio process through
  PluginDebugService. Installed sources matched the generated bundles exactly.
- In native Studio, D20 Normal and Disadvantage clicks produced results and updated
  history. Resized its floating window to 320 pixels and visually confirmed that
  all three mode labels, result, breakdown and history fit. Restored its width.
- Ledger roster selection displayed the ink heading and colored resource meters.
  Temporarily constrained its local viewport to 330 pixels, set local display text
  to four-digit values and a long character name, and checked 51 control/numeric
  text widths against actual engine TextBounds. All fit; the long name truncated
  cleanly. This checks the content width, not a successful native dock resize.
- Cloned two generated plate canvases into a temporary local CoreGui preview.
  Visually checked normal and 9999 / 9999 values at 228 × 116; all text bounds fit.
  These are canvas checks, not new camera-distance or animal-placement checks.
- Removed the preview, restored local text/viewport dimensions and selection, and
  reset UI scroll positions. Three registered characters retained byte-identical
  combat-state attributes. All 241 captured BaseParts retained their names,
  parents, sizes and transforms. Each saved plate migrated to style 9 and remained
  a disabled hover template. No extra Studio session or demo model was created.
- A native divider drag was not verified by automation. The existing drag callbacks
  and clamp tests remain in place. No full Studio restart or second Team Create
  editor was tested. The reported chest-selection issue remains unresolved.
