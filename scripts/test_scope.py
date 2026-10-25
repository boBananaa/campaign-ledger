"""Exercise the production world scope and plugin entry points with engine fakes."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile
root=Path(__file__).resolve().parents[1]
base=(root/'tests/identity-runtime.fixture.luau').read_text().split('local first, second = character(')[0]
scope=(root/'src/WorldScope.luau').read_text()
preamble=base+'\nlocal WorldScope=(function()\n'+scope+'\nend)()\n'
checks=r'''
local shared = services.ReplicatedStorage
local function setScope(enabled, assigned)
 shared:SetAttribute(WorldScope.placeAttribute, assigned)
 shared:SetAttribute(WorldScope.enabledAttribute, enabled)
 flush()
end
for _, invalid in ipairs({ 0, -1, 1.5, math.huge, 0/0, "12345", false }) do
 check(not WorldScope.matches(invalid, true, invalid), "invalid current place ID stays inactive")
end
check(not WorldScope.matches(12345, true, 999), "copied marker does not opt in different place")
check(not WorldScope.matches(12345, "true", 12345), "string true is not opt-in")
check(not WorldScope.matches(12345, false, 12345), "explicit disabled")
check(WorldScope.matches(12345, true, 12345), "matching explicit place opt-in")
setScope(false, nil)
local starts, stops = 0, 0
local destroy = WorldScope.run(plugin, function()
 starts += 1
 return function() stops += 1 end
end)
check(starts == 0, "inactive place creates no session")
-- Registered models already exist in the fixture; character data never opts in a world.
character("Copied character")
check(starts == 0, "copying registered character cannot start plugins")
setScope(true, 12345)
check(starts == 1 and stops == 0, "shared opt-in starts installed plugin without reload")
setScope(true, 12345)
check(starts == 1, "duplicate replicated updates do not duplicate session")
setScope(false, 12345)
check(stops == 1, "shared disable releases session")
setScope(true, 12345)
check(starts == 2, "undo or re-enable restarts session once")
game.PlaceId = 67890; game:GetPropertyChangedSignal("PlaceId"):Fire(); flush()
check(stops == 2, "new publication ID deactivates copied world")
setScope(true, 67890)
check(starts == 3, "explicitly enabling destination reactivates after export")
-- Stop before a queued replicated change: it must not resurrect the session.
shared:SetAttribute(WorldScope.enabledAttribute, false)
destroy(); flush(); destroy()
check(stops == 3 and starts == 3, "unload cancels queued scope changes and is idempotent")
setScope(true, 67890)
check(starts == 3, "destroy removes scope observers")
local oldEnabled, oldPlace = shared:GetAttribute(WorldScope.enabledAttribute), shared:GetAttribute(WorldScope.placeAttribute)
game.PlaceId = 0
local ok = WorldScope.setEnabled(plugin, true)
check(not ok and shared:GetAttribute(WorldScope.placeAttribute) == oldPlace, "unsaved place cannot inherit another world enable")
game.PlaceId = 12345
services.RunService.IsRunning = function() return true end
check(not WorldScope.setEnabled(plugin, true), "world setup rejects Play mode")
services.RunService.IsRunning = function() return false end
local originalBegin = history.TryBeginRecording
history.TryBeginRecording = function() return nil end
check(not WorldScope.setEnabled(plugin, true), "no world changes when undo recording unavailable")
history.TryBeginRecording = originalBegin
check(WorldScope.setEnabled(plugin, true), "explicit enable records saved place ID")
check(WorldScope.isEnabled(), "saved scope is active for this place")
check(WorldScope.setEnabled(plugin, false) and not WorldScope.isEnabled(), "explicit disable preserves world data")
print("PASS: " .. count .. " world isolation and lifecycle checks")
'''
def run(source):
    with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',prefix='.scope-runtime-',dir=root/'tests',delete=False) as f:
        f.write(source);path=Path(f.name)
    try:subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'luau',str(path)],check=True)
    finally:path.unlink(missing_ok=True)
run(preamble+checks)
# Actual D20/TurnWatch entry points must create no UI in unrelated worlds.
# The enabled-session body uses fakes; this verifies bootstrap wiring and teardown,
# not font rendering, CoreGui input or Team Create networking.
for entry in ['D20Main','TurnMain','Main']:
    source=(root/'src'/f'{entry}.luau').read_text()
    source=re.sub(r'local (\w+) = require\(script\.Parent\.\w+\)\n','',source)
    stubs=r'''
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled", false)
Enum.TextXAlignment = { Center = "Center" }
Enum.TextTruncate = { None = "None" }
Turn.isActive = function(side) return side == "party" or side == "enemy" end
local destroyedOverlays = 0
services.CoreGui = object("CoreGui", "CoreGui")
local Theme = { colors = {}, display = "Garamond" }
function Theme.create(class, props)
 local item = object(class, props.Name)
 for key,value in pairs(props) do item[key] = value end
 local destroy = item.Destroy
 function item:Destroy() destroyedOverlays += 1; destroy(self) end
 return item
end
function Theme.label(parent, text, size, props) return Theme.create("TextLabel", props) end
local DicePanel = { new = function() return object("Frame", "DiceContent") end }
local Random = { new = function() return {} end }
local UDim2 = { new = function() return {} end }
local Vector2 = { new = function() return {} end }
local createdToolbars = {}
local originalToolbar = plugin.CreateToolbar
function plugin:CreateToolbar(...)
 local toolbar = originalToolbar(self, ...); toolbar.buttons = {}
 local originalButton = toolbar.CreateButton
 function toolbar:CreateButton(...)
  local b=originalButton(self, ...);table.insert(self.buttons,b);return b
 end
 function toolbar:Destroy() self.destroyed = true end
 table.insert(createdToolbars, toolbar);return toolbar
end
'''
    # Don't construct UI on startup; run the source in an isolated do scope.
    assertions=r'''
flush()
check(#createdWidgets == 0 and #createdToolbars == 0, "unmarked world creates no plugin UI")
local shared = services.ReplicatedStorage
shared:SetAttribute("CampaignLedgerPlaceId", game.PlaceId)
shared:SetAttribute("CampaignLedgerEnabled", true);flush()
check(#createdToolbars == 1, "shared world enable activates installed plugin")
if #createdWidgets > 0 then
 check(createdWidgets[1].Enabled == false, "restored-open D20 remains closed on startup")
 createdToolbars[1].buttons[1].Click:Fire()
 check(createdWidgets[1].Enabled == true, "D20 opens only after explicit toolbar click")
end
shared:SetAttribute("CampaignLedgerEnabled", false);flush()
check(createdToolbars[1].buttons[1].Enabled == false, "disabling world makes retained toolbar inert")
if #createdWidgets > 0 then check(not createdWidgets[1].Enabled, "disabling world hides native D20 handle") end
shared:SetAttribute("CampaignLedgerEnabled", true);flush()
check(#createdToolbars == 1 and createdToolbars[1].buttons[1].Enabled, "re-enable reuses native controls without duplicate IDs")
if #createdWidgets > 0 then check(#createdWidgets == 1 and not createdWidgets[1].Enabled, "re-enable reuses closed widget") end
plugin.Unloading:Fire();flush()
shared:SetAttribute("CampaignLedgerEnabled", true);flush()
check(#createdToolbars == 1, "unloaded plugin cannot reactivate")
print("PASS: " .. count .. " ENTRY world-gated startup checks")
'''.replace('ENTRY',entry)
    if entry == 'Main':
        assertions = r'''
flush()
check(#createdWidgets == 0 and #createdToolbars == 1, "unmarked world has setup button only, no ledger window")
createdToolbars[1].buttons[1].Click:Fire();flush()
check(WorldScope.isEnabled() and #createdWidgets == 1, "explicit D&D world click enables and constructs session")
check(createdWidgets[1].Enabled == false, "enable never pops open ledger menu")
createdToolbars[2].buttons[1].Click:Fire()
check(createdWidgets[1].Enabled == true, "ledger opens only after explicit menu click")
createdToolbars[1].buttons[1].Click:Fire();flush()
check(not WorldScope.isEnabled() and not createdWidgets[1].Enabled and not createdToolbars[2].buttons[1].Enabled, "world toggle shuts down session UI")
createdToolbars[1].buttons[1].Click:Fire();flush()
check(#createdWidgets == 1 and #createdToolbars == 2, "re-enable reuses ledger native handles")
createdToolbars[2].buttons[1].Click:Fire()
check(createdWidgets[1].Enabled, "only one live click callback after restart")
plugin.Unloading:Fire();flush()
check(createdToolbars[1].destroyed and createdToolbars[2].destroyed and createdWidgets[1].destroyed, "all native handles released on unload")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled", true);flush()
check(#createdWidgets == 1, "unloaded ledger cannot reactivate")
print("PASS: " .. count .. " Main world-gated startup checks")
'''
    module = {'Main': 'LedgerSession', 'D20Main': 'DiceSession', 'TurnMain': 'ViewerSession'}[entry]
    session = (root/'src'/f'{module}.luau').read_text()
    session = re.sub(r'^local \w+ = require\(script\.Parent\.\w+\)\n', '', session, flags=re.M)
    run(preamble+stubs+f'\nlocal {module}=(function()\n'+session+'\nend)()\ndo\n'+source+'\nend\n'+assertions)
