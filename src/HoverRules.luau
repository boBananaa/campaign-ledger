-- Pure hit resolution and visibility rules, independent of Roblox services.
local HoverRules = {}
function HoverRules.character(target, root, registered)
 local cursor = target
 while cursor and cursor ~= root do
  if registered[cursor] then return cursor end
  cursor = cursor.Parent
 end
 return nil
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
