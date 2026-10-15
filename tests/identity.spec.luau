local Registry = require("../src/Registry")
local count = 0
local function check(value, message) assert(value, message); count += 1 end
local function object(kind, name, parent)
	local item = { kind = kind, Name = name, Parent = parent, attributes = {}, children = {}, tags = {} }
	if parent then table.insert(parent.children, item) end
	function item:IsA(class) return self.kind == class or (self.kind == "Workspace" and class == "Model") end
	function item:GetAttribute(key) return self.attributes[key] end
	function item:HasTag(key) return self.tags[key] == true end
	function item:FindFirstChild(name)
		for _, child in ipairs(self.children) do if child.Name == name then return child end end
	end
	function item:FindFirstChildOfClass(class)
		for _, child in ipairs(self.children) do if child:IsA(class) then return child end end
	end
	function item:GetDescendants()
		local result = {}
		local function visit(node)
			for _, child in ipairs(node.children) do table.insert(result, child); visit(child) end
		end
		visit(self); return result
	end
	return item
end
local nextId = 0
local function guid()
	nextId += 1
	return string.format("00000000-0000-4000-8000-%012d", nextId)
end
local registry = Registry.new(guid)
local first, second = object("Model", "Same Name"), object("Model", "Same Name")
first.attributes.stats, second.attributes.stats = "spent original", "different clone stats"
local updates, ids = registry:plan({ first, second })
check(#updates == 2 and ids[first] ~= ids[second], "identical names receive separate IDs")
check(Registry.validId(ids[first]) and Registry.validId(ids[second]), "IDs are UUID strings")
check(first:GetAttribute(Registry.idAttribute) == nil, "planning never writes instances")
for _, update in ipairs(updates) do update.character.attributes[Registry.idAttribute] = update.id end
local firstId, secondId = ids[first], ids[second]
updates, ids = registry:plan({ second, first })
check(#updates == 0 and ids[first] == firstId and ids[second] == secondId, "order-independent stable identity")
first.Name = "Renamed"
updates, ids = registry:plan({ first, second })
check(#updates == 0 and ids[first] == firstId, "renaming does not alter identity")
local clone = object("Model", "Same Name")
clone.attributes[Registry.idAttribute] = firstId
updates, ids = registry:plan({ clone, second, first })
check(#updates == 1 and updates[1].character == clone, "clone gets a new ID even when enumerated first")
check(ids[first] == firstId and ids[clone] ~= firstId, "original keeps its ID")
for _, update in ipairs(updates) do update.character.attributes[Registry.idAttribute] = update.id end
updates, ids = registry:plan({ second, clone })
check(#updates == 0 and ids[second] == secondId, "removing one preserves same-name survivor")
check(first.attributes.stats == "spent original" and second.attributes.stats == "different clone stats", "identity repair preserves combat data")
local reopened = Registry.new(guid)
updates, ids = reopened:plan({ second, clone })
check(#updates == 0 and ids[second] == secondId, "saved IDs survive reload")
clone.attributes[Registry.idAttribute] = secondId
updates, ids = reopened:plan({ clone, second })
check(#updates == 1 and updates[1].character == clone and ids[second] == secondId, "duplicate ID repaired after reload")
check(not Registry.validId(nil) and not Registry.validId(2) and not Registry.validId("Same Name"), "invalid IDs rejected")
local future = guid()
local fresh = object("Model", "Fresh")
second.attributes[Registry.idAttribute] = future
local calls = 0
local collision = Registry.new(function() calls += 1; return calls == 1 and future or guid() end)
updates, ids = collision:plan({ fresh, second })
check(ids[fresh] ~= future and ids[second] == future and calls == 2, "generated collision cannot steal a later existing ID")

local world = object("Workspace", "Workspace")
local wrapper = object("Model", "Wrapper", world)
local rig = object("Model", "Same Name", wrapper)
object("Humanoid", "Humanoid", rig)
local head = object("BasePart", "Head", rig)
local anchor = object("Attachment", "CampaignLedgerAnchor", head)
check(Registry.character(wrapper) == rig, "outer wrapper resolves to actual rig")
check(Registry.character(rig) == rig, "actual rig unchanged")
check(Registry.character(head) == head, "single part token supported")
check(Registry.character(object("Model", "Dog")) ~= nil, "non-humanoid model supported")
local otherRig = object("Model", "Same Name", wrapper)
object("Humanoid", "Humanoid", otherRig)
check(Registry.character(wrapper) == nil, "multi-character group rejected")
local gui = object("BillboardGui", "CampaignLedgerPlate", rig)
gui.Adornee = anchor
check(Registry.plateOwner(gui, world) == rig, "legacy direct plate resolves exact instance")
gui.Parent = world
check(Registry.plateOwner(gui, world) == rig, "legacy moved plate resolves anchor's rig")
local reference = object("ObjectValue", "CampaignLedgerOwner", gui)
reference.Value = rig
gui.Parent, gui.Adornee = otherRig, nil
check(Registry.plateOwner(gui, world) == rig, "explicit owner survives reparent and cleared adornment")
check(Registry.plateOwner(gui, world) ~= otherRig, "same-name neighbour cannot claim moved plate")
local unrelated = object("BillboardGui", "Unrelated", world)
check(Registry.plateOwner(unrelated, world) == nil, "ownerless GUI does not become Workspace character")
print("PASS: " .. count .. " identity, duplicate-name and plate-ownership checks")
