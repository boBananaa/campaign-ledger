local Theme = require(script.Parent.Theme)
local LauncherPanel = {}
LauncherPanel.__index = LauncherPanel
local C = Theme.colors

function LauncherPanel.new(widget, actions)
 local self = setmetatable({}, LauncherPanel)
 self.root = Theme.create("Frame", { Name = "CampaignLauncher", BackgroundColor3 = C.shell,
  BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, widget)
 Theme.label(self.root, "Campaign Tools", 28, { Font = Theme.display, TextXAlignment = Enum.TextXAlignment.Center,
  Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 34) })
 local binding = Theme.create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
  Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 1) }, self.root)
 Theme.junction(binding, 0)
 self.worldStatus = Theme.label(self.root, "", 14, { TextColor3 = C.light,
  Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 24) })
 Theme.label(self.root, "Player display", 17, { Font = Theme.bold,
  Position = UDim2.fromOffset(14, 94), Size = UDim2.new(1, -28, 0, 24) })
 self.plates = Theme.button(self.root, "Stat plates: On", { Name = "LauncherPlates", TextSize = 14,
  Position = UDim2.fromOffset(14, 124), Size = UDim2.new(1, -28, 0, 32) })
 self.plates.Activated:Connect(actions.togglePlates)
 self.turn = Theme.button(self.root, "Turn text: On", { Name = "LauncherTurn", TextSize = 14,
  Position = UDim2.fromOffset(14, 164), Size = UDim2.new(0.5, -18, 0, 32) })
 self.turn.Activated:Connect(actions.toggleTurn)
 self.hover = Theme.button(self.root, "Hover-only: On", { Name = "LauncherHover", TextSize = 14,
  Position = UDim2.new(0.5, 4, 0, 164), Size = UDim2.new(0.5, -18, 0, 32) })
 self.hover.Activated:Connect(actions.toggleHover)
 self.pose = Theme.button(self.root, "Pose Change", { Name = "LauncherPose", TextSize = 15,
  Position = UDim2.fromOffset(14, 204), Size = UDim2.new(1, -28, 0, 32) })
 self.pose.Activated:Connect(actions.openPose)
 Theme.rule(self.root, { Position = UDim2.fromOffset(14, 254), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = C.edge })
 self.dm = Theme.button(self.root, "DM controls: Off", { Name = "LauncherDM", TextSize = 15,
  Position = UDim2.fromOffset(14, 266), Size = UDim2.new(1, -28, 0, 32) })
 self.dm.Activated:Connect(actions.toggleDM)
 Theme.label(self.root, "Enable Ledger and D20 on this computer.", 14, { TextColor3 = C.light,
  TextWrapped = true, Position = UDim2.fromOffset(14, 304), Size = UDim2.new(1, -28, 0, 28) })
 self.ledger = Theme.button(self.root, "Open Ledger", { Name = "LauncherLedger", TextSize = 15,
  Position = UDim2.fromOffset(14, 344), Size = UDim2.new(0.5, -18, 0, 32) })
 self.ledger.Activated:Connect(actions.openLedger)
 self.dice = Theme.button(self.root, "Open D20", { Name = "LauncherDice", TextSize = 15,
  Position = UDim2.new(0.5, 4, 0, 344), Size = UDim2.new(0.5, -18, 0, 32) })
 self.dice.Activated:Connect(actions.openDice)
 self.characters = Theme.button(self.root, "Open Characters", { Name = "LauncherCharacters", TextSize = 15,
  Position = UDim2.fromOffset(14, 384), Size = UDim2.new(1, -28, 0, 32) })
 self.characters.Activated:Connect(actions.openCharacters)
 self.world = Theme.button(self.root, "Enable D&D in this world", { Name = "LauncherWorld", TextSize = 14,
  Position = UDim2.fromOffset(14, 428), Size = UDim2.new(1, -28, 0, 32) })
 self.world.Activated:Connect(actions.toggleWorld)
 Theme.label(self.root, "World activation is shared with the party.", 12, { TextColor3 = C.light,
  Position = UDim2.fromOffset(14, 464), Size = UDim2.new(1, -28, 0, 18) })
 self.footer = Theme.label(self.root, "Turn text appears only during combat.", 13, { TextColor3 = C.light,
  TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
  Position = UDim2.new(0, 14, 1, -46), Size = UDim2.new(1, -28, 0, 38) })
 return self
end
function LauncherPanel:refresh(state)
 self.worldStatus.Text = state.worldEnabled and "D&D is enabled in this world" or "D&D is inactive in this world"
 self.plates.Text = state.platesVisible and "Stat plates: On" or "Stat plates: Off"
 self.dm.Text = state.dmEnabled and "DM controls: On" or "DM controls: Off"
 self.turn.Text = state.turnVisible and "Turn text: On" or "Turn text: Off"
 self.hover.Text = state.hoverOnly and "Hover-only: On" or "Hover-only: Off"
 self.world.Text = state.worldEnabled and "Disable D&D in this world" or "Enable D&D in this world"
 Theme.select(self.dm, state.dmEnabled, C.active)
 Theme.select(self.plates, state.viewerReady and state.platesVisible, C.active)
 Theme.select(self.turn, state.viewerReady and state.turnVisible, C.active)
 Theme.select(self.hover, state.viewerReady and state.hoverOnly, C.active)
 Theme.enable(self.plates, state.viewerReady)
 Theme.enable(self.pose, state.poseReady == true and state.worldEnabled)
 Theme.enable(self.turn, state.viewerReady); Theme.enable(self.hover, state.viewerReady and state.platesVisible)
 Theme.enable(self.ledger, state.dmEnabled and state.worldEnabled)
 Theme.enable(self.dice, state.dmEnabled and state.worldEnabled)
 Theme.enable(self.characters, state.dmEnabled and state.worldEnabled)
 Theme.enable(self.world, state.dmEnabled)
end
function LauncherPanel:notify(message)
 self.footer.Text = message
end
function LauncherPanel:destroy() self.root:Destroy() end
return LauncherPanel
