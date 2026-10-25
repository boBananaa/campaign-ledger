local WorldScope = require(script.Parent.WorldScope)
local ViewerSession = {}
function ViewerSession.start(plugin, options)
options = options or {}
local Theme = require(script.Parent.Theme)
local Turn = require(script.Parent.Turn)
local Hover = require(script.Parent.Hover)
local C = Theme.colors
local shared = game:GetService("ReplicatedStorage")
local coreGui = game:GetService("CoreGui")
local toolbar, toggle, hoverToggle
if not options.launcher then
 toolbar = WorldScope.toolbar(plugin, "Campaign Turn Watch")
 toggle = WorldScope.button(plugin, toolbar, "CampaignTurnWatch.Open", "Show or hide combat turn text", "", "Turn Watch")
 toggle.ClickableWhenViewportHidden = true
 hoverToggle = WorldScope.button(plugin, toolbar, "CampaignTurnWatch.Hover", "Show character stats only while hovering", "", "Hover plates")
 hoverToggle.ClickableWhenViewportHidden = true
end
local function changed() if options.onChanged then options.onChanged() end end
local hover = Hover.start(plugin, function(value)
 if hoverToggle then hoverToggle:SetActive(value) end
 changed()
end)
local hoverClick
if hoverToggle then
 hoverToggle:SetActive(hover:getHoverOnly())
 hoverClick = hoverToggle.Click:Connect(function() hover:setHoverOnly(not hover:getHoverOnly()) end)
end
local overlayName = "CampaignLedgerTurnOverlay"
local previous = coreGui:FindFirstChild(overlayName)
if previous and previous:GetAttribute("CampaignLedgerOwned") then previous:Destroy() end
-- CoreGui is local Studio UI: this overlay never becomes part of the shared map.
local overlay = Theme.create("ScreenGui", { Name = overlayName, Enabled = false,
	ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
overlay:SetAttribute("CampaignLedgerOwned", true)
local phase = Theme.label(overlay, "", 28, { Name = "CombatTurn", Font = Theme.display,
	TextColor3 = C.text, TextStrokeColor3 = C.shell, TextStrokeTransparency = 0.15,
	TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.new(1, -32, 0, 40), Active = false, Selectable = false })
overlay.Parent = coreGui
local visible = true
local function refresh()
	local side = shared:GetAttribute(Turn.attribute)
	local title = Turn.view(side)
	phase.Text = title
	overlay.Enabled = visible and Turn.isActive(side)
	if toggle then toggle:SetActive(visible) end
 changed()
end
local connection = shared:GetAttributeChangedSignal(Turn.attribute):Connect(refresh)
local toggleClick
if toggle then toggleClick = toggle.Click:Connect(function() visible = not visible; refresh() end) end
refresh()
local alive = true
local function stop()
 alive = false
 connection:Disconnect()
 if hoverClick then hoverClick:Disconnect() end
 if toggleClick then toggleClick:Disconnect() end
 hover:destroy(); overlay:Destroy()
 if toolbar then WorldScope.pauseToolbar(plugin, toolbar) end
end
return stop, {
 getVisible = function() return visible end,
 setVisible = function(value) if alive then visible = value == true; refresh() end end,
 getHoverOnly = function() return hover:getHoverOnly() end,
 getPlatesVisible = function() return hover:getPlatesVisible() end,
 setPlatesVisible = function(value) if alive then hover:setPlatesVisible(value) end end,
 setHoverOnly = function(value) if alive then hover:setHoverOnly(value) end end,
}
end
return ViewerSession
