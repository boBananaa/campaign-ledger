-- Persistent identity is separate from display names and combat values.
local Registry = {}
Registry.__index = Registry
Registry.idAttribute = "CampaignLedgerId"
Registry.tag = "CampaignLedgerCharacter"

function Registry.validId(value)
	return type(value) == "string" and #value == 36
		and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

function Registry.new(generate)
	return setmetatable({ generate = generate, owners = {} }, Registry)
end

function Registry:plan(characters)
	local present, owners, ids, updates, reserved = {}, {}, {}, {}, {}
	for _, character in ipairs(characters) do
		present[character] = true
		local id = character:GetAttribute(Registry.idAttribute)
		if Registry.validId(id) then reserved[id] = true end
	end
	-- Preserve the known original when a duplicate carrying its ID arrives first.
	for id, character in pairs(self.owners) do
		if present[character] and character:GetAttribute(Registry.idAttribute) == id then owners[id] = character end
	end
	for _, character in ipairs(characters) do
		local id = character:GetAttribute(Registry.idAttribute)
		if not Registry.validId(id) or (owners[id] and owners[id] ~= character) then
			repeat id = self.generate() until Registry.validId(id) and not reserved[id]
			reserved[id] = true
			table.insert(updates, { character = character, id = id })
		end
		owners[id], ids[character] = character, id
	end
	self.owners = owners
	return updates, ids
end

function Registry.character(candidate)
	if not candidate:IsA("Model") then return candidate end
	local humanoid
	for _, object in ipairs(candidate:GetDescendants()) do
		if object:IsA("Humanoid") then
			if humanoid then return nil, "Select one character, not a group containing multiple humanoids." end
			humanoid = object
		end
	end
	-- Register the actual rig, so ungrouping an outer wrapper cannot erase its stats.
	if humanoid and humanoid.Parent:IsA("Model") then return humanoid.Parent end
	return candidate
end

function Registry.plateOwner(gui, root)
	local reference = gui:FindFirstChild("CampaignLedgerOwner")
	if reference and reference:IsA("ObjectValue") and reference.Value and reference.Value ~= root then return reference.Value end
	local parent = gui.Parent
	if parent and parent ~= root and (parent:IsA("Model") or parent:IsA("BasePart")) then return parent end
	local cursor = gui.Adornee
	while cursor and cursor ~= root do
		if cursor:HasTag(Registry.tag) then return cursor end
		if cursor:IsA("Model") and cursor:FindFirstChildOfClass("Humanoid") then return cursor end
		cursor = cursor.Parent
	end
	return nil
end

return Registry
