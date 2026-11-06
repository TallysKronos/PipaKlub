from pathlib import Path
from PIL import Image
from collections import Counter
import json
root=Path(__file__).parent.parent
pairs=[
('velcao',root/'velcao/overworld-anim-64-v1/revisao-recortes/a-velcao-left.png',root/'velcao/overworld-anim-64-v1/velcao-left.png'),
('alvacordo',root/'alvacordo/overworld-anim-64-v2/revisao-recortes/antes.png',root/'alvacordo/overworld-anim-64-v2/alvacordo-64.png')]
report={}
for name,before,after in pairs:
 a=Image.open(before).convert('RGBA');b=Image.open(after).convert('RGBA')
 assert a.size==b.size==(2048,64)
 changes=[];opaque_edits=0;added=0;removed=0
 for f in range(32):
  n=0
  for y in range(64):
   for x in range(64):
    p=(64*f+x,y);old=a.getpixel(p);new=b.getpixel(p)
    if old!=new:
     n+=1
     if old[3]:opaque_edits+=1
     if not old[3] and new[3]:added+=1
     if old[3] and not new[3]:removed+=1
  if n:changes.append({'frame':f+1,'pixels':n})
 report[name]={'changed_frames':changes,'total_changed':sum(c['pixels'] for c in changes),'opaque_pixels_changed':opaque_edits,'added':added,'removed':removed}
 if name=='velcao':
  assert opaque_edits==0 and added==492
 else:
  for f in [4,5,6,11,15]:
   assert all(b.getpixel((64*(f-1)+x,46))[3]==255 for x in range(40,44))
  for f in [19,20,21,22,23]:
   assert all(b.getpixel((64*(f-1)+x,y))[3]==255 for y in [45,46] for x in range(40,44))
  for f in [19,20,21,22]:
   assert all(b.getpixel((64*(f-1)+x,y))[3]==0 for y in range(47,53) for x in [14,15])
  metrics=[]
  for f in range(32):
   cell=b.crop((f*64,0,(f+1)*64,64));cs=Counter(cell.get_flattened_data())
   metrics.append({'frame':f+1,'opaque':sum(n for c,n in cs.items() if c[3]),'visible_colors':sum(1 for c in cs if c[3]),'bounds':cell.getbbox()})
  (root/'alvacordo/overworld-anim-64-v2/validacao-grades.json').write_text(json.dumps(metrics,indent=2))
(root/'overworld-family-64-v1/validacao-recortes.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
# Diagnostic controls for this local review page, no runtime game changes.
p=root/'overworld-family-64-v1/index.html'
html=p.read_text(encoding='utf-8')
if 'id="step-prev"' not in html:
 controls='''const nav=document.querySelector("nav");
for(const [id,label,delta] of [["step-prev","◀ Quadro",-1],["step-next","Quadro ▶",1]]){const b=document.createElement("button");b.id=id;b.textContent=label;b.onclick=()=>{paused=true;document.getElementById("pause").textContent="Continuar";for(const c of cards){c.f=c.f+delta;if(c.f>c.to)c.f=c.from;if(c.f<c.from)c.f=c.to;c.time=0;c.done=false;}};nav.appendChild(b);}
let bgMode=0;document.getElementById("bg").onclick=()=>{bgMode=(bgMode+1)%3;document.querySelectorAll(".stage").forEach(e=>e.style.background=["#a8b6b8","#152327","#f02bad"][bgMode]);};
'''
 html=html.replace('</script>',controls+'</script>')
 html=html.replace('left.src=c.left;','left.src=c.left+"?rev=recortes-20261105";').replace('right.src=c.right;','right.src=c.right+"?rev=recortes-20261105";')
 p.write_text(html,encoding='utf-8')
print('qa and review controls updated')

