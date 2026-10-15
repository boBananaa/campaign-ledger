local State = require("../src/State")
local Layout = require("../src/Layout")
local Placement = require("../src/Placement")
local Dice = require("../src/Dice")
local Turn = require("../src/Turn")
local count = 0
local function check(value, message) assert(value, message); count += 1 end
local state = State.default("Aster")
for _, key in ipairs(State.resources) do
	local spent = State.adjustAmount(state, key, "2", -1)
	check(spent[key].current == math.max(0, state[key].current - 2), "custom subtract " .. key)
	check(State.adjustAmount(spent, key, "2", 1)[key].current == state[key].current, "custom add " .. key)
	check(State.setMaximum(spent, key, "100")[key].current == spent[key].current, "maximum preserves spent amount " .. key)
	check(State.setMaximum(state, key, "1")[key].current == 1, "lower maximum clamps " .. key)
	check(State.adjustAmount(state, key, "9999", 1)[key].current == state[key].maximum, "custom clamp " .. key)
end
for _, value in ipairs({ "0", "-3", "1.5", "no", "10000" }) do
	check(State.adjustAmount(state, "hp", value, -1) == nil, "reject bad amount " .. value)
end
check(State.adjustAmount(state, "hp", "1", 0) == nil, "reject bad direction")
check(State.setMaximum(state, "hp", "-1") == nil, "reject negative maximum")
check(State.setMaximum(state, "hp", "99999") == nil, "reject huge maximum")
check(Layout.editorPadding >= 2, "selection stroke has padding above scroll boundary")
check(Layout.selectButtonTop + Layout.selectButtonHeight < Layout.headingHeight, "selection button inside its own row")
check(Layout.split(640, 99999) == 380, "splitter preserves editor space")
check(Layout.split(640, -99999) == 200, "splitter preserves roster space")
check(Layout.split(760, 284) == 284, "default split stable")

local identity = { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local flat = Placement.bounds({ { sx = 8, sy = 2, sz = 4, transform = identity } })
check(flat.x == 0 and flat.z == 0 and flat.top == 1, "dog centered on entire geometry")
local sideways = { 10, 4, -5, 0, -1, 0, 1, 0, 0, 0, 0, 1 }
local rotated = Placement.bounds({ { sx = 8, sy = 2, sz = 4, transform = sideways } })
check(rotated.top == 8 and rotated.height == 8, "rotated part world height uses all dimensions")
check(rotated.x == 10 and rotated.y == 4 and rotated.z == -5, "rotated translated geometry centre")
local body = { sx = 4, sy = 2, sz = 2, transform = identity }
local head = { sx = 2, sy = 2, sz = 2, transform = { 4, 2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } }
local dog = Placement.bounds({ body, head })
check(dog.x == 1.5 and dog.top == 3, "off-centre head does not become nameplate centre")
local plateBottom = Placement.plateCenter(dog.top, 9) - Placement.height / 2
check(plateBottom > 9, "plate clears existing high nametag")
check(Placement.plateCenter(3, nil) - Placement.height / 2 > 3.2, "default name clearance")
check(Placement.plateCenter(3, nil) - Placement.height / 2 < 3.5, "default gap stays close to the miniature")
check(State.shiftPlate(state, 0.25).plateOffset == 0.25, "per-character height adjustment")
check(State.shiftPlate(State.shiftPlate(state, 1), 0).plateOffset == 0, "reset to automatic height")
check(Placement.bounds({}) == nil, "empty model handled")

local function rng(values)
	local index = 0
	return { NextInteger = function(_, low, high)
		assert(low == 1 and high == 20)
		index += 1; assert(values[index], "unexpected extra roll")
		return values[index]
	end }
end
local roll = Dice.roll(rng({ 20 }), "normal", "-2")
check(roll.natural == 20 and roll.total == 18 and roll.second == nil, "normal roll plus negative modifier")
roll = Dice.roll(rng({ 2, 18 }), "advantage", "3")
check(roll.natural == 18 and roll.total == 21, "advantage")
roll = Dice.roll(rng({ 18, 2 }), "disadvantage", "3")
check(roll.natural == 2 and roll.total == 5, "disadvantage")
roll = Dice.roll(rng({ 1, 1 }), "advantage", "0")
check(roll.natural == 1, "tied natural one")
check(Dice.roll(rng({}), "normal", "oops") == nil, "bad modifier does not consume random roll")
check(Dice.roll(rng({}), "normal", "1.5") == nil, "fractional modifier rejected")
check(Dice.roll(rng({}), "bogus", "0") == nil, "bad dice mode rejected")
check(Dice.describe(roll):find("= 1", 1, true) ~= nil, "roll breakdown includes total")
check(Turn.view("party") == "Party turn", "party display")
check(Turn.view("enemy") == "Enemy turn", "enemy display")
check(Turn.view(nil) == "No active combat", "unset display")
check(Turn.view("idle") == "No active combat", "end combat display")
check(Turn.view("corrupt") == "Turn unavailable", "unknown state does not announce a false turn")
local spent = State.adjust(State.adjust(State.adjust(state, "mana", -8), "ap", -3), "hp", -7)
local recovered = State.recover(spent, "3", "2")
check(recovered.mana.current == 7 and recovered.ap.current == 2, "recovery adds configured amounts")
check(recovered.hp.current == spent.hp.current, "recovery leaves health untouched")
check(spent.mana.current == 4 and spent.ap.current == 0, "recovery does not mutate original")
check(recovered.mana.maximum == spent.mana.maximum and recovered.ap.maximum == spent.ap.maximum, "recovery preserves maximums")
check(State.recover(spent, "9999", "9999").mana.current == state.mana.maximum, "mana recovery caps at maximum")
check(State.recover(spent, "9999", "9999").ap.current == state.ap.maximum, "action recovery caps at maximum")
check(State.recover(spent, "2", "0").ap.current == 0, "zero skips actions")
check(State.recover(spent, "0", "2").mana.current == 4, "zero skips mana")
check(State.recover(state, "1", "1").mana.current == state.mana.current, "full resources stay full")
for _, bad in ipairs({ "-1", "1.5", "oops", "10000", "inf", "nan" }) do
 check(State.recover(spent, bad, "1") == nil, "invalid mana recovery " .. bad)
 check(State.recover(spent, "1", bad) == nil, "invalid action recovery " .. bad)
end
check(State.recover(spent, "0", "0") == nil, "both zero rejected")
check(Turn.isActive("party") and Turn.isActive("enemy"), "active sides show overlay")
check(not Turn.isActive(nil) and not Turn.isActive("idle") and not Turn.isActive("corrupt"), "inactive and unknown states hide overlay")
print("PASS: " .. count .. " combat UI, placement, dice and turn checks")
