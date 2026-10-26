local Theme = require(script.Parent.Theme)
local State = require(script.Parent.State)
local RosterPanel = {}
RosterPanel.__index = RosterPanel
local C = Theme.colors
local function frame(parent, props)
 return Theme.create("Frame", props, parent)
end
function RosterPanel.new(widget, actions)
 local self = setmetatable({ actions = actions, rows = {} }, RosterPanel)
 self.root = Theme.create("Frame", { Name = "CharacterRosterPanel", BackgroundColor3 = C.shell,
  BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, widget)
 Theme.label(self.root, "Characters", 28, { Font = Theme.display, TextXAlignment = Enum.TextXAlignment.Center,
  Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 34) })
 self.search = Theme.input(self.root, "Search characters…", { Name = "RosterSearch",
  Position = UDim2.fromOffset(12, 50), Size = UDim2.new(1, -24, 0, 30) })
 self.search:GetPropertyChangedSignal("Text"):Connect(function() self:drawRoster() end)
 self.roster = Theme.create("ScrollingFrame", { Name = "CharacterRoster", BackgroundColor3 = C.surface,
  BorderSizePixel = 0, Position = UDim2.fromOffset(12, 90), Size = UDim2.new(1, -24, 1, -178),
  CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
  ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, self.root)
 Theme.stroke(self.roster, C.edge)
 Theme.create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, self.roster)
 self.register = Theme.button(self.root, "+ Register selected model", { Name = "RegisterCharacter", TextSize = 14,
  Position = UDim2.new(0, 12, 1, -78), Size = UDim2.new(1, -24, 0, 30) })
 self.register.Activated:Connect(actions.register)
 self.footer = Theme.label(self.root, "Choose a character to open its combat controls.", 13, { TextColor3 = C.light,
  TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
  Position = UDim2.new(0, 12, 1, -40), Size = UDim2.new(1, -24, 0, 34) })
 self:refresh({}, nil)
 return self
end
function RosterPanel:drawRoster()
 for _, row in ipairs(self.rows) do row:Destroy() end
 self.rows = {}
 local query, shown = string.lower(self.search.Text), 0
 for _, entry in ipairs(self.entries or {}) do
  local name = entry.state and entry.state.name or entry.character.Name
  if query == "" or string.find(string.lower(name), query, 1, true) then
   shown += 1
   local active = entry.character == self.selected
   local button = Theme.create("TextButton", { Name = "Character_" .. (entry.pending and entry.character.Name or entry.id or tostring(shown)), Text = "", BorderSizePixel = 0,
    BackgroundColor3 = active and C.selection or C.field, BackgroundTransparency = active and 0 or 0.65,
    AutoButtonColor = false, Size = UDim2.new(1, -5, 0, 42), LayoutOrder = shown, Selectable = true }, self.roster)
   if active then frame(button, { BackgroundTransparency = 0, BackgroundColor3 = C.accent,
    Size = UDim2.new(0, 3, 1, 0) }) end
   Theme.label(button, name, 18, { Font = Theme.display, TextColor3 = C.text,
    Position = UDim2.fromOffset(10, 1), Size = UDim2.new(1, -42, 0, 24) })
   if active then Theme.label(button, "›", 24, { TextColor3 = C.text, Font = Theme.bold,
    Position = UDim2.new(1, -25, 0, 4), Size = UDim2.fromOffset(20, 28), TextXAlignment = Enum.TextXAlignment.Center }) end
   if entry.pending then
    Theme.label(button, "Waiting for replacement", 13, { TextColor3 = C.muted,
     Position = UDim2.fromOffset(10, 23), Size = UDim2.new(1, -20, 0, 18) })
   elseif entry.state then
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
function RosterPanel:refresh(entries, selected)
 self.entries, self.selected = entries, selected
 self:drawRoster()
end
function RosterPanel:notify(message, isError)
 self.footer.Text = message; self.footer.TextColor3 = isError and C.hp or C.light
end
function RosterPanel:destroy() self.root:Destroy() end
return RosterPanel
