local Theme = require(script.Parent.Theme)
local PosePanel = {}
PosePanel.__index = PosePanel
local C = Theme.colors
function PosePanel.new(widget, actions)
 local self = setmetatable({}, PosePanel)
 self.root = Theme.create("Frame", { Name = "PoseChange", BackgroundColor3 = C.shell, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, widget)
 Theme.label(self.root, "Pose Change", 28, { Font = Theme.display, TextXAlignment = Enum.TextXAlignment.Center,
  Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 34) })
 self.name = Theme.label(self.root, "Select a registered character", 22, { Font = Theme.display,
  Position = UDim2.fromOffset(14, 54), Size = UDim2.new(1, -28, 0, 30) })
 self.summary = Theme.label(self.root, "", 14, { TextColor3 = C.light, TextWrapped = true,
  Position = UDim2.fromOffset(14, 88), Size = UDim2.new(1, -28, 0, 42) })
 self.help = Theme.label(self.root, "Save the registration before deleting the old pose. Then paste one replacement model.", 16,
  { TextColor3 = C.light, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
   Position = UDim2.fromOffset(14, 138), Size = UDim2.new(1, -28, 0, 72) })
 self.target = Theme.label(self.root, "", 14, { TextColor3 = C.muted,
  Position = UDim2.fromOffset(14, 216), Size = UDim2.new(1, -28, 0, 24) })
 self.primary = Theme.button(self.root, "Save registration & change pose", { Name = "PosePrimary", TextSize = 15,
  Position = UDim2.fromOffset(14, 248), Size = UDim2.new(1, -28, 0, 34) })
 self.primary.Activated:Connect(actions.primary)
 self.cancel = Theme.button(self.root, "Cancel pose change", { Name = "PoseCancel", TextSize = 14,
  Position = UDim2.fromOffset(14, 290), Size = UDim2.new(1, -28, 0, 30) })
 self.cancel.Activated:Connect(actions.cancel)
 self.footer = Theme.label(self.root, "Existing stats and maximums are preserved.", 13, { TextColor3 = C.light,
  TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Position = UDim2.new(0, 14, 1, -66), Size = UDim2.new(1, -28, 0, 58) })
 return self
end
function PosePanel:refresh(view)
 self.name.Text = view.name or "Select a registered character"
 self.summary.Text = view.summary or ""
 self.primary.Text = view.confirming and "Confirm replacement" or view.pending and "Use selected model" or "Save registration & change pose"
 self.help.Text = view.pending and "Registration saved. Delete the old pose, then paste one new model. A newly pasted, selected replacement transfers automatically."
  or "Save the registration before deleting the old pose. Then paste one replacement model."
 self.target.Text = view.target and ("Selected: " .. view.target) or "Select one model in the map."
 self.cancel.Visible = view.pending == true
 Theme.enable(self.primary, view.canApply == true)
 Theme.enable(self.cancel, view.canCancel == true)
end
function PosePanel:notify(message, isError)
 self.footer.Text = message
 self.footer.TextColor3 = isError and C.hp or C.light
end
function PosePanel:destroy() self.root:Destroy() end
return PosePanel
