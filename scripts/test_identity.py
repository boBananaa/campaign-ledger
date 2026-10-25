"""Run the actual Main removal callbacks and Plate cleanup with a small Studio API fake."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
plate = (root / "src/Plate.luau").read_text()
functions = []
for name in ("get", "owner", "clear"):
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
