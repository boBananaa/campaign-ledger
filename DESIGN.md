# Campaign Ledger

## Workflow and scope

A Studio edit-mode plugin for D&D sessions in Team Create. Characters are existing
Models or BaseParts anywhere in Workspace. Register explicitly through selection;
never rename, move, resize, or replace their geometry. No demo objects in the user's
character collection. Runtime gameplay and player movement are outside this plugin.

## Design tokens

| Token | Hex | Role |
| --- | --- | --- |
| Ash base | #28202A | Supporting dark surface |
| Smoked plum | #3C303B | Roster, character sheet and overhead resource surface |
| Input well | #4B3B48 | Editable fields and dice result |
| Pale ash | #EEE6E1 | Primary text and exact values |
| Supporting text | #C5B5C0 | Secondary labels and maximums |
| Faded rose | #E7A1A1 | Health |
| Lavender | #B6BEDF | Mana |
| Pale bone | #DAC9B0 | Action points |
| Dark binding | #251C25 | Outer shell and overhead name strip |
| Burgundy | #6B4B5A | Active controls and roll action |
| Roster selection | #64434F | Selected character row |
| Rose accent | #D5A1B2 | Focus outlines and selection mark |

The user selected palette C, Ash & burgundy, from three otherwise identical
mockups. Smoked plum and faded wine replace the previous beige/brown scheme.
Keep dark surfaces separate from pale text tokens, including selected controls,
overhead names and Turn Watch. Resource colors remain distinct from selection
fills. Use native Roblox fonts: Garamond for character names and the ledger title;
SourceSans / SourceSansSemibold for controls, labels and numeric values. Body 16,
supporting 13–14, heading 28, key value 24. Current values are larger than maximums.

Use square edges throughout: panel surfaces, buttons, inputs, roster selections,
overhead plates, resource bars and AP diamonds. No UICorner instances.

## Layout

Compact overhead plate: centered character name, two left-aligned resource bars
with exact numbers, and countable AP pips. A fine rose-grey edge ties it to a miniature's
nameplate. One expressive piece, with quiet controls around it.

The plate spans 3.8 studs and shrinks naturally with distance. All child geometry
uses relative layout and text scales with it. A maximum 228 × 116 pixel canvas
keeps it restrained up close; it disappears beyond 160 studs. No per-frame camera
listeners or replicated size changes are needed.

```
          Aster Vale
 Health  =========----  24 / 36
 Mana    ======-------   8 / 14
 Actions   ◆ ◆ ◇             2 / 3
```

Dockable DM ledger: a searchable, vertically scrollable roster above the selected
character editor. This stacked layout keeps both useful at narrow Studio dock sizes.
Left-align names and labels; right-align summaries. Use a single continuous editor,
not a dashboard of identical cards.

```
          Campaign Ledger
 [Search characters…                ]
 Aster Vale     Health 24  Mana 8 AP 2
 Rowan Ash      Health 40  Mana 6 AP 3
 [+ Register selected character     ]
 ────────── divider grip ─────────────
 ┃ Aster Vale                       ┃
                       [Select model]
 Health                      24 / 36
 ━━━━━━━━━━━━━━━━━━░░░░░░░░░░░░░░░░░
 Amount [1] [Subtract] [Add]
 [−5] [−1] [+1] [+5]
 (Mana and Actions follow this grid)
 Party turn
 [Party turn] [Enemy turn] [End combat]
 Turn recovery
 Mana to add            Actions to add
 [2]                    [1]
 [Refill selected] [Refill all characters]
 [Expand maximums and settings       ]
 [Hover-only plates: On              ]
```

## Review before implementation

The initial three-bar idea resembled a generic RPG HUD. Replace the AP bar with
countable pips, because discrete actions are the distinctive combat need. Avoid
decorative runes, artificial weathering, and oversized ornate headings because
they obscure quick adjustments and character geometry. The user's supplied slide
now determines the parchment and rust palette. Center the title; omit the DM badge
and tagline as requested. Keep all exact values visible;
color reinforces labels rather than replacing them. No ambient animation.

## Architecture

1. Pure resource module: bounded integer validation, clamping, relative adjustments,
   per-character AP reset and restoration. Tests exercise actual rules.
2. Shared UI helpers and persistent BillboardGui rendering, without external assets.
3. DockWidgetPluginGui panel: search, selection linking, explicit registration,
   amount-based combat editing, collapsed maximum edits, quick deltas, readable feedback, unregister.
4. Plugin controller: CollectionService registry and one JSON state attribute on
   each character; newest state is read at action time. Every local character edit
   and its plate are saved in the same ChangeHistoryService recording. External
   overhead labels and Humanoid names drive automatic names. Ignore generated
   plates in observers and compare displayed text before writing. Read-only name
   resolution never changes combat values. Explicit manual naming remains available.
   Upgrade legacy plate styles once per character per plugin load, in a recording.
5. Self-contained generated Script plus .rbxmx package. Script Sync transfers code
   only; registration creates real saved plate objects through the installed plugin.

## Verification

Run pure Luau resource tests and syntax compilation. Load the plugin in Studio,
check panel layout, registration on an isolated temporary fixture, damage, mana,
AP spending, undo, search and removal. Test persistence separately in a temporary
place if practical. Team Create replication still requires a second editor; do not
claim a multi-user check from a single Studio window.

## Limits

Studio collaborators with Edit access can change place data. This is a DM workflow,
not a security boundary against other editors. Shared state uses last-writer-wins;
coordinate ownership when two DMs edit the same character. Ordinary place saving
persists stats; there is no DataStore. No automatic Humanoid health coupling.

## Combat revision

The roster/editor boundary is now a local draggable split with bounded heights.
Select model sits in a separate padded row below the character name. During combat,
show current/max summaries, a positive amount input, Add/Subtract and small presets.
Keep maximum-only edits and permanent settings in a collapsed section below combat.
Persist a maximum change against the latest resource state, never an old textbox's
current value.

Keep human nameplates close to their heads and ignore tall weapons when positioning
those plates. Non-humanoid tokens use rotated visible-part bounds and a centred
attachment. Leave a small gap over existing labels. Include per-character quarter-
stud height tuning for unusual figures; avoid implying that arbitrary rigs need no
calibration. Pure placement tests cover rotated, off-centre and translated geometry.

Add two independent native plugins: D20 Roller for local DM rolls, and Turn Watch for
players. The latter reads one shared party/enemy/idle attribute written through the
ledger. Party versus enemy turns are the whole requested turn model; no individual
assignment or initiative automation. All three inherit the same square-edged palette.

Reuse the user's Studio session for QA. At most one extra session is permitted when
needed, and any extra session must be closed before finishing. No repeated new-place
launches to work around stale native window bindings.

## Manual recovery and turn notice

Under the shared turn controls, show two numeric recovery inputs (mana/actions),
then explicit selected/all-character apply buttons. Recovery is DM-triggered and
independent of side switching. Clamp at each maximum and preserve health. Save the
last applied amounts locally; one undo recording covers an entire batch.

Turn Watch is a local CoreGui ScreenGui, not a dock widget. Use one parchment-ink
text line, with a dark outline for legibility, centred near the top of the viewport.
Show it only for party/enemy states. Hide the entire overlay outside combat and
remove it on plugin unload. Keep the toolbar toggle as an optional visibility switch.

## Character identity and ownership

Keep display names independent of identity. Persist a CampaignLedgerId UUID on each
registered character; repair copied IDs while preserving the known original during
the session. Use exact Instance references for selection and edits, with ID-based
tie breaking for identical names. Never use a character name or path as a unique key.

Every generated plate records its owning character with an ObjectValue and its ID.
Index generated plates by a separate tag, allowing removal to find moved duplicates
without scanning the whole map on every combat edit. Only the exact owner's GUI and
anchors are removed. Legacy orphan recovery uses an anchored rig and validated
displayed values; Workspace is explicitly excluded despite inheriting Model.

## Hover-only display

Preserve parchment #C1B6A7, paper #D8CDBB, rust #97372C, ink #382B22 and teal
#405B5A, with Garamond names and SourceSans controls. Add one square display-mode
button in a fixed bottom row, visible without selecting a
character. The control reads Hover plates: On/Off · this window; player toolbar has Hover
plates. Keep the current plate layout and avoid added animation or decoration.

A passive local CoreGui viewport surface supplies pointer coordinates. Normalize
against its rectangle, cast through the current camera and resolve the nearest
registered ancestor by Instance. Do not activate the plugin mouse or alter selection.
At up to 60 Hz, choose local-copy visibility; reconcile templates every 0.2 seconds and on
registry changes. One local renderer is shared by Ledger and Turn Watch, with failover
when its plugin unloads. Hover writes only local CoreGui UI and local preferences.
Saved Workspace plates are disabled templates; their saved visibility flag preserves
the existing explicit Hide setting. Automatic name changes update cached local names.

## Earlier parchment direction (superseded)

This section records the previous revision. The medieval revision below replaces its layout and typography.

The user approved the lighter parchment direction after a design subagent reviewed
the references. Borrow compact alignment from the plugin reference and character
framing from the D&D sheet. Avoid turning each resource into another identical card.
The shared ink name band is the visual signature; small square corner brackets are
limited to names and the dice result. No gradients, shadows, gold badges, textures,
taglines, decorative labels or ambient animation.

The roster retains the draggable split. Keep Select model in its own row beneath
the character name. Keep turn and recovery controls below the resource editor to
preserve usable roster space at narrow dock widths. Show selected turns and hover
mode with filled controls plus their existing text labels. Recovery remains manual.

Overhead style 9 uses the same world size, distance limit, attachments, text names,
exact values and AP pips as style 8. Only surfaces, framing and name contrast change.
Turn Watch remains top-of-screen text, hidden outside combat. D20 uses a framed
writing-field result, ink selected mode, rust roll button and wrapping scrollable
history. All updates use native Roblox GUI instances without downloaded assets.


## Medieval combat revision · October 2026

Dark binding surrounds two smoked-plum reading surfaces. Garamond is limited
to the centered title and character names; controls and numbers remain SourceSans.
A single open diamond interrupts the title rule. Major surfaces use fine inset
edges and square corner marks. No rounded corners, gradients, external textures,
gold badge or tagline. All motifs are original native GUI primitives.

Turn status and Party / Enemy / End controls are fixed above the roster. Recovery
is a closed-by-default disclosure immediately beneath them, with separate mana/AP
amounts, selected recovery and an all-registered count. It never switches a turn.
Search, roster and registration sit above the draggable divider. The selected
character sheet contains three compact resource rows with preset adjustments and
an aligned custom amount column. AP uses −1 / +1 / Refill AP so the compact labels
stay readable. Permanent edits remain in Character details. The hover preference
and two-line feedback stay at the bottom, outside both scrolling regions.

At 330 × 640 with disclosures closed and the divider at its upper limit, all combat
controls and the details disclosure fit. A 480px-high dock scrolls the editor. Taller
windows allow more roster space; the divider clamps before consuming the combat
editor. Opening Recovery reserves its own space and may require editor scrolling.

Style 11 plates keep the previous world dimensions, maximum canvas, distance,
attachments, owner identity, automatic naming and hover behavior. Only the palette, name
strip, font and resource framing change. D20 has a shorter result well and a
scrollable recent-roll list. Turn Watch remains plain text hidden outside combat.

The change is built without Script Sync or installation while another Studio
project is in use. The offline preview comes from the real constructor tree and
approximates rendering. Live input, font metrics, world-space placement and native
selection must still be checked in the intended Studio session before release.


## World isolation

A shared, explicit saved-place opt-in controls campaign activation. The combined
plugin offers only its closed launcher in unmarked projects; no roster observers,
hover viewer or DM menu constructors run there. The legacy Ledger exposes a small
world setup button. A copied character never opts in a map.
Turn Watch activates automatically for installed collaborators once the DM enables
the map. Each collaborator still installs the viewer once; Team Create does not
install Studio extensions. Exporting to a new place ID requires a deliberate enable.

DM Ledger and D20 use closed defaults that override restored open state. Opening
one is always a local explicit action. The world toggle enables/disables the suite
for everyone with current plugins, without deleting characters or combat data.
Changes and Undo/Redo start/stop owned sessions cleanly. Studio reserves native
control IDs after destruction, so the plugin reuses its toolbar/action/widget
handles, disables buttons and clears/hides window content while inactive.
Those cached handles are destroyed only on plugin unload. This is workflow scope,
not an editing permission boundary.


## Single publishing asset

Campaign Tools packages all features in one Script/plugin. Player-facing Turn Watch
and hover stats are active by default inside an enabled world. A local DM controls
toggle, off on first installation, enables Ledger/D20 and access to world setup.
Menus still start closed. Explicit DM preference is remembered, while world activation
is shared. This role setting is presentation/workflow, not a security boundary.

One world-scoped lifecycle owns the sessions. Ledger and ViewerSession lease one
hover controller for the same plugin Instance; turning DM controls off keeps the
player viewer alive. The package is prepared for one asset upload and one update
channel. It is not a Creator Store publication or an automatic installation.

## Single-button launcher

The combined build has one Campaign Tools toolbar button. A compact launcher holds
local turn/hover switches, the DM role toggle, explicit Ledger/D20 opens and shared
world activation. Player controls come first; DM actions are disabled until opted
in. Inactive worlds keep the launcher available while feature actions stay disabled.
Its square controls and restrained diamond divider reuse the ash/burgundy theme.

All windows start closed, overriding restored visibility. Closing the launcher
leaves player features running. Session controllers expose opens and preferences
without creating individual toolbars in the combined build; standalone variants
keep their existing controls. Role/world toggles reuse native IDs and never
automatically reopen a DM menu.

## Session fixes and saved-data compatibility

The launcher adds an independent Stat plates on/off control above the turn and
hover-only switches. Its minimum content height is 460px. Hiding plates is local
and remembered, preserves hover mode, and leaves turn text and model names alone.

Movement bases stay usable for native Studio picking, but hovering their empty
surface cannot reveal stats. Thin horizontal stands at the bottom of multi-part
figures are recognized without renaming or changing authored parts. Visible body
hits reveal stats; transparent helpers cannot intercept the ray.

Each model displays one canonical generated plate. A shared unique plate key
allows collaborators to converge on the same duplicate winner. Legacy nested
registrations are suppressed without deleting stored values. Style 12 adds the
plate identity key while keeping the established appearance and placement.

New registrations start full at 100 Health, 125 Mana and 6 AP. Existing version-1
state loads as-is. Saving a maximum explicitly refills that resource only, using
the current saved state for all other fields.
