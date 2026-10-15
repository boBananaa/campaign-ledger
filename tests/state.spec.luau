local State = require("../src/State")
local count = 0
local function check(condition, message)
	assert(condition, message)
	count += 1
end
local state = State.default("Aster Vale")
check(State.validate(state), "defaults valid")
for _, key in ipairs(State.resources) do
	local damaged = State.adjust(state, key, -7)
	check(damaged[key].current == math.max(0, state[key].current - 7), "subtract " .. key)
	check(state[key].current == state[key].maximum, "input immutable " .. key)
	check(State.adjust(state, key, -99999)[key].current == 0, "lower clamp " .. key)
	check(State.adjust(damaged, key, 99999)[key].current == state[key].maximum, "upper clamp " .. key)
	check(State.setResource(state, key, 9, 4)[key].current == 4, "lower maximum clamps " .. key)
	check(State.setResource(state, key, 0, 0)[key].maximum == 0, "zero maximum " .. key)
	check(State.setResource(state, key, "12", "20")[key].current == 12, "UI strings " .. key)
end
for _, bad in ipairs({ "", "oops", "1.5", "nan", "inf", "-1", "10000" }) do
	check(State.setResource(state, "hp", bad, "30") == nil, "reject bad current " .. bad)
	check(State.setResource(state, "hp", "1", bad) == nil, "reject bad max " .. bad)
end
check(State.integer(0/0) == nil, "reject NaN")
check(State.integer(math.huge) == nil, "reject infinity")
check(State.setResource(state, "bogus", 1, 2) == nil, "reject unknown resource")
local spent = State.adjust(State.adjust(State.adjust(state, "hp", -9), "mana", -4), "ap", -2)
local turn = State.newTurn(spent)
check(turn.ap.current == turn.ap.maximum, "new turn refills AP")
check(turn.hp.current == spent.hp.current and turn.mana.current == spent.mana.current, "new turn preserves HP and mana")
local restored = State.restore(spent)
check(restored.hp.current == 30 and restored.mana.current == 12 and restored.ap.current == 3, "restore all")
check(spent.hp.current == 21 and spent.mana.current == 8 and spent.ap.current == 1, "reset leaves original intact")
check(State.rename(state, "  Rowan Ash  ").name == "Rowan Ash", "trim names")
check(State.rename(state, " ") == nil, "reject blank name")
check(State.rename(state, string.rep("a", 49)) == nil, "name length limit")
check(State.rename(state, "a\nb") == nil, "reject multiline name")
check(State.rename(state, "Éowyn").name == "Éowyn", "unicode name")
check(State.validate(nil) == false, "missing state")
local corrupt = State.copy(state); corrupt.hp.current = "3"
check(State.validate(corrupt) == false, "strict stored number type")
corrupt = State.copy(state); corrupt.ap.current = 99
check(State.validate(corrupt) == false, "corrupt bounds")
corrupt = State.copy(state); corrupt.version = 2
check(State.validate(corrupt) == false, "unknown schema")
print("PASS: " .. count .. " combat-state checks")
