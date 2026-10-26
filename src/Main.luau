-- Campaign Ledger: Studio edit-mode plugin. Ordinary runtime Scripts do nothing.
if not plugin then
	warn("Campaign Ledger: select this Script and use Plugins > Save as Local Plugin.")
	return
end

local WorldScope = require(script.Parent.WorldScope)

local setupToolbar = plugin:CreateToolbar("Campaign setup")
local worldToggle = setupToolbar:CreateButton("CampaignLedger.World", "Enable or disable D&D tools in this saved world for installed viewers", "", "D&D world")
worldToggle.ClickableWhenViewportHidden = true
local stopWorldStatus = WorldScope.watch(function(enabled) worldToggle:SetActive(enabled) end)
local setupClick = worldToggle.Click:Connect(function()
 local ok, message = WorldScope.setEnabled(plugin, not WorldScope.isEnabled())
 if not ok then warn("Campaign Ledger: " .. tostring(message)) end
end)
plugin.Unloading:Connect(function() setupClick:Disconnect(); stopWorldStatus(); setupToolbar:Destroy() end)

local LedgerSession = require(script.Parent.LedgerSession)
local PoseSession = require(script.Parent.PoseSession)
WorldScope.run(plugin, function()
 local stopPose, pose = PoseSession.start(plugin)
 local stopLedger = LedgerSession.start(plugin, { pose = pose })
 return function() stopLedger(); stopPose() end
end)
