local WorldScope = require(script.Parent.WorldScope)
local LedgerSession = {}
function LedgerSession.start(plugin, options)
options = options or {}
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local State = require(script.Parent.State)
local Names = require(script.Parent.Names)
local Plate = require(script.Parent.Plate)
local Panel = require(script.Parent.Panel)
local Turn = require(script.Parent.Turn)
local Hover = require(script.Parent.Hover)
local hover
local Registry = require(script.Parent.Registry)
local registry = Registry.new(function() return HttpService:GenerateGUID(false) end)

local TAG = "CampaignLedgerCharacter"
local ATTRIBUTE = "CampaignLedgerState"
local selected, panel
local alive, queued, busy = true, false, false
local automaticSyncFailed = false
local connections, observed, styled = {}, {}, {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function read(character)
	local raw = character:GetAttribute(ATTRIBUTE)
	if type(raw) ~= "string" then return nil, "Character stats are missing." end
	local ok, state = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok then return nil, "Character stats contain invalid JSON. Use Studio Undo to recover." end
	local valid, message = State.validate(state)
	if not valid then return nil, message end
	return Names.apply(character, state)
end

local function isCharacter(character)
	return character and character:IsDescendantOf(Workspace) and CollectionService:HasTag(character, TAG)
end

local refresh, transaction
local function scheduleRefresh()
	if queued or not alive then return end
	queued = true
	task.defer(function()
		queued = false
		if alive and panel then refresh() end
	end)
end

refresh = function()
	local entries, present, plateUpdates, pruneUpdates = {}, {}, {}, {}
	local characters = {}
	for _, character in ipairs(CollectionService:GetTagged(TAG)) do
		if character:IsDescendantOf(Workspace) and not Registry.registeredAncestor(character.Parent, Workspace) then
			table.insert(characters, character)
		end
	end
	local identityUpdates, ids = registry:plan(characters)
	for _, character in ipairs(characters) do
			present[character] = true
			local state = read(character)
			table.insert(entries, { character = character, state = state, id = ids[character] })
			if state and Plate.anchor(character) then
				local plate = Plate.get(character)
				local upgrade = not plate or not styled[character] and plate:GetAttribute("CampaignLedgerStyleVersion") ~= Plate.styleVersion
					or (plate and plate:GetAttribute(Registry.idAttribute) ~= ids[character])
				if #Plate.list(character) > 1 then table.insert(pruneUpdates, character) end
				local label = plate and plate:FindFirstChild("CharacterName", true)
				if upgrade or (label and label.Text ~= state.name) then
					table.insert(plateUpdates, { character = character, upgrade = upgrade })
				end
			end
			if not observed[character] then
				observed[character] = {
					character:GetAttributeChangedSignal(ATTRIBUTE):Connect(scheduleRefresh),
					character:GetAttributeChangedSignal(Registry.idAttribute):Connect(scheduleRefresh),
					character:GetPropertyChangedSignal("Name"):Connect(scheduleRefresh),
					character.AncestryChanged:Connect(scheduleRefresh),
					Names.observe(character, scheduleRefresh),
				}
			end
	end
	for character, listeners in pairs(observed) do
		if not present[character] then
			for _, listener in ipairs(listeners) do listener:Disconnect() end
			observed[character] = nil
		end
	end
	if not present[selected] then selected = nil end
	table.sort(entries, function(a, b)
		local aName = a.state and a.state.name or a.character.Name
		local bName = b.state and b.state.name or b.character.Name
		if string.lower(aName) == string.lower(bName) then return a.id < b.id end
		return string.lower(aName) < string.lower(bName)
	end)
	panel:refresh(entries, selected, selected and read(selected) or nil)
	if (#plateUpdates > 0 or #identityUpdates > 0 or #pruneUpdates > 0) and not busy and not automaticSyncFailed and not RunService:IsRunning() then
		-- Idempotent shared writes: generated plates are excluded from name observers.
		-- Upgrade once per character per load so Undo can restore an older style.
		local synced = transaction("Update ledger plates and names", function()
			for _, update in ipairs(identityUpdates) do update.character:SetAttribute(Registry.idAttribute, update.id) end
			for _, update in ipairs(plateUpdates) do
				local character = update.character
				local state = isCharacter(character) and read(character)
				if state then
					if update.upgrade then
						Plate.render(character, state)
					else
						local plate = Plate.get(character)
						local label = plate and plate:FindFirstChild("CharacterName", true)
						if label and label.Text ~= state.name then label.Text = state.name end
					end
				end
			end
			for _, character in ipairs(pruneUpdates) do Plate.prune(character) end
		end)
		if synced then
			for _, update in ipairs(plateUpdates) do if update.upgrade then styled[update.character] = true end end
		else
			-- Do not retry a failed automatic edit on every deferred refresh.
			automaticSyncFailed = true
		end
	end
end

local function notify(message, isError)
	if alive then panel:notify(message, isError) end
end

-- No yields inside a recording. Attribute and rendered plate undo together.
transaction = function(label, operation)
	if RunService:IsRunning() then notify("Stop Play mode to edit the campaign ledger.", true); return false end
	if busy then notify("An edit is already in progress.", true); return false end
	busy = true
	local beginOK, recording = pcall(function() return ChangeHistoryService:TryBeginRecording("CampaignLedger", label) end)
	if not beginOK or not recording then
		busy = false
		notify("Studio could not begin an undo record. Finish other edits, then try again.", true)
		return false
	end
	plugin:SetAttribute("CampaignLedgerRecording", recording)
	local ok, message = pcall(operation)
	local finishOK, finishMessage = pcall(function()
		ChangeHistoryService:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	end)
	plugin:SetAttribute("CampaignLedgerRecording", nil)
	busy = false
	scheduleRefresh()
	if not ok or not finishOK then
		warn("Campaign Ledger: " .. tostring(message or finishMessage))
		notify("The edit failed. Check Output; use Studio Undo if needed.", true)
		return false
	end
	return true
end

local function change(label, transform, message)
	local target = selected
	if not isCharacter(target) then notify("Choose a registered character first.", true); return end
	local state, readError = read(target)
	if not state then notify(readError, true); return end
	local nextState, errorMessage = transform(state)
	if not nextState then notify(errorMessage, true); return end
	if not Plate.anchor(target) then notify("This character has no BasePart to anchor its plate.", true); return end
	if transaction(label, function()
		target:SetAttribute(ATTRIBUTE, HttpService:JSONEncode(nextState))
		Plate.render(target, nextState)
	end) then
		automaticSyncFailed = false
		notify(type(message) == "function" and message(state, nextState) or message or label)
	end
end

local function taggedAncestor(instance)
	return Registry.registeredAncestor(instance, Workspace)
end

local function register()
	local objects = Selection:Get()
	if #objects ~= 1 then notify("Select exactly one character Model or BasePart in Workspace.", true); return end
	local candidate = objects[1]
	local existing = taggedAncestor(candidate)
	if existing then selected = existing; scheduleRefresh(); notify("This character is already registered."); return end
	if not candidate:IsDescendantOf(Workspace) or not (candidate:IsA("Model") or candidate:IsA("BasePart")) then
		notify("Select a character Model or BasePart in Workspace.", true); return
	end
	local canonical, candidateError = Registry.character(candidate)
	if not canonical then notify(candidateError, true); return end
	candidate = canonical
	existing = taggedAncestor(candidate)
	if existing then selected = existing; scheduleRefresh(); notify("This character is already registered."); return end
	if not Plate.anchor(candidate) then notify("The selected model needs at least one BasePart.", true); return end
	for _, character in ipairs(CollectionService:GetTagged(TAG)) do
		if character:IsDescendantOf(candidate) then
			notify("Select one character; this group already contains registered characters.", true); return
		end
	end
	if candidate:GetAttribute(ATTRIBUTE) ~= nil then
		notify("This model already has ledger data. Restore its CampaignLedgerCharacter tag or clear that attribute first.", true)
		return
	end
	local default = State.default("Character")
	local state = State.rename(default, Names.resolve(candidate)) or default
	state.autoName = true
	if transaction("Register " .. state.name, function()
		-- Re-read at the write boundary. Another editor/plugin may have registered
		-- this exact instance after selection; never replace an existing state.
		if candidate:GetAttribute(ATTRIBUTE) ~= nil or taggedAncestor(candidate) then return end
		candidate:SetAttribute(Registry.idAttribute, HttpService:GenerateGUID(false))
		candidate:SetAttribute(ATTRIBUTE, HttpService:JSONEncode(state))
		CollectionService:AddTag(candidate, TAG)
		Plate.render(candidate, state)
	end) then
		selected = candidate
		notify("Registered " .. state.name .. ". Set maximums for your combat system.")
	end
end

-- Recover legacy plates whose wrapper was ungrouped, and index moved plates for
-- exact-owner cleanup. Never infer character identity from its display name.
local function recoverLegacyPlates()
	local plates = {}
	for _, object in ipairs(Workspace:GetDescendants()) do
		if object:IsA("BillboardGui") and object.Name == Plate.name
			and object:GetAttribute("CampaignLedgerOwned") == true then table.insert(plates, object) end
	end
	if #plates == 0 then return end
	transaction("Recover ledger plate ownership", function()
		for _, gui in ipairs(plates) do
			if not gui:IsDescendantOf(Workspace) then continue end
			CollectionService:AddTag(gui, Plate.tag)
			local owner = Plate.owner(gui)
			if owner and owner:IsDescendantOf(Workspace) and not isCharacter(owner) then
				local state = read(owner)
				if not state and owner:GetAttribute(ATTRIBUTE) == nil then state = Plate.recoverState(gui) end
				if state then
					if not owner:GetAttribute(ATTRIBUTE) then owner:SetAttribute(ATTRIBUTE, HttpService:JSONEncode(state)) end
					CollectionService:AddTag(owner, TAG)
					if not Registry.validId(owner:GetAttribute(Registry.idAttribute)) then
						owner:SetAttribute(Registry.idAttribute, HttpService:GenerateGUID(false))
					end
					Plate.render(owner, state)
				end
			end
		end
	end)
end

local actions = { register = register }
actions.choose = function(character)
	if isCharacter(character) then selected = character; scheduleRefresh() end
end
actions.selectModel = function()
	if isCharacter(selected) then Selection:Set({ selected }) end
end
actions.setMaximum = function(key, maximum)
	change("Set " .. State.labels[key] .. " maximum", function(state) return State.setMaximum(state, key, maximum) end,
		function(_, state) return "Saved " .. State.labels[key] .. ": " .. state[key].current .. " / " .. state[key].maximum end)
end
actions.adjustAmount = function(key, amount, direction)
	change("Adjust " .. State.labels[key], function(state) return State.adjustAmount(state, key, amount, direction) end,
		function(old, new) return State.labels[key] .. ": " .. old[key].current .. " → " .. new[key].current .. " · " .. new.name end)
end
actions.loadDivider = function()
	local ok, value = pcall(function() return plugin:GetSetting("CampaignLedgerDivider") end)
	if ok and type(value) == "number" and value == value and math.abs(value) < math.huge then return value end
end
actions.saveDivider = function(value)
	pcall(function() plugin:SetSetting("CampaignLedgerDivider", value) end)
end
actions.getHoverOnly = function() return hover:getHoverOnly() end
actions.toggleHoverOnly = function()
 hover:setHoverOnly(not hover:getHoverOnly())
end
actions.setTurn = function(side)
	if side ~= "party" and side ~= "enemy" and side ~= "idle" then return end
	if transaction("Change combat turn", function() ReplicatedStorage:SetAttribute(Turn.attribute, side) end) then
		local title = Turn.view(side)
		notify(title .. ". Player displays updated.")
	end
end
actions.loadRecovery = function()
	local ok, settings = pcall(function() return plugin:GetSetting("CampaignLedgerRecovery") end)
	if ok and type(settings) == "table" then
		local amounts = State.recoveryAmounts(settings.mana, settings.ap)
		if amounts then return amounts end
	end
	return { mana = 1, ap = 1 }
end
actions.recover = function(manaValue, apValue, allCharacters)
	local amounts, message = State.recoveryAmounts(manaValue, apValue)
	if not amounts then notify(message, true); return end
	local targets = allCharacters and CollectionService:GetTagged(TAG) or { selected }
	local updates = {}
	-- Validate every target before writing anything. Roster search never limits recovery.
	for _, character in ipairs(targets) do
		if isCharacter(character) and not Registry.registeredAncestor(character.Parent, Workspace) then
			local state, readError = read(character)
			if not state then notify(character.Name .. ": " .. readError, true); return end
			if not Plate.anchor(character) then notify(character.Name .. " has no plate anchor.", true); return end
			table.insert(updates, { character = character, state = State.recover(state, amounts.mana, amounts.ap) })
		end
	end
	if #updates == 0 then notify(allCharacters and "No registered characters to refill." or "Choose a registered character first.", true); return end
	if transaction("Apply mana and action recovery", function()
		for _, update in ipairs(updates) do
			update.character:SetAttribute(ATTRIBUTE, HttpService:JSONEncode(update.state))
			Plate.render(update.character, update.state)
		end
	end) then
		automaticSyncFailed = false
		pcall(function() plugin:SetSetting("CampaignLedgerRecovery", amounts) end)
		notify("Recovery applied to " .. #updates .. " character(s): +" .. amounts.mana .. " mana, +" .. amounts.ap .. " actions.")
	end
end
actions.adjust = function(key, delta)
	change("Adjust " .. State.labels[key], function(state) return State.adjust(state, key, delta) end,
		function(old, new) return State.labels[key] .. ": " .. old[key].current .. " → " .. new[key].current .. " · " .. new.name end)
end
actions.newTurn = function() change("Refill actions", State.newTurn, "Actions refilled. Combat turn unchanged.") end
actions.restore = function() change("Restore resources", State.restore, "Health, mana and actions restored.") end
actions.rename = function(name) change("Rename ledger character", function(state) return State.rename(state, name) end, "Character name saved.") end
actions.toggleAutoName = function()
	change("Change name source", function(state)
		local result = State.copy(state)
		result.autoName = state.autoName == false
		return Names.apply(selected, result)
	end, function(_, state) return state.autoName and "Name follows the model’s overhead display." or "Manual name enabled." end)
end
actions.togglePlate = function()
	change("Toggle overhead plate", function(state)
		local result = State.copy(state); result.showPlate = not result.showPlate; return result
	end, function(_, state) return state.showPlate and "Overhead plate shown." or "Overhead plate hidden." end)
end
actions.rebuild = function() change("Rebuild overhead plate", State.copy, "Overhead plate rebuilt.") end
actions.shiftPlate = function(delta)
	change("Adjust plate height", function(state) return State.shiftPlate(state, delta) end, "Plate height updated.")
end
actions.remove = function()
	local target = selected
	if not isCharacter(target) then return end
	if transaction("Remove character from ledger", function()
		Plate.clear(target)
		target:SetAttribute(ATTRIBUTE, nil)
		CollectionService:RemoveTag(target, TAG)
	end) then selected = nil; notify("Removed from ledger. Character model preserved; Studio Undo restores stats.") end
end

-- Recover an unfinished recording if Studio reloaded the plugin mid-operation.
local previous = plugin:GetAttribute("CampaignLedgerRecording")
if previous then
	pcall(function() ChangeHistoryService:FinishRecording(previous, Enum.FinishRecordingOperation.Cancel) end)
	plugin:SetAttribute("CampaignLedgerRecording", nil)
end

local toolbar, toggle
if not options.launcher then
 toolbar = WorldScope.toolbar(plugin, "Campaign Ledger")
 toggle = WorldScope.button(plugin, toolbar, "CampaignLedgerOpen", "Open the D&D character ledger", "", "DM Ledger")
 toggle.ClickableWhenViewportHidden = true
end
local widget = WorldScope.widget(plugin, "CampaignLedger.DM.v1.1", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, false, true, 410, 760, 330, 480
))
widget.Title = "Campaign Ledger"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hover = Hover.start(plugin, function(value) if panel then panel:updateHoverOnly(value) end end)
panel = Panel.new(widget, actions)
panel:updateHoverOnly(hover:getHoverOnly())
recoverLegacyPlates()
panel:updateTurn(ReplicatedStorage:GetAttribute(Turn.attribute))
connect(ReplicatedStorage:GetAttributeChangedSignal(Turn.attribute), function()
	panel:updateTurn(ReplicatedStorage:GetAttribute(Turn.attribute))
end)
if toggle then
 connect(toggle.Click, function() widget.Enabled = not widget.Enabled end)
 connect(widget:GetPropertyChangedSignal("Enabled"), function() toggle:SetActive(widget.Enabled) end)
 toggle:SetActive(widget.Enabled)
end
local openAction = WorldScope.action(plugin, "CampaignLedger.Toggle", "Toggle Campaign Ledger", "Open or close the D&D ledger", "", true)
connect(openAction.Triggered, function() widget.Enabled = not widget.Enabled end)

connect(Selection.SelectionChanged, function()
	local objects = Selection:Get()
	if #objects == 1 then
		local character = taggedAncestor(objects[1])
		if character then selected = character; scheduleRefresh() end
	end
end)
connect(CollectionService:GetInstanceAddedSignal(TAG), scheduleRefresh)
connect(CollectionService:GetInstanceRemovedSignal(TAG), scheduleRefresh)
connect(CollectionService:GetInstanceAddedSignal(Plate.tag), scheduleRefresh)
connect(CollectionService:GetInstanceRemovedSignal(Plate.tag), scheduleRefresh)
connect(Workspace.DescendantAdded, function(object) if CollectionService:HasTag(object, TAG) then scheduleRefresh() end end)
connect(Workspace.DescendantRemoving, function(object) if CollectionService:HasTag(object, TAG) then scheduleRefresh() end end)
connect(ChangeHistoryService.OnUndo, scheduleRefresh)
connect(ChangeHistoryService.OnRedo, scheduleRefresh)
local function stopSession()
	alive = false
	hover:destroy()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for _, listeners in pairs(observed) do for _, listener in ipairs(listeners) do listener:Disconnect() end end
	panel:destroy()
	widget.Enabled = false
	if toolbar then WorldScope.pauseToolbar(plugin, toolbar) end
end
refresh()
local initialSelection = Selection:Get()
if #initialSelection == 1 then
	selected = taggedAncestor(initialSelection[1])
	scheduleRefresh()
end

return stopSession, { open = function() if alive then widget.Enabled = true end end }
end
return LedgerSession
