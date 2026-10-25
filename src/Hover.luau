local Rules = require(script.Parent.HoverRules)
local Hover = {}
local ROOT = "CampaignLedgerLocalPlates"
local SETTING = "CampaignLedgerHoverOnly"
local VISIBLE_SETTING = "CampaignLedgerPlatesVisible"
local TAG = "CampaignLedgerGeneratedPlate"
local CHARACTER_TAG = "CampaignLedgerCharacter"

local function createController(plugin, onChanged)
 local core = game:GetService("CoreGui")
 local world = game:GetService("Workspace")
 local collection = game:GetService("CollectionService")
 local run = game:GetService("RunService")
 local input = game:GetService("UserInputService")
 local ok, saved = pcall(function() return plugin:GetSetting(SETTING) end)
 local hoverOnly = not (ok and saved == false)
 local visibleOK, savedVisible = pcall(function() return plugin:GetSetting(VISIBLE_SETTING) end)
 local platesVisible = not (visibleOK and savedVisible == false)
 local root, owner, sensor, rootConnection
 local copies, registered, tracked, links, movementBases = {}, {}, {}, {}, {}
 local mouseX, mouseY, inside, focused, elapsed = 0, 0, false, true, 0
 local alive = true
 local update
 local rayParams = RaycastParams.new()
 rayParams.FilterType = Enum.RaycastFilterType.Exclude
 rayParams.IgnoreWater = true
 local function preferenceChanged()
  hoverOnly = root:GetAttribute("HoverOnly") ~= false
  platesVisible = root:GetAttribute("PlatesVisible") ~= false
  pcall(function() plugin:SetSetting(SETTING, hoverOnly) end)
  pcall(function() plugin:SetSetting(VISIBLE_SETTING, platesVisible) end)
  if onChanged then onChanged(hoverOnly) end
  if owner and update then update() end
 end
 local function attach()
  local current = core:FindFirstChild(ROOT)
  if current and current:GetAttribute("CampaignLedgerOwned") ~= true then return false end
  if current then
   local leader = current:FindFirstChild("OwnerPlugin")
   if not leader or not leader.Value then current:Destroy(); current = nil end
  end
  if not current then
   current = Instance.new("Folder"); current.Name = ROOT
   current:SetAttribute("CampaignLedgerOwned", true); current:SetAttribute("HoverOnly", hoverOnly)
   current:SetAttribute("PlatesVisible", platesVisible)
   local reference = Instance.new("ObjectValue"); reference.Name = "OwnerPlugin"; reference.Value = plugin; reference.Parent = current
   current.Parent = core
  end
  if root ~= current then
   if rootConnection then for _, connection in ipairs(rootConnection) do connection:Disconnect() end end
   root = current
   owner = root.OwnerPlugin.Value == plugin
   rootConnection = {
    root:GetAttributeChangedSignal("HoverOnly"):Connect(preferenceChanged),
    root:GetAttributeChangedSignal("PlatesVisible"):Connect(preferenceChanged),
   }
   preferenceChanged()
   if owner then
    copies, registered, tracked = {}, {}, {}
    local screen = Instance.new("ScreenGui"); screen.Name = "HoverSurface"
    screen.IgnoreGuiInset = true; screen.ResetOnSpawn = false; screen.DisplayOrder = -10; screen.Parent = root
    sensor = Instance.new("Frame"); sensor.Name = "ViewportPointer"
    sensor.BackgroundTransparency = 1; sensor.BorderSizePixel = 0; sensor.Active = false
    sensor.Selectable = false; sensor.Size = UDim2.fromScale(1, 1); sensor.Parent = screen
    local function moved(x, y)
     mouseX, mouseY, inside = x, y, true
     if update then update() end
    end
    table.insert(links, sensor.MouseEnter:Connect(moved))
    table.insert(links, sensor.MouseMoved:Connect(moved))
    table.insert(links, sensor.MouseLeave:Connect(function() inside = false; if update then update() end end))
   end
  end
  return owner
 end
 local function sync()
  registered, tracked, movementBases = {}, {}, {}
  local present, chosen = {}, {}
  for _, character in ipairs(collection:GetTagged(CHARACTER_TAG)) do
   if character:IsDescendantOf(world) then registered[character] = true end
  end
  for character in pairs(registered) do
   for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") and Rules.movementBase(part, character) then movementBases[part] = true end
   end
  end
  for _, template in ipairs(collection:GetTagged(TAG)) do
   if template:IsA("BillboardGui") and template:IsDescendantOf(world)
    and template:GetAttribute("CampaignLedgerLocalTemplate") == true then
    local reference = template:FindFirstChild("CampaignLedgerOwner")
    local character = reference and reference.Value
    if character and character:IsDescendantOf(world) and character:HasTag(CHARACTER_TAG)
     and Rules.character(character, world, registered) == character then
     if Rules.prefer(template, chosen[character]) then chosen[character] = template end
    end
   end
  end
  for character, template in pairs(chosen) do
     present[template], tracked[template] = true, character
     local copy = copies[template]
     if copy then
      local sourceName = template:FindFirstChild("CharacterName", true)
      local localName = copy:FindFirstChild("CharacterName", true)
      if sourceName and localName and sourceName.Text ~= localName.Text then localName.Text = sourceName.Text end
     end
  end
  for template, copy in pairs(copies) do
   if not present[template] then copy:Destroy(); copies[template] = nil end
  end
 end
 update = function()
  local hovered
  local camera = world.CurrentCamera
  if platesVisible and hoverOnly and inside and focused and camera and sensor and sensor.Visible then
   local pos, size, viewport = sensor.AbsolutePosition, sensor.AbsoluteSize, camera.ViewportSize
   -- Read the current pointer each sample so coalesced GUI events cannot leave
   -- the ray one mouse move behind. The passive surface still gates viewport exit.
   local pointer = input:GetMouseLocation()
   mouseX, mouseY = pointer.X, pointer.Y
   local x, y = Rules.viewportPoint(mouseX, mouseY, pos.X, pos.Y, size.X, size.Y, viewport.X, viewport.Y)
   if x then
    local ray = camera:ViewportPointToRay(x, y)
    local excluded = {}
    for _ = 1, 32 do
     rayParams.FilterDescendantsInstances = excluded
     local hit = world:Raycast(ray.Origin, ray.Direction * 10000, rayParams)
     if not hit or not Rules.skipHit(hit.Instance) then
      hovered = hit and not movementBases[hit.Instance] and Rules.character(hit.Instance, world, registered) or nil; break
     end
     table.insert(excluded, hit.Instance)
    end
   end
  end
  for template, character in pairs(tracked) do
   local visible = Rules.visible(hoverOnly, platesVisible and template:GetAttribute("CampaignLedgerPlateVisible"), character, hovered)
   local copy = copies[template]
   if visible and not copy then
    copy = template:Clone()
    collection:RemoveTag(copy, TAG)
    copy.Name = "Character_" .. tostring(character:GetAttribute("CampaignLedgerId"))
    copy:SetAttribute("CampaignLedgerLocalCopy", true)
    copy.Active = false
    for _, child in ipairs(copy:GetDescendants()) do
     if child:IsA("GuiObject") then child.Active = false; child.Selectable = false end
    end
    copy.Enabled = false; copy.Parent = root; copies[template] = copy
   end
   if copy then copy.Enabled = visible end
  end
 end
 local dirty, syncElapsed = true, 0
 table.insert(links, collection:GetInstanceAddedSignal(TAG):Connect(function() dirty = true end))
 table.insert(links, collection:GetInstanceRemovedSignal(TAG):Connect(function() dirty = true end))
 table.insert(links, input.WindowFocusReleased:Connect(function() focused = false; inside = false; if owner then update() end end))
 table.insert(links, input.WindowFocused:Connect(function() focused = true end))
 table.insert(links, run.Heartbeat:Connect(function(dt)
  if not alive then return end
  elapsed += dt; syncElapsed += dt
  if elapsed < 1 / 60 then return end
  elapsed = 0
  if not attach() then return end
  if dirty or syncElapsed >= 0.2 then dirty = false; syncElapsed = 0; sync() end
  update()
 end))
 attach()
 local controller = {}
 function controller:getHoverOnly() return hoverOnly end
 function controller:getPlatesVisible() return platesVisible end
 function controller:setPlatesVisible(value)
  attach()
  if root then root:SetAttribute("PlatesVisible", value == true) end
 end
 function controller:setHoverOnly(value)
  attach()
  if root then root:SetAttribute("HoverOnly", value == true) end
 end
 function controller:destroy()
  if not alive then return end
  alive = false
  if rootConnection then for _, connection in ipairs(rootConnection) do connection:Disconnect() end end
  for _, link in ipairs(links) do link:Disconnect() end
  if owner and root and root.Parent then root:Destroy() end
 end
 return controller
end
-- A combined plugin has one owner Instance; its features share one renderer.
local leases = {}
function Hover.start(plugin, onChanged)
 local entry = leases[plugin]
 if not entry then
  entry = { listeners = {} }
  leases[plugin] = entry
  entry.controller = createController(plugin, function(value)
   for _, callback in pairs(entry.listeners) do if callback then callback(value) end end
  end)
 end
 local lease, alive = {}, true
 entry.listeners[lease] = onChanged or false
 if onChanged then onChanged(entry.controller:getHoverOnly()) end
 function lease:getHoverOnly() return entry.controller:getHoverOnly() end
 function lease:getPlatesVisible() return entry.controller:getPlatesVisible() end
 function lease:setPlatesVisible(value) if alive then entry.controller:setPlatesVisible(value) end end
 function lease:setHoverOnly(value) if alive then entry.controller:setHoverOnly(value) end end
 function lease:destroy()
  if not alive then return end
  alive = false
  entry.listeners[self] = nil
  if next(entry.listeners) == nil then
   leases[plugin] = nil
   entry.controller:destroy()
  end
 end
 return lease
end
return Hover
