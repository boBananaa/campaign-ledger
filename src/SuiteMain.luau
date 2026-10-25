-- One toolbar button opens the Campaign Tools launcher. Player features run independently.
if not plugin then return end
local WorldScope = require(script.Parent.WorldScope)
local LauncherPanel = require(script.Parent.LauncherPanel)
local LedgerSession = require(script.Parent.LedgerSession)
local DiceSession = require(script.Parent.DiceSession)
local ViewerSession = require(script.Parent.ViewerSession)
local ROLE_SETTING = "CampaignToolsDMEnabled"
local ok, saved = pcall(function() return plugin:GetSetting(ROLE_SETTING) end)
local dmEnabled = ok and saved == true
local scoped, alive = false, true
local stopLedger, stopDice, ledger, dice, viewer, launcher
local function refresh()
 if not launcher or not alive then return end
 launcher:refresh({ dmEnabled = dmEnabled, worldEnabled = WorldScope.isEnabled(), viewerReady = viewer ~= nil,
  turnVisible = not viewer or viewer.getVisible(), hoverOnly = not viewer or viewer.getHoverOnly() })
end
local function stopDM()
 ledger, dice = nil, nil
 if stopDice then local stop = stopDice; stopDice = nil; stop() end
 if stopLedger then local stop = stopLedger; stopLedger = nil; stop() end
end
local function startDM()
 if not alive or not scoped or not dmEnabled or stopLedger then return end
 stopLedger, ledger = LedgerSession.start(plugin, { launcher = true })
 stopDice, dice = DiceSession.start(plugin, { launcher = true })
end
local actions = {}
function actions.toggleDM()
 dmEnabled = not dmEnabled
 pcall(function() plugin:SetSetting(ROLE_SETTING, dmEnabled) end)
 if dmEnabled then startDM() else stopDM() end
 refresh()
end
function actions.toggleWorld()
 if not dmEnabled then return end
 local changed, message = WorldScope.setEnabled(plugin, not WorldScope.isEnabled())
 launcher:notify(changed and "World setting updated." or tostring(message))
end
function actions.toggleTurn()
 if viewer then viewer.setVisible(not viewer.getVisible()) end
end
function actions.toggleHover()
 if viewer then viewer.setHoverOnly(not viewer.getHoverOnly()) end
end
function actions.openLedger() if ledger then ledger.open() end end
function actions.openDice() if dice then dice.open() end end

local toolbar = plugin:CreateToolbar("Campaign Tools")
local button = toolbar:CreateButton("CampaignTools.Open", "Open Campaign Tools", "", "Campaign Tools")
button.ClickableWhenViewportHidden = true
local widget = WorldScope.widget(plugin, "CampaignTools.Launcher.v1", DockWidgetPluginGuiInfo.new(
 Enum.InitialDockState.Float, false, true, 350, 430, 320, 420))
widget.Title = "Campaign Tools"
launcher = LauncherPanel.new(widget, actions)
local click = button.Click:Connect(function() widget.Enabled = not widget.Enabled end)
local visibility = widget:GetPropertyChangedSignal("Enabled"):Connect(function() button:SetActive(widget.Enabled) end)
button:SetActive(widget.Enabled)
refresh()
local stopStatus = WorldScope.watch(refresh)
WorldScope.run(plugin, function()
 scoped = true
 local stopViewer
 stopViewer, viewer = ViewerSession.start(plugin, { launcher = true, onChanged = refresh })
 startDM()
 refresh()
 return function()
  scoped = false
  stopDM()
  viewer = nil
  stopViewer()
  refresh()
 end
end)
plugin.Unloading:Connect(function()
 alive = false
 click:Disconnect(); visibility:Disconnect(); stopStatus(); launcher:destroy(); toolbar:Destroy()
end)
