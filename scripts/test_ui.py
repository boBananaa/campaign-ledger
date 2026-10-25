"""Run real UI constructors/callbacks against deterministic engine fakes, optionally export preview trees."""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('luau', nargs='?', default='luau')
parser.add_argument('--snapshots', type=Path)
args = parser.parse_args()
source = (root / 'tests/ui-runtime.fixture.luau').read_text()
for module in ['Theme', 'State', 'Layout', 'Turn', 'Dice', 'Panel', 'DicePanel', 'LauncherPanel']:
    text = (root / 'src' / f'{module}.luau').read_text()
    import re
    text = re.sub(r'require\(script\.Parent\.(\w+)\)', r'\1', text)
    source += f'\nlocal {module} = (function()\n{text}\nend)()\n'
source += r'''
local host = widget(330, 640)
local panel = Panel.new(host, actions)
check(panel.viewport.ClassName == "Frame", "no scrolling outer container")
check(panel.turnRow.Parent == panel.root, "turn controls independent of character scroll")
click(host, "Turn_party"); check(last()[1] == "setTurn" and last()[2] == "party", "start turn without selecting character")
click(host, "RecoveryToggle")
check(panel.recovery.Visible and panel.editor.Position.Y.Offset > 272, "recovery expansion reserves space")
click(host, "RecoverSelected"); check(last()[1] == "setTurn", "selected recovery disabled without character")
click(host, "RecoverAll"); check(last()[1] == "recover" and last()[4] == true, "all recovery available without selection")
click(host, "RecoveryToggle")
local a, b = { Name = "Lisa" }, { Name = "Lisa" }
local state = State.default("Lisa Leaphart Schroder")
state.hp.current = 24; state.hp.maximum = 40; state.mana.current = 7; state.mana.maximum = 12; state.ap.current = 2
local entries = { { character = a, state = state, id = "one" }, { character = b, state = State.default("Lisa"), id = "two" } }
panel:refresh(entries, a, state); panel:updateTurn("party"); panel:updateHoverOnly(true)
check(panel.heading.Visible and not panel.advanced.Visible, "details collapsed by default")
click(host, "Character_two"); check(last()[2] == b, "roster targets actual instance with same name")
click(host, "hpPreset1"); check(last()[1] == "adjust" and last()[2] == "hp" and last()[3] == -5, "quick damage dispatch")
panel.fields.hp.amount.Text = "12"
click(host, "hpSubtract"); check(last()[1] == "adjustAmount" and last()[3] == "12" and last()[4] == -1, "custom damage uses typed amount")
click(host, "manaAdd"); check(last()[2] == "mana" and last()[4] == 1, "custom gain direction")
click(host, "apPreset3"); check(last()[1] == "newTurn", "refill AP dispatch")
panel.fields.hp.maximum.focused = true; panel.fields.hp.maximum.Text = "9999"
panel:refresh(entries, a, state)
check(panel.fields.hp.amount.Text == "12" and panel.fields.hp.maximum.Text == "9999", "passive refresh preserves active inputs")
click(host, "CharacterDetails"); check(panel.advanced.Visible, "details disclosure opens")
panel.fields.hp.maximum.FocusLost:Fire(true)
check(last()[1] == "setMaximum" and last()[3] == "9999", "Enter commits maximum")
click(host, "CharacterDetails")
local contentHeight = Layout.editorPadding + Layout.headingHeight + 3 * Layout.resourceHeight + 4 * 6 + 28 + 8
check(contentHeight <= panel.editor.Size.Y.Offset, "core controls and disclosure fit 330x640 default split")
local drag = panel.divider:FindFirstChildOfClass("UIDragDetector")
drag.DragStart:Fire(Vector2.new(0, 256)); drag.DragContinue:Fire(Vector2.new(0, 9999)); drag.DragEnd:Fire(Vector2.new(0, 9999))
check(panel.editor.Size.Y.Offset >= 304 and last()[1] == "saveDivider", "divider clamp preserves combat space and saves")
panel:notify("Health: 29 → 24"); snapshot(host, "ledger-330")
host.TestSize = Vector2.new(500, 820); panel.viewport:GetPropertyChangedSignal("AbsoluteSize"):Fire()
drag.DragStart:Fire(Vector2.new(0, 256)); drag.DragContinue:Fire(Vector2.new(0, 316)); drag.DragEnd:Fire(Vector2.new(0, 316))
check(panel.split == 316, "divider movable in taller window")
snapshot(host, "ledger-wide")
click(host, "RecoveryToggle"); snapshot(host, "ledger-recovery")
click(host, "RecoveryToggle"); click(host, "CharacterDetails"); snapshot(host, "ledger-details")
click(host, "CharacterDetails"); panel:refresh(entries, b, entries[2].state)
check(panel.fields.hp.amount.Text == "1", "switching character clears previous adjustment amount")
panel.search.Text = "no results"; check(#panel.rows == 1 and panel.rows[1].Text == "No matching characters.", "search empty result")
panel.search.Text = ""; panel:refresh({}, nil, nil); snapshot(host, "ledger-empty")
check(not panel.heading.Visible and not panel.advanced.Visible and panel.turnRow.Visible, "deselection retains global combat controls")
local edge = State.default(string.rep("Very long character name ", 4))
edge.hp.current, edge.hp.maximum = 9999, 9999; edge.mana.current, edge.mana.maximum = 0, 0; edge.ap.current, edge.ap.maximum = 0, 0
panel:refresh({ { character = a, state = edge, id = "one" } }, a, edge)
check(panel.fields.mana.fill.Size.X.Scale == 0 and panel.fields.hp.current.Text == "9999", "zero maxima and four-digit display")
host.TestSize = Vector2.new(330, 480); panel.viewport:GetPropertyChangedSignal("AbsoluteSize"):Fire(); snapshot(host, "ledger-minimum")
click(host, "RecoveryToggle"); check(panel.editor.Size.Y.Offset > 0, "minimum height recovery leaves positive editor viewport")
panel:destroy(); check(#host:GetChildren() == 0, "panel unload removes whole owned surface")
for _, c in ipairs(panel.connections) do check(not c.active, "external panel listeners disconnected") end
local diceHost = widget(330, 475)
local rolls = { 14, 3, 20 }; local index = 0
local diceRoot = DicePanel.new(diceHost, { NextInteger = function() index += 1; return rolls[index] end })
click(diceHost, "RollD20"); check(diceHost:FindFirstChild("Total", true).Text == "14", "dice result callback")
diceHost:FindFirstChild("Modifier", true).Text = "+2"; click(diceHost, "RollD20")
check(diceHost:FindFirstChild("Total", true).Text == "5" and index == 2, "positive modifier applies to one D20")
diceHost:FindFirstChild("Modifier", true).Text = "oops"; click(diceHost, "RollD20")
check(index == 2 and diceHost:FindFirstChild("Breakdown", true).Text ~= "", "invalid modifier does not consume roll")
snapshot(diceHost, "dice-error")
diceHost:FindFirstChild("Modifier", true).Text = "-2"
diceHost:FindFirstChild("Modifier", true).FocusLost:Fire(true)
check(diceHost:FindFirstChild("NaturalRoll", true).Text == "Natural 20" and diceHost:FindFirstChild("Total", true).Text == "18" and index == 3, "Enter rolls one D20 with negative modifier and preserves natural 20")
local resultWell = diceHost:FindFirstChild("RollResult", true)
for _, name in ipairs({ "Total", "Breakdown", "NaturalRoll" }) do
 local child = diceHost:FindFirstChild(name, true)
 check(child.Position.Y.Offset + child.Size.Y.Offset <= resultWell.Size.Y.Offset, "result content stays inside framed well")
end
local diceSheet = diceHost:FindFirstChild("D20Roller", true)
local history = diceHost:FindFirstChild("RollHistory", true)
check(history.Position.Y.Offset + history.Size.Y.Offset <= diceSheet.Size.Y.Offset, "roll history stays inside scroll canvas")
snapshot(diceHost, "dice")
local launchHost = widget(320, 460)
local launchActions = {}
for _, name in ipairs({ "toggleDM", "toggleTurn", "toggleHover", "togglePlates", "toggleWorld", "openLedger", "openDice" }) do
 launchActions[name] = function() table.insert(calls, { name }) end
end
local launcher = LauncherPanel.new(launchHost, launchActions)
launcher:refresh({ dmEnabled = false, worldEnabled = true, viewerReady = true, turnVisible = true, hoverOnly = true, platesVisible = true })
local beforeClick = #calls
click(launchHost, "LauncherLedger")
check(#calls == beforeClick and not launcher.ledger.Interactable, "player launcher cannot open Ledger")
click(launchHost, "LauncherTurn");check(last()[1] == "toggleTurn", "launcher turn display control dispatch")
click(launchHost, "LauncherHover");check(last()[1] == "toggleHover", "launcher hover display control dispatch")
click(launchHost, "LauncherPlates");check(last()[1] == "togglePlates", "launcher master plate control dispatch")
snapshot(launchHost, "launcher-player")
launcher:refresh({ dmEnabled = true, worldEnabled = true, viewerReady = true, turnVisible = true, hoverOnly = true, platesVisible = true })
click(launchHost, "LauncherLedger");check(last()[1] == "openLedger", "launcher opens Ledger")
click(launchHost, "LauncherDice");check(last()[1] == "openDice", "launcher opens D20")
check(launcher.footer.Position.Y.Offset + launcher.footer.Size.Y.Offset <= 0, "launcher footer stays inside minimum height")
snapshot(launchHost, "launcher-dm")
launcher:refresh({ dmEnabled = true, worldEnabled = true, viewerReady = true, turnVisible = true, hoverOnly = true, platesVisible = false })
check(launcher.plates.Text == "Stat plates: Off" and not launcher.hover.Interactable and launcher.turn.Interactable, "master hidden state disables hover switch independently of turn text")
snapshot(launchHost, "launcher-hidden")
launcher:refresh({ dmEnabled = true, worldEnabled = false, viewerReady = false, turnVisible = true, hoverOnly = true, platesVisible = true })
beforeClick = #calls;click(launchHost, "LauncherDice");click(launchHost, "LauncherTurn")
check(#calls == beforeClick and launcher.world.Interactable, "inactive world blocks feature actions but permits setup")
click(launchHost, "LauncherWorld");check(last()[1] == "toggleWorld", "launcher world setup dispatch")
snapshot(launchHost, "launcher-inactive")
launcher:destroy();check(#launchHost:GetChildren() == 0, "launcher destroys owned panel")
print("PASS: " .. count .. " UI workflow, layout and lifecycle checks")
'''
with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', dir=root / 'tests', prefix='.ui-runtime-', delete=False) as f:
    f.write(source)
    path = Path(f.name)
try:
    result = subprocess.run([args.luau, str(path)], text=True, capture_output=True)
    if result.returncode:
        print(result.stdout)
        print(result.stderr)
        raise SystemExit(result.returncode)
    for line in result.stdout.splitlines():
        if line.startswith('UI_SNAPSHOT '):
            if args.snapshots:
                data = json.loads(line[len('UI_SNAPSHOT '):]); args.snapshots.mkdir(parents=True, exist_ok=True)
                (args.snapshots / f"{data['name']}.json").write_text(json.dumps(data))
        else:
            print(line)
finally:
    path.unlink(missing_ok=True)
