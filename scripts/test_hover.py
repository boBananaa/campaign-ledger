"""Exercise the production hover controller with deterministic Studio API fakes."""
from pathlib import Path
import subprocess
import sys
import tempfile
root = Path(__file__).resolve().parents[1]
base = (root / 'tests/identity-runtime.fixture.luau').read_text().split('local first, second = character(')[0]
fixture = (root / 'tests/hover-runtime.fixture.luau').read_text()
module = (root / 'src/Hover.luau').read_text().replace('require(script.Parent.HoverRules)', 'require("../src/HoverRules")')
checks = r'''
local first, second = character("Same Name"), character("Same Name")
first:SetAttribute("CampaignLedgerId", "first"); second:SetAttribute("CampaignLedgerId", "second")
local a, b = template(first), template(second)
local firstState, secondState = first:GetAttribute("CampaignLedgerState"), second:GetAttribute("CampaignLedgerState")
local dm, player = client("DM"), client("Turn Watch")
local dmHover, playerHover = Hover.start(dm), Hover.start(player)
step()
check(dmHover:getHoverOnly() and playerHover:getHoverOnly(), "default enabled for both clients")
check(#core:GetChildren() == 1 and #copies() == 0, "both installed plugins share one renderer")
currentHit = first.Head; sensor().MouseMoved:Fire(200, 100); step()
check(shown() == 1, "hover reveals exactly one plate")
check(copies()[1].CampaignLedgerOwner.Value == first, "local copy points to exact owner")
check(not copies()[1]:HasTag("CampaignLedgerGeneratedPlate"), "local copy not indexed as shared template")
check(a.Enabled == false and b.Enabled == false, "hover never enables shared templates")
a.CharacterName.Text = "Updated overhead name"; step()
check(copies()[1].CharacterName.Text == "Updated overhead name", "automatic name updates reach an existing local copy")
currentHit = second.Head; step()
check(shown() == 1, "stationary cursor camera/model movement updates hover")
local enabledOwner
for _, copy in ipairs(copies()) do if copy.Enabled then enabledOwner = copy.CampaignLedgerOwner.Value end end
check(enabledOwner == second, "same-name neighbour resolves independently")
sensor().MouseLeave:Fire(); step()
check(shown() == 0, "viewport exit clears hover")
currentHit = first.Head; sensor().MouseMoved:Fire(100, 100); step(); released:Fire()
check(shown() == 0, "window focus loss immediately hides hover")
focused:Fire(); sensor().MouseMoved:Fire(100, 100); step()
check(shown() == 1, "hover resumes after focus returns and pointer moves")
dmHover:setHoverOnly(false); step()
check(shown() == 2, "opt-out displays every permitted plate")
check(not playerHover:getHoverOnly(), "same-window preference synchronized between plugins")
check(dm.settings.CampaignLedgerHoverOnly == false and player.settings.CampaignLedgerHoverOnly == false, "preference persisted by both plugins")
a:SetAttribute("CampaignLedgerPlateVisible", false); step()
check(shown() == 1, "explicit hidden plate wins over opt-out")
local previousCopy
for _, copy in ipairs(copies()) do if copy.CampaignLedgerOwner.Value == second then previousCopy = copy end end
b:Destroy(); b = template(second); step()
check(previousCopy.Parent == nil and shown() == 1, "replaced stats template discards stale local copy")
second.tags.CampaignLedgerCharacter = nil; step()
check(shown() == 0, "unregistering character removes local plate")
check(first:GetAttribute("CampaignLedgerState") == firstState and second:GetAttribute("CampaignLedgerState") == secondState, "hover and opt-out preserve combat state")
dmHover:destroy(); step()
check(root() ~= nil and root().OwnerPlugin.Value == player, "remaining plugin takes over when renderer owner unloads")
check(not playerHover:getHoverOnly(), "takeover preserves saved preference")
playerHover:destroy()
check(root() == nil, "last plugin unload removes local UI completely")
local restarted = Hover.start(dm); step()
check(not restarted:getHoverOnly(), "preference survives plugin restart")
restarted:setHoverOnly(true); step()
check(shown() == 0, "re-enabled hover starts hidden")
restarted:destroy()
check(a.Enabled == false, "unload leaves shared templates disabled")
local changeA, changeB = 0, 0
local leaseA = Hover.start(dm, function() changeA += 1 end)
local leaseB = Hover.start(dm, function() changeB += 1 end)
local surfaces = 0
for _, child in ipairs(root():GetChildren()) do if child.Name == "HoverSurface" then surfaces += 1 end end
check(surfaces == 1, "combined plugin consumers share one pointer surface")
leaseA:setHoverOnly(false); step()
check(not leaseB:getHoverOnly() and changeA > 1 and changeB > 1, "shared preference notifies both features")
leaseA:destroy(); step()
check(root() ~= nil and not leaseB:getHoverOnly(), "disabling DM lease keeps player viewer alive")
leaseA:destroy(); step()
check(root() ~= nil, "lease release is idempotent")
leaseB:destroy(); step()
check(root() == nil, "last feature lease removes shared renderer")
print("PASS: " .. count .. " hover controller, local UI and lifecycle checks")
'''
source = base + '\n' + fixture + '\nlocal Hover = (function()\n' + module + '\nend)()\n' + checks
with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', prefix='.hover-runtime-', dir=root / 'tests', delete=False) as f:
    f.write(source)
    path = Path(f.name)
try:
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else 'luau', str(path)], check=True)
finally:
    path.unlink(missing_ok=True)
