-- Layout limits shared by the UI and regression checks.
local Layout = {}
function Layout.split(height, requested)
	local maximum = math.max(200, height - 260)
	return math.clamp(requested, 200, maximum)
end
Layout.editorPadding = 8
Layout.headingHeight = 74
Layout.selectButtonTop = 42
Layout.selectButtonHeight = 30
return Layout
