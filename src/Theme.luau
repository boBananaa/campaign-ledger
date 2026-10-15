local Theme = {}
Theme.colors = {
	base = Color3.fromRGB(193, 182, 167), surface = Color3.fromRGB(216, 205, 187),
	field = Color3.fromRGB(229, 219, 201), text = Color3.fromRGB(56, 43, 34),
	muted = Color3.fromRGB(91, 74, 61), hp = Color3.fromRGB(151, 55, 44),
	mana = Color3.fromRGB(64, 91, 90), ap = Color3.fromRGB(106, 74, 42),
	line = Color3.fromRGB(120, 99, 78), track = Color3.fromRGB(159, 145, 124),
	accent = Color3.fromRGB(151, 55, 44),
}
Theme.font = Enum.Font.SourceSans
Theme.bold = Enum.Font.SourceSansSemibold
Theme.display = Enum.Font.Fondamento

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
	button:SetAttribute("ThemeSelectedColor", color or Theme.colors.text)
	button.BackgroundColor3 = selected and (color or Theme.colors.text) or button:GetAttribute("ThemeBackground")
	button.TextColor3 = selected and Theme.colors.field or button:GetAttribute("ThemeForeground")
	button:FindFirstChildOfClass("UIStroke").Color = selected and (color or Theme.colors.text) or Theme.colors.line
end

function Theme.button(parent, text, props)
	local settings = { BackgroundColor3 = Theme.colors.surface, BorderSizePixel = 0,
		Text = text, TextColor3 = Theme.colors.text, TextSize = 16, Font = Theme.bold,
		AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 32), Selectable = true }
	for key, value in pairs(props or {}) do settings[key] = value end
	local button = Theme.create("TextButton", settings, parent)
	button:SetAttribute("ThemeBackground", settings.BackgroundColor3)
	button:SetAttribute("ThemeForeground", settings.TextColor3)
	local stroke = Theme.stroke(button)
	local hovered, focused = false, false
	local function paint()
		local selected = button:GetAttribute("ThemeSelected")
		local color = selected and button:GetAttribute("ThemeSelectedColor") or button:GetAttribute("ThemeBackground")
		button.BackgroundColor3 = hovered and color:Lerp(Theme.colors.text, 0.08) or color
		stroke.Color = (hovered or focused) and Theme.colors.accent or selected and color or Theme.colors.line
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
