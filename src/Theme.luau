local Theme = {}
-- Approved palette C: ash and burgundy. Surfaces and text have separate roles.
Theme.colors = {
	base = Color3.fromRGB(40, 32, 42),
	surface = Color3.fromRGB(60, 48, 59),
	field = Color3.fromRGB(75, 59, 72),
	text = Color3.fromRGB(238, 230, 225),
	muted = Color3.fromRGB(197, 181, 192),
	hp = Color3.fromRGB(231, 161, 161),
	mana = Color3.fromRGB(182, 190, 223),
	ap = Color3.fromRGB(218, 201, 176),
	line = Color3.fromRGB(133, 108, 125),
	track = Color3.fromRGB(40, 31, 40),
	accent = Color3.fromRGB(213, 161, 178),
	shell = Color3.fromRGB(37, 28, 37),
	edge = Color3.fromRGB(110, 85, 103),
	light = Color3.fromRGB(203, 188, 198),
	selection = Color3.fromRGB(100, 67, 79),
	active = Color3.fromRGB(107, 75, 90),
	enemyActive = Color3.fromRGB(112, 68, 75),
}
Theme.font = Enum.Font.SourceSans
Theme.bold = Enum.Font.SourceSansSemibold
Theme.display = Enum.Font.Garamond

function Theme.create(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end

function Theme.stroke(parent, color)
	return Theme.create("UIStroke", { Color = color or Theme.colors.line, Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

function Theme.rule(parent, props)
	local settings = { Name = "Rule", BackgroundColor3 = Theme.colors.line,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Active = false, Selectable = false }
	for key, value in pairs(props or {}) do settings[key] = value end
	return Theme.create("Frame", settings, parent)
end

-- Small square corner brackets mark the character sheet and dice result, not every control.
function Theme.corners(parent, color, length)
	local size = length or 7
	for _, corner in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local anchor = Vector2.new(corner[1], corner[2])
		local position = UDim2.fromScale(corner[1], corner[2])
		Theme.rule(parent, { Name = "CornerHorizontal", BackgroundColor3 = color or Theme.colors.line,
			AnchorPoint = anchor, Position = position, Size = UDim2.fromOffset(size, 1) })
		Theme.rule(parent, { Name = "CornerVertical", BackgroundColor3 = color or Theme.colors.line,
			AnchorPoint = anchor, Position = position, Size = UDim2.fromOffset(1, size) })
	end
end

function Theme.junction(parent, y)
	for _, side in ipairs({ { 0, 0 }, { 0.5, 12 } }) do
		Theme.rule(parent, { BackgroundColor3 = Theme.colors.edge,
			Position = UDim2.new(side[1], side[2], 0, y), Size = UDim2.new(0.5, -12, 0, 1) })
	end
	local diamond = Theme.create("Frame", { Name = "BindingJunction", BackgroundTransparency = 1,
		BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, y),
		Size = UDim2.fromOffset(5, 5), Rotation = 45, Active = false, Selectable = false }, parent)
	Theme.stroke(diamond, Theme.colors.light)
end

function Theme.enable(button, enabled)
	button:SetAttribute("ThemeEnabled", enabled)
	button.Active, button.Selectable, button.Interactable = enabled, enabled, enabled
	button.TextTransparency = enabled and 0 or 0.55
end

function Theme.label(parent, text, size, props)
	local settings = { BackgroundTransparency = 1, BorderSizePixel = 0, Text = text,
		TextColor3 = Theme.colors.text, TextSize = size or 16, Font = Theme.font,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 24), RichText = false, Active = false, Selectable = false }
	for key, value in pairs(props or {}) do settings[key] = value end
	return Theme.create("TextLabel", settings, parent)
end

function Theme.select(button, selected, color)
	button:SetAttribute("ThemeSelected", selected)
	button:SetAttribute("ThemeSelectedColor", color or Theme.colors.active)
	button.BackgroundColor3 = selected and (color or Theme.colors.active) or button:GetAttribute("ThemeBackground")
	button.TextColor3 = selected and Theme.colors.text or button:GetAttribute("ThemeForeground")
	button:FindFirstChildOfClass("UIStroke").Color = Theme.colors.line
end

function Theme.button(parent, text, props)
	local settings = { BackgroundColor3 = Theme.colors.field, BorderSizePixel = 0,
		Text = text, TextColor3 = Theme.colors.text, TextSize = 16, Font = Theme.bold,
		AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 32), Selectable = true }
	for key, value in pairs(props or {}) do settings[key] = value end
	local button = Theme.create("TextButton", settings, parent)
	button:SetAttribute("ThemeBackground", settings.BackgroundColor3)
	button:SetAttribute("ThemeForeground", settings.TextColor3)
	local stroke = Theme.stroke(button)
	local hovered, focused = false, false
	local function paint()
		if button:GetAttribute("ThemeEnabled") == false then return end
		local selected = button:GetAttribute("ThemeSelected")
		local color = selected and button:GetAttribute("ThemeSelectedColor") or button:GetAttribute("ThemeBackground")
		button.BackgroundColor3 = hovered and color:Lerp(Theme.colors.text, 0.08) or color
		stroke.Color = (hovered or focused) and Theme.colors.accent or Theme.colors.line
	end
	button.MouseEnter:Connect(function() hovered = true; paint() end)
	button.MouseLeave:Connect(function() hovered = false; paint() end)
	button.SelectionGained:Connect(function() focused = true; paint() end)
	button.SelectionLost:Connect(function() focused = false; paint() end)
	return button
end

function Theme.input(parent, placeholder, props)
	local settings = { BackgroundColor3 = Theme.colors.field, BorderSizePixel = 0,
		Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Theme.colors.muted,
		TextColor3 = Theme.colors.text, TextSize = 17, Font = Theme.font,
		ClearTextOnFocus = false, Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left }
	for key, value in pairs(props or {}) do settings[key] = value end
	local input = Theme.create("TextBox", settings, parent)
	local stroke = Theme.stroke(input)
	Theme.create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, input)
	input.Focused:Connect(function() stroke.Color = Theme.colors.accent; stroke.Thickness = 2 end)
	input.FocusLost:Connect(function() stroke.Color = Theme.colors.line; stroke.Thickness = 1 end)
	return input
end

return Theme
