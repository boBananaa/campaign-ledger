-- Shared opt-in belongs to a saved place. Plugin installation remains per editor.
local WorldScope = {}
WorldScope.enabledAttribute = "CampaignLedgerEnabled"
WorldScope.placeAttribute = "CampaignLedgerPlaceId"

function WorldScope.matches(placeId, enabled, assignedPlaceId)
 return type(placeId) == "number" and placeId > 0 and placeId < math.huge and placeId % 1 == 0
  and enabled == true and type(assignedPlaceId) == "number" and assignedPlaceId == placeId
end

function WorldScope.isEnabled()
 local shared = game:GetService("ReplicatedStorage")
 return WorldScope.matches(game.PlaceId, shared:GetAttribute(WorldScope.enabledAttribute), shared:GetAttribute(WorldScope.placeAttribute))
end

function WorldScope.setEnabled(plugin, enabled)
 if game:GetService("RunService"):IsRunning() then return false, "Stop Play mode before changing the D&D world setting." end
 if not WorldScope.matches(game.PlaceId, true, game.PlaceId) then
  return false, "Save this place to Roblox first, then enable D&D here."
 end
 local history, shared = game:GetService("ChangeHistoryService"), game:GetService("ReplicatedStorage")
 local recording = history:TryBeginRecording(enabled and "Enable D&D in this world" or "Disable D&D in this world")
 if not recording then return false, "Finish the current Studio edit, then try again." end
 local oldEnabled, oldPlace = shared:GetAttribute(WorldScope.enabledAttribute), shared:GetAttribute(WorldScope.placeAttribute)
 local ok, message = pcall(function()
  if enabled then shared:SetAttribute(WorldScope.placeAttribute, game.PlaceId) end
  shared:SetAttribute(WorldScope.enabledAttribute, enabled == true)
 end)
 if not ok then
  shared:SetAttribute(WorldScope.placeAttribute, oldPlace)
  shared:SetAttribute(WorldScope.enabledAttribute, oldEnabled)
 end
 history:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
 return ok, message
end

-- Changes can arrive from another Team Create editor or Undo. Coalesce both attributes
-- so activation never runs in the middle of the enable/disable undo recording.
function WorldScope.watch(callback)
 local shared = game:GetService("ReplicatedStorage")
 local alive, queued, previous = true, false, nil
 local function update()
  if not alive then return end
  local enabled = WorldScope.isEnabled()
  if enabled ~= previous then previous = enabled; callback(enabled) end
 end
 local function schedule()
  if queued or not alive then return end
  queued = true
  task.defer(function() queued = false; update() end)
 end
 local connections = {
  shared:GetAttributeChangedSignal(WorldScope.enabledAttribute):Connect(schedule),
  shared:GetAttributeChangedSignal(WorldScope.placeAttribute):Connect(schedule),
  game:GetPropertyChangedSignal("PlaceId"):Connect(schedule),
 }
 update()
 return function()
  alive = false
  for _, connection in ipairs(connections) do connection:Disconnect() end
 end
end

-- Studio reserves toolbar/action IDs for the plugin lifetime even after Destroy.
-- Reuse native handles across world toggles; pause their buttons and clear content.
local resources = {}
local function owned(plugin)
 if not resources[plugin] then resources[plugin] = { toolbars = {}, buttons = {}, widgets = {}, actions = {} } end
 return resources[plugin]
end
function WorldScope.toolbar(plugin, name)
 local r = owned(plugin)
 if not r.toolbars[name] then
  r.toolbars[name] = plugin:CreateToolbar(name)
  r.buttons[r.toolbars[name]] = {}
 end
 return r.toolbars[name]
end
function WorldScope.button(plugin, toolbar, id, tooltip, icon, text)
 local buttons = owned(plugin).buttons[toolbar]
 if not buttons[id] then buttons[id] = toolbar:CreateButton(id, tooltip, icon, text) end
 buttons[id].Enabled = true
 return buttons[id]
end
function WorldScope.pauseToolbar(plugin, toolbar)
 for _, button in pairs(owned(plugin).buttons[toolbar]) do button:SetActive(false); button.Enabled = false end
end
function WorldScope.widget(plugin, id, info)
 local r = owned(plugin)
 if not r.widgets[id] then r.widgets[id] = plugin:CreateDockWidgetPluginGuiAsync(id, info) end
 r.widgets[id].Enabled = false
 return r.widgets[id]
end
function WorldScope.action(plugin, id, title, description, icon, allowBinding)
 local actions = owned(plugin).actions
 if not actions[id] then actions[id] = plugin:CreatePluginAction(id, title, description, icon, allowBinding) end
 return actions[id]
end
local function dispose(plugin)
 local r = resources[plugin]
 if not r then return end
 for _, widget in pairs(r.widgets) do widget:Destroy() end
 for _, action in pairs(r.actions) do action:Destroy() end
 for _, buttons in pairs(r.buttons) do for _, button in pairs(buttons) do button:Destroy() end end
 for _, toolbar in pairs(r.toolbars) do toolbar:Destroy() end
 resources[plugin] = nil
end

-- A session owns its widgets, hover viewer and listeners. Unmarked places get none.
function WorldScope.run(plugin, startSession)
 local stopSession, alive = nil, true
 local function stop()
  if stopSession then local cleanup = stopSession; stopSession = nil; cleanup() end
 end
 local stopWatching = WorldScope.watch(function(enabled)
  if not alive then return end
  if enabled and not stopSession then stopSession = startSession() elseif not enabled then stop() end
 end)
 local unloading
 local function destroy()
  if not alive then return end
  alive = false
  stopWatching(); stop(); dispose(plugin)
  if unloading then unloading:Disconnect() end
 end
 unloading = plugin.Unloading:Connect(destroy)
 return destroy
end
return WorldScope
