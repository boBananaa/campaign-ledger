local DicePanel = require(script.Parent.DicePanel)
local WorldScope = require(script.Parent.WorldScope)
local DiceSession = {}
function DiceSession.start(plugin, options)
 options = options or {}
 local toolbar, toggle
 if not options.launcher then
  toolbar = WorldScope.toolbar(plugin, "Campaign D20")
  toggle = WorldScope.button(plugin, toolbar, "CampaignD20.Open", "Open the DM's D20 roller", "", "D20 Roller")
  toggle.ClickableWhenViewportHidden = true
 end
 local widget = WorldScope.widget(plugin, "CampaignD20.v1", DockWidgetPluginGuiInfo.new(
  Enum.InitialDockState.Float, false, true, 380, 475, 320, 320))
 widget.Title = "D20 Roller"
 local content = DicePanel.new(widget, Random.new())
 local click, visibility
 if toggle then
  click = toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
  visibility = widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
  toggle:SetActive(widget.Enabled)
 end
 local alive = true
 local function stop()
  alive = false
  if click then click:Disconnect(); visibility:Disconnect() end
  content:Destroy(); widget.Enabled = false
  if toolbar then WorldScope.pauseToolbar(plugin, toolbar) end
 end
 return stop, { open = function() if alive then widget.Enabled = true end end }
end
return DiceSession
