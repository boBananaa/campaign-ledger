-- Prefer an existing overhead name; never read our own generated plate.
local Names = {}

function Names.clean(text, richText)
	if type(text) ~= "string" then return nil end
	if richText then
		text = text:gsub("<[^>]*>", "")
		text = text:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&")
	end
	text = text:gsub("[%c]", " "):match("^%s*(.-)%s*$")
	local length = utf8.len(text)
	if not length or length == 0 then return nil end
	if length > 48 then text = text:sub(1, utf8.offset(text, 49) - 1) end
	return text
end

function Names.isOwned(object, character)
	local cursor = object
	while cursor and cursor ~= character do
		if cursor:GetAttribute("CampaignLedgerOwned") == true then return true end
		cursor = cursor.Parent
	end
	return false
end

local function billboardFor(object, character)
	local cursor, billboard = object, nil
	while cursor and cursor ~= character do
		if cursor:IsA("GuiObject") and not cursor.Visible then return nil end
		if cursor:IsA("BillboardGui") then
			if not cursor.Enabled then return nil end
			billboard = cursor
		end
		cursor = cursor.Parent
	end
	if not billboard or Names.isOwned(object, character) then return nil end
	local adornee = billboard.Adornee
	if adornee and adornee ~= character and not adornee:IsDescendantOf(character) then return nil end
	return billboard
end

local function candidate(object, character)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) or object.TextTransparency >= 1 then return nil end
	local gui = billboardFor(object, character)
	if not gui then return nil end
	local text = Names.clean(object.Text, object.RichText)
	if not text or not text:find("[^%d%p%s]") or text:find("%d%s*/%s*%d") then return nil end
	local id = string.lower(object.Name)
	local content = string.lower(text)
	for _, resource in ipairs({ "health", "mana", "actions", "hp", "mp", "ap", "level", "status" }) do
		if id == resource or id == resource .. "value" or content == resource
			or content:match("^" .. resource .. "%s*:") then return nil end
	end
	local score = math.min(object.TextSize, 40)
	if id:find("name", 1, true) then score += 100 end
	if string.lower(gui.Name):find("name", 1, true) then score += 50 end
	return text, score
end

function Names.resolve(character)
	local best, bestScore, bestPath
	for _, object in ipairs(character:GetDescendants()) do
		local text, score = candidate(object, character)
		if text then
			local path = object:GetFullName()
			if not bestScore or score > bestScore or (score == bestScore and path < bestPath) then
				best, bestScore, bestPath = text, score, path
			end
		end
	end
	if bestScore and bestScore >= 50 then return best end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid and humanoid.DisplayDistanceType.Name ~= "None" and humanoid.NameDisplayDistance > 0 then
		return Names.clean(humanoid.DisplayName) or Names.clean(humanoid.Parent.Name) or "Character"
	end
	if best then return best end
	return Names.clean(character.Name) or "Character"
end

function Names.apply(character, state)
	if state.autoName == false then return state end
	-- Return a new view; reading the roster must never overwrite combat state.
	local result = table.clone(state)
	result.name = Names.clean(character:GetAttribute("CampaignLedgerPoseName")) or Names.resolve(character)
	return result
end

function Names.observe(character, callback)
	local listeners, watched = {}, {}
	local function watch(object)
		if Names.isOwned(object, character) or watched[object] then return end
		local properties
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			properties = { "Text", "RichText", "Visible", "TextTransparency", "TextSize", "Name" }
		elseif object:IsA("BillboardGui") then
			properties = { "Enabled", "Adornee", "Name" }
		elseif object:IsA("Humanoid") then
			properties = { "DisplayName", "NameDisplayDistance", "DisplayDistanceType" }
		elseif object:IsA("GuiObject") then
			properties = { "Visible" }
		end
		if not properties then return end
		local group = {}
		for _, property in ipairs(properties) do
			table.insert(group, object:GetPropertyChangedSignal(property):Connect(callback))
		end
		watched[object] = group
	end
	for _, object in ipairs(character:GetDescendants()) do watch(object) end
	table.insert(listeners, character.DescendantAdded:Connect(function(object)
		if Names.isOwned(object, character) then return end
		watch(object)
		callback()
	end))
	table.insert(listeners, character.DescendantRemoving:Connect(function(object)
		if Names.isOwned(object, character) then return end
		if watched[object] then
			for _, listener in ipairs(watched[object]) do listener:Disconnect() end
			watched[object] = nil
		end
		callback()
	end))
	return { Disconnect = function()
		for _, listener in ipairs(listeners) do listener:Disconnect() end
		for _, group in pairs(watched) do for _, listener in ipairs(group) do listener:Disconnect() end end
	end }
end

return Names
