# Campaign Ledger

## Workflow and scope

A Studio edit-mode plugin for D&D sessions in Team Create. Characters are existing
Models or BaseParts anywhere in Workspace. Register explicitly through selection;
never rename, move, resize, or replace their geometry. No demo objects in the user's
character collection. Runtime gameplay and player movement are outside this plugin.

## Design tokens

| Token | Hex | Role |
| --- | --- | --- |
| Parchment | #C1B6A7 | Main panel and overhead plates |
| Paper | #D8CDBB | Inputs and selected surfaces |
| Dark ink | #382B22 | Primary text |
| Ship red | #97372C | Title, health and selection |
| Weathered teal | #405B5A | Mana |
| Walnut | #6A4A2A | Action points |

The palette follows the user's Crew of Northwatch character-sheet reference:
grey-beige parchment, rusty red artwork and brown botanical borders. Keep native
UI surfaces clean rather than adding noisy raster texture beneath small controls.
Supporting text uses brown ink. Use native Roblox fonts: Fondamento for
character names and the ledger title; SourceSans / SourceSansSemibold for controls,
labels and numeric values. Body 16, supporting 14, heading 26, key value 24.

Use square edges throughout: panel surfaces, buttons, inputs, roster selections,
overhead plates, resource bars and AP diamonds. No UICorner instances.

## Layout

Compact overhead plate: centered character name, two left-aligned resource bars
with exact numbers, and countable AP pips. A thin brown edge ties it to a miniature's
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
 Aster Vale                  24  8  2
 Rowan Ash                   40  6  3
 [Register selected character       ]
 ------------------------------------
 Aster Vale              [Select model]
 Health          [24] / [36] [Save]
 [−5] [−1] [+1] [+5]
 Mana             [8] / [14] [Save]
 [−5] [−1] [+1] [+5]
 Actions          [2] / [3]  [Save]
 [Spend 1] [Refund 1] [New turn]
 [Restore all resources]
 ------------------------------------
 Saved: Health 24 → 19
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
   inline current/maximum editing, quick deltas, readable feedback, unregister.
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

## Hover-only test build

Preserve parchment #C1B6A7, paper #D8CDBB, rust #97372C, ink #382B22 and teal
#405B5A, with Fondamento names and SourceSans controls. Add one square display-mode
button in a general settings row below turn recovery, visible without selecting a
character. The control reads Hover-only plates: On/Off; player toolbar has Hover
plates. Keep the current plate layout and avoid added animation or decoration.

A passive local CoreGui viewport surface supplies pointer coordinates. Normalize
against its rectangle, cast through the current camera and resolve the nearest
registered ancestor by Instance. Do not activate the plugin mouse or alter selection.
At 20 Hz, choose local-copy visibility; reconcile templates every 0.2 seconds and on
registry changes. One local renderer is shared by Ledger and Turn Watch, with failover
when its plugin unloads. Hover writes only local CoreGui UI and local preferences.
Saved Workspace plates are disabled templates; their saved visibility flag preserves
the existing explicit Hide setting. Automatic name changes update cached local names.
