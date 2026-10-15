local Rules = require("../src/HoverRules")
local count = 0
local function check(value, message) assert(value, message); count += 1 end
local root = {}
local first = { Name = "Same Name", Parent = root }
local second = { Name = "Same Name", Parent = root }
local weapon = { Parent = { Parent = first } }
local head = { Parent = first }
local dog = { Parent = root }
local dogHead = { Parent = { Parent = dog } }
local registered = { [first] = true, [second] = true, [dog] = true }
check(Rules.character(head, root, registered) == first, "head resolves owning character")
check(Rules.character(weapon, root, registered) == first, "nested weapon/accessory resolves character")
check(Rules.character(dogHead, root, registered) == dog, "non-humanoid nested head supported")
check(Rules.character({ Parent = second }, root, registered) == second, "duplicate names remain distinct")
check(Rules.character(nil, root, registered) == nil, "empty sky hides plate")
check(Rules.character({ Parent = root }, root, registered) == nil, "terrain and unregistered objects hide plate")
check(Rules.character(root, root, { [root] = true }) == nil, "Workspace never a character")
check(Rules.visible(true, true, first, first), "hovered owner shows")
check(not Rules.visible(true, true, first, second), "same-name neighbour stays hidden")
check(not Rules.visible(true, true, first, nil), "leaving character hides")
check(Rules.visible(false, true, first, nil), "opt-out shows permitted plates")
check(not Rules.visible(false, false, first, first), "hide plate wins over opt-out")
check(not Rules.visible(true, false, first, first), "hide plate wins over hover")
check(not Rules.visible(false, true, nil, nil), "missing owner cannot show")
local x, y = Rules.viewportPoint(250, 170, 50, 70, 400, 200, 800, 400)
check(x == 400 and y == 200, "coordinates normalized to camera viewport")
x, y = Rules.viewportPoint(50, 70, 50, 70, 400, 200, 800, 400)
check(x == 0 and y == 0, "top-left included")
check(Rules.viewportPoint(450, 170, 50, 70, 400, 200, 800, 400) == nil, "right edge outside")
check(Rules.viewportPoint(250, 270, 50, 70, 400, 200, 800, 400) == nil, "bottom edge outside")
check(Rules.viewportPoint(0, 170, 50, 70, 400, 200, 800, 400) == nil, "outside viewport rejected")
check(Rules.viewportPoint(250, 170, 50, 70, 0, 200, 800, 400) == nil, "unlaid-out sensor rejected")
check(Rules.viewportPoint(250, 170, 50, 70, 400, 200, 0, 400) == nil, "missing camera viewport rejected")
registered[first] = nil
check(Rules.character(weapon, root, registered) == nil, "removed character no longer hovered")
print("PASS: " .. count .. " hover hit and visibility checks")
