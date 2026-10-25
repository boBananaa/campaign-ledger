-- Pure combat rules; no Roblox services or UI dependencies.
local State = {}
State.resources = { "hp", "mana", "ap" }
State.labels = { hp = "Health", mana = "Mana", ap = "Actions" }
State.limit = 9999

function State.integer(value: any): number?
	local number = tonumber(value)
	if not number or number ~= number or math.abs(number) == math.huge or number % 1 ~= 0 then
		return nil
	end
	return number
end

function State.default(name)
	return {
		version = 1, name = name, showPlate = true, autoName = true, plateOffset = 0,
		hp = { current = 100, maximum = 100 },
		mana = { current = 125, maximum = 125 },
		ap = { current = 6, maximum = 6 },
	}
end

function State.validate(state: any)
	if type(state) ~= "table" or state.version ~= 1 then
		return false, "Unsupported or missing character stats."
	end
	if type(state.name) ~= "string" or #state.name == 0 or #state.name > 192 then
		return false, "Character name must contain 1–48 characters."
	end
	local nameLength = utf8.len(state.name)
	if not nameLength or nameLength > 48 or state.name:find("[%c]") then
		return false, "Character name must contain 1–48 characters without line breaks."
	end
	if type(state.showPlate) ~= "boolean" then
		return false, "Invalid plate visibility."
	end
	if state.autoName ~= nil and type(state.autoName) ~= "boolean" then
		return false, "Invalid automatic name setting."
	end
	if state.plateOffset ~= nil and (type(state.plateOffset) ~= "number" or state.plateOffset ~= state.plateOffset
		or state.plateOffset < -3 or state.plateOffset > 10) then return false, "Invalid plate height." end
	for _, key in ipairs(State.resources) do
		local resource = state[key]
		if type(resource) ~= "table" then
			return false, "Missing " .. State.labels[key] .. " stats."
		end
		local current, maximum = State.integer(resource.current), State.integer(resource.maximum)
		if type(resource.current) ~= "number" or type(resource.maximum) ~= "number"
			or not current or not maximum or maximum < 0 or maximum > State.limit
			or current < 0 or current > maximum then
			return false, "Invalid " .. State.labels[key] .. " values."
		end
	end
	return true
end

function State.copy(state)
	local result = { version = 1, name = state.name, showPlate = state.showPlate,
		autoName = state.autoName ~= false, plateOffset = state.plateOffset or 0 }
	for _, key in ipairs(State.resources) do
		result[key] = { current = state[key].current, maximum = state[key].maximum }
	end
	return result
end

function State.setResource(state, key, currentValue, maximumValue)
	if not State.labels[key] then return nil, "Unknown resource." end
	local current, maximum = State.integer(currentValue), State.integer(maximumValue)
	if current == nil or maximum == nil then return nil, "Enter whole numbers for both values." end
	if maximum < 0 or maximum > State.limit then return nil, "Maximum must be 0–9999." end
	if current < 0 or current > State.limit then return nil, "Current must be 0–9999." end
	local result = State.copy(state)
	result[key] = { current = math.min(current, maximum), maximum = maximum }
	return result
end

function State.adjust(state, key, delta)
	if not State.labels[key] or not State.integer(delta) then return nil, "Invalid adjustment." end
	local result = State.copy(state)
	result[key].current = math.max(0, math.min(state[key].maximum, state[key].current + delta))
	return result
end

function State.adjustAmount(state, key, amount, direction)
	local number = State.integer(amount)
	if not number or number < 1 or number > State.limit or (direction ~= -1 and direction ~= 1) then
		return nil, "Enter an amount from 1 to 9999."
	end
	return State.adjust(state, key, number * direction)
end

function State.setMaximum(state, key, maximum)
	if not State.labels[key] then return nil, "Unknown resource." end
	return State.setResource(state, key, maximum, maximum)
end

function State.shiftPlate(state, delta)
	local result = State.copy(state)
	result.plateOffset = delta == 0 and 0 or math.clamp(result.plateOffset + delta, -3, 10)
	return result
end

function State.newTurn(state)
	local result = State.copy(state)
	result.ap.current = result.ap.maximum
	return result
end

function State.recoveryAmounts(manaValue, apValue)
	local mana, ap = State.integer(manaValue), State.integer(apValue)
	if mana == nil or ap == nil or mana < 0 or ap < 0 or mana > State.limit or ap > State.limit then
		return nil, "Enter mana and action recovery from 0 to 9999."
	end
	if mana == 0 and ap == 0 then return nil, "Set at least one recovery amount above zero." end
	return { mana = mana, ap = ap }
end

function State.recover(state, manaValue, apValue)
	local amounts, message = State.recoveryAmounts(manaValue, apValue)
	if not amounts then return nil, message end
	local result = State.copy(state)
	for _, key in ipairs({ "mana", "ap" }) do
		result[key].current = math.min(result[key].maximum, result[key].current + amounts[key])
	end
	return result
end

function State.restore(state)
	local result = State.copy(state)
	for _, key in ipairs(State.resources) do result[key].current = result[key].maximum end
	return result
end

function State.rename(state, text)
	local name = tostring(text):match("^%s*(.-)%s*$")
	local length = utf8.len(name)
	if not length or length < 1 or length > 48 or name:find("[%c]") then
		return nil, "Use a name with 1–48 characters and no line breaks."
	end
	local result = State.copy(state)
	result.name = name
	result.autoName = false
	return result
end

return State
