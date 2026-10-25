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
 self.turn = Theme.button(self.root, "Turn text: On", { Name = "LauncherTurn", TextSize = 14,
  Position = UDim2.fromOffset(14, 124), Size = UDim2.new(0.5, -18, 0, 32) })
 self.turn.Activated:Connect(actions.toggleTurn)
 self.hover = Theme.button(self.root, "Hover-only: On", { Name = "LauncherHover", TextSize = 14,
  Position = UDim2.new(0.5, 4, 0, 124), Size = UDim2.new(0.5, -18, 0, 32) })
 self.hover.Activated:Connect(actions.toggleHover)
 Theme.rule(self.root, { Position = UDim2.fromOffset(14, 174), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = C.edge })
 self.dm = Theme.button(self.root, "DM controls: Off", { Name = "LauncherDM", TextSize = 15,
  Position = UDim2.fromOffset(14, 186), Size = UDim2.new(1, -28, 0, 32) })
 self.dm.Activated:Connect(actions.toggleDM)
 Theme.label(self.root, "Enable Ledger and D20 on this computer.", 14, { TextColor3 = C.light,
  TextWrapped = true, Position = UDim2.fromOffset(14, 224), Size = UDim2.new(1, -28, 0, 28) })
 self.ledger = Theme.button(self.root, "Open Ledger", { Name = "LauncherLedger", TextSize = 15,
  Position = UDim2.fromOffset(14, 264), Size = UDim2.new(0.5, -18, 0, 32) })
 self.ledger.Activated:Connect(actions.openLedger)
 self.dice = Theme.button(self.root, "Open D20", { Name = "LauncherDice", TextSize = 15,
  Position = UDim2.new(0.5, 4, 0, 264), Size = UDim2.new(0.5, -18, 0, 32) })
 self.dice.Activated:Connect(actions.openDice)
 self.world = Theme.button(self.root, "Enable D&D in this world", { Name = "LauncherWorld", TextSize = 14,
  Position = UDim2.fromOffset(14, 310), Size = UDim2.new(1, -28, 0, 32) })
 self.world.Activated:Connect(actions.toggleWorld)
 Theme.label(self.root, "World activation is shared with the party.", 12, { TextColor3 = C.light,
  Position = UDim2.fromOffset(14, 346), Size = UDim2.new(1, -28, 0, 18) })
 self.footer = Theme.label(self.root, "Turn text appears only during combat.", 13, { TextColor3 = C.light,
  TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
  Position = UDim2.new(0, 14, 1, -46), Size = UDim2.new(1, -28, 0, 38) })
 return self
end
function LauncherPanel:refresh(state)
 self.worldStatus.Text = state.worldEnabled and "D&D is enabled in this world" or "D&D is inactive in this world"
 self.dm.Text = state.dmEnabled and "DM controls: On" or "DM controls: Off"
 self.turn.Text = state.turnVisible and "Turn text: On" or "Turn text: Off"
 self.hover.Text = state.hoverOnly and "Hover-only: On" or "Hover-only: Off"
 self.world.Text = state.worldEnabled and "Disable D&D in this world" or "Enable D&D in this world"
 Theme.select(self.dm, state.dmEnabled, C.active)
 Theme.select(self.turn, state.viewerReady and state.turnVisible, C.active)
 Theme.select(self.hover, state.viewerReady and state.hoverOnly, C.active)
 Theme.enable(self.turn, state.viewerReady); Theme.enable(self.hover, state.viewerReady)
 Theme.enable(self.ledger, state.dmEnabled and state.worldEnabled)
 Theme.enable(self.dice, state.dmEnabled and state.worldEnabled)
 Theme.enable(self.world, state.dmEnabled)
end
function LauncherPanel:notify(message)
 self.footer.Text = message
end
function LauncherPanel:destroy() self.root:Destroy() end
return LauncherPanel
