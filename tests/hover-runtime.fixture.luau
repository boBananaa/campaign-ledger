-- Additional Studio API fakes for the real Hover controller; no production logic is duplicated.
local baseObject = object
local currentPointer = { X = 200, Y = 100 }
object = function(kind, name, parent)
 local o = baseObject(kind, name, parent)
 if kind == "BasePart" then
  o.Transparency, o.LocalTransparencyModifier, o.CanQuery, o.CanCollide = 0, 0, true, true
  o.Size, o.Position = { X = 1, Y = 2, Z = 1 }, { X = 0, Y = 3, Z = 0 }
  o.CFrame = { RightVector = { Y = 0 }, UpVector = { Y = 1 }, LookVector = { Y = 0 } }
 end
 o.MouseEnter, o.MouseMoved, o.MouseLeave = signal(), signal(), signal()
 for _, event in ipairs({ o.MouseEnter, o.MouseMoved }) do
  local fire = event.Fire
  function event:Fire(x, y) currentPointer.X, currentPointer.Y = x, y; fire(self, x, y) end
 end
 o.AbsolutePosition, o.AbsoluteSize, o.Visible = { X = 0, Y = 0 }, { X = 800, Y = 400 }, true
 setmetatable(o, { __index = function(self, key)
  for _, child in ipairs(objects) do if rawget(child, "Parent") == self and rawget(child, "Name") == key then return child end end
 end })
 function o:Clone()
  local copy = object(self.kind, self.Name)
  copy.attrs, copy.tags = table.clone(self.attrs), table.clone(self.tags)
  copy.Adornee, copy.Value, copy.Enabled = self.Adornee, self.Value, self.Enabled
  for _, child in ipairs(self:GetChildren()) do local duplicate = child:Clone(); duplicate.Parent = copy end
  return copy
 end
 return o
end
local Instance = { new = function(kind) return object(kind, kind) end }
local UDim2 = { fromScale = function(x, y) return { x, y } end }
local core = object("CoreGui", "CoreGui")
local heartbeat = signal()
local focused, released = signal(), signal()
services.CoreGui, services.UserInputService = core, { WindowFocused = focused, WindowFocusReleased = released, InputBegan = signal() }
function services.UserInputService:GetFocusedTextBox() return nil end
function services.UserInputService:IsKeyDown() return false end
Enum.KeyCode = { V = "V", LeftControl = "LeftControl", RightControl = "RightControl", LeftMeta = "LeftMeta", RightMeta = "RightMeta" }
function services.UserInputService:GetMouseLocation() return currentPointer end
local RaycastParams = { new = function() return {} end }
Enum.RaycastFilterType = { Exclude = "Exclude" }
services.RunService.Heartbeat = heartbeat
local currentHit
local currentHits, rayCalls, lastRayPoint = nil, 0, nil
local direction = setmetatable({}, { __mul = function(self) return self end })
workspace.CurrentCamera = { ViewportSize = { X = 800, Y = 400 }, ViewportPointToRay = function(_, x, y)
 lastRayPoint = { X = x, Y = y }
 return { Origin = {}, Direction = direction }
end }
function workspace:Raycast(_, _, params)
 rayCalls += 1
 for _, hit in ipairs(currentHits or (currentHit and { currentHit } or {})) do
  if not table.find(params.FilterDescendantsInstances, hit) then return { Instance = hit } end
 end
end
local function client(name)
 local p = object("Plugin", name)
 p.settings = {}
 function p:GetSetting(key) return self.settings[key] end
 function p:SetSetting(key, value) self.settings[key] = value end
 return p
end
local function template(character)
 local t = object("BillboardGui", "CampaignLedgerPlate", character)
 t.Enabled = false
 t:SetAttribute("CampaignLedgerLocalTemplate", true)
 t:SetAttribute("CampaignLedgerPlateVisible", true)
 local ref = object("ObjectValue", "CampaignLedgerOwner", t); ref.Value = character
 local label = object("TextLabel", "CharacterName", t); label.Text = character.Name
 collection:AddTag(t, "CampaignLedgerGeneratedPlate")
 return t
end
local function step() heartbeat:Fire(0.21) end
local function root() return core:FindFirstChild("CampaignLedgerLocalPlates") end
local function sensor() return root().HoverSurface.ViewportPointer end
local function copies()
 local result = {}
 for _, o in ipairs(root():GetChildren()) do if o:IsA("BillboardGui") then table.insert(result, o) end end
 return result
end
local function shown()
 local n = 0; for _, o in ipairs(copies()) do if o.Enabled then n += 1 end end; return n
end
