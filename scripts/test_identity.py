"""Run the actual Main removal callbacks and Plate cleanup with a small Studio API fake."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
plate = (root / "src/Plate.luau").read_text()
functions = []
for name in ("list", "get", "owner", "clearAnchors", "clear", "prune"):
    match = re.search(rf"^function Plate\.{name}\(.*?(?=^function |^return Plate)", plate, re.M | re.S)
    assert match, name
    functions.append(match.group())
main = (root / "src/Main.luau").read_text()
main = re.sub(r"^local \w+ = require\(script.Parent.\w+\)\n", "", main, flags=re.M)
fixture = (root / "tests/identity-runtime.fixture.luau").read_text()
checks = r'''
flush()
check(#createdWidgets == 1 and createdWidgets[1].Enabled == false, "ledger does not restore an open menu on startup")
local firstId, secondId = first:GetAttribute(Registry.idAttribute), second:GetAttribute(Registry.idAttribute)
check(firstId ~= secondId, "controller assigns different identities to identical names")
check(#entries == 2, "both same-name rows displayed")
local firstHead = first:FindFirstChild("Head")
local legacyFirst, legacySecond = first:GetAttribute("CampaignLedgerState"), second:GetAttribute("CampaignLedgerState")
check(http:JSONDecode(legacyFirst).hp.maximum == 30 and http:JSONDecode(legacyFirst).mana.maximum == 12 and http:JSONDecode(legacyFirst).ap.maximum == 3, "startup preserves old saved maxima despite new defaults")
selection:Set({firstHead});captured.register();flush()
check(#entries == 2 and first:GetAttribute("CampaignLedgerState") == legacyFirst, "registering an already owned body part leaves stats unchanged")
local primary = Plate.get(first)
local duplicate = object("BillboardGui", Plate.name, first)
duplicate:SetAttribute("CampaignLedgerOwned",true);duplicate:SetAttribute("CampaignLedgerPlateId","zz-last")
local ref = object("ObjectValue","CampaignLedgerOwner",duplicate);ref.Value=first
collection:AddTag(duplicate,Plate.tag);flush()
check(#Plate.list(first)==1 and Plate.get(first)==primary, "incoming same-owner duplicate pruned without replacing canonical plate")
check(first:GetAttribute("CampaignLedgerState")==legacyFirst and second:GetAttribute("CampaignLedgerState")==legacySecond, "duplicate reconciliation preserves exact saved state bytes for both models")
local extraAnchor=object("Attachment","CampaignLedgerAnchor",firstHead);extraAnchor:SetAttribute("CampaignLedgerOwned",true)
Plate.prune(first)
check(extraAnchor.Parent==nil and primary.Adornee.Parent==firstHead, "duplicate cleanup preserves winner anchor and removes orphan helper")
local alias=firstHead
alias:SetAttribute("CampaignLedgerState",http:JSONEncode(State.default("Legacy limb")))
alias:SetAttribute(Registry.idAttribute,"legacy-limb-id")
local aliasState=alias:GetAttribute("CampaignLedgerState")
collection:AddTag(alias,Registry.tag);flush()
check(#entries==2 and alias:GetAttribute("CampaignLedgerState")==aliasState and alias:GetAttribute(Registry.idAttribute)=="legacy-limb-id", "nested legacy registration hidden without deleting its data or identity")
collection:RemoveTag(alias,Registry.tag);alias:SetAttribute("CampaignLedgerState",nil);alias:SetAttribute(Registry.idAttribute,nil);flush()
local fresh=object("Model","New rig",workspace);local freshHead=object("BasePart","Head",fresh);object("Humanoid","Humanoid",fresh)
selection:Set({freshHead});captured.register();flush()
local freshState=fresh:GetAttribute("CampaignLedgerState")
check(freshState and freshHead:GetAttribute("CampaignLedgerState")==nil and #entries==3, "first registration through a limb targets its full rig")
local initial=http:JSONDecode(freshState)
check(initial.hp.current==100 and initial.mana.current==125 and initial.ap.current==6, "new rig begins full at requested defaults")
selection:Set({fresh});captured.register();flush()
check(fresh:GetAttribute("CampaignLedgerState")==freshState and #entries==3, "repeat registration is idempotent and never resets values")
captured.choose(fresh);captured.adjust("mana",-40);flush();captured.setMaximum("hp","150");flush()
local raised=http:JSONDecode(fresh:GetAttribute("CampaignLedgerState"))
check(raised.hp.current==150 and raised.hp.maximum==150 and raised.mana.current==85 and raised.ap.current==6, "explicit maximum save fills only that resource")
captured.remove();flush()
local racing=object("Model","Other editor rig",workspace);object("BasePart","Head",racing);object("Humanoid","Humanoid",racing)
local incoming=State.default("Other editor rig");incoming.hp.current=8
local incomingRaw=http:JSONEncode(incoming)
local begin=history.TryBeginRecording
function history:TryBeginRecording(...)
 history.TryBeginRecording=begin
 racing:SetAttribute("CampaignLedgerState",incomingRaw);racing:SetAttribute(Registry.idAttribute,http:GenerateGUID(false));collection:AddTag(racing,Registry.tag)
 return begin(self,...)
end
selection:Set({racing});captured.register();flush()
check(racing:GetAttribute("CampaignLedgerState")==incomingRaw, "registration arriving at transaction boundary cannot be overwritten by defaults")
captured.choose(racing);captured.remove();flush()
local firstState = first:GetAttribute("CampaignLedgerState")
local secondPlate = Plate.get(second)
secondPlate.Parent = workspace
local extra = object("BillboardGui", Plate.name, workspace)
extra:SetAttribute("CampaignLedgerOwned", true)
local owner = object("ObjectValue", "CampaignLedgerOwner", extra); owner.Value = second
collection:AddTag(extra, Plate.tag)
captured.choose(second); flush(); captured.remove(); flush()
check(#entries == 1 and entries[1].character == first, "remove callback retains exact same-name survivor")
check(first:HasTag(Registry.tag) and first:GetAttribute("CampaignLedgerState") == firstState, "survivor registration and stats unchanged")
check(first:GetAttribute(Registry.idAttribute) == firstId and Plate.get(first) ~= nil, "survivor ID and plate unchanged")
check(not second:HasTag(Registry.tag) and second:GetAttribute("CampaignLedgerState") == nil, "only target unregistered")
check(second.Parent == workspace, "remove preserves character model")
check(secondPlate.Parent == nil and extra.Parent == nil, "all moved and duplicate plates removed")
check(second:FindFirstChild("Head"):FindFirstChild("CampaignLedgerAnchor") == nil, "target anchor removed")
local clone = character("Same Name")
clone:SetAttribute(Registry.idAttribute, firstId); flush()
check(clone:GetAttribute(Registry.idAttribute) ~= firstId, "copied ID repaired by controller")
check(first:GetAttribute(Registry.idAttribute) == firstId and #entries == 2, "original stays stable when clone arrives")
captured.choose(first); flush(); captured.remove(); flush()
check(#entries == 1 and entries[1].character == clone, "removing original leaves clone registered")
captured.choose(clone); flush(); captured.remove(); flush()
check(#entries == 0, "final removal leaves no stale rows")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled", false); flush()
check(not createdWidgets[1].Enabled, "disabling world hides cached ledger widget")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled", true); flush()
check(#createdWidgets == 1 and not createdWidgets[1].Enabled, "re-enabling reuses native handle with a closed fresh ledger")
game.PlaceId = 999; game:GetPropertyChangedSignal("PlaceId"):Fire(); flush()
check(not createdWidgets[1].Enabled, "copying the world to another place stops the ledger")
plugin.Unloading:Fire(); flush()
print("PASS: " .. count .. " controller removal and generated-plate cleanup checks")
'''
scope = (root / "src/WorldScope.luau").read_text()
session = (root / "src/LedgerSession.luau").read_text()
session = re.sub(r"^local \w+ = require\(script.Parent.\w+\)\n", "", session, flags=re.M)
source = fixture + "\nlocal WorldScope = (function()\n" + scope + "\nend)()\n" + "\nlocal LedgerSession = (function()\n" + session + "\nend)()\n" + "\nlocal CollectionService = collection\n" + "\n".join(functions) + "\ndo\n" + main + "\nend\n" + checks
# Relative requires resolve beside the fixture. Always remove generated source, even on failure.
with tempfile.NamedTemporaryFile(mode="w", suffix=".luau", prefix=".identity-runtime-", dir=root / "tests", delete=False) as file:
    file.write(source)
    path = Path(file.name)
try:
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
finally:
    path.unlink(missing_ok=True)
