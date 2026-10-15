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
 local self = setmetatable({ actions = actions, fields = {}, rows = {}, connections = {}, expanded = false }, Panel)
 self.viewport = Theme.create("ScrollingFrame", { Name = "LedgerViewport", BackgroundColor3 = C.base,
  BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
  AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, widget)
 self.root = frame(self.viewport, { Name = "CampaignLedger", BackgroundTransparency = 0,
  BackgroundColor3 = C.base, Size = UDim2.new(1, -4, 0, 640) })
 Theme.label(self.root, "Campaign Ledger", 26, { Font = Theme.display, TextColor3 = C.accent,
  Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 34), TextXAlignment = Enum.TextXAlignment.Center })
 self.search = Theme.input(self.root, "Search characters…", { Position = UDim2.fromOffset(16, 56), Size = UDim2.new(1, -32, 0, 34) })
 self.search:GetPropertyChangedSignal("Text"):Connect(function() self:drawRoster() end)
 self.roster = Theme.create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0,
  Position = UDim2.fromOffset(16, 98), Size = UDim2.new(1, -32, 0, 130), CanvasSize = UDim2.new(),
  AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 stack(self.roster, 2)
 self.register = Theme.button(self.root, "+ Register selected character", { TextColor3 = C.accent })
 self.register.Activated:Connect(actions.register)
 self.divider = Theme.button(self.root, "Drag to resize", { BackgroundColor3 = C.base, TextColor3 = C.muted,
  TextSize = 12, Size = UDim2.new(1, -32, 0, 18) })
 self.editor = Theme.create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0,
  CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
  ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 self.content = frame(self.editor, { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
 Theme.create("UIPadding", { PaddingTop = UDim.new(0, Layout.editorPadding), PaddingBottom = UDim.new(0, 8),
  PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, self.content)
 stack(self.content, 12)
 self.empty = Theme.label(self.content, "Select a model and register it to begin.", 17, { LayoutOrder = 0,
  TextColor3 = C.muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 70) })
 self.heading = frame(self.content, { Size = UDim2.new(1, 0, 0, Layout.headingHeight), LayoutOrder = 1 })
 self.title = Theme.label(self.heading, "", 23, { Font = Theme.display, Size = UDim2.new(1, 0, 0, 30) })
 Theme.button(self.heading, "Select model", { Position = UDim2.new(1, -110, 0, Layout.selectButtonTop),
  Size = UDim2.fromOffset(110, Layout.selectButtonHeight), TextSize = 15 }).Activated:Connect(actions.selectModel)
 for index, key in ipairs(State.resources) do
  local row = frame(self.content, { Name = key .. "Combat", LayoutOrder = index + 1, Size = UDim2.new(1, 0, 0, 103) })
  Theme.label(row, State.labels[key], 18, { Font = Theme.bold, TextColor3 = C[key], Size = UDim2.new(0.4, 0, 0, 25) })
  local summary = Theme.label(row, "", 23, { Font = Theme.bold, Position = UDim2.fromScale(0.4, 0),
   Size = UDim2.new(0.6, 0, 0, 25), TextXAlignment = Enum.TextXAlignment.Right })
  local amount = Theme.input(row, "Amount", { Text = "1", Position = UDim2.fromOffset(0, 33), Size = UDim2.new(0.4, -6, 0, 34) })
  Theme.button(row, "Subtract", { Position = UDim2.new(0.4, 0, 0, 33), Size = UDim2.new(0.3, -4, 0, 34),
   TextSize = 15, TextColor3 = C[key] }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, -1) end)
  Theme.button(row, "Add", { Position = UDim2.new(0.7, 2, 0, 33), Size = UDim2.new(0.3, -2, 0, 34),
   TextSize = 15, TextColor3 = C[key] }).Activated:Connect(function() actions.adjustAmount(key, amount.Text, 1) end)
  if key == "ap" then
   local specs = { { "Spend 1", -1 }, { "Refund 1", 1 }, { "Refill AP", 0 } }
   for i, spec in ipairs(specs) do
    Theme.button(row, spec[1], { Position = UDim2.new((i - 1) / 3, 0, 0, 75), Size = UDim2.new(1 / 3, -5, 0, 28),
     TextSize = 14 }).Activated:Connect(function() if spec[2] == 0 then actions.newTurn() else actions.adjust(key, spec[2]) end end)
   end
  else
   for i, delta in ipairs({ -5, -1, 1, 5 }) do
    Theme.button(row, (delta > 0 and "+" or "−") .. math.abs(delta), { Position = UDim2.new((i - 1) / 4, 0, 0, 75),
     Size = UDim2.new(0.25, -5, 0, 28), TextSize = 15 }).Activated:Connect(function() actions.adjust(key, delta) end)
   end
  end
  self.fields[key] = { row = row, summary = summary, amount = amount }
 end
 self.turnRow = frame(self.content, { LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 244) })
 self.turnTitle = Theme.label(self.turnRow, "No active combat", 19, { Font = Theme.bold, Size = UDim2.new(1, 0, 0, 24) })
 for index, spec in ipairs({ { "Party turn", "party" }, { "Enemy turn", "enemy" }, { "End combat", "idle" } }) do
  Theme.button(self.turnRow, spec[1], { Position = UDim2.new((index - 1) / 3, 0, 0, 31),
   Size = UDim2.new(1 / 3, -5, 0, 32), TextSize = 14 }).Activated:Connect(function() actions.setTurn(spec[2]) end)
 end
 Theme.label(self.turnRow, "Updates everyone’s Turn Watch plugin.", 13, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 0, 20) })
 local recovery = actions.loadRecovery()
 Theme.label(self.turnRow, "Turn recovery", 18, { Font = Theme.bold,
  Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 24) })
 Theme.label(self.turnRow, "Mana to add", 14, { TextColor3 = C.mana,
  Position = UDim2.fromOffset(0, 129), Size = UDim2.new(0.5, -5, 0, 20) })
 Theme.label(self.turnRow, "Actions to add", 14, { TextColor3 = C.ap,
  Position = UDim2.new(0.5, 3, 0, 129), Size = UDim2.new(0.5, -3, 0, 20) })
 local manaRecovery = Theme.input(self.turnRow, "0–9999", { Text = tostring(recovery.mana),
  Position = UDim2.fromOffset(0, 153), Size = UDim2.new(0.5, -5, 0, 32) })
 local apRecovery = Theme.input(self.turnRow, "0–9999", { Text = tostring(recovery.ap),
  Position = UDim2.new(0.5, 3, 0, 153), Size = UDim2.new(0.5, -3, 0, 32) })
 for index, spec in ipairs({ { "Refill selected", false }, { "Refill all characters", true } }) do
  Theme.button(self.turnRow, spec[1], { Position = UDim2.new((index - 1) * 0.5, (index - 1) * 3, 0, 193),
   Size = UDim2.new(0.5, -5, 0, 32), TextSize = 14 }).Activated:Connect(function()
    actions.recover(manaRecovery.Text, apRecovery.Text, spec[2])
   end)
 end
 Theme.label(self.turnRow, "Apply when ready. Caps at maximums; 0 skips a resource.", 12, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(0, 227), Size = UDim2.new(1, 0, 0, 17) })
 local display = frame(self.content, { LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 62) })
 Theme.label(display, "Display settings for this Studio window", 14, { TextColor3 = C.muted })
 self.hoverToggle = Theme.button(display, "Hover-only plates: On", { Position = UDim2.fromOffset(0, 27), TextSize = 16 })
 self.hoverToggle.Activated:Connect(actions.toggleHoverOnly)
 self.advancedToggle = Theme.button(self.content, "Expand maximums and settings", { LayoutOrder = 7, TextSize = 16 })
 self.advanced = frame(self.content, { LayoutOrder = 8, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Visible = false })
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
 self.footer = Theme.label(self.root, "Select a model to begin.", 14, { TextColor3 = C.muted,
  Position = UDim2.new(0, 16, 1, -34), Size = UDim2.new(1, -32, 0, 28) })
 self.split = actions.loadDivider() or 284
 local function layout()
  local height = math.max(640, self.viewport.AbsoluteSize.Y)
  self.root.Size = UDim2.new(1, -4, 0, height)
  self.split = Layout.split(height, self.split)
  self.roster.Size = UDim2.new(1, -32, 0, self.split - 154)
  self.register.Position, self.register.Size = UDim2.fromOffset(16, self.split - 48), UDim2.new(1, -32, 0, 34)
  self.divider.Position = UDim2.fromOffset(16, self.split)
  self.editor.Position = UDim2.fromOffset(16, self.split + 28)
  self.editor.Size = UDim2.new(1, -32, 1, -self.split - 72)
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
end
function Panel:notify(message, isError)
 self.footer.Text, self.footer.TextColor3 = message, isError and C.hp or C.muted
end
function Panel:updateTurn(value)
 local title, _, color = Turn.view(value)
 self.turnTitle.Text, self.turnTitle.TextColor3 = title, C[color]
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
   local button = Theme.create("TextButton", { Name = "Character_" .. (entry.id or tostring(shown)), Text = "", BorderSizePixel = 0, BackgroundColor3 = C.surface,
    BackgroundTransparency = active and 0 or 1, AutoButtonColor = true, Size = UDim2.new(1, -5, 0, 42),
    LayoutOrder = shown, Selectable = true }, self.roster)
   if active then frame(button, { BackgroundTransparency = 0, BackgroundColor3 = C.accent,
    Size = UDim2.fromOffset(2, 28), Position = UDim2.fromOffset(0, 7) }) end
   Theme.label(button, name, 17, { Font = Theme.bold, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 23) })
   local text = "Stats need repair"
   if entry.state then
    local s = entry.state
    text = s.hp.current .. " health    " .. s.mana.current .. " mana    " .. s.ap.current .. " actions"
   end
   Theme.label(button, text, 13, { TextColor3 = C.muted, Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -20, 0, 17) })
   button.Activated:Connect(function() self.actions.choose(entry.character) end)
   button.SelectionGained:Connect(function() button.BackgroundTransparency = 0 end)
   button.SelectionLost:Connect(function() button.BackgroundTransparency = active and 0 or 1 end)
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
  fields.summary.Text = state[key].current .. " / " .. state[key].maximum
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
