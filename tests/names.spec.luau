local Names = require("../src/Names")
local State = require("../src/State")
local count = 0
local function check(condition, message) assert(condition, message); count += 1 end

-- Small hierarchy fixture for the resolver, not an emulation of Studio rendering.
local function object(class, name, parent, props)
	local item = { ClassName = class, Name = name, Parent = parent, children = {}, attributes = {}, signals = {} }
	for key, value in pairs(props or {}) do item[key] = value end
	function item:IsA(kind)
		return self.ClassName == kind or (kind == "GuiObject" and (self.ClassName == "TextLabel" or self.ClassName == "TextButton" or self.ClassName == "Frame"))
	end
	function item:GetAttribute(key) return self.attributes[key] end
	function item:IsDescendantOf(ancestor)
		local cursor = self.Parent
		while cursor do if cursor == ancestor then return true end; cursor = cursor.Parent end
		return false
	end
	function item:GetDescendants()
		local result = {}
		local function visit(node)
			for _, child in ipairs(node.children) do table.insert(result, child); visit(child) end
		end
		visit(self); return result
	end
	function item:FindFirstChildWhichIsA(kind)
		for _, child in ipairs(self:GetDescendants()) do if child:IsA(kind) then return child end end
	end
	function item:GetFullName() return (self.Parent and self.Parent:GetFullName() .. "." or "") .. self.Name end
	function item:GetPropertyChangedSignal(key)
		if not self.signals[key] then
			local signal = { listeners = {} }
			function signal:Connect(fn)
				local listener = { fn = fn, active = true }
				function listener:Disconnect() self.active = false end
				table.insert(self.listeners, listener); return listener
			end
			function signal:Fire(value) for _, listener in ipairs(self.listeners) do if listener.active then listener.fn(value) end end end
			self.signals[key] = signal
		end
		return self.signals[key]
	end
	item.DescendantAdded = item:GetPropertyChangedSignal("added")
	item.DescendantRemoving = item:GetPropertyChangedSignal("removing")
	if parent then table.insert(parent.children, item) end
	return item
end

local function label(parent, name, text, props)
	local properties = { Visible = true, Text = text, RichText = false, TextTransparency = 0, TextSize = 20 }
	for key, value in pairs(props or {}) do properties[key] = value end
	return object("TextLabel", name, parent, properties)
end

local character = object("Model", "Token 17")
check(Names.resolve(character) == "Token 17", "model fallback")
local humanoid = object("Humanoid", "Humanoid", character, {
	DisplayName = "Assata Leaphart", NameDisplayDistance = 100, DisplayDistanceType = { Name = "Viewer" },
})
check(Names.resolve(character) == "Assata Leaphart", "Humanoid display name")
humanoid.DisplayName = ""
check(Names.resolve(character) == "Token 17", "empty Humanoid uses parent name")
humanoid.DisplayName = "Assata Leaphart"
local gui = object("BillboardGui", "Nameplate", character, { Enabled = true })
local nameLabel = label(gui, "CharacterName", "<b>Aster Vale</b>", { RichText = true })
label(gui, "HealthValue", "30 / 30", { TextSize = 40 })
check(Names.resolve(character) == "Aster Vale", "existing named billboard overrides Humanoid")
nameLabel.Text = "Rowan Ash"
check(Names.resolve(character) == "Rowan Ash", "updated label reflected")
nameLabel.Visible = false
check(Names.resolve(character) == "Assata Leaphart", "hidden label ignored")
nameLabel.Visible = true; gui.Enabled = false
check(Names.resolve(character) == "Assata Leaphart", "disabled billboard ignored")
gui.Enabled = true
local unrelated = object("Model", "Other character")
gui.Adornee = unrelated
check(Names.resolve(character) == "Assata Leaphart", "unrelated adornment ignored")
gui.Adornee = nil
local owned = object("BillboardGui", "CampaignLedgerPlate", character, { Enabled = true })
owned.attributes.CampaignLedgerOwned = true
local generated = label(owned, "CharacterName", "Stale generated name", { TextSize = 40 })
check(Names.resolve(character) == "Rowan Ash", "generated plate excluded")
gui.Name = "StatusBoard"; nameLabel.Name = "StatusText"; nameLabel.Text = "Poisoned"
check(Names.resolve(character) == "Assata Leaphart", "generic status text does not override visible Humanoid")
humanoid.DisplayDistanceType.Name = "None"
check(Names.resolve(character) == "Poisoned", "plain custom billboard supported without visible Humanoid")
nameLabel.Text = "30 / 40"
check(Names.resolve(character) == "Token 17", "numeric stat labels ignored")
gui.Name = "Nameplate"; nameLabel.Name = "CharacterName"; nameLabel.Text = "Aster Vale"
local state = State.default("Old name")
local automatic = Names.apply(character, state)
check(automatic.name == "Aster Vale" and state.name == "Old name", "automatic view preserves stored state")
local manual = State.rename(state, "My custom name")
check(manual.autoName == false and Names.apply(character, manual).name == "My custom name", "manual override")
check(State.adjust(manual, "hp", -5).autoName == false, "combat edit preserves manual mode")
local legacy = State.copy(state); legacy.autoName = nil
check(State.validate(legacy) and Names.apply(character, legacy).name == "Aster Vale", "old saved state defaults to automatic")
check(Names.clean(" <b>Éowyn &amp; Rowan</b> ", true) == "Éowyn & Rowan", "rich text entities")
check(utf8.len(Names.clean(string.rep("É", 60))) == 48, "truncate by unicode characters")
check(Names.clean("   ") == nil, "empty source rejected")
local calls = 0
local observer = Names.observe(character, function() calls += 1 end)
nameLabel:GetPropertyChangedSignal("Text"):Fire()
check(calls == 1, "external name changes observed")
generated:GetPropertyChangedSignal("Text"):Fire()
check(calls == 1, "own label excluded from observer feedback")
character.DescendantAdded:Fire(generated)
check(calls == 1, "own plate additions excluded")
observer:Disconnect()
nameLabel:GetPropertyChangedSignal("Text"):Fire()
check(calls == 1, "observer cleanup")
local poseState=State.default("Stored name")
character.attributes.CampaignLedgerPoseName="Preserved character"
check(Names.apply(character,poseState).name=="Preserved character","pose name overrides a replacement prefab name without rewriting state")
poseState.autoName=false;poseState.name="Manual character"
check(Names.apply(character,poseState).name=="Manual character","manual names retain priority over pose name override")
print("PASS: " .. count .. " automatic-name checks")
