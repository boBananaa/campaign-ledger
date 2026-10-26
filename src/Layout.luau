-- The roster owns its own window; combat controls keep a dedicated editor viewport.
local Layout = {}
Layout.editorPadding = 4
Layout.headingHeight = 48
Layout.selectButtonTop = 26
Layout.selectButtonHeight = 20
Layout.resourceHeight = 64
Layout.recoveryHeight = 104
Layout.editorBottom = 64
function Layout.combatGeometry(height, recoveryOpen)
 local extra = recoveryOpen and Layout.recoveryHeight or 0
 return { navigation = 140 + extra, editor = 178 + extra,
  editorHeight = math.max(1, height - 178 - extra - Layout.editorBottom) }
end
return Layout
