-- Minimal engine fake for the real UI constructors. Does not simulate Studio rendering/input routing.
local count = 0
local function check(value, message) assert(value, message); count += 1 end
local function signal()
 local event = { listeners = {} }
 function event:Connect(fn)
  local connection = { fn = fn, active = true }
  function connection:Disconnect() self.active = false end
  table.insert(self.listeners, connection)
  return connection
 end
 function event:Fire(...)
  for _, connection in ipairs(table.clone(self.listeners)) do if connection.active then connection.fn(...) end end
 end
 return event
end
local function enum(path)
 return setmetatable({}, { __index = function(self, key)
  local value = path == "Enum" and enum(path .. "." .. key) or path .. "." .. key
  rawset(self, key, value); return value
 end })
end
local Enum = enum("Enum")
local UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset, kind = "UDim" } end }
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo) return { X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0), kind = "UDim2" } end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
local Vector2 = { new = function(x, y) return { X = x, Y = y, kind = "Vector2" } end }
Vector2.zero = Vector2.new(0, 0)
local Color3 = {}
function Color3.fromRGB(r, g, b)
 return { kind = "Color3", R = r, G = g, B = b, Lerp = function(self, other, t)
  return Color3.fromRGB(self.R + (other.R - self.R) * t, self.G + (other.G - self.G) * t, self.B + (other.B - self.B) * t)
 end }
end
local objects, methods = {}, {}
local function absolute(object)
 local fixed = object.props.TestSize
 if fixed then return fixed end
 local parentSize = object.Parent and absolute(object.Parent) or Vector2.zero
 local size = object.Size
 return Vector2.new(parentSize.X * size.X.Scale + size.X.Offset, parentSize.Y * size.Y.Scale + size.Y.Offset)
end
local events = { "Activated", "MouseEnter", "MouseLeave", "SelectionGained", "SelectionLost", "Focused", "FocusLost",
 "WindowFocusReleased", "DragStart", "DragContinue", "DragEnd" }
local Instance = {}
function Instance.new(class)
 local self = setmetatable({ ClassName = class, props = { Name = class, Size = UDim2.fromOffset(100, 100),
  Position = UDim2.new(), AnchorPoint = Vector2.zero, Visible = true, BackgroundTransparency = 0, BorderSizePixel = 0,
  Text = "", TextSize = 14, TextTransparency = 0, LayoutOrder = 0, AutomaticSize = "Enum.AutomaticSize.None" },
  attrs = {}, signals = {}, destroyed = false }, {
  __index = function(o, key)
   if methods[key] then return methods[key] end
   if key == "AbsoluteSize" then return absolute(o) end
   return o.props[key]
  end,
  __newindex = function(o, key, value)
   local old = o.props[key]; o.props[key] = value
   if old ~= value and o.signals[key] then o.signals[key]:Fire() end
  end,
 })
 for _, name in ipairs(events) do self.props[name] = signal() end
 table.insert(objects, self); return self
end
function methods:GetChildren()
 local children = {}; for _, object in ipairs(objects) do if not object.destroyed and object.Parent == self then table.insert(children, object) end end
 return children
end
function methods:FindFirstChildOfClass(class) for _, child in ipairs(self:GetChildren()) do if child.ClassName == class then return child end end end
function methods:FindFirstChild(name, recursive)
 for _, child in ipairs(self:GetChildren()) do
  if child.Name == name then return child end
  if recursive then local found = child:FindFirstChild(name, true); if found then return found end end
 end
end
function methods:GetPropertyChangedSignal(key) if not self.signals[key] then self.signals[key] = signal() end; return self.signals[key] end
function methods:GetAttribute(key) return self.attrs[key] end
function methods:SetAttribute(key, value) self.attrs[key] = value end
function methods:IsFocused() return self.focused == true end
function methods:Destroy()
 for _, child in ipairs(self:GetChildren()) do child:Destroy() end
 self.destroyed = true; self.Parent = nil
 for _, event in ipairs(events) do for _, c in ipairs(self[event].listeners) do c:Disconnect() end end
 for _, event in pairs(self.signals) do for _, c in ipairs(event.listeners) do c:Disconnect() end end
end
local function widget(w, h)
 local result = Instance.new("DockWidgetPluginGui"); result.TestSize = Vector2.new(w, h); return result
end
local calls, actions = {}, {}
for _, name in ipairs({ "register", "choose", "selectModel", "adjustAmount", "adjust", "newTurn", "setTurn", "recover", "setMaximum",
 "restore", "rename", "toggleAutoName", "togglePlate", "shiftPlate", "rebuild", "remove", "toggleHoverOnly", "openCharacters", "poseChange" }) do
 actions[name] = function(...) table.insert(calls, { name, ... }) end
end
function actions.loadRecovery() return { mana = 2, ap = 1 } end
function actions.loadDivider() return nil end
local function click(root, name)
 local button = root:FindFirstChild(name, true); assert(button, name)
 if button.Interactable ~= false then button.Activated:Fire() end
end
local function last() return calls[#calls] end
-- Snapshot only serializable native GUI properties. The companion renderer approximates font metrics.
local properties = { "Name", "Size", "Position", "AnchorPoint", "Visible", "BackgroundTransparency", "BackgroundColor3",
 "Text", "PlaceholderText", "TextSize", "TextColor3", "TextTransparency", "Font", "TextWrapped", "TextXAlignment", "LayoutOrder",
 "AutomaticSize", "Rotation", "Color", "Thickness", "Padding", "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight", "Interactable" }
local function quote(s) return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"' end
local function json(value)
 if type(value) == "string" then return quote(value) end
 if type(value) ~= "table" then return tostring(value) end
 local result = {}
 for key, child in pairs(value) do if type(child) ~= "function" then table.insert(result, quote(tostring(key)) .. ":" .. json(child)) end end
 return "{" .. table.concat(result, ",") .. "}"
end
local function snapshot(root, name)
 local function tree(object)
  local props, children = {}, {}
  for _, key in ipairs(properties) do props[key] = object[key] end
  for index, child in ipairs(object:GetChildren()) do children[tostring(index)] = tree(child) end
  return { class = object.ClassName, props = props, children = children }
 end
 print("UI_SNAPSHOT " .. json({ name = name, width = root.TestSize.X, height = root.TestSize.Y, root = tree(root) }))
end
