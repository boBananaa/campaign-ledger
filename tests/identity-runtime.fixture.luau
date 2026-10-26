-- Main controller regression harness. scripts/test_identity.py supplies real controller and cleanup code.
local State = require("../src/State")
local Registry = require("../src/Registry")
local count = 0
local function check(value, message) assert(value, message); count += 1 end
local function signal()
 local s = { listeners = {} }
 function s:Connect(fn)
  local c = { fn = fn, active = true }; function c:Disconnect() self.active = false end
  table.insert(self.listeners, c); return c
 end
 function s:Fire(...) for _, c in ipairs(table.clone(self.listeners)) do if c.active then c.fn(...) end end end
 return s
end
local objects = {}
local function object(kind, name, parent)
 local o = { kind = kind, Name = name, Parent = parent, attrs = {}, tags = {}, signals = {},
  AncestryChanged = signal(), DescendantAdded = signal(), DescendantRemoving = signal() }
 table.insert(objects, o)
 if kind == "TextLabel" or kind == "TextButton" then o.TextTransparency, o.TextSize, o.RichText = 0, 14, false end
 function o:IsA(class) return self.kind == class or (self.kind == "Workspace" and class == "Model") end
 function o:IsDescendantOf(root) local c = self.Parent; while c do if c == root then return true end; c = c.Parent end; return false end
 function o:GetChildren() local r = {}; for _, c in ipairs(objects) do if c.Parent == self then table.insert(r, c) end end; return r end
 function o:GetDescendants() local r = {}; for _, c in ipairs(objects) do if c:IsDescendantOf(self) then table.insert(r, c) end end; return r end
 function o:FindFirstChild(name, recursive) for _, c in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if c.Name == name then return c end end end
 function o:FindFirstChildOfClass(class) for _, c in ipairs(self:GetChildren()) do if c:IsA(class) then return c end end end
 function o:FindFirstChildWhichIsA(class, recursive) for _, c in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if c:IsA(class) then return c end end end
 function o:GetAttribute(key) return self.attrs[key] end
 function o:GetPropertyChangedSignal(key) if not self.signals[key] then self.signals[key] = signal() end; return self.signals[key] end
 function o:GetAttributeChangedSignal(key) return self:GetPropertyChangedSignal("attr_" .. key) end
 function o:SetAttribute(key, value) self.attrs[key] = value; self:GetAttributeChangedSignal(key):Fire() end
 function o:HasTag(tag) return self.tags[tag] == true end
 function o:Destroy() for _, c in ipairs(self:GetChildren()) do c:Destroy() end; self.Parent = nil; self.tags = {}; self.destroyed = true end
 return o
end
local workspace = object("Workspace", "Workspace")
local collection = { added = signal(), removed = signal() }
function collection:GetTagged(tag) local r = {}; for _, o in ipairs(objects) do if o:HasTag(tag) and o:IsDescendantOf(workspace) then table.insert(r, o) end end; return r end
function collection:HasTag(o, tag) return o:HasTag(tag) end
function collection:AddTag(o, tag) o.tags[tag] = true; self.added:Fire(o) end
function collection:RemoveTag(o, tag) o.tags[tag] = nil; self.removed:Fire(o) end
function collection:GetInstanceAddedSignal() return self.added end
function collection:GetInstanceRemovedSignal() return self.removed end
local json, serial, uuid = {}, 0, 0
local http = {}
function http:JSONEncode(state) serial += 1; local key = "state_" .. serial; json[key] = State.copy(state); return key end
function http:JSONDecode(raw) assert(json[raw], "Bad JSON"); return State.copy(json[raw]) end
function http:GenerateGUID() uuid += 1; return string.format("00000000-0000-4000-8000-%012d", uuid) end
local history = { OnUndo = signal(), OnRedo = signal(), OnRecordingFinished = signal() }
function history:TryBeginRecording() return "recording" end
function history:FinishRecording() end
local selection = { SelectionChanged = signal(), objects = {} }
function selection:Get() return self.objects end
function selection:Set(value) self.objects = value; self.SelectionChanged:Fire() end
local services = { Workspace = workspace, CollectionService = collection, HttpService = http, ChangeHistoryService = history,
 Selection = selection, ReplicatedStorage = object("ReplicatedStorage", "ReplicatedStorage"), RunService = { IsRunning = function() return false end } }
local game = object("DataModel", "Game")
game.PlaceId = 12345
function game:GetService(key) return assert(services[key], key) end
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled", true)
services.ReplicatedStorage:SetAttribute("CampaignLedgerPlaceId", game.PlaceId)
local queued = {}
local task = { defer = function(fn) table.insert(queued, fn) end }
local function flush()
 local rounds = 0
 while #queued > 0 do rounds += 1; assert(rounds < 40, "refresh loop"); local batch = queued; queued = {}; for _, fn in ipairs(batch) do fn() end end
end
local plugin = object("Plugin", "Plugin")
plugin.Unloading = signal()
function plugin:GetSetting() end
function plugin:SetSetting() end
local reservedButtons, reservedWidgets, reservedActions = {}, {}, {}
function plugin:CreateToolbar(name)
 local t = {}; function t:Destroy() end
 function t:CreateButton(id)
  local key = name .. ":" .. id
  assert(not reservedButtons[key], "Native toolbar ID remains reserved after Destroy: " .. key)
  reservedButtons[key] = true
  return { Click = signal(), SetActive = function() end, Destroy = function(self) self.destroyed = true end }
 end
 return t
end
local createdWidgets = {}
function plugin:CreateDockWidgetPluginGuiAsync(id, info)
 assert(not reservedWidgets[id], "Native widget ID remains reserved after Destroy")
 reservedWidgets[id] = true
 local w = object("DockWidgetPluginGui", "DM")
 -- Simulate a globally restored open widget. The constructor must override it.
 w.Enabled = true
 if info.InitialEnabledShouldOverrideRestore then w.Enabled = info.InitialEnabled end
 table.insert(createdWidgets, w)
 return w
end
function plugin:CreatePluginAction(id) assert(not reservedActions[id], "Native action ID remains reserved after Destroy"); reservedActions[id] = true; local action = object("PluginAction", "Action"); action.Triggered = signal(); return action end
local Enum = { FinishRecordingOperation = { Commit = 1, Cancel = 2 }, InitialDockState = { Float = 1 }, ZIndexBehavior = { Sibling = 1 } }
local DockWidgetPluginGuiInfo = { new = function(_, enabled, override)
 return { InitialEnabled = enabled, InitialEnabledShouldOverrideRestore = override }
end }
local Names = { apply = function(_, state) return state end, observe = function() return { Disconnect = function() end } end,
 resolve = function(character) return character.Name end }
local Turn = { attribute = "CampaignLedgerTurn", view = function(value) return tostring(value) end }
local Hover = { start = function() return { getHoverOnly = function() return true end, setHoverOnly = function() end, destroy = function() end } end }
local captured, entries
local Panel = { new = function(_, actions)
 captured = actions
 return { refresh = function(_, value) entries = value end, notify = function() end, updateTurn = function() end, updateHoverOnly = function() end, destroy = function() end }
end }
local RosterPanel = { new = function()
 return { refresh = function() end, notify = function() end, destroy = function() end }
end }
local PoseStore = { isRecord = function() return false end, forId = function() return nil end,
 records = function() return {} end, nameAttribute = "CampaignLedgerPoseName" }
local PoseSession = { start = function() return function() end, { begin = function() end, open = function() end } end }
local Plate = { name = "CampaignLedgerPlate", tag = "CampaignLedgerGeneratedPlate", styleVersion = 7 }
-- Renderer is a UI stub; owner resolution and deletion below are copied from production.
function Plate.anchor(character) return character:FindFirstChild("Head") end
function Plate.render(character, state)
 Plate.clear(character)
 local anchor = object("Attachment", "CampaignLedgerAnchor", Plate.anchor(character)); anchor:SetAttribute("CampaignLedgerOwned", true)
 local gui = object("BillboardGui", Plate.name, character); gui.Adornee = anchor
 gui:SetAttribute("CampaignLedgerPlateId", http:GenerateGUID(false))
 gui:SetAttribute("CampaignLedgerOwned", true); gui:SetAttribute("CampaignLedgerStyleVersion", Plate.styleVersion)
 gui:SetAttribute(Registry.idAttribute, character:GetAttribute(Registry.idAttribute))
 local owner = object("ObjectValue", "CampaignLedgerOwner", gui); owner.Value = character
 collection:AddTag(gui, Plate.tag)
 local label = object("TextLabel", "CharacterName", gui); label.Text = state.name
 return gui
end
local function character(name)
 local m = object("Model", name, workspace); object("BasePart", "Head", m)
 local state = State.default(name); state.autoName = false; state.hp.current = 11; state.mana.current = 2; state.ap.current = 1
 state.hp.maximum, state.mana.maximum, state.ap.maximum = 30, 12, 3
 m:SetAttribute("CampaignLedgerState", http:JSONEncode(state)); collection:AddTag(m, Registry.tag); return m
end
local first, second = character("Same Name"), character("Same Name")
-- PRODUCTION CONTROLLER INSERTED HERE
