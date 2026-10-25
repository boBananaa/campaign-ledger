"""Run the combined plugin and real session/hover controllers with deterministic Studio fakes."""
from pathlib import Path
import re, subprocess, sys, tempfile
root=Path(__file__).resolve().parents[1]
base=(root/'tests/identity-runtime.fixture.luau').read_text().split('local first, second = character(')[0]
hover_fixture=(root/'tests/hover-runtime.fixture.luau').read_text()
def inline(name):
    text=(root/'src'/f'{name}.luau').read_text()
    return re.sub(r'^local \w+ = require\(script\.Parent\.\w+\)\n','',text,flags=re.M)
preamble=base+'\n'+hover_fixture+r'''
Enum.TextXAlignment={Center="Center"};Enum.TextTruncate={None="None"}
UDim2.new=function() return {} end
local Vector2={new=function() return {} end}
local Random={new=function() return {} end}
local Theme={colors={},display="Garamond"}
function Theme.create(class,props,parent)
 local item=object(class,props.Name,parent)
 for key,value in pairs(props) do item[key]=value end
 return item
end
function Theme.label(parent,text,size,props)
 local item=Theme.create("TextLabel",props,parent);item.Text=text;return item
end
local DicePanel={new=function(widget) return object("Frame","DiceContent",widget) end}
plugin.settings={}
function plugin:GetSetting(key) return self.settings[key] end
function plugin:SetSetting(key,value) self.settings[key]=value end
local launcherActions, launcherState
local LauncherPanel = { new = function(widget, actions)
 launcherActions = actions
 local root = object("Frame", "CampaignLauncher", widget)
 return { refresh = function(_, state) launcherState = state end,
  notify = function() end, destroy = function() root:Destroy() end }
end }
local toolbarButtons, toolbarCount = {}, 0
local originalToolbar=plugin.CreateToolbar
function plugin:CreateToolbar(...)
 toolbarCount += 1
 local toolbar=originalToolbar(self,...)
 local create=toolbar.CreateButton
 function toolbar:CreateButton(id,...)
  local button=create(self,id,...)
  function button:SetActive(value) self.active=value end
  toolbarButtons[id]=button
  return button
 end
 return toolbar
end
local function click(id)
 local b=assert(toolbarButtons[id],id)
 if b.Enabled ~= false then b.Click:Fire() end
 flush();step()
end
local function action(name)
 assert(launcherActions[name],name)();flush();step()
end
local function nativeButtonCount()
 local n=0;for _ in pairs(toolbarButtons) do n+=1 end;return n
end
local CollectionService=collection
'''
# Use production plate identity helpers so a temporary character remains realistic.
plate=(root/'src/Plate.luau').read_text()
for name in ['get','owner','clear']:
    match=re.search(rf'^function Plate\.{name}\(.*?(?=^function |^return Plate)',plate,re.M|re.S)
    preamble+='\n'+match.group()
for module in ['Turn','WorldScope','HoverRules','Hover','LedgerSession','DiceSession','ViewerSession']:
    if module=='Hover':
        text=(root/'src/Hover.luau').read_text().replace('require(script.Parent.HoverRules)','HoverRules')
    else:text=inline(module)
    preamble+=f'\nlocal {module}=(function()\n{text}\nend)()\n'
entry=inline('SuiteMain')
checks=r'''
flush();step()
check(#createdWidgets == 1 and not createdWidgets[1].Enabled, "fresh player mode has one closed launcher and no DM windows")
check(nativeButtonCount()==1 and toolbarCount==1, "one toolbar button in player mode")
click("CampaignTools.Open");check(createdWidgets[1].Enabled,"toolbar opens launcher explicitly")
check(launcherState.dmEnabled == false, "DM controls default off")
check(not launcherState.dmEnabled, "player mode cannot toggle shared world")
check(core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled, "party turn text active without player click")
check(root() ~= nil and root():GetAttribute("HoverOnly"), "hover viewer active and hover-only by default")
local playerCharacter=character("Aster")
playerCharacter:SetAttribute("CampaignLedgerId","test-character")
local stats=playerCharacter:GetAttribute("CampaignLedgerState")
template(playerCharacter)
currentHit=playerCharacter.Head;sensor().MouseMoved:Fire(100,100);step()
check(shown() == 1, "player sees hovered stats without enabling DM controls")
check(playerCharacter:GetAttribute("CampaignLedgerState")==stats, "default player viewer preserves character stats")
currentHit=nil;playerCharacter:Destroy();step()
local viewerSensor=sensor()
action("toggleDM")
check(plugin.settings.CampaignToolsDMEnabled == true, "DM choice saved locally")
check(#createdWidgets == 3 and not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "DM enabling builds two closed menus")
check(sensor()==viewerSensor, "DM Ledger shares the existing viewer renderer")
local surfaces=0
for _,child in ipairs(root():GetChildren()) do if child.Name=="HoverSurface" then surfaces+=1 end end
check(surfaces==1, "one hover sensor with all three features enabled")
action("openLedger")
check(createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "launcher opens Ledger explicitly")
action("openDice");check(createdWidgets[3].Enabled,"launcher opens D20 explicitly")
check(nativeButtonCount()==1 and toolbarCount==1,"enabling DM controls creates no extra toolbar buttons")
click("CampaignTools.Open");check(not createdWidgets[1].Enabled and root()~=nil,"closing launcher leaves viewer running")
action("toggleDM")
check(plugin.settings.CampaignToolsDMEnabled == false and not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "turning DM controls off closes menus")
check(root() ~= nil and sensor()==viewerSensor, "DM off leaves player viewer running")
check(core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled, "DM off leaves turn text running")
action("toggleHover")
check(not root():GetAttribute("HoverOnly"), "player hover preference remains usable")
action("toggleHover")
action("toggleTurn");check(not core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled,"launcher switch hides local turn notice")
action("toggleTurn");check(core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled,"launcher switch restores local turn notice")
action("toggleDM")
check(#createdWidgets==3 and not createdWidgets[2].Enabled, "DM re-enable reuses native IDs with menus closed")
action("toggleWorld")
check(not WorldScope.isEnabled() and root()==nil and core:FindFirstChild("CampaignLedgerTurnOverlay")==nil, "world off removes shared viewer and turn text")
check(not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "world off closes both DM menus")
action("toggleWorld")
check(WorldScope.isEnabled() and root()~=nil and #createdWidgets==3, "world re-enable restarts combined features without duplicate native IDs")
check(not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "world re-enable does not pop menus open")
services.ReplicatedStorage:SetAttribute(Turn.attribute,"idle");flush();step()
check(not core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled, "end combat hides combined turn text")
plugin.Unloading:Fire();flush();step()
check(root()==nil and core:FindFirstChild("CampaignLedgerTurnOverlay")==nil, "combined unload removes viewer UI")
check(createdWidgets[1].destroyed and createdWidgets[2].destroyed and createdWidgets[3].destroyed, "combined unload disposes both native widgets")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled",false);flush()
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled",true);flush()
check(root()==nil and #createdWidgets==3, "unloaded suite cannot resurrect")
print("PASS: "..count.." combined player defaults, DM switching, shared viewer and lifecycle checks")
'''
other=r'''
flush();step()
check(root()==nil and #createdWidgets==1 and not createdWidgets[1].Enabled and core:FindFirstChild("CampaignLedgerTurnOverlay")==nil, "unmarked world has no player overlay or menus")
action("toggleDM")
check(#createdWidgets==1 and root()==nil, "DM preference alone cannot activate unrelated world")
action("toggleWorld")
check(WorldScope.isEnabled() and root()~=nil and #createdWidgets==3, "explicit world enable starts one combined session")
game.PlaceId=98765;game:GetPropertyChangedSignal("PlaceId"):Fire();flush();step()
check(root()==nil and not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "export to new place ID deactivates suite")
action("toggleWorld")
check(WorldScope.isEnabled() and root()~=nil and #createdWidgets==3, "destination enable binds new ID without new native handles")
plugin.Unloading:Fire();flush();step()
check(root()==nil and createdWidgets[1].destroyed, "destination unload releases suite")
print("PASS: "..count.." combined unrelated-world and export checks")
'''
remembered=r'''
flush();step()
check(launcherState.dmEnabled and #createdWidgets==3, "explicit previous DM preference restored")
check(not createdWidgets[1].Enabled and not createdWidgets[2].Enabled and not createdWidgets[3].Enabled, "remembered DM choice never auto-opens launcher or menus")
check(nativeButtonCount()==1 and toolbarCount==1,"remembered DM still has one native toolbar button")
check(root()~=nil and core:FindFirstChild("CampaignLedgerTurnOverlay").Enabled, "remembered DM retains automatic player features")
plugin.Unloading:Fire();flush();step()
print("PASS: "..count.." remembered-DM startup checks")
'''
for setup,assertions in [
 ('services.ReplicatedStorage:SetAttribute("CampaignLedgerTurn","party")\n',checks),
 ('services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled",false)\n',other),
 ('plugin.settings.CampaignToolsDMEnabled=true\nservices.ReplicatedStorage:SetAttribute("CampaignLedgerTurn","party")\n',remembered)]:
    source=preamble+'\n'+setup+'\ndo\n'+entry+'\nend\n'+assertions
    with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',prefix='.suite-runtime-',dir=root/'tests',delete=False) as f:
        f.write(source);path=Path(f.name)
    try:subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'luau',str(path)],check=True)
    finally:path.unlink(missing_ok=True)
