local Theme = require(script.Parent.Theme)
local State = require(script.Parent.State)
local Layout = require(script.Parent.Layout)
local Turn = require(script.Parent.Turn)
local Panel = {}
Panel.__index = Panel
local C = Theme.colors

local function frame(parent, props)
 local values = { BackgroundTransparency = 1, BorderSizePixel = 0 }
 for key, value in pairs(props or {}) do values[key] = value end
 return Theme.create("Frame", values, parent)
end
local function stack(parent, gap)
 Theme.create("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end

function Panel.new(widget, actions)
 local self = setmetatable({ actions = actions, fields = {}, rows = {}, turnButtons = {}, connections = {}, expanded = false }, Panel)
 self.viewport = frame(widget, { Name = "LedgerViewport", BackgroundTransparency = 0,
  BackgroundColor3 = C.shell, Size = UDim2.fromScale(1, 1) })
 self.root = frame(self.viewport, { Name = "CampaignLedger", Size = UDim2.fromScale(1, 1) })
 Theme.label(self.root, "Campaign Ledger", 28, { Font = Theme.display, TextColor3 = C.text,
  Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 32), TextXAlignment = Enum.TextXAlignment.Center })
 local binding = frame(self.root, { Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 0, 1) })
 Theme.junction(binding, 0)
 self.turnRow = frame(self.root, { Name = "CombatTurn", Position = UDim2.fromOffset(12, 50), Size = UDim2.new(1, -24, 0, 84) })
 self.turnTitle = Theme.label(self.turnRow, "No active combat", 14, { Font = Theme.bold, TextColor3 = C.light,
  Size = UDim2.new(1, 0, 0, 18) })
 for index, spec in ipairs({ { "Party turn", "party" }, { "Enemy turn", "enemy" }, { "End combat", "idle" } }) do
  local button = Theme.button(self.turnRow, spec[1], { Name = "Turn_" .. spec[2],
   BackgroundColor3 = C.shell, TextColor3 = C.text, Position = UDim2.new((index - 1) / 3, (index - 1) * 2, 0, 24),
   Size = UDim2.new(1 / 3, -4, 0, 28), TextSize = 14 })
  button.Activated:Connect(function() actions.setTurn(spec[2]) end)
  self.turnButtons[spec[2]] = button
 end
 self.recoveryToggle = Theme.button(self.turnRow, "+ Recovery", { Name = "RecoveryToggle", TextSize = 14,
  TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = C.shell, TextColor3 = C.light,
  Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 26) })
 Theme.create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, self.recoveryToggle)
 self.recovery = frame(self.root, { Name = "Recovery", Visible = false, BackgroundTransparency = 0,
  BackgroundColor3 = C.surface, Position = UDim2.fromOffset(12, 138), Size = UDim2.new(1, -24, 0, 96) })
 local recovery = actions.loadRecovery()
 for index, spec in ipairs({ { "Mana to add", "mana" }, { "AP to add", "ap" } }) do
  Theme.label(self.recovery, spec[1], 14, { Font = Theme.bold, TextColor3 = C[spec[2]],
   Position = UDim2.new((index - 1) / 2, 8, 0, 4), Size = UDim2.new(0.5, -16, 0, 18) })
 end
 self.manaRecovery = Theme.input(self.recovery, "0–9999", { Name = "ManaRecovery", Text = tostring(recovery.mana),
  Position = UDim2.fromOffset(8, 24), Size = UDim2.new(0.5, -12, 0, 26) })
 self.apRecovery = Theme.input(self.recovery, "0–9999", { Name = "ActionRecovery", Text = tostring(recovery.ap),
  Position = UDim2.new(0.5, 4, 0, 24), Size = UDim2.new(0.5, -12, 0, 26) })
 for index, spec in ipairs({ { "Recover selected", false }, { "Recover all models", true } }) do
  local button = Theme.button(self.recovery, spec[1], { Name = spec[2] and "RecoverAll" or "RecoverSelected",
   Position = UDim2.new((index - 1) / 2, index == 1 and 8 or 4, 0, 54),
   Size = UDim2.new(0.5, -12, 0, 26), TextSize = 14 })
  button.Activated:Connect(function() actions.recover(self.manaRecovery.Text, self.apRecovery.Text, spec[2]) end)
  if spec[2] then self.recoverAll = button else self.recoverSelected = button end
 end
 Theme.label(self.recovery, "Manual recovery · caps at maximum · 0 skips", 13, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(8, 80), Size = UDim2.new(1, -16, 0, 16) })
 self.search = Theme.input(self.root, "Search characters…", { Position = UDim2.fromOffset(12, 140), Size = UDim2.new(1, -24, 0, 28) })
 self.search:GetPropertyChangedSignal("Text"):Connect(function() self:drawRoster() end)
 self.roster = Theme.create("ScrollingFrame", { Name = "CharacterRoster", BackgroundColor3 = C.surface, BorderSizePixel = 0,
  Position = UDim2.fromOffset(12, 174), Size = UDim2.new(1, -24, 0, 130), CanvasSize = UDim2.new(),
  AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 Theme.stroke(self.roster, C.edge)
 stack(self.roster, 2)
 self.register = Theme.button(self.root, "+ Register selected model", { Name = "RegisterCharacter", BackgroundColor3 = C.shell, TextColor3 = C.text, TextSize = 14 })
 self.register.Activated:Connect(actions.register)
 self.divider = Theme.create("TextButton", { Name = "RosterDivider", Text = "", AutoButtonColor = false,
  BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 12), Selectable = false }, self.root)
 Theme.rule(self.divider, { Position = UDim2.fromOffset(0, 5) })
 frame(self.divider, { BackgroundTransparency = 0, BackgroundColor3 = C.shell,
  Position = UDim2.new(0.5, -27, 0, 0), Size = UDim2.fromOffset(54, 12) })
 for _, x in ipairs({ -16, -4, 8 }) do
  Theme.rule(self.divider, { BackgroundColor3 = C.muted, Position = UDim2.new(0.5, x, 0, 4), Size = UDim2.fromOffset(8, 2) })
 end
 self.editor = Theme.create("ScrollingFrame", { Name = "CharacterEditor", BackgroundColor3 = C.surface, BorderSizePixel = 0,
  CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
  ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 Theme.stroke(self.editor, C.edge)
 Theme.corners(self.editor, C.light, 9)
 self.content = frame(self.editor, { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
 Theme.create("UIPadding", { PaddingTop = UDim.new(0, Layout.editorPadding), PaddingBottom = UDim.new(0, 8),
  PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 4) }, self.content)
 stack(self.content, 6)
 self.empty = Theme.label(self.content, "Select a model and register it to begin.", 17, { LayoutOrder = 0,
  TextColor3 = C.muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 70) })
 self.heading = frame(self.content, { Size = UDim2.new(1, 0, 0, Layout.headingHeight), LayoutOrder = 1 })
 local nameBand = frame(self.heading, { Name = "CharacterHeading", BackgroundTransparency = 0,
  BackgroundColor3 = C.surface, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 24) })
 self.title = Theme.label(nameBand, "", 22, { Name = "SelectedCharacterName", Font = Theme.display, TextColor3 = C.text,
  Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 1, 0) })
 Theme.button(self.heading, "Select model in map", { Name = "SelectModel", BackgroundColor3 = C.surface, Position = UDim2.new(0, 0, 0, Layout.selectButtonTop),
  Size = UDim2.fromOffset(140, Layout.selectButtonHeight), TextSize = 13 }).Activated:Connect(actions.selectModel)
 Theme.label(self.heading, "Custom amount ↓", 12, { TextColor3 = C.muted, Position = UDim2.new(0.5, 0, 0, 26),
  Size = UDim2.new(0.5, 0, 0, 20) })
 for index, key in ipairs(State.resources) do
  local row = frame(self.content, { Name = key .. "Combat", LayoutOrder = index + 1, Size = UDim2.new(1, 0, 0, Layout.resourceHeight) })
  Theme.label(row, State.labels[key], 16, { Font = Theme.bold, TextColor3 = C[key], Size = UDim2.new(1, -158, 0, 24) })
  local current = Theme.label(row, "", 24, { Name = key .. "Current", Font = Theme.bold,
   Position = UDim2.new(1, -150, 0, -1), Size = UDim2.fromOffset(82, 26), TextXAlignment = Enum.TextXAlignment.Right })
  local maximum = Theme.label(row, "", 15, { Name = key .. "Maximum", TextColor3 = C.muted,
   Position = UDim2.new(1, -64, 0, 2), Size = UDim2.fromOffset(64, 22), TextXAlignment = Enum.TextXAlignment.Right })
  local track = frame(row, { Name = key .. "Track", BackgroundTransparency = 0, BackgroundColor3 = C.track,
   Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 4) })
  Theme.stroke(track)
  local fill = frame(track, { Name = "Fill", BackgroundTransparency = 0, BackgroundColor3 = C[key], Size = UDim2.fromScale(1, 1) })
  local presets = frame(row, { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(0.5, -6, 0, 28) })
  local specs = key == "ap" and { { "−1", -1 }, { "+1", 1 }, { "Refill AP", 0 } }
   or { { "−5", -5 }, { "−1", -1 }, { "+1", 1 }, { "+5", 5 } }
  for i, spec in ipairs(specs) do
   Theme.button(presets, spec[1], { Name = key .. "Preset" .. i,
    Position = UDim2.new(key == "ap" and (i == 3 and 0.5 or (i - 1) * 0.25) or (i - 1) / #specs, 0, 0, 0),
    Size = UDim2.new(key == "ap" and (i == 3 and 0.5 or 0.25) or 1 / #specs, -3, 1, 0),
    TextSize = key == "ap" and 12 or 15 }).Activated:Connect(function()
     if key == "ap" and spec[2] == 0 then actions.newTurn() else actions.adjust(key, spec[2]) end
    end)
  end
  local amount = Theme.input(row, "Amt", { Name = key .. "Amount", Text = "1", TextSize = 15,
   TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0.5, 0, 0, 36), Size = UDim2.new(0.13, -2, 0, 28) })
  -- Narrow numeric wells need all four digits, without the usual text padding.
  local padding = amount:FindFirstChildOfClass("UIPadding")
  padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 1), UDim.new(0, 1)
  Theme.button(row, "Subtract", { Name = key .. "Subtract", Position = UDim2.new(0.63, 3, 0, 36),
   Size = UDim2.new(0.23, -5, 0, 28), TextSize = 13 }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, -1) end)
  Theme.button(row, "Add", { Name = key .. "Add", Position = UDim2.new(0.86, 2, 0, 36),
   Size = UDim2.new(0.14, -2, 0, 28), TextSize = 13 }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, 1) end)
  self.fields[key] = { row = row, current = current, summaryMaximum = maximum, fill = fill, amount = amount }
 end
 self.advancedToggle = Theme.button(self.content, "+ Character details · maximums & settings", { Name = "CharacterDetails", LayoutOrder = 6, TextSize = 14, Size = UDim2.new(1, 0, 0, 28) })
 self.advanced = frame(self.content, { LayoutOrder = 7, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Visible = false })
 stack(self.advanced, 12)
 self.advancedToggle.Activated:Connect(function()
  self.expanded = not self.expanded
  self.advanced.Visible = self.expanded and self.selected ~= nil
  self.advancedToggle.Text = self.expanded and "− Character details · maximums & settings" or "+ Character details · maximums & settings"
 end)
 for index, key in ipairs(State.resources) do
  local row = frame(self.advanced, { LayoutOrder = index, Size = UDim2.new(1, 0, 0, 62) })
  Theme.label(row, State.labels[key] .. " maximum", 16, { Font = Theme.bold, TextColor3 = C[key], Size = UDim2.new(1, 0, 0, 21) })
  local maximum = Theme.input(row, "Maximum", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, -80, 0, 34) })
  local function save() actions.setMaximum(key, maximum.Text) end
  Theme.button(row, "Save", { Position = UDim2.new(1, -70, 0, 26), Size = UDim2.fromOffset(70, 34) }).Activated:Connect(save)
  maximum.FocusLost:Connect(function(enter) if enter then save() end end)
  self.fields[key].maximum = maximum
 end
 Theme.button(self.advanced, "Restore all resources", { LayoutOrder = 4 }).Activated:Connect(actions.restore)
 local nameRow = frame(self.advanced, { LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 62) })
 Theme.label(nameRow, "Character name", 14, { TextColor3 = C.muted })
 self.nameInput = Theme.input(nameRow, "Character name", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, -80, 0, 34) })
 local function rename() actions.rename(self.nameInput.Text) end
 Theme.button(nameRow, "Save", { Position = UDim2.new(1, -70, 0, 26), Size = UDim2.fromOffset(70, 34) }).Activated:Connect(rename)
 self.nameInput.FocusLost:Connect(function(enter) if enter then rename() end end)
 self.autoName = Theme.button(self.advanced, "Use a manual name", { LayoutOrder = 6, TextSize = 15 })
 self.autoName.Activated:Connect(actions.toggleAutoName)
 self.visibility = Theme.button(self.advanced, "Hide overhead plate", { LayoutOrder = 7, TextSize = 15 })
 self.visibility.Activated:Connect(actions.togglePlate)
 local heightRow = frame(self.advanced, { LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 60) })
 self.heightLabel = Theme.label(heightRow, "Plate height: auto", 16)
 for index, spec in ipairs({ { "Lower", -0.25 }, { "Auto", 0 }, { "Raise", 0.25 } }) do
  Theme.button(heightRow, spec[1], { Position = UDim2.new((index - 1) / 3, 0, 0, 27), Size = UDim2.new(1 / 3, -5, 0, 30),
   TextSize = 15 }).Activated:Connect(function() actions.shiftPlate(spec[2]) end)
 end
 Theme.button(self.advanced, "Rebuild overhead plate", { LayoutOrder = 9, TextSize = 15 }).Activated:Connect(actions.rebuild)
 Theme.button(self.advanced, "Remove from ledger", { LayoutOrder = 10, TextSize = 15,
  TextColor3 = C.muted }).Activated:Connect(actions.remove)
 Theme.label(self.advanced, "Lowering a maximum clamps the current value. Studio Undo reverts edits.", 14, {
  LayoutOrder = 11, TextColor3 = C.muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 42) })
 self.hoverToggle = Theme.button(self.root, "Hover plates: On", { Name = "HoverPreference", BackgroundColor3 = C.shell,
  TextColor3 = C.light, Position = UDim2.new(0, 12, 1, -60), Size = UDim2.new(1, -24, 0, 26), TextSize = 14 })
 self.hoverToggle.Activated:Connect(actions.toggleHoverOnly)
 self.footer = Theme.label(self.root, "Type an amount, then Subtract or Add.", 13, { TextColor3 = C.light,
  TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Position = UDim2.new(0, 12, 1, -30), Size = UDim2.new(1, -24, 0, 28) })
 self.split = actions.loadDivider() or Layout.minimumSplit
 local function layout()
  local height = math.max(480, self.viewport.AbsoluteSize.Y)
  local extra = self.recoveryOpen and Layout.recoveryHeight or 0
  local geometry = Layout.geometry(height, self.split + extra, self.recoveryOpen)
  self.split = geometry.split - extra
  self.search.Position = UDim2.fromOffset(12, geometry.search)
  self.roster.Position = UDim2.fromOffset(12, geometry.roster)
  self.roster.Size = UDim2.new(1, -24, 0, geometry.rosterHeight)
  self.register.Position, self.register.Size = UDim2.fromOffset(12, geometry.register), UDim2.new(1, -24, 0, 28)
  self.divider.Position = UDim2.fromOffset(12, geometry.split)
  self.editor.Position = UDim2.fromOffset(12, geometry.editor)
  self.editor.Size = UDim2.new(1, -24, 0, geometry.editorHeight)
 end
 table.insert(self.connections, self.viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
 self.recoveryToggle.Activated:Connect(function()
  self.recoveryOpen = not self.recoveryOpen
  self.recovery.Visible = self.recoveryOpen
  self.recoveryToggle.Text = self.recoveryOpen and "− Recovery" or "+ Recovery"
  layout()
 end)
 local dragStartY, dragStartSplit
 local detector = Theme.create("UIDragDetector", { DragStyle = Enum.UIDragDetectorDragStyle.TranslateLine,
  DragAxis = Vector2.new(0, 1), ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset }, self.divider)
 local function moveDivider(position)
  if dragStartY then
   self.split = dragStartSplit + position.Y - dragStartY
   layout()
  end
 end
 local function stopDrag()
  dragStartY, dragStartSplit = nil, nil
  actions.saveDivider(self.split)
 end
 self.stopDrag = stopDrag
 detector.DragStart:Connect(function(position)
  dragStartY, dragStartSplit = position.Y, self.split
 end)
 detector.DragContinue:Connect(moveDivider)
 detector.DragEnd:Connect(function(position) moveDivider(position); stopDrag() end)
 table.insert(self.connections, widget.WindowFocusReleased:Connect(stopDrag))
 layout()
 self:refresh({}, nil, nil)
 return self
end

function Panel:updateHoverOnly(value)
 self.hoverToggle.Text = value and "Hover plates: On · this window" or "Hover plates: Off · this window"
 Theme.select(self.hoverToggle, value, C.active)
end
function Panel:notify(message, isError)
 self.footer.Text, self.footer.TextColor3 = (isError and "Error: " or "") .. message, isError and C.hp or C.light
end
function Panel:updateTurn(value)
 local title = Turn.view(value)
 self.turnTitle.Text, self.turnTitle.TextColor3 = title, C.text
 for side, button in pairs(self.turnButtons) do
  Theme.select(button, side == value and side ~= "idle", side == "party" and C.active or C.enemyActive)
 end
end
function Panel:destroy()
 self.stopDrag()
 for _, connection in ipairs(self.connections) do connection:Disconnect() end
 self.viewport:Destroy()
end
function Panel:drawRoster()
 for _, row in ipairs(self.rows) do row:Destroy() end
 self.rows = {}
 local query, shown = string.lower(self.search.Text), 0
 for _, entry in ipairs(self.entries or {}) do
  local name = entry.state and entry.state.name or entry.character.Name
  if query == "" or string.find(string.lower(name), query, 1, true) then
   shown += 1
   local active = entry.character == self.selected
   local button = Theme.create("TextButton", { Name = "Character_" .. (entry.id or tostring(shown)), Text = "", BorderSizePixel = 0,
    BackgroundColor3 = active and C.selection or C.field, BackgroundTransparency = active and 0 or 0.65,
    AutoButtonColor = false, Size = UDim2.new(1, -5, 0, 42), LayoutOrder = shown, Selectable = true }, self.roster)
   if active then frame(button, { BackgroundTransparency = 0, BackgroundColor3 = C.accent,
    Size = UDim2.new(0, 3, 1, 0) }) end
   Theme.label(button, name, 18, { Font = Theme.display, TextColor3 = C.text,
    Position = UDim2.fromOffset(10, 1), Size = UDim2.new(1, -42, 0, 24) })
   if active then Theme.label(button, "›", 24, { TextColor3 = C.text, Font = Theme.bold,
    Position = UDim2.new(1, -25, 0, 4), Size = UDim2.fromOffset(20, 28), TextXAlignment = Enum.TextXAlignment.Center }) end
   if entry.state then
    for index, key in ipairs(State.resources) do
     local label = key == "ap" and "AP" or State.labels[key]
     Theme.label(button, label .. " " .. entry.state[key].current, 13, { TextColor3 = active and C.text or C[key],
      Position = UDim2.new((index - 1) / 3, 10, 0, 23), Size = UDim2.new(1 / 3, -12, 0, 18) })
    end
   else
    Theme.label(button, "Stats need repair", 13, { TextColor3 = C.hp,
     Position = UDim2.fromOffset(10, 23), Size = UDim2.new(1, -20, 0, 18) })
   end
   button.Activated:Connect(function() self.actions.choose(entry.character) end)
   local function highlight(value) button.BackgroundTransparency = active and 0 or value and 0 or 0.65 end
   button.MouseEnter:Connect(function() highlight(true) end)
   button.MouseLeave:Connect(function() highlight(false) end)
   button.SelectionGained:Connect(function() highlight(true) end)
   button.SelectionLost:Connect(function() highlight(false) end)
   table.insert(self.rows, button)
  end
 end
 if shown == 0 then table.insert(self.rows, Theme.label(self.roster,
  query == "" and "No characters registered yet." or "No matching characters.", 15,
  { TextColor3 = C.muted, Size = UDim2.new(1, -5, 0, 38) })) end
end
function Panel:refresh(entries, selected, state)
 local changed = self.selected ~= selected
 self.entries, self.selected = entries, selected
 self:drawRoster()
 local visible = state ~= nil
 Theme.enable(self.recoverSelected, visible)
 self.recoverAll.Text = "Recover all (" .. #entries .. ")"
 self.empty.Visible, self.heading.Visible, self.advancedToggle.Visible = not visible, visible, visible
 self.advanced.Visible = visible and self.expanded
 for _, fields in pairs(self.fields) do fields.row.Visible = visible end
 self.empty.Text = selected and "This character has invalid stats. Use Studio Undo to recover its last valid values."
  or "Select a model in the map, then click Register selected model. Already registered? Choose it in the roster above."
 if not state then return end
 self.title.Text = state.name
 for key, fields in pairs(self.fields) do
  fields.current.Text = tostring(state[key].current)
  fields.summaryMaximum.Text = "/ " .. state[key].maximum
  fields.fill.Size = UDim2.fromScale(state[key].maximum == 0 and 0 or state[key].current / state[key].maximum, 1)
  if changed or not fields.maximum:IsFocused() then fields.maximum.Text = tostring(state[key].maximum) end
  if changed then fields.amount.Text = "1" end
 end
 if changed or not self.nameInput:IsFocused() then self.nameInput.Text = state.name end
 self.autoName.Text = state.autoName ~= false and "Use a manual name" or "Use model’s overhead name"
 self.visibility.Text = state.showPlate and "Hide overhead plate" or "Show overhead plate"
 self.heightLabel.Text = "Plate height: " .. ((state.plateOffset or 0) == 0 and "auto" or string.format("%+.2f studs", state.plateOffset))
 if changed then self.editor.CanvasPosition = Vector2.zero end
end
return Panel
