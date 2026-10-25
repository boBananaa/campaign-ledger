-- Pure hit resolution and visibility rules, independent of Roblox services.
local HoverRules = {}
function HoverRules.character(target, root, registered)
 local cursor, result = target, nil
 while cursor and cursor ~= root do
  if registered[cursor] then result = cursor end
  cursor = cursor.Parent
 end
 return result
end

function HoverRules.prefer(candidate, current)
 if not current then return true end
 local a = candidate:GetAttribute("CampaignLedgerPlateId")
 local b = current:GetAttribute("CampaignLedgerPlateId")
 return type(a) == "string" and (type(b) ~= "string" or a < b)
end

function HoverRules.skipHit(part)
 return part and part:IsA("BasePart") and ((part.Transparency or 0) >= 0.95 or (part.LocalTransparencyModifier or 0) >= 0.95)
end

function HoverRules.movementBase(part, character)
 if not part:IsA("BasePart") then return false end
 local cursor = part
 while cursor and cursor ~= character do
  local override = cursor:GetAttribute("CampaignLedgerIgnoreHover")
  if type(override) == "boolean" then return override end
  cursor = cursor.Parent
 end
 -- A stand is a very thin, horizontal part below the rest of a multi-part
 -- figure. Never infer this for a standalone flat token or a body accessory.
 if not character:IsA("Model") or part.Parent ~= character or not part.Size or not part.CFrame then return false end
 local size, frame = part.Size, part.CFrame
 local height = math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z
 if height > math.max(size.X, size.Y, size.Z) * 0.12 then return false end
 local above = false
 for _, other in ipairs(character:GetDescendants()) do
  if other ~= part and other:IsA("BasePart") and other.Transparency < 0.95 then
   if other.Position.Y < part.Position.Y then return false end
   if other.Position.Y > part.Position.Y + height then above = true end
  end
 end
 return above
end
function HoverRules.visible(hoverOnly, permitted, owner, hovered)
 return permitted == true and owner ~= nil and (not hoverOnly or owner == hovered)
end
function HoverRules.viewportPoint(x, y, left, top, width, height, viewportWidth, viewportHeight)
 if width <= 0 or height <= 0 or viewportWidth <= 0 or viewportHeight <= 0 then return nil end
 local u, v = (x - left) / width, (y - top) / height
 if u < 0 or v < 0 or u >= 1 or v >= 1 then return nil end
 return u * viewportWidth, v * viewportHeight
end
return HoverRules
