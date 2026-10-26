"""Run production pose storage/session and Ledger callbacks with deterministic Studio fakes."""
from pathlib import Path
import re, subprocess, sys, tempfile
root=Path(__file__).resolve().parents[1]
base=(root/'tests/identity-runtime.fixture.luau').read_text().split('local first, second = character(')[0]
base+='\n'+(root/'tests/hover-runtime.fixture.luau').read_text()
base+='\nlocal userId=101\nservices.StudioService={GetUserId=function() return userId end}\nlocal CollectionService=collection\n'
plate=(root/'src/Plate.luau').read_text()
for name in ['list','get','owner','clearAnchors','clear','prune']:
    base+='\n'+re.search(rf'^function Plate\.{name}\(.*?(?=^function |^return Plate)',plate,re.M|re.S).group()
for name in ['Names','WorldScope','PoseStore']:
    source=(root/'src'/f'{name}.luau').read_text()
    source=re.sub(r'^local \w+ = require\(script.Parent.\w+\)\n','',source,flags=re.M)
    base+=f'\nlocal {name}=(function()\n{source}\nend)()\n'
base+=r'''
local poseActions, poseView
local PosePanel={new=function(widget,actions)
 poseActions=actions
 local content=object("Frame","PoseContent",widget)
 return {refresh=function(_,view) poseView=view end,notify=function() end,destroy=function() content:Destroy() end}
end}
'''
for name in ['PoseSession','LedgerSession']:
    source=(root/'src'/f'{name}.luau').read_text()
    source=re.sub(r'^local \w+ = require\(script.Parent.\w+\)\n','',source,flags=re.M)
    base+=f'\nlocal {name}=(function()\n{source}\nend)()\n'
checks=r'''
local function original(name)
 local model=character(name);model:SetAttribute(Registry.idAttribute,http:GenerateGUID(false))
 return model
end
local function replacement(name)
 local model=object("Model",name,workspace);object("BasePart","Head",model)
 return model
end
local source=original("Aster")
local initialRaw=source:GetAttribute("CampaignLedgerState")
local id=source:GetAttribute(Registry.idAttribute)
local a=PoseStore.new(plugin)
local record=a:begin(source)
check(record and not source:HasTag(Registry.tag),"begin saves pending registration and detaches old model")
check(source:GetAttribute("CampaignLedgerState")==initialRaw and record:GetAttribute("CampaignLedgerState")==initialRaw,"begin retains exact original data bytes")
check(record.Parent==PoseStore.folder() and not record:IsDescendantOf(source),"snapshot lives outside model deletion")
userId=202;local b=PoseStore.new(plugin)
check(not b:begin(source) and not b:apply(record,replacement("Other"),false),"another editor cannot claim a pending transfer")
userId=101
source:Destroy()
check(PoseStore.isRecord(record) and not a:cancel(record),"deleting original preserves backup and prevents destructive cancellation")
local savedPlace=game.PlaceId;game.PlaceId=98765
check(not a:apply(record,replacement("Other place"),false) and record.Parent~=nil,"pending record cannot transfer into a different place")
game.PlaceId=savedPlace
local reloaded=PoseStore.new(plugin)
check(reloaded:mine()==record,"pending transfer resumes after controller reload")
local dest=replacement("Different pose name")
local foreign=original("Unrelated plate owner");Plate.render(foreign,http:JSONDecode(foreign:GetAttribute("CampaignLedgerState")))
local foreignPlate=Plate.get(foreign)
local copiedPlate=object("BillboardGui",Plate.name,dest);copiedPlate:SetAttribute("CampaignLedgerOwned",true)
local copiedRef=object("ObjectValue","CampaignLedgerOwner",copiedPlate);copiedRef.Value=foreign;collection:AddTag(copiedPlate,Plate.tag)
local ok,text,target=reloaded:apply(record,dest,false)
check(ok and target==dest and dest:GetAttribute(Registry.idAttribute)==id,"replacement inherits persistent identity")
check(dest:GetAttribute("CampaignLedgerState")==initialRaw and dest:HasTag(Registry.tag),"replacement inherits exact current/max/settings data")
check(#PoseStore.records()==0 and #Plate.list(dest)==1,"successful transfer consumes record and builds exactly one plate")
check(copiedPlate.Parent==nil and Plate.get(foreign)==foreignPlate,"copied foreign ownership is scrubbed only inside the replacement")
check(not reloaded:apply(record,replacement("Second"),false),"consumed record cannot register a second model")

source=original("Cancel me");record=a:begin(source)
local spent=PoseStore.read(record);spent.hp.current=3;record:SetAttribute("CampaignLedgerState",http:JSONEncode(spent))
check(a:cancel(record) and source:HasTag(Registry.tag) and http:JSONDecode(source:GetAttribute("CampaignLedgerState")).hp.current==3,"cancel restores original with latest pending combat edits")
check(#Plate.list(source)==1 and not PoseStore.isRecord(record),"cancel restores one plate and removes temporary record")

source=original("Failure safety");record=a:begin(source)
local registered=original("Unrelated")
local unrelatedRaw=registered:GetAttribute("CampaignLedgerState")
check(not a:apply(record,registered,false) and registered:GetAttribute("CampaignLedgerState")==unrelatedRaw,"another registration cannot be overwritten")
local rendering=Plate.render
local broken=replacement("Broken")
Plate.render=function() error("simulated render failure") end
check(not a:apply(record,broken,false) and PoseStore.isRecord(record),"failed target render keeps saved registration")
check(broken:GetAttribute("CampaignLedgerState")==nil and not broken:HasTag(Registry.tag),"failed transfer rolls target back")
check(not a:cancel(record) and PoseStore.isRecord(record) and not source:HasTag(Registry.tag),"failed cancel rolls back partial restoration and keeps backup")
Plate.render=rendering
local untouchedSource=source:GetAttribute("CampaignLedgerState")
source:SetAttribute("CampaignLedgerState",http:JSONEncode(State.default("Another edit")))
check(not a:apply(record,broken,false) and not a:cancel(record) and PoseStore.isRecord(record),"changed original data cannot be overwritten or cleared by a pending transfer")
source:SetAttribute("CampaignLedgerState",untouchedSource)
check(a:cancel(record),"pending record remains recoverable after failures")

source=original("Guard boundary");record=a:begin(source)
local guarded=original("Guarded replacement")
local incomingRaw=http:JSONEncode(State.default("Incoming editor edit"))
local startRecording=history.TryBeginRecording
function history:TryBeginRecording(...)
 history.TryBeginRecording=startRecording;guarded:SetAttribute("CampaignLedgerState",incomingRaw)
 return startRecording(self,...)
end
check(not a:apply(record,guarded,false,true) and guarded:GetAttribute("CampaignLedgerState")==incomingRaw and PoseStore.isRecord(record),"write-boundary rejection cannot roll back another editor's newer target data")
local originalRaw=source:GetAttribute("CampaignLedgerState")
function history:TryBeginRecording(...)
 history.TryBeginRecording=startRecording;source:SetAttribute("CampaignLedgerState",incomingRaw)
 return startRecording(self,...)
end
check(not a:cancel(record) and source:GetAttribute("CampaignLedgerState")==incomingRaw and PoseStore.isRecord(record),"cancel boundary rejection cannot erase newer original data")
source:SetAttribute("CampaignLedgerState",originalRaw);a:cancel(record)

source=original("Name stays");local saved=http:JSONDecode(source:GetAttribute("CampaignLedgerState"));saved.autoName=true
source:SetAttribute("CampaignLedgerState",http:JSONEncode(saved))
record=a:begin(source);dest=replacement("Pose prefab")
check(a:apply(record,dest,false) and Names.apply(dest,http:JSONDecode(dest:GetAttribute("CampaignLedgerState"))).name=="Name stays","automatic name setting preserves character name across pose prefab names")

source=original("Undo owner");record=a:begin(source)
local begin=history.TryBeginRecording;history.TryBeginRecording=function() return nil end
local untouched=replacement("No undo")
check(not a:apply(record,untouched,false) and untouched:GetAttribute("CampaignLedgerState")==nil and PoseStore.isRecord(record),"no undo recording means no transfer mutations")
history.TryBeginRecording=begin
local duplicate=record:Clone();duplicate.Name=http:GenerateGUID(false);duplicate.Parent=PoseStore.folder();duplicate:SetAttribute("OwnerUserId",202)
check(not a:apply(record,untouched,false),"conflicting shared records block transfer rather than lose one snapshot")
duplicate:Destroy();a:cancel(record)

-- Real pose controller: only selected newly-added models may auto-complete.
source=original("Automatic")
selection:Set({source})
local stop,controller=PoseSession.start(plugin)
controller.begin(source);flush();record=controller.pending()
check(record and poseView.pending,"player pose controller arms without DM mode")
local remote=replacement("Someone else's paste");workspace.DescendantAdded:Fire(remote);flush()
check(PoseStore.isRecord(record) and remote:GetAttribute("CampaignLedgerState")==nil,"remote additions without local selection cannot steal transfer")
dest=replacement("Local paste");workspace.DescendantAdded:Fire(dest);selection:Set({dest});flush()
check(PoseStore.isRecord(record),"ordinary selection of a new remote model cannot auto-consume snapshot")
history.OnRecordingFinished:Fire("Paste",nil,nil,Enum.FinishRecordingOperation.Commit);flush()
check(not controller.pending() and dest:HasTag(Registry.tag),"one newly pasted locally-selected model auto-inherits registration")
check(createdWidgets[1].Enabled,"pose transfer UI opened only by explicit action")
source=original("Manual fallback");local existing=replacement("Already in map")
controller.begin(source);flush();selection:Set({existing});flush()
check(controller.pending()~=nil,"selecting a pre-existing model requires explicit confirmation")
poseActions.primary();flush();check(existing:HasTag(Registry.tag) and not controller.pending(),"Use selected model completes manual fallback")
source=original("Explicit transfer");controller.begin(source);flush()
local occupied=original("Existing other registration")
local occupiedRaw=occupied:GetAttribute("CampaignLedgerState")
local occupiedId=occupied:GetAttribute(Registry.idAttribute)
selection:Set({occupied});flush();poseActions.primary();flush()
check(controller.pending()~=nil and occupied:GetAttribute("CampaignLedgerState")==occupiedRaw and poseView.confirming,"occupied replacement requires a second explicit confirmation")
poseActions.primary();flush()
local archived=false
for _,item in ipairs(PoseStore.folder():GetChildren()) do if item:GetAttribute("Status")=="replaced" and item:GetAttribute(Registry.idAttribute)==occupiedId and item:GetAttribute("CampaignLedgerState")==occupiedRaw then archived=true end end
check(not controller.pending() and archived,"confirmed occupied replacement preserves previous registration in a saved archive")
source=original("Keyboard paste");controller.begin(source);flush()
local input=services.UserInputService
input.IsKeyDown=function(_,key) return key==Enum.KeyCode.LeftMeta end
input.InputBegan:Fire({KeyCode=Enum.KeyCode.V},false)
local keyed=replacement("Keyboard replacement");workspace.DescendantAdded:Fire(keyed);selection:Set({keyed});flush()
check(not controller.pending() and keyed:HasTag(Registry.tag),"Command-V gesture allows a newly-selected pasted model to inherit")
input.IsKeyDown=function() return false end
source=original("Paused across reload");controller.begin(source);flush();record=controller.pending()
stop();flush();check(PoseStore.isRecord(record) and not createdWidgets[1].Enabled,"stopping viewer session closes UI without deleting pending data")
stop,controller=PoseSession.start(plugin);controller.open();flush()
check(controller.pending()==record and #createdWidgets==1,"reload restores pending flow and reuses native widget ID")
local candidate=replacement("Queued undo");workspace.DescendantAdded:Fire(candidate);selection:Set({candidate});history.OnUndo:Fire();flush()
check(PoseStore.isRecord(record) and not candidate:HasTag(Registry.tag),"Undo cancels queued auto-completion")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled",false)
check(not a:apply(record,candidate,false) and PoseStore.isRecord(record),"inactive world cannot consume a pending transfer")
services.ReplicatedStorage:SetAttribute("CampaignLedgerEnabled",true)
poseActions.cancel();flush();stop()

-- DM callbacks edit the authoritative snapshot, including all-character recovery.
source=original("DM pending");record=a:begin(source)
local stopLedger=LedgerSession.start(plugin,{launcher=true,pose={begin=function() end}});flush()
local found=false;for _,entry in ipairs(entries) do if entry.character==record and entry.pending then found=true end end
check(found,"independent roster includes waiting-for-replacement registration")
captured.choose(record);flush();captured.adjust("hp",-4);flush()
check(PoseStore.read(record).hp.current==7,"combat edits work while original model is absent")
captured.recover("2","1",false);flush()
check(PoseStore.read(record).mana.current==4 and PoseStore.read(record).ap.current==2,"recovery updates pending registration")
local before=record:GetAttribute("CampaignLedgerState");captured.remove();flush()
check(record:GetAttribute("CampaignLedgerState")==before and PoseStore.isRecord(record),"Remove from ledger cannot discard an unfinished pose backup")
dest=replacement("New combat pose");check(a:apply(record,dest,false),"pending edited character can finish pose transfer")
local final=http:JSONDecode(dest:GetAttribute("CampaignLedgerState"))
check(final.hp.current==7 and final.mana.current==4 and final.ap.current==2,"latest DM edits transfer rather than stale original snapshot")
stopLedger();flush()
print("PASS: "..count.." pose transfer, recovery, player lifecycle and DM integration checks")
'''
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',prefix='.pose-runtime-',dir=root/'tests',delete=False) as f:
    f.write(base+checks);path=Path(f.name)
try:subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'luau',str(path)],check=True)
finally:path.unlink(missing_ok=True)
