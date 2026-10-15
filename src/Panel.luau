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
 self.viewport = Theme.create("ScrollingFrame", { Name = "LedgerViewport", BackgroundColor3 = C.base,
  BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
  AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, widget)
 self.root = frame(self.viewport, { Name = "CampaignLedger", BackgroundTransparency = 0,
  BackgroundColor3 = C.base, Size = UDim2.new(1, -4, 0, 640) })
 Theme.label(self.root, "Campaign Ledger", 26, { Font = Theme.display, TextColor3 = C.accent,
  Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 34), TextXAlignment = Enum.TextXAlignment.Center })
 Theme.rule(self.root, { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 1) })
 self.search = Theme.input(self.root, "Search characters…", { Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 0, 32) })
 self.search:GetPropertyChangedSignal("Text"):Connect(function() self:drawRoster() end)
 self.roster = Theme.create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0,
  Position = UDim2.fromOffset(12, 98), Size = UDim2.new(1, -24, 0, 130), CanvasSize = UDim2.new(),
  AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 stack(self.roster, 2)
 self.register = Theme.button(self.root, "+ Register selected character", { TextColor3 = C.accent })
 self.register.Activated:Connect(actions.register)
 self.divider = Theme.create("TextButton", { Name = "RosterDivider", Text = "", AutoButtonColor = false,
  BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 18), Selectable = false }, self.root)
 Theme.rule(self.divider, { Position = UDim2.fromOffset(0, 8) })
 frame(self.divider, { BackgroundTransparency = 0, BackgroundColor3 = C.base,
  Position = UDim2.new(0.5, -27, 0, 0), Size = UDim2.fromOffset(54, 18) })
 for _, x in ipairs({ -16, -4, 8 }) do
  Theme.rule(self.divider, { BackgroundColor3 = C.muted, Position = UDim2.new(0.5, x, 0, 6), Size = UDim2.fromOffset(8, 3) })
 end
 self.editor = Theme.create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0,
  CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
  ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 self.content = frame(self.editor, { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
 Theme.create("UIPadding", { PaddingTop = UDim.new(0, Layout.editorPadding), PaddingBottom = UDim.new(0, 8),
  PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, self.content)
 stack(self.content, 10)
 self.empty = Theme.label(self.content, "Select a model and register it to begin.", 17, { LayoutOrder = 0,
  TextColor3 = C.muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 70) })
 self.heading = frame(self.content, { Size = UDim2.new(1, 0, 0, Layout.headingHeight), LayoutOrder = 1 })
 local nameBand = frame(self.heading, { Name = "CharacterHeading", BackgroundTransparency = 0,
  BackgroundColor3 = C.text, Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 34) })
 Theme.corners(nameBand, C.accent, 7)
 self.title = Theme.label(nameBand, "", 22, { Name = "SelectedCharacterName", Font = Theme.display, TextColor3 = C.field,
  Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0) })
 Theme.button(self.heading, "Select model", { Position = UDim2.new(1, -110, 0, Layout.selectButtonTop),
  Size = UDim2.fromOffset(110, Layout.selectButtonHeight), TextSize = 15 }).Activated:Connect(actions.selectModel)
 for index, key in ipairs(State.resources) do
  local row = frame(self.content, { Name = key .. "Combat", LayoutOrder = index + 1, Size = UDim2.new(1, 0, 0, 104) })
  Theme.label(row, State.labels[key], 18, { Font = Theme.bold, TextColor3 = C[key], Size = UDim2.new(1, -154, 0, 30) })
  local current = Theme.label(row, "", 28, { Name = key .. "Current", Font = Theme.bold,
   Position = UDim2.new(1, -154, 0, -1), Size = UDim2.fromOffset(84, 32), TextXAlignment = Enum.TextXAlignment.Right })
  local maximum = Theme.label(row, "", 16, { Name = key .. "Maximum", TextColor3 = C.muted,
   Position = UDim2.new(1, -65, 0, 5), Size = UDim2.fromOffset(65, 24), TextXAlignment = Enum.TextXAlignment.Right })
  local track = frame(row, { Name = key .. "Track", BackgroundTransparency = 0, BackgroundColor3 = C.track,
   Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 3) })
  local fill = frame(track, { Name = "Fill", BackgroundTransparency = 0, BackgroundColor3 = C[key], Size = UDim2.fromScale(1, 1) })
  local amountGroup = frame(row, { Position = UDim2.fromOffset(0, 42), Size = UDim2.new(0.4, -6, 0, 30) })
  Theme.label(amountGroup, "Amount", 14, { TextColor3 = C.muted, Size = UDim2.fromOffset(46, 30) })
  local amount = Theme.input(amountGroup, "1", { Text = "1", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center,
   Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -48, 1, 0) })
  Theme.button(row, "Subtract", { Position = UDim2.new(0.4, 0, 0, 42), Size = UDim2.new(0.3, -4, 0, 30),
   TextSize = 15, TextColor3 = C[key] }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, -1) end)
  Theme.button(row, "Add", { Position = UDim2.new(0.7, 2, 0, 42), Size = UDim2.new(0.3, -2, 0, 30),
   TextSize = 15, TextColor3 = C[key] }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, 1) end)
  if key == "ap" then
   local specs = { { "Spend 1", -1 }, { "Refund 1", 1 }, { "Refill AP", 0 } }
   for i, spec in ipairs(specs) do
    Theme.button(row, spec[1], { Position = UDim2.new((i - 1) / 3, (i - 1) * 2, 0, 78),
     Size = UDim2.new(1 / 3, -4, 0, 26), TextSize = 14 }).Activated:Connect(function()
      if spec[2] == 0 then actions.newTurn() else actions.adjust(key, spec[2]) end
     end)
   end
  else
   for i, delta in ipairs({ -5, -1, 1, 5 }) do
    Theme.button(row, (delta > 0 and "+" or "−") .. math.abs(delta), { Position = UDim2.new((i - 1) / 4, (i - 1) * 1.5, 0, 78),
     Size = UDim2.new(0.25, -4.5, 0, 26), TextSize = 15 }).Activated:Connect(function() actions.adjust(key, delta) end)
   end
  end
  self.fields[key] = { row = row, current = current, summaryMaximum = maximum, fill = fill, amount = amount }
 end
 self.turnRow = frame(self.content, { Name = "CombatTurn", LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 224) })
 Theme.rule(self.turnRow)
 self.turnTitle = Theme.label(self.turnRow, "No active combat", 20, { Font = Theme.bold,
  Position = UDim2.fromOffset(0, 9), Size = UDim2.new(1, 0, 0, 26) })
 for index, spec in ipairs({ { "Party turn", "party" }, { "Enemy turn", "enemy" }, { "End combat", "idle" } }) do
  local button = Theme.button(self.turnRow, spec[1], { Position = UDim2.new((index - 1) / 3, (index - 1) * 2, 0, 41),
   Size = UDim2.new(1 / 3, -4, 0, 30), TextSize = 14 })
  button.Activated:Connect(function() actions.setTurn(spec[2]) end)
  self.turnButtons[spec[2]] = button
 end
 local recovery = actions.loadRecovery()
 Theme.label(self.turnRow, "Turn recovery", 17, { Font = Theme.bold,
  Position = UDim2.fromOffset(0, 87), Size = UDim2.new(1, 0, 0, 24) })
 Theme.label(self.turnRow, "Mana to add", 14, { TextColor3 = C.mana,
  Position = UDim2.fromOffset(0, 115), Size = UDim2.new(0.5, -5, 0, 20) })
 Theme.label(self.turnRow, "Actions to add", 14, { TextColor3 = C.ap,
  Position = UDim2.new(0.5, 3, 0, 115), Size = UDim2.new(0.5, -3, 0, 20) })
 local manaRecovery = Theme.input(self.turnRow, "0–9999", { Name = "ManaRecovery", Text = tostring(recovery.mana),
  Position = UDim2.fromOffset(0, 138), Size = UDim2.new(0.5, -3, 0, 30) })
 local apRecovery = Theme.input(self.turnRow, "0–9999", { Name = "ActionRecovery", Text = tostring(recovery.ap),
  Position = UDim2.new(0.5, 3, 0, 138), Size = UDim2.new(0.5, -3, 0, 30) })
 for index, spec in ipairs({ { "Refill selected", false }, { "Refill all characters", true } }) do
  Theme.button(self.turnRow, spec[1], { Position = UDim2.new((index - 1) * 0.5, (index - 1) * 3, 0, 176),
   Size = UDim2.new(0.5, -3, 0, 30), TextSize = 14 }).Activated:Connect(function()
    actions.recover(manaRecovery.Text, apRecovery.Text, spec[2])
   end)
 end
 Theme.label(self.turnRow, "Caps at maximums. Set 0 to skip a resource.", 13, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(0, 208), Size = UDim2.new(1, 0, 0, 16) })
 self.advancedToggle = Theme.button(self.content, "Expand maximums and settings", { LayoutOrder = 6, TextSize = 15 })
 self.advanced = frame(self.content, { LayoutOrder = 7, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Visible = false })
 stack(self.advanced, 12)
 self.advancedToggle.Activated:Connect(function()
  self.expanded = not self.expanded
  self.advanced.Visible = self.expanded and self.selected ~= nil
  self.advancedToggle.Text = self.expanded and "Collapse maximums and settings" or "Expand maximums and settings"
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
 local display = frame(self.content, { Name = "DisplaySettings", LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 62) })
 Theme.rule(display)
 self.hoverToggle = Theme.button(display, "Hover-only plates: On", { Position = UDim2.fromOffset(0, 10), TextSize = 15 })
 self.hoverToggle.Activated:Connect(actions.toggleHoverOnly)
 Theme.label(display, "Display preference for this Studio window.", 13, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 18) })
 self.footer = Theme.label(self.root, "Select a model to begin.", 14, { TextColor3 = C.muted,
  Position = UDim2.new(0, 12, 1, -30), Size = UDim2.new(1, -24, 0, 24) })
 Theme.rule(self.root, { Position = UDim2.new(0, 12, 1, -36), Size = UDim2.new(1, -24, 0, 1) })
 self.split = actions.loadDivider() or 284
 local function layout()
  local height = math.max(640, self.viewport.AbsoluteSize.Y)
  self.root.Size = UDim2.new(1, -4, 0, height)
  self.split = Layout.split(height, self.split)
  self.roster.Size = UDim2.new(1, -24, 0, self.split - 148)
  self.register.Position, self.register.Size = UDim2.fromOffset(12, self.split - 42), UDim2.new(1, -24, 0, 32)
  self.divider.Position = UDim2.fromOffset(12, self.split)
  self.editor.Position = UDim2.fromOffset(12, self.split + 20)
  self.editor.Size = UDim2.new(1, -24, 1, -self.split - 64)
 end
 self.viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
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
 self.hoverToggle.Text = value and "Hover-only plates: On" or "Hover-only plates: Off"
 Theme.select(self.hoverToggle, value, C.mana)
end
function Panel:notify(message, isError)
 self.footer.Text, self.footer.TextColor3 = message, isError and C.hp or C.muted
end
function Panel:updateTurn(value)
 local title, _, color = Turn.view(value)
 self.turnTitle.Text, self.turnTitle.TextColor3 = title, C[color]
 for side, button in pairs(self.turnButtons) do
  Theme.select(button, side == value and side ~= "idle", side == "party" and C.mana or C.hp)
 end
end
function Panel:destroy()
 self.stopDrag()
 for _, connection in ipairs(self.connections) do connection:Disconnect() end
 self.root:Destroy()
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
    BackgroundColor3 = active and C.text or C.surface, BackgroundTransparency = active and 0 or 1,
    AutoButtonColor = false, Size = UDim2.new(1, -5, 0, 48), LayoutOrder = shown, Selectable = true }, self.roster)
   if active then frame(button, { BackgroundTransparency = 0, BackgroundColor3 = C.accent,
    Size = UDim2.new(0, 3, 1, 0) }) end
   Theme.label(button, name, 18, { Font = Theme.display, TextColor3 = active and C.field or C.text,
    Position = UDim2.fromOffset(10, 1), Size = UDim2.new(1, -20, 0, 24) })
   if entry.state then
    for index, key in ipairs(State.resources) do
     local label = key == "ap" and "AP" or State.labels[key]
     Theme.label(button, label .. " " .. entry.state[key].current, 13, { TextColor3 = active and C.surface or C[key],
      Position = UDim2.new((index - 1) / 3, 10, 0, 26), Size = UDim2.new(1 / 3, -12, 0, 18) })
    end
   else
    Theme.label(button, "Stats need repair", 13, { TextColor3 = active and C.surface or C.hp,
     Position = UDim2.fromOffset(10, 26), Size = UDim2.new(1, -20, 0, 18) })
   end
   button.Activated:Connect(function() self.actions.choose(entry.character) end)
   local function highlight(value) button.BackgroundTransparency = active and 0 or value and 0.35 or 1 end
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
 self.empty.Visible, self.heading.Visible, self.advancedToggle.Visible = not visible, visible, visible
 self.advanced.Visible = visible and self.expanded
 for _, fields in pairs(self.fields) do fields.row.Visible = visible end
 self.empty.Text = selected and "This character has invalid stats. Use Studio Undo to recover its last valid values."
  or "Select a character model in the map, then click Register selected character."
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
