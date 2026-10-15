local Theme = {}
Theme.colors = {
	base = Color3.fromRGB(193, 182, 167), surface = Color3.fromRGB(216, 205, 187),
	text = Color3.fromRGB(56, 43, 34), muted = Color3.fromRGB(91, 74, 61),
	hp = Color3.fromRGB(151, 55, 44), mana = Color3.fromRGB(64, 91, 90),
	ap = Color3.fromRGB(106, 74, 42), line = Color3.fromRGB(120, 99, 78),
	track = Color3.fromRGB(159, 145, 124), accent = Color3.fromRGB(151, 55, 44),
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

function Theme.label(parent, text, size, props)
	local settings = { BackgroundTransparency = 1, BorderSizePixel = 0, Text = text,
		TextColor3 = Theme.colors.text, TextSize = size or 16, Font = Theme.font,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 24), RichText = false }
	for key, value in pairs(props or {}) do settings[key] = value end
	return Theme.create("TextLabel", settings, parent)
end

function Theme.button(parent, text, props)
	local settings = { BackgroundColor3 = Theme.colors.surface, BorderSizePixel = 0,
		Text = text, TextColor3 = Theme.colors.text, TextSize = 16, Font = Theme.bold,
		AutoButtonColor = true, Size = UDim2.new(1, 0, 0, 34), Selectable = true }
	for key, value in pairs(props or {}) do settings[key] = value end
	local button = Theme.create("TextButton", settings, parent)
	Theme.stroke(button)
	button.SelectionGained:Connect(function() button:FindFirstChildOfClass("UIStroke").Color = Theme.colors.accent end)
	button.SelectionLost:Connect(function() button:FindFirstChildOfClass("UIStroke").Color = Theme.colors.line end)
	return button
end

function Theme.input(parent, placeholder, props)
	local settings = { BackgroundColor3 = Theme.colors.surface, BorderSizePixel = 0,
		Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Theme.colors.muted,
		TextColor3 = Theme.colors.text, TextSize = 17, Font = Theme.font,
		ClearTextOnFocus = false, Size = UDim2.new(1, 0, 0, 34),
		TextXAlignment = Enum.TextXAlignment.Left }
	for key, value in pairs(props or {}) do settings[key] = value end
	local input = Theme.create("TextBox", settings, parent)
	local stroke = Theme.stroke(input)
	Theme.create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, input)
	input.Focused:Connect(function() stroke.Color = Theme.colors.accent end)
	input.FocusLost:Connect(function() stroke.Color = Theme.colors.line end)
	return input
end

return Theme
