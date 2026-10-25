from pathlib import Path
import json, html
import argparse
parser = argparse.ArgumentParser(description="Approximate native GUI snapshot trees as an offline HTML review; not a Studio renderer.")
parser.add_argument("snapshots", type=Path)
args = parser.parse_args()
base = args.snapshots
def children(n): return list(n['children'].values())
def val(u,axis,parent):
 d=u.get(axis,{})
 return d.get('Scale',0)*parent+d.get('Offset',0)
def gui(n): return n['class'] in ['Frame','ScrollingFrame','TextLabel','TextBox','TextButton','DockWidgetPluginGui']
def color(c): return 'rgb(%s,%s,%s)'%(c.get('R',0),c.get('G',0),c.get('B',0))
def dimensions(n,pw,ph,override=None):
 p=n['props'];w,h=override or (val(p['Size'],'X',pw),val(p['Size'],'Y',ph))
 pad=next((c['props'] for c in children(n) if c['class']=='UIPadding'),{})
 left=val({'X':pad.get('PaddingLeft',{})},'X',w);right=val({'X':pad.get('PaddingRight',{})},'X',w)
 top=val({'X':pad.get('PaddingTop',{})},'X',h);bottom=val({'X':pad.get('PaddingBottom',{})},'X',h)
 layout=next((c['props'] for c in children(n) if c['class']=='UIListLayout'),None)
 kids=[c for c in children(n) if gui(c) and c['props'].get('Visible',True)]
 if layout: kids.sort(key=lambda c:c['props'].get('LayoutOrder',0))
 boxes=[];cursor=top
 for c in kids:
  cw,ch,inner=dimensions(c,w-left-right,h-top-bottom)
  cp=c['props'];x=left+val(cp['Position'],'X',w-left-right)-cp['AnchorPoint']['X']*cw
  y=top+val(cp['Position'],'Y',h-top-bottom)-cp['AnchorPoint']['Y']*ch
  if layout:x=left;y=cursor;cursor+=ch+layout.get('Padding',{}).get('Offset',0)
  boxes.append((c,x,y,cw,ch,inner))
 if p.get('AutomaticSize')=='Enum.AutomaticSize.Y':
  h=max([y+ch for c,x,y,cw,ch,inner in boxes]+[top])+bottom
  if n['class']=='TextLabel':h=max(h, p.get('TextSize',14)*1.3)
 return w,h,boxes

def render(n,x,y,w,h,boxes):
 p=n['props'];style=[f'left:{x}px;top:{y}px;width:{w}px;height:{h}px']
 if n['class']=='ScrollingFrame':style+=['overflow:hidden']
 else:style+=['overflow:visible']
 if p.get('Rotation'):style+=[f'transform:rotate({p["Rotation"]}deg)']
 c=p.get('BackgroundColor3');a=1-p.get('BackgroundTransparency',0)
 if c and a>0:style+=[f'background:rgba({c["R"]},{c["G"]},{c["B"]},{a})']
 stroke=next((c['props'] for c in children(n) if c['class']=='UIStroke'),None)
 if stroke:style+=[f'outline:{stroke.get("Thickness",1)}px solid {color(stroke["Color"])};outline-offset:0px']
 result=f'<div class="node" data-name="{html.escape(p["Name"])}" style="{";".join(style)}">'
 if n['class'].startswith('Text'):
  font=p.get('Font',''); family='Baskerville,Georgia,serif' if 'Garamond' in font else 'Arial,sans-serif'
  weight='600' if 'Semibold' in font else '400'
  align=p.get('TextXAlignment','').split('.')[-1].lower() or 'center'
  pad=next((c['props'] for c in children(n) if c['class']=='UIPadding'),{})
  text=p.get('Text') or p.get('PlaceholderText','')
  ts=[f'font:{weight} {p.get("TextSize",14)}px {family}',f'color:{color(p.get("TextColor3",{}))}',f'text-align:{align}',f'opacity:{1-p.get("TextTransparency",0)}',f'padding:0 {pad.get("PaddingRight",{}).get("Offset",0)}px 0 {pad.get("PaddingLeft",{}).get("Offset",0)}px']
  ts+=['white-space:normal'] if p.get('TextWrapped') else ['white-space:nowrap;text-overflow:ellipsis']
  result+=f'<span class="text" style="{";".join(ts)}">{html.escape(text)}</span>'
 for c,cx,cy,cw,ch,inner in boxes:result+=render(c,cx,cy,cw,ch,inner)
 return result+'</div>'
labels={'ledger-330':'Compact · 330 × 640','ledger-wide':'Room to browse · 500 × 820','ledger-recovery':'Manual recovery','ledger-details':'Character details','ledger-empty':'No selection','ledger-minimum':'Minimum · 330 × 480','dice':'D20 roller'}
head='''<!doctype html><html><meta charset="utf-8"><style>*{box-sizing:border-box}body{background:#181714;color:#d8cdbb;font:14px Arial;margin:32px}.panels{display:flex;gap:28px;align-items:flex-start}.pane{flex:none}h1{font:32px Georgia;margin:0 0 10px}p{color:#b6ab99;margin:0 0 28px}.window{position:relative;box-shadow:0 6px 24px #0007}.node{position:absolute}.text{position:absolute;inset:0;display:flex;align-items:center;overflow:hidden;justify-content:inherit;line-height:1.1}.text[style*="text-align:center"]{justify-content:center}.text[style*="text-align:right"]{justify-content:flex-end}h2{font:14px Arial;margin:0 0 12px;color:#b6ab99}</style><h1>Campaign Ledger</h1><p>Isolated UI review · generated from the Luau UI constructors · approximate fonts and engine layout</p><div class="panels">'''
body=''
for name in ['ledger-330','ledger-wide','ledger-recovery','dice']:
 data=json.loads((base/f'{name}.json').read_text());w,h=data['width'],data['height'];root=data['root'];_,_,boxes=dimensions(root,w,h,(w,h))
 body+=f'<section class="pane"><h2>{labels[name]}</h2><div class="window" style="width:{w}px;height:{h}px">'+render(root,0,0,w,h,boxes)+'</div></section>'
(base/'review.html').write_text(head+body+'</div></html>')
for name in ['ledger-details','ledger-empty','ledger-minimum']:
 data=json.loads((base/f'{name}.json').read_text());w,h=data['width'],data['height'];root=data['root'];_,_,boxes=dimensions(root,w,h,(w,h))
 (base/f'{name}.html').write_text(head+f'<section><h2>{labels[name]}</h2><div class="window" style="width:{w}px;height:{h}px">'+render(root,0,0,w,h,boxes)+'</div></section></div></html>')
launcher_body=''
for name,label in [('launcher-player','Player defaults'),('launcher-dm','DM controls enabled'),('launcher-inactive','World not enabled')]:
 data=json.loads((base/f'{name}.json').read_text());w,h=data['width'],data['height'];root=data['root'];_,_,boxes=dimensions(root,w,h,(w,h))
 launcher_body+=f'<section class="pane"><h2>{label}</h2><div class="window" style="width:{w}px;height:{h}px">'+render(root,0,0,w,h,boxes)+'</div></section>'
(base/'launcher.html').write_text(head.replace('<h1>Campaign Ledger</h1>','<h1>Campaign Tools launcher</h1>')+launcher_body+'</div></html>')
