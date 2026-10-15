local Dice = {}
function Dice.roll(random, mode, modifier)
	modifier = tonumber(modifier)
	if not modifier or modifier ~= modifier or math.abs(modifier) > 9999 or modifier % 1 ~= 0 then
		return nil, "Enter a whole-number modifier from −9999 to 9999."
	end
	if mode ~= "normal" and mode ~= "advantage" and mode ~= "disadvantage" then return nil, "Choose a roll mode." end
	local first = random:NextInteger(1, 20)
	local second = mode ~= "normal" and random:NextInteger(1, 20) or nil
	local natural = first
	if mode == "advantage" then natural = math.max(first, second) end
	if mode == "disadvantage" then natural = math.min(first, second) end
	return { first = first, second = second, natural = natural, modifier = modifier, total = natural + modifier, mode = mode }
end
function Dice.describe(roll)
	local dice = tostring(roll.first)
	if roll.second then dice ..= ", " .. roll.second .. "; kept " .. roll.natural end
	local sign = roll.modifier < 0 and " − " or " + "
	return "D20 " .. dice .. sign .. math.abs(roll.modifier) .. " = " .. roll.total
end
return Dice
