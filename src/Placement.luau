-- World-space axis-aligned bounds, including arbitrary part rotation.
-- Snapshots use CFrame:GetComponents() and part Size; no engine globals needed.
local Placement = {}
Placement.width = 3.8
Placement.height = 3.8 * 116 / 228

function Placement.bounds(parts)
	local lowX, lowY, lowZ = math.huge, math.huge, math.huge
	local highX, highY, highZ = -math.huge, -math.huge, -math.huge
	for _, part in ipairs(parts) do
		local c = part.transform
		local x, y, z = part.sx / 2, part.sy / 2, part.sz / 2
		local ex = math.abs(c[4]) * x + math.abs(c[5]) * y + math.abs(c[6]) * z
		local ey = math.abs(c[7]) * x + math.abs(c[8]) * y + math.abs(c[9]) * z
		local ez = math.abs(c[10]) * x + math.abs(c[11]) * y + math.abs(c[12]) * z
		lowX, highX = math.min(lowX, c[1] - ex), math.max(highX, c[1] + ex)
		lowY, highY = math.min(lowY, c[2] - ey), math.max(highY, c[2] + ey)
		lowZ, highZ = math.min(lowZ, c[3] - ez), math.max(highZ, c[3] + ez)
	end
	if #parts == 0 then return nil end
	return { x = (lowX + highX) / 2, y = (lowY + highY) / 2, z = (lowZ + highZ) / 2,
		top = highY, height = highY - lowY }
end

function Placement.plateCenter(top, nameTop)
	-- Keep the bottom of our plate above the existing name region, not over it.
	local bottom = math.max(top + 0.2, nameTop or -math.huge) + 0.15
	return bottom + Placement.height / 2
end
return Placement
