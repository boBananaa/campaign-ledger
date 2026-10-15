if not plugin then return end
local Theme = require(script.Parent.Theme)
local Turn = require(script.Parent.Turn)
local C = Theme.colors
local shared = game:GetService("ReplicatedStorage")
local coreGui = game:GetService("CoreGui")
local toolbar = plugin:CreateToolbar("Campaign Turn Watch")
local toggle = toolbar:CreateButton("CampaignTurnWatch.Open", "Show or hide combat turn text", "", "Turn Watch")
toggle.ClickableWhenViewportHidden = true
local overlayName = "CampaignLedgerTurnOverlay"
local previous = coreGui:FindFirstChild(overlayName)
if previous and previous:GetAttribute("CampaignLedgerOwned") then previous:Destroy() end
-- CoreGui is local Studio UI: this overlay never becomes part of the shared map.
local overlay = Theme.create("ScreenGui", { Name = overlayName, Enabled = false,
	ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
overlay:SetAttribute("CampaignLedgerOwned", true)
local phase = Theme.label(overlay, "", 28, { Name = "CombatTurn", Font = Theme.bold,
	TextColor3 = C.surface, TextStrokeColor3 = C.text, TextStrokeTransparency = 0.15,
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
	toggle:SetActive(visible)
end
local connection = shared:GetAttributeChangedSignal(Turn.attribute):Connect(refresh)
toggle.Click:Connect(function() visible = not visible; refresh() end)
refresh()
plugin.Unloading:Connect(function() connection:Disconnect(); overlay:Destroy(); toolbar:Destroy() end)
