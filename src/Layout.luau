-- Only roster/editor scroll. Global combat controls never leave the widget.
local Layout = {}
Layout.editorPadding = 4
Layout.headingHeight = 48
Layout.selectButtonTop = 26
Layout.selectButtonHeight = 20
Layout.resourceHeight = 64
Layout.recoveryHeight = 104
Layout.minimumSplit = 256
Layout.editorBottom = 64
Layout.editorGap = 16
function Layout.split(height, requested, recoveryOpen)
 local minimum = Layout.minimumSplit + (recoveryOpen and Layout.recoveryHeight or 0)
 -- At normal height keep all three combat rows and the details disclosure in view.
 local maximum = math.max(minimum, height - 384)
 return math.clamp(requested, minimum, maximum)
end
function Layout.geometry(height, requested, recoveryOpen)
 local split = Layout.split(height, requested, recoveryOpen)
 return { split = split, search = 140 + (recoveryOpen and Layout.recoveryHeight or 0),
  roster = 174 + (recoveryOpen and Layout.recoveryHeight or 0),
  rosterHeight = split - 212 - (recoveryOpen and Layout.recoveryHeight or 0),
  register = split - 32, editor = split + Layout.editorGap,
  editorHeight = math.max(1, height - split - Layout.editorGap - Layout.editorBottom) }
end
return Layout
