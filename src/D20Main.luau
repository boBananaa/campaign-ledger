if not plugin then return end
local WorldScope = require(script.Parent.WorldScope)
local DiceSession = require(script.Parent.DiceSession)
WorldScope.run(plugin, function() return DiceSession.start(plugin) end)
