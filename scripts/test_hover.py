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
local movement=object("BasePart","Part",first)
movement.Size={X=0.24,Y=5.56,Z=4.51};movement.Position={X=0,Y=0.12,Z=0}
movement.CFrame={RightVector={Y=1},UpVector={Y=0},LookVector={Y=0}}
currentHit=movement;step()
check(shown()==0, "horizontal miniature base cannot trigger stats")
check(movement.CanQuery and movement.CanCollide and movement.Parent==first, "base exclusion leaves Studio picking and model geometry alone")
currentHit=first.Head;step();check(shown()==1,"body still reveals stats above excluded movement base")
local customBase=object("BasePart","MoveHandle",first);customBase:SetAttribute("CampaignLedgerIgnoreHover",true)
currentHit=customBase;step();check(shown()==0,"explicit ignore attribute supports unusual movement handles")
customBase:Destroy()
local flatToken=object("BasePart","Flat token",workspace);collection:AddTag(flatToken,"CampaignLedgerCharacter");template(flatToken)
currentHit=flatToken;step();check(shown()==1,"a standalone flat token remains an eligible character")
flatToken:Destroy();currentHit=first.Head;step()
local invisible = object("BasePart", "Invisible helper", workspace); invisible.Transparency = 1
currentHits = { invisible, first.Head };step()
check(shown() == 1, "invisible helper in front cannot hide hovered visible character")
currentHits = { invisible };step();check(shown() == 0, "invisible geometry alone cannot reveal a plate")
local wall = object("BasePart", "Wall", workspace);wall.Transparency = 0
currentHits = { wall, first.Head };step();check(shown() == 0, "opaque wall blocks hover of character behind it")
currentHits = nil;currentHit = first.Head
currentPointer.X, currentPointer.Y = 260, 130;step()
check(lastRayPoint.X == 260 and lastRayPoint.Y == 130, "ray reads current pointer even without another GUI mouse event")
check(copies()[1].CampaignLedgerOwner.Value == first, "local copy points to exact owner")
check(copies()[1].Active == false and sensor().Active == false, "stat copy and pointer surface do not sink model selection")
currentHit=second.Head;heartbeat:Fire(0.02)
local fastOwner;for _,copy in ipairs(copies()) do if copy.Enabled then fastOwner=copy.CampaignLedgerOwner.Value end end
check(fastOwner==second, "hover updates within 20ms rather than waiting 50ms")
currentHit=first.Head;step()
check(not copies()[1]:HasTag("CampaignLedgerGeneratedPlate"), "local copy not indexed as shared template")
check(a.Enabled == false and b.Enabled == false, "hover never enables shared templates")
local duplicate = template(first)
a:SetAttribute("CampaignLedgerPlateId", "a");duplicate:SetAttribute("CampaignLedgerPlateId", "z");step()
check(shown() == 1 and #copies() == 2, "concurrent same-owner templates render one local plate")
duplicate:Destroy();step()
local limb = first.Head;collection:AddTag(limb,"CampaignLedgerCharacter")
local nested = template(limb);step()
check(shown() == 1 and #copies() == 2, "nested body-part registration cannot stack another overlay")
nested:Destroy();collection:RemoveTag(limb,"CampaignLedgerCharacter");step()
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
playerHover:setPlatesVisible(false)
check(shown() == 0 and not dmHover:getPlatesVisible(), "master off immediately hides every plate and syncs consumers")
check(dm.settings.CampaignLedgerPlatesVisible == false and player.settings.CampaignLedgerPlatesVisible == false, "master preference persisted by both plugins")
playerHover:setHoverOnly(true);step();check(shown() == 0, "hover cannot bypass master off")
playerHover:setHoverOnly(false);playerHover:setPlatesVisible(true);step()
check(shown() == 2 and not playerHover:getHoverOnly(), "master on restores the saved hover mode")
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
restarted:setPlatesVisible(false);restarted:destroy()
restarted = Hover.start(dm);step()
check(not restarted:getPlatesVisible() and shown() == 0, "master hidden preference survives plugin restart")
restarted:setPlatesVisible(true)
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
