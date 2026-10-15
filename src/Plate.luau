local Theme = require(script.Parent.Theme)
local Placement = require(script.Parent.Placement)
local Names = require(script.Parent.Names)
local State = require(script.Parent.State)
local Registry = require(script.Parent.Registry)
local CollectionService = game:GetService("CollectionService")
local Plate = {}
Plate.name = "CampaignLedgerPlate"
Plate.tag = "CampaignLedgerGeneratedPlate"
Plate.styleVersion = 9
local C = Theme.colors

-- Convert the design's reference pixels to relative layout once. Roblox handles
-- camera-distance scaling natively, without per-frame place writes in Team Create.
local function scaleLayout(parent, width, height)
	for _, object in ipairs(parent:GetChildren()) do
		if object:IsA("GuiObject") then
			local size, position = object.Size, object.Position
			local childWidth = size.X.Scale * width + size.X.Offset
			local childHeight = size.Y.Scale * height + size.Y.Offset
			object.Size = UDim2.fromScale(childWidth / width, childHeight / height)
			object.Position = UDim2.fromScale(position.X.Scale + position.X.Offset / width,
				position.Y.Scale + position.Y.Offset / height)
			if object:IsA("TextLabel") then
				object.TextScaled = true
				Theme.create("UITextSizeConstraint", { MinTextSize = 1, MaxTextSize = object.TextSize }, object)
			end
			scaleLayout(object, math.max(childWidth, 1), math.max(childHeight, 1))
		end
	end
end

function Plate.head(character)
	if not character:IsA("Model") then return nil end
	local head = character:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then return head end
	local candidate, volume = nil, -1
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 and string.lower(part.Name):match("head$") then
			local size = part.Size
			local value = size.X * size.Y * size.Z
			if value > volume then candidate, volume = part, value end
		end
	end
	return candidate
end

function Plate.anchor(character)
	if character:IsA("BasePart") then return character end
	if not character:IsA("Model") then return nil end
	local head = Plate.head(character)
	if head then return head end
	if character.PrimaryPart then return character.PrimaryPart end
	local largest, volume = nil, -1
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local size = part.Size
			local candidate = size.X * size.Y * size.Z
			if part.Transparency < 1 and candidate > volume then largest, volume = part, candidate end
		end
	end
	return largest or character:FindFirstChildWhichIsA("BasePart", true)
end

function Plate.bounds(character)
	local parts = character:IsA("BasePart") and { character } or character:GetDescendants()
	-- Human rigs use their head rather than a raised weapon or tall accessory.
	local head = Plate.head(character)
	if head then parts = { head } end
	local visible, all = {}, {}
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			local snapshot = { sx = part.Size.X, sy = part.Size.Y, sz = part.Size.Z, transform = { part.CFrame:GetComponents() } }
			table.insert(all, snapshot)
			if part.Transparency < 1 then table.insert(visible, snapshot) end
		end
	end
	return Placement.bounds(#visible > 0 and visible or all)
end

local function existingNameTop(character, bounds)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
	local nativeName = humanoid and humanoid.DisplayDistanceType.Name ~= "None" and humanoid.NameDisplayDistance > 0
	local highest = bounds.top + (nativeName and 1.4 or 0.2)
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BillboardGui") and object.Enabled and not Names.isOwned(object, character) then
			local target = object.Adornee or object.Parent
			local position = target:IsA("Attachment") and target.WorldPosition or target:IsA("BasePart") and target.Position
			if position then
				local halfHeight = object.Size.Y.Scale / 2
				-- Pixel-based existing name labels need a little additional clearance.
				local pixelAllowance = object.Size.Y.Offset > 0 and 1 or 0
				local top = position.Y + object.StudsOffsetWorldSpace.Y + object.StudsOffset.Y
					+ math.abs(object.ExtentsOffsetWorldSpace.Y) * bounds.height / 2 + halfHeight + pixelAllowance
				highest = math.max(highest, top)
			end
		end
	end
	return highest
end

function Plate.get(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BillboardGui") and child.Name == Plate.name
			and child:GetAttribute("CampaignLedgerOwned") == true then return child end
	end
	return nil
end

function Plate.owner(gui)
	return Registry.plateOwner(gui, workspace)
end

function Plate.recoverState(gui)
	local label = gui:FindFirstChild("CharacterName", true)
	local name = label and Names.clean(label.Text)
	if not name then return nil end
	local state = State.default(name)
	state.showPlate = gui:GetAttribute("CampaignLedgerPlateVisible")
	if state.showPlate == nil then state.showPlate = gui.Enabled end
	for _, key in ipairs(State.resources) do
		local value = gui:FindFirstChild(key .. "Value", true)
		local current, maximum
		if value then current, maximum = value.Text:match("^(%d+)%s*/%s*(%d+)$") end
		if not current or not maximum then return nil end
		state[key] = { current = tonumber(current), maximum = tonumber(maximum) }
	end
	return State.validate(state) and state or nil
end

function Plate.clear(character)
	local candidates = CollectionService:GetTagged(Plate.tag)
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BillboardGui") then table.insert(candidates, object) end
	end
	local removed = {}
	for _, gui in ipairs(candidates) do
		if not removed[gui] and gui:IsA("BillboardGui") and gui.Name == Plate.name
			and gui:GetAttribute("CampaignLedgerOwned") == true and Plate.owner(gui) == character then
			removed[gui] = true
			gui:Destroy()
		end
	end
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("Attachment") and object.Name == "CampaignLedgerAnchor"
			and object:GetAttribute("CampaignLedgerOwned") == true then
			local cursor = object.Parent
			while cursor and cursor ~= character and not cursor:HasTag(Registry.tag) do cursor = cursor.Parent end
			if cursor == character then object:Destroy() end
		end
	end
end

function Plate.render(character, state)
	local anchor = Plate.anchor(character)
	assert(anchor, "Character needs a Head, PrimaryPart or another BasePart.")
	Plate.clear(character)
	local bounds = assert(Plate.bounds(character), "Character has no geometry.")
	local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
	local standardHead = character:IsA("Model") and character:FindFirstChild("Head", true)
	local human = humanoid and standardHead and standardHead:IsA("BasePart")
	-- An attachment at the geometry's centre follows the model even when its Head
	-- is sideways, off-centre, or absent (for example a dog or a single mesh token).
	local attachment = Theme.create("Attachment", { Name = "CampaignLedgerAnchor",
		Position = anchor.CFrame:PointToObjectSpace(Vector3.new(bounds.x, human and bounds.y or bounds.top, bounds.z)) }, nil)
	attachment:SetAttribute("CampaignLedgerOwned", true)
	attachment.Parent = anchor
	-- Build while unparented; collaborators see a complete persisted plate.
	local gui = Theme.create("BillboardGui", {
		Name = Plate.name, Adornee = attachment, Size = UDim2.fromScale(Placement.width, Placement.height),
		AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 160,
		Enabled = false, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, nil)
	gui:SetAttribute("CampaignLedgerOwned", true)
	gui:SetAttribute("CampaignLedgerLocalTemplate", true)
	gui:SetAttribute("CampaignLedgerPlateVisible", state.showPlate)
	gui:SetAttribute("CampaignLedgerStyleVersion", Plate.styleVersion)
	gui:SetAttribute(Registry.idAttribute, character:GetAttribute(Registry.idAttribute))
	local owner = Theme.create("ObjectValue", { Name = "CampaignLedgerOwner", Value = character }, gui)
	owner:SetAttribute("CampaignLedgerOwned", true)
	CollectionService:AddTag(gui, Plate.tag)
	if human then
		gui.StudsOffsetWorldSpace = Vector3.new(0, Placement.plateCenter(bounds.top, existingNameTop(character, bounds)) - bounds.y + (state.plateOffset or 0), 0)
	else
		-- Camera-relative clearance keeps low animal/token plates above their head
		-- in the image, including when the DM looks steeply down at the table.
		gui.StudsOffsetWorldSpace = Vector3.new(0, math.max(0, existingNameTop(character, bounds) - bounds.top - 0.2), 0)
		gui.StudsOffset = Vector3.new(0, Placement.height / 2 + 0.65 + (state.plateOffset or 0), 0)
	end
	local canvas = Theme.create("Frame", { Name = "Canvas", BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, gui)
	Theme.create("UISizeConstraint", { MinSize = Vector2.zero, MaxSize = Vector2.new(228, 116) }, canvas)
	local body = Theme.create("Frame", { Name = "Plate", BackgroundColor3 = C.surface,
		BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.new(1, -2, 1, -6),
		Position = UDim2.fromOffset(1, 1) }, canvas)
	Theme.stroke(body, C.line)
	local nameBand = Theme.create("Frame", { Name = "NameBand", BackgroundColor3 = C.text, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32) }, body)
	Theme.corners(nameBand, C.accent, 7)
	Theme.label(nameBand, state.name, 20, { Name = "CharacterName", Font = Theme.display,
		Position = UDim2.fromOffset(8, 2), Size = UDim2.new(1, -16, 0, 27),
		TextColor3 = C.field, TextXAlignment = Enum.TextXAlignment.Center })
	for index, key in ipairs({ "hp", "mana" }) do
		local resource = state[key]
		local y = 36 + (index - 1) * 25
		Theme.label(body, key == "hp" and "Health" or "Mana", 13, {
			Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(47, 18), TextColor3 = C[key] })
		Theme.label(body, resource.current .. " / " .. resource.maximum, 14, {
			Name = key .. "Value", Font = Theme.bold, Position = UDim2.new(1, -82, 0, y),
			Size = UDim2.fromOffset(70, 18), TextXAlignment = Enum.TextXAlignment.Right })
		local track = Theme.create("Frame", { Name = key .. "Track", BackgroundColor3 = C.track,
			BorderSizePixel = 0, Position = UDim2.fromOffset(61, y + 5), Size = UDim2.fromOffset(79, 7) }, body)
		local fraction = resource.maximum == 0 and 0 or resource.current / resource.maximum
		local fill = Theme.create("Frame", { Name = "Fill", BackgroundColor3 = C[key], BorderSizePixel = 0,
			Size = UDim2.fromScale(fraction, 1) }, track)
	end
	Theme.label(body, "Actions", 13, { Position = UDim2.fromOffset(12, 87),
		Size = UDim2.fromOffset(47, 18), TextColor3 = C.ap })
	local ap = state.ap
	if ap.maximum <= 10 then
		for index = 1, ap.maximum do
			local pip = Theme.create("Frame", { Name = "Action" .. index,
				BackgroundColor3 = index <= ap.current and C.ap or C.track, BorderSizePixel = 0,
				Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(63 + (index - 1) * 8, 94),
				Rotation = 45 }, body)
		end
	else
		Theme.label(body, "Available", 12, { Position = UDim2.fromOffset(61, 87),
			Size = UDim2.fromOffset(79, 18), TextColor3 = C.muted })
	end
	Theme.label(body, ap.current .. " / " .. ap.maximum, 14, { Name = "apValue", Font = Theme.bold,
		Position = UDim2.new(1, -82, 0, 87), Size = UDim2.fromOffset(70, 18),
		TextXAlignment = Enum.TextXAlignment.Right })
	scaleLayout(canvas, 228, 116)
	gui.Parent = character
	return gui
end

return Plate
