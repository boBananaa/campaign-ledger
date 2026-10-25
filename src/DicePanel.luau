local Theme = require(script.Parent.Theme)
local Dice = require(script.Parent.Dice)
local C = Theme.colors
local DicePanel = {}
function DicePanel.new(widget, random)
local viewport = Theme.create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.shell,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3, ScrollBarImageColor3 = C.light, ScrollingDirection = Enum.ScrollingDirection.Y }, widget)
local root = Theme.create("Frame", { Name = "D20Roller", BorderSizePixel = 0, BackgroundColor3 = C.shell,
	Size = UDim2.new(1, -4, 0, 453) }, viewport)
Theme.label(root, "D20 Roller", 26, { Font = Theme.display, TextColor3 = C.text,
	Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 34), TextXAlignment = Enum.TextXAlignment.Center })
local binding = Theme.create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 1) }, root)
Theme.junction(binding, 0)
Theme.label(root, "Modifier", 16, { TextColor3 = C.text, Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -112, 0, 32) })
local modifier = Theme.input(root, "+0", { Name = "Modifier", Text = "0", TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.new(1, -100, 0, 64), Size = UDim2.fromOffset(88, 32) })
local well = Theme.create("Frame", { Name = "RollResult", BackgroundColor3 = C.field, BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 113), Size = UDim2.new(1, -24, 0, 142) }, root)
Theme.stroke(well)
Theme.corners(well, C.accent, 12)
local result = Theme.label(well, "—", 64, { Name = "Total", Font = Theme.bold, TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 72) })
local detail = Theme.label(well, "Roll when you’re ready.", 16, { Name = "Breakdown", TextWrapped = true,
	TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromOffset(12, 78), Size = UDim2.new(1, -24, 0, 32) })
local natural = Theme.label(well, "", 18, { Name = "NaturalRoll", Font = Theme.bold, TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(12, 114), Size = UDim2.new(1, -24, 0, 24) })
local rollButton = Theme.button(root, "Roll D20", { Name = "RollD20", BackgroundColor3 = C.active, TextColor3 = C.text,
	Position = UDim2.fromOffset(12, 267), Size = UDim2.new(1, -24, 0, 40), TextSize = 20 })
Theme.rule(root, { Position = UDim2.fromOffset(12, 319), Size = UDim2.new(1, -24, 0, 1) })
Theme.label(root, "Recent rolls", 17, { Font = Theme.bold, TextColor3 = C.text, Position = UDim2.fromOffset(12, 329), Size = UDim2.new(1, -24, 0, 24) })
local history = Theme.create("ScrollingFrame", { Name = "RollHistory", BackgroundTransparency = 1, BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 359), Size = UDim2.new(1, -24, 0, 82), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 3, ScrollBarImageColor3 = C.light }, root)
Theme.create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, history)
local historyRows = {}
local function drawHistory(recent)
	for _, row in ipairs(historyRows) do row:Destroy() end
	historyRows = {}
	if #recent == 0 then
		table.insert(historyRows, Theme.label(history, "No rolls yet.", 14, { TextColor3 = C.light }))
	end
	for index, value in ipairs(recent) do
		local row = Theme.label(history, Dice.describe(value), 14, {
			Name = "RecentRoll" .. index, TextColor3 = index == 1 and C.text or C.light,
			Font = index == 1 and Theme.bold or Theme.font, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = index,
			Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		table.insert(historyRows, row)
	end
	history.CanvasPosition = Vector2.zero
end
local recent = {}
drawHistory(recent)
local function roll()
	local value, message = Dice.roll(random, "normal", modifier.Text)
	if not value then detail.Text = message; detail.TextColor3 = C.hp; return end
	result.Text = tostring(value.total)
	detail.Text, detail.TextColor3 = Dice.describe(value), C.text
	natural.Text = value.natural == 20 and "Natural 20" or value.natural == 1 and "Natural 1" or ""
	table.insert(recent, 1, value)
	if #recent > 5 then table.remove(recent) end
	drawHistory(recent)
end
rollButton.Activated:Connect(roll)
modifier.FocusLost:Connect(function(enter) if enter then roll() end end)
 return viewport
end
return DicePanel
