local Rules = require(script.Parent.HoverRules)
local Hover = {}
local ROOT = "CampaignLedgerLocalPlates"
local SETTING = "CampaignLedgerHoverOnly"
local TAG = "CampaignLedgerGeneratedPlate"
local CHARACTER_TAG = "CampaignLedgerCharacter"

function Hover.start(plugin, onChanged)
 local core = game:GetService("CoreGui")
 local world = game:GetService("Workspace")
 local collection = game:GetService("CollectionService")
 local run = game:GetService("RunService")
 local input = game:GetService("UserInputService")
 local ok, saved = pcall(function() return plugin:GetSetting(SETTING) end)
 local hoverOnly = not (ok and saved == false)
 local root, owner, sensor, rootConnection
 local copies, registered, tracked, links = {}, {}, {}, {}
 local mouseX, mouseY, inside, focused, elapsed = 0, 0, false, true, 0
 local alive = true
 local function preferenceChanged()
  hoverOnly = root:GetAttribute("HoverOnly") ~= false
  pcall(function() plugin:SetSetting(SETTING, hoverOnly) end)
  if onChanged then onChanged(hoverOnly) end
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
   local reference = Instance.new("ObjectValue"); reference.Name = "OwnerPlugin"; reference.Value = plugin; reference.Parent = current
   current.Parent = core
  end
  if root ~= current then
   if rootConnection then rootConnection:Disconnect() end
   root = current
   owner = root.OwnerPlugin.Value == plugin
   rootConnection = root:GetAttributeChangedSignal("HoverOnly"):Connect(preferenceChanged)
   preferenceChanged()
   if owner then
    copies, registered, tracked = {}, {}, {}
    local screen = Instance.new("ScreenGui"); screen.Name = "HoverSurface"
    screen.IgnoreGuiInset = true; screen.ResetOnSpawn = false; screen.DisplayOrder = -10; screen.Parent = root
    sensor = Instance.new("Frame"); sensor.Name = "ViewportPointer"
    sensor.BackgroundTransparency = 1; sensor.BorderSizePixel = 0; sensor.Active = false
    sensor.Selectable = false; sensor.Size = UDim2.fromScale(1, 1); sensor.Parent = screen
    local function moved(x, y) mouseX, mouseY, inside = x, y, true end
    table.insert(links, sensor.MouseEnter:Connect(moved))
    table.insert(links, sensor.MouseMoved:Connect(moved))
    table.insert(links, sensor.MouseLeave:Connect(function() inside = false end))
   end
  end
  return owner
 end
 local function sync()
  registered, tracked = {}, {}
  local present = {}
  for _, template in ipairs(collection:GetTagged(TAG)) do
   if template:IsA("BillboardGui") and template:IsDescendantOf(world)
    and template:GetAttribute("CampaignLedgerLocalTemplate") == true then
    local reference = template:FindFirstChild("CampaignLedgerOwner")
    local character = reference and reference.Value
    if character and character:IsDescendantOf(world) and character:HasTag(CHARACTER_TAG) then
     registered[character], present[template] = true, true
     tracked[template] = character
     local copy = copies[template]
     if copy then
      local sourceName = template:FindFirstChild("CharacterName", true)
      local localName = copy:FindFirstChild("CharacterName", true)
      if sourceName and localName and sourceName.Text ~= localName.Text then localName.Text = sourceName.Text end
     end
    end
   end
  end
  for template, copy in pairs(copies) do
   if not present[template] then copy:Destroy(); copies[template] = nil end
  end
 end
 local function update()
  local hovered
  local camera = world.CurrentCamera
  if hoverOnly and inside and focused and camera and sensor and sensor.Visible then
   local pos, size, viewport = sensor.AbsolutePosition, sensor.AbsoluteSize, camera.ViewportSize
   local x, y = Rules.viewportPoint(mouseX, mouseY, pos.X, pos.Y, size.X, size.Y, viewport.X, viewport.Y)
   if x then
    local ray = camera:ViewportPointToRay(x, y)
    local hit = world:Raycast(ray.Origin, ray.Direction * 10000)
    hovered = Rules.character(hit and hit.Instance, world, registered)
   end
  end
  for template, character in pairs(tracked) do
   local visible = Rules.visible(hoverOnly, template:GetAttribute("CampaignLedgerPlateVisible"), character, hovered)
   local copy = copies[template]
   if visible and not copy then
    copy = template:Clone()
    collection:RemoveTag(copy, TAG)
    copy.Name = "Character_" .. tostring(character:GetAttribute("CampaignLedgerId"))
    copy:SetAttribute("CampaignLedgerLocalCopy", true)
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
  if elapsed < 0.05 then return end
  elapsed = 0
  if not attach() then return end
  if dirty or syncElapsed >= 0.2 then dirty = false; syncElapsed = 0; sync() end
  update()
 end))
 attach()
 local controller = {}
 function controller:getHoverOnly() return hoverOnly end
 function controller:setHoverOnly(value)
  attach()
  if root then root:SetAttribute("HoverOnly", value == true) end
 end
 function controller:destroy()
  if not alive then return end
  alive = false
  if rootConnection then rootConnection:Disconnect() end
  for _, link in ipairs(links) do link:Disconnect() end
  if owner and root and root.Parent then root:Destroy() end
 end
 return controller
end
return Hover
