if not plugin then return end
local WorldScope = require(script.Parent.WorldScope)
local ViewerSession = require(script.Parent.ViewerSession)
WorldScope.run(plugin, function() return ViewerSession.start(plugin) end)
