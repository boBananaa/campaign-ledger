local PoseStore = require(script.Parent.PoseStore)
local PosePanel = require(script.Parent.PosePanel)
local WorldScope = require(script.Parent.WorldScope)
local Registry = require(script.Parent.Registry)
local State = require(script.Parent.State)
local Names = require(script.Parent.Names)
local PoseSession = {}
function PoseSession.start(plugin, onChanged)
 local store = PoseStore.new(plugin)
 local selection, world = game:GetService("Selection"), game:GetService("Workspace")
 local shared, history = game:GetService("ReplicatedStorage"), game:GetService("ChangeHistoryService")
 local input = game:GetService("UserInputService")
 local alive, queued, ticket = true, false, 0
 local panel, widget, message, errorFlag
 local links, observed, recent = {}, {}, {}
 local pasteUntil = 0
 local confirmation
 local refresh, schedule
 local function connect(signal, callback) table.insert(links, signal:Connect(callback)) end
 local function picked() local items = selection:Get(); return #items == 1 and items[1] or nil end
 local function notify(text, isError)
  message, errorFlag = text, isError
  if panel then panel:notify(text, isError) end
  if onChanged then onChanged() end
 end
 refresh = function()
  if not alive then return end
  local pending, target = store:mine(), picked()
  local present = {}
  for _, record in ipairs(PoseStore.records()) do
   present[record] = true
   if not observed[record] then
    observed[record] = {
     record:GetAttributeChangedSignal(PoseStore.stateAttribute):Connect(schedule),
     record:GetAttributeChangedSignal(PoseStore.nameAttribute):Connect(schedule),
     record.AncestryChanged:Connect(schedule),
    }
   end
  end
  for record, connections in pairs(observed) do
   if not present[record] then for _, link in ipairs(connections) do link:Disconnect() end; observed[record] = nil end
  end
  if panel then
   local state, canApply, canCancel
   if pending then
    state = PoseStore.read(pending)
    canApply = store:candidate(pending, target, false, true) ~= nil
    local source = PoseStore.source(pending)
    canCancel = source ~= nil and source:IsDescendantOf(world) and not source:HasTag(Registry.tag)
   else
    local source = target and Registry.registeredAncestor(target, world)
    if source then
     local ok, saved = pcall(function() return game:GetService("HttpService"):JSONDecode(source:GetAttribute(PoseStore.stateAttribute)) end)
     if ok and State.validate(saved) then state = Names.apply(source, saved); canApply = true end
    end
   end
   local summary = state and string.format("Health %d / %d   Mana %d / %d   AP %d / %d", state.hp.current, state.hp.maximum,
    state.mana.current, state.mana.maximum, state.ap.current, state.ap.maximum) or ""
   panel:refresh({ pending = pending ~= nil, name = state and state.name, summary = summary,
    target = target and target.Name, canApply = canApply == true, canCancel = canCancel == true,
    confirming = confirmation ~= nil })
   if message then panel:notify(message, errorFlag) end
  end
  if onChanged then onChanged() end
 end
 schedule = function()
  if queued or not alive then return end
  queued = true
  task.defer(function() queued = false; if alive then refresh() end end)
 end
 local function finish(automatic, replaceExisting)
  local pending = store:mine()
  if not pending then return end
  local ok, text, target = store:apply(pending, picked(), automatic, replaceExisting)
  confirmation = nil
  notify(text, not ok)
  if ok then ticket += 1; recent = {}; pasteUntil = 0; selection:Set({ target }) end
  schedule()
 end
 local function open()
  if not widget then
   widget = WorldScope.widget(plugin, "CampaignTools.Pose.v1", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 360, 410, 320, 400))
   widget.Title = "Pose Change"
  end
  if not panel then
   panel = PosePanel.new(widget, {
    primary = function()
     if store:mine() then
      local pending, item = store:mine(), picked()
      local safe = store:candidate(pending, item, false)
      local target = store:candidate(pending, item, false, true)
      if not safe and target then
       local raw, id = target:GetAttribute(PoseStore.stateAttribute), target:GetAttribute(Registry.idAttribute)
       if confirmation and confirmation.target == target and confirmation.raw == raw and confirmation.id == id and confirmation.record == pending then
        finish(false, true)
       else
        confirmation = { target = target, raw = raw, id = id, record = pending }
        notify("This model already has a registration. Click Confirm replacement to replace it; its previous stats will be backed up.")
        schedule()
       end
      else finish(false) end
     else
      local record, text = store:begin(picked()); notify(text, record == nil); ticket += 1; recent = {}; pasteUntil = 0; schedule()
     end
    end,
    cancel = function() confirmation = nil; local record = store:mine(); if record then local ok, text = store:cancel(record); notify(text, not ok); ticket += 1; recent = {}; pasteUntil = 0; schedule() end end,
   })
  end
  widget.Enabled = true; refresh()
 end
 local function selectionChanged()
  ticket += 1
  confirmation = nil
  local request = ticket
  schedule()
  task.defer(function()
   if not alive or request ~= ticket or not store:mine() then return end
   local item = picked()
   local target = item and (item:IsA("Model") or item:IsA("BasePart")) and Registry.character(item)
   if target and recent[target] and os.clock() <= pasteUntil and store:candidate(store:mine(), item, true) then
    pasteUntil = 0; finish(true)
   end
  end)
 end
 connect(selection.SelectionChanged, selectionChanged)
 connect(input.InputBegan, function(key, processed)
  if processed or not store:mine() or key.KeyCode ~= Enum.KeyCode.V or input:GetFocusedTextBox() then return end
  if input:IsKeyDown(Enum.KeyCode.LeftControl) or input:IsKeyDown(Enum.KeyCode.RightControl)
   or input:IsKeyDown(Enum.KeyCode.LeftMeta) or input:IsKeyDown(Enum.KeyCode.RightMeta) then pasteUntil = os.clock() + 5 end
 end)
 connect(history.OnRecordingFinished, function(name, displayName, _, operation)
  if operation == Enum.FinishRecordingOperation.Commit and store:mine()
   and (string.lower(name or ""):find("paste", 1, true) or string.lower(displayName or ""):find("paste", 1, true)) then
   pasteUntil = os.clock() + 5; selectionChanged()
  end
 end)
 connect(world.DescendantAdded, function(item)
  if store:mine() and (item:IsA("Model") or item:IsA("BasePart")) then recent[item] = true end
 end)
 connect(world.DescendantRemoving, schedule)
 connect(shared.DescendantAdded, schedule); connect(shared.DescendantRemoving, schedule)
 local function undoRedo() ticket += 1; recent = {}; pasteUntil = 0; confirmation = nil; message = nil; schedule() end
 connect(history.OnUndo, undoRedo); connect(history.OnRedo, undoRedo)
 refresh()
 local controller = {}
 function controller.open() open() end
 function controller.begin(character)
  confirmation = nil
  open()
  if PoseStore.isRecord(character) and character:GetAttribute("OwnerUserId") ~= store.userId then
   notify("The editor who started this pose change must finish it. DM combat edits are still available.", true)
   return
  end
  if character and not PoseStore.isRecord(character) then
   local record, text = store:begin(character); notify(text, record == nil); ticket += 1; recent = {}; pasteUntil = 0; schedule()
  end
 end
 function controller.pending() return store:mine() end
 local function stop()
  alive = false; ticket += 1
  for _, link in ipairs(links) do link:Disconnect() end
  for _, connections in pairs(observed) do for _, link in ipairs(connections) do link:Disconnect() end end
  if panel then panel:destroy() end
  if widget then widget.Enabled = false end
 end
 return stop, controller
end
return PoseSession
