if not plugin then return end
local Theme = require(script.Parent.Theme)
local Dice = require(script.Parent.Dice)
local C = Theme.colors
local toolbar = plugin:CreateToolbar("Campaign D20")
local toggle = toolbar:CreateButton("CampaignD20.Open", "Open the DM's D20 roller", "", "D20 Roller")
toggle.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync("CampaignD20.v1", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, true, false, 380, 590, 320, 320))
widget.Title = "D20 Roller"
local viewport = Theme.create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.base,
	BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap, ScrollingDirection = Enum.ScrollingDirection.Y }, widget)
local root = Theme.create("Frame", { Name = "D20Roller", BackgroundTransparency = 1,
	Size = UDim2.new(1, -4, 0, 610) }, viewport)
Theme.label(root, "D20 Roller", 26, { Font = Theme.display, TextColor3 = C.accent,
	Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 34), TextXAlignment = Enum.TextXAlignment.Center })
Theme.rule(root, { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 1) })
local mode, modes = "normal", {}
local modeGroup = Theme.create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 32) }, root)
for index, value in ipairs({ "normal", "advantage", "disadvantage" }) do
	local label = value:sub(1, 1):upper() .. value:sub(2)
	local button = Theme.button(modeGroup, label, { Position = UDim2.new((index - 1) / 3, (index - 1) * 2, 0, 0),
		Size = UDim2.new(1 / 3, -4, 0, 32), TextSize = 14 })
	modes[value] = button
	button.Activated:Connect(function()
		mode = value
		for key, other in pairs(modes) do Theme.select(other, key == mode) end
	end)
end
Theme.select(modes.normal, true)
Theme.label(root, "Modifier", 16, { Position = UDim2.fromOffset(12, 109), Size = UDim2.new(1, -112, 0, 32) })
local modifier = Theme.input(root, "+0", { Name = "Modifier", Text = "0", TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.new(1, -100, 0, 109), Size = UDim2.fromOffset(88, 32) })
local well = Theme.create("Frame", { Name = "RollResult", BackgroundColor3 = C.field, BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 158), Size = UDim2.new(1, -24, 0, 198) }, root)
Theme.stroke(well)
Theme.corners(well, C.accent, 12)
local result = Theme.label(well, "—", 80, { Name = "Total", Font = Theme.bold, TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 98) })
local detail = Theme.label(well, "Roll when you’re ready.", 16, { Name = "Breakdown", TextWrapped = true,
	TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromOffset(12, 110), Size = UDim2.new(1, -24, 0, 46) })
local natural = Theme.label(well, "", 18, { Name = "NaturalRoll", Font = Theme.bold, TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(12, 164), Size = UDim2.new(1, -24, 0, 24) })
local rollButton = Theme.button(root, "Roll D20", { BackgroundColor3 = C.accent, TextColor3 = C.field,
	Position = UDim2.fromOffset(12, 368), Size = UDim2.new(1, -24, 0, 40), TextSize = 20 })
Theme.rule(root, { Position = UDim2.fromOffset(12, 428), Size = UDim2.new(1, -24, 0, 1) })
Theme.label(root, "Recent rolls", 17, { Font = Theme.bold, Position = UDim2.fromOffset(12, 438), Size = UDim2.new(1, -24, 0, 24) })
local history = Theme.create("ScrollingFrame", { Name = "RollHistory", BackgroundTransparency = 1, BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 470), Size = UDim2.new(1, -24, 0, 128), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 3, ScrollBarImageColor3 = C.ap }, root)
Theme.create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, history)
local historyRows = {}
local function drawHistory(recent)
	for _, row in ipairs(historyRows) do row:Destroy() end
	historyRows = {}
	if #recent == 0 then
		table.insert(historyRows, Theme.label(history, "No rolls yet.", 14, { TextColor3 = C.muted }))
	end
	for index, value in ipairs(recent) do
		local row = Theme.label(history, value.mode .. ": " .. Dice.describe(value), 14, {
			Name = "RecentRoll" .. index, TextColor3 = index == 1 and C.text or C.muted,
			Font = index == 1 and Theme.bold or Theme.font, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = index,
			Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		table.insert(historyRows, row)
	end
	history.CanvasPosition = Vector2.zero
end
local random, recent = Random.new(), {}
drawHistory(recent)
local function roll()
	local value, message = Dice.roll(random, mode, modifier.Text)
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
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() widget:Destroy(); toolbar:Destroy() end)
