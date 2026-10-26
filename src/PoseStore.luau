-- Saved edit-mode transfers. Records live outside Workspace/model deletion.
local State = require(script.Parent.State)
local Names = require(script.Parent.Names)
local Registry = require(script.Parent.Registry)
local Plate = require(script.Parent.Plate)
local WorldScope = require(script.Parent.WorldScope)
local PoseStore = {}
PoseStore.__index = PoseStore
PoseStore.folderName = "CampaignToolsPoseChanges"
PoseStore.stateAttribute = "CampaignLedgerState"
PoseStore.nameAttribute = "CampaignLedgerPoseName"
local shared = game:GetService("ReplicatedStorage")
local world = game:GetService("Workspace")
local collection = game:GetService("CollectionService")
local http = game:GetService("HttpService")

function PoseStore.folder()
 local folder = shared:FindFirstChild(PoseStore.folderName)
 if folder and folder:IsA("Folder") and folder:GetAttribute("CampaignToolsOwned") == true then return folder end
 return nil
end
function PoseStore.isRecord(record)
 return record ~= nil and record.Parent == PoseStore.folder() and record:IsA("Folder")
  and record:GetAttribute("CampaignToolsPoseRecord") == true
  and record:GetAttribute("PlaceId") == game.PlaceId
  and record:GetAttribute("Status") == "pending"
end
function PoseStore.records()
 local records, folder = {}, PoseStore.folder()
 if folder then for _, record in ipairs(folder:GetChildren()) do if PoseStore.isRecord(record) then table.insert(records, record) end end end
 table.sort(records, function(a, b) return a.Name < b.Name end)
 return records
end
function PoseStore.source(record)
 local ref = record:FindFirstChild("SourceModel")
 return ref and ref:IsA("ObjectValue") and ref.Value or nil
end
function PoseStore.forId(id)
 if not Registry.validId(id) then return nil end
 for _, record in ipairs(PoseStore.records()) do if record:GetAttribute(Registry.idAttribute) == id then return record end end
 return nil
end
function PoseStore.read(record)
 local ok, state = pcall(function() return http:JSONDecode(record:GetAttribute(PoseStore.stateAttribute)) end)
 if not ok then return nil, "The saved pose-change data could not be read. It has been kept for recovery." end
 local valid, message = State.validate(state)
 if not valid then return nil, message end
 return Names.apply(record, state)
end
function PoseStore.new(plugin)
 local ok, userId = pcall(function() return game:GetService("StudioService"):GetUserId() end)
 return setmetatable({ plugin = plugin, userId = ok and userId or 0, busy = false }, PoseStore)
end
function PoseStore:mine()
 for _, record in ipairs(PoseStore.records()) do if record:GetAttribute("OwnerUserId") == self.userId then return record end end
 return nil
end
function PoseStore:edit(label, operation, rollback)
 if not WorldScope.isEnabled() then return false, "Enable D&D in this world first." end
 if game:GetService("RunService"):IsRunning() then return false, "Stop Play mode before changing a pose." end
 if self.userId <= 0 then return false, "Sign into Studio before changing a pose." end
 if self.busy then return false, "Finish the current pose edit first." end
 local history = game:GetService("ChangeHistoryService")
 local started, recording = pcall(function() return history:TryBeginRecording("CampaignTools.Pose", label) end)
 if not started or not recording then return false, "Finish the current Studio edit, then try again." end
 self.busy = true
 local ok, message = pcall(operation)
 if not ok and rollback then
  local restored, restoreError = pcall(rollback)
  if not restored then warn("Campaign Tools pose recovery: " .. tostring(restoreError)) end
 end
 local finished, finishError = pcall(function()
  history:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
 end)
 self.busy = false
 if not ok or not finished then return false, tostring(message or finishError) end
 return true
end
function PoseStore:begin(candidate)
 if self:mine() then return self:mine(), "Finish or cancel your pending pose change first." end
 local source = candidate and Registry.registeredAncestor(candidate, world)
 if not source or not source:IsDescendantOf(world) then return nil, "Select a registered character in the map first." end
 local raw = source:GetAttribute(PoseStore.stateAttribute)
 local ok, state = pcall(function() return http:JSONDecode(raw) end)
 if not ok then return nil, "The original character has unreadable stats; nothing was changed." end
 local valid, message = State.validate(state)
 if not valid then return nil, message end
 local id = source:GetAttribute(Registry.idAttribute)
 if not Registry.validId(id) then return nil, "This character needs a valid ledger ID before changing its pose." end
 if PoseStore.forId(id) then return nil, "Another editor is already changing this character's pose." end
 if not Plate.anchor(source) then return nil, "The original character has no usable geometry." end
 local record, detached = nil, false
 local edited, errorMessage = self:edit("Prepare character pose change", function()
  assert(source:IsDescendantOf(world) and source:HasTag(Registry.tag) and source:GetAttribute(Registry.idAttribute) == id
   and source:GetAttribute(PoseStore.stateAttribute) == raw and not PoseStore.forId(id), "Character changed; try again.")
  local folder = PoseStore.folder()
  if not folder then
   assert(not shared:FindFirstChild(PoseStore.folderName), "The pose storage name is occupied by unrelated content.")
   folder = Instance.new("Folder"); folder.Name = PoseStore.folderName
   folder:SetAttribute("CampaignToolsOwned", true); folder.Parent = shared
  end
  record = Instance.new("Folder"); record.Name = http:GenerateGUID(false)
  record:SetAttribute("CampaignToolsPoseRecord", true); record:SetAttribute("PlaceId", game.PlaceId)
  record:SetAttribute("OwnerUserId", self.userId); record:SetAttribute("Status", "pending")
  record:SetAttribute(Registry.idAttribute, id); record:SetAttribute(PoseStore.stateAttribute, raw)
  record:SetAttribute(PoseStore.nameAttribute, Names.apply(source, state).name)
  record:SetAttribute("OriginalState", raw)
  local ref = Instance.new("ObjectValue"); ref.Name = "SourceModel"; ref.Value = source; ref.Parent = record
  record.Parent = folder -- Fully save before detaching the model's registration.
  collection:RemoveTag(source, Registry.tag); detached = true
  Plate.clear(source)
 end, function()
  if detached then collection:AddTag(source, Registry.tag); Plate.render(source, state) end
  if record then record:Destroy() end
 end)
 if not edited then return nil, errorMessage end
 return record, "Registration saved. Delete the old pose and paste its replacement."
end
function PoseStore:candidate(record, selected, automatic, replaceExisting)
 if not PoseStore.isRecord(record) or record:GetAttribute("OwnerUserId") ~= self.userId then return nil, "This pose change belongs to another editor or is no longer pending." end
 if not Registry.validId(record:GetAttribute(Registry.idAttribute)) then return nil, "The saved character ID is invalid. The recovery record has been kept." end
 local source = PoseStore.source(record)
 if source and source:IsDescendantOf(world) and (source:HasTag(Registry.tag)
  or source:GetAttribute(Registry.idAttribute) ~= record:GetAttribute(Registry.idAttribute)
  or source:GetAttribute(PoseStore.stateAttribute) ~= record:GetAttribute("OriginalState")) then
  return nil, "The original model's registration changed while waiting. Nothing was overwritten."
 end
 local count = 0
 for _, other in ipairs(PoseStore.records()) do if other:GetAttribute(Registry.idAttribute) == record:GetAttribute(Registry.idAttribute) then count += 1 end end
 if count ~= 1 then return nil, "Conflicting pose changes exist. Saved data is preserved; resolve the other pending change first." end
 if not selected or not selected:IsDescendantOf(world) or not (selected:IsA("Model") or selected:IsA("BasePart")) then
  return nil, "Select exactly one replacement model in Workspace."
 end
 local target, message = Registry.character(selected)
 if not target then return nil, message end
 if target == PoseStore.source(record) then return nil, "Choose the new pose, not the original model." end
 if Registry.registeredAncestor(target.Parent, world) then return nil, "The replacement is inside an already registered character." end
 for _, child in ipairs(target:GetDescendants()) do if child:HasTag(Registry.tag) then return nil, "The replacement contains registered characters." end end
 local raw, id = target:GetAttribute(PoseStore.stateAttribute), target:GetAttribute(Registry.idAttribute)
 if raw ~= nil or target:HasTag(Registry.tag) then
  -- A freshly pasted copy of this exact character may already carry its data.
  if id ~= record:GetAttribute(Registry.idAttribute) then
   if automatic or not replaceExisting then return nil, "The selected model already has another character's registration." end
   local ok, existing = pcall(function() return http:JSONDecode(raw) end)
   if not ok or not State.validate(existing) then return nil, "The replacement has unreadable saved stats. Choose a clean replacement; its old data was left untouched." end
  end
  if automatic and raw ~= record:GetAttribute("OriginalState") then return nil, "This copy has different saved stats. Use selected model to confirm the replacement." end
 end
 if not Plate.anchor(target) then return nil, "The replacement needs a Head, PrimaryPart or another BasePart." end
 return target
end
function PoseStore:apply(record, selected, automatic, replaceExisting)
 local target, message = self:candidate(record, selected, automatic, replaceExisting)
 if not target then return false, message end
 local state, stateError = PoseStore.read(record)
 if not state then return false, stateError end
 local raw, id = record:GetAttribute(PoseStore.stateAttribute), record:GetAttribute(Registry.idAttribute)
 local oldRaw, oldId, oldName, tagged = target:GetAttribute(PoseStore.stateAttribute), target:GetAttribute(Registry.idAttribute), target:GetAttribute(PoseStore.nameAttribute), target:HasTag(Registry.tag)
 local source = PoseStore.source(record)
 local sourceRaw, sourceId, sourceName = source and source:GetAttribute(PoseStore.stateAttribute), source and source:GetAttribute(Registry.idAttribute), source and source:GetAttribute(PoseStore.nameAttribute)
 local archive, targetTouched, sourceTouched = nil, false, false
 local edited, errorMessage = self:edit("Transfer character to replacement pose", function()
  assert(self:candidate(record, target, automatic, replaceExisting) == target and record:GetAttribute(PoseStore.stateAttribute) == raw, "Pose change changed; try again.")
  assert(target:GetAttribute(PoseStore.stateAttribute) == oldRaw and target:GetAttribute(Registry.idAttribute) == oldId
   and target:HasTag(Registry.tag) == tagged, "Replacement registration changed; review it again.")
  if oldRaw and oldId ~= id then
   archive = Instance.new("Folder"); archive.Name = http:GenerateGUID(false)
   archive:SetAttribute("CampaignToolsPoseRecord", true); archive:SetAttribute("PlaceId", game.PlaceId)
   archive:SetAttribute("Status", "replaced"); archive:SetAttribute("OwnerUserId", self.userId)
   archive:SetAttribute(PoseStore.stateAttribute, oldRaw); archive:SetAttribute(Registry.idAttribute, oldId)
   archive:SetAttribute(PoseStore.nameAttribute, oldName); archive:SetAttribute("ReplacedById", id)
   archive.Parent = PoseStore.folder()
  end
  targetTouched = true
  -- Pasted prefabs can carry stale owner references. Only remove generated
  -- plates physically inside this replacement; never follow them to another rig.
  for _, gui in ipairs(target:GetDescendants()) do
   if gui:IsA("BillboardGui") and gui.Name == Plate.name and gui:GetAttribute("CampaignLedgerOwned") == true then gui:Destroy() end
  end
  target:SetAttribute(PoseStore.stateAttribute, raw); target:SetAttribute(Registry.idAttribute, id)
  target:SetAttribute(PoseStore.nameAttribute, record:GetAttribute(PoseStore.nameAttribute))
  collection:AddTag(target, Registry.tag)
  Plate.render(target, state)
  if source and source:IsDescendantOf(world) then
   sourceTouched = true
   source:SetAttribute(PoseStore.stateAttribute, nil); source:SetAttribute(Registry.idAttribute, nil); source:SetAttribute(PoseStore.nameAttribute, nil)
  end
  record:Destroy() -- Consume only after the replacement and its plate exist.
 end, function()
  if targetTouched then
   Plate.clear(target); target:SetAttribute(PoseStore.stateAttribute, oldRaw)
   target:SetAttribute(Registry.idAttribute, oldId); target:SetAttribute(PoseStore.nameAttribute, oldName)
   if tagged then collection:AddTag(target, Registry.tag) else collection:RemoveTag(target, Registry.tag) end
   if oldRaw and tagged then local ok, oldState = pcall(function() return http:JSONDecode(oldRaw) end); if ok and State.validate(oldState) then Plate.render(target, oldState) end end
  end
  if sourceTouched and source and source:IsDescendantOf(world) then
   source:SetAttribute(PoseStore.stateAttribute, sourceRaw); source:SetAttribute(Registry.idAttribute, sourceId); source:SetAttribute(PoseStore.nameAttribute, sourceName)
  end
  if archive then archive:Destroy() end
 end)
 return edited, edited and ("Pose changed for " .. state.name .. ". Stats preserved.") or errorMessage, edited and target or nil
end
function PoseStore:cancel(record)
 if not PoseStore.isRecord(record) or record:GetAttribute("OwnerUserId") ~= self.userId then return false, "Choose your own pending pose change." end
 local source = PoseStore.source(record)
 if not source or not source:IsDescendantOf(world) then return false, "The original model was deleted. Your stats are safe; select a replacement to finish."
 end
 local state, message = PoseStore.read(record)
 if not state then return false, message end
 if source:HasTag(Registry.tag) then return false, "The original model has another active registration. The saved record was kept." end
 if source:GetAttribute(Registry.idAttribute) ~= record:GetAttribute(Registry.idAttribute)
  or source:GetAttribute(PoseStore.stateAttribute) ~= record:GetAttribute("OriginalState") then
  return false, "The original model's saved data changed. The recovery record has been kept."
 end
 local oldRaw = source:GetAttribute(PoseStore.stateAttribute)
 local sourceTouched = false
 local ok, errorMessage = self:edit("Cancel character pose change", function()
  assert(not source:HasTag(Registry.tag) and source:GetAttribute(PoseStore.stateAttribute) == oldRaw
   and source:GetAttribute(Registry.idAttribute) == record:GetAttribute(Registry.idAttribute), "Original registration changed; try again.")
  sourceTouched = true
  source:SetAttribute(PoseStore.stateAttribute, record:GetAttribute(PoseStore.stateAttribute))
  collection:AddTag(source, Registry.tag); Plate.render(source, state); record:Destroy()
 end, function()
  if sourceTouched then Plate.clear(source); collection:RemoveTag(source, Registry.tag); source:SetAttribute(PoseStore.stateAttribute, oldRaw) end
 end)
 return ok, ok and "Pose change cancelled. Original registration restored." or errorMessage
end
return PoseStore
