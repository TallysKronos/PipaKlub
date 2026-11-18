from pathlib import Path
import bpy,tempfile,subprocess,os
D=Path(__file__).resolve().parent
s=bpy.context.scene
rig=next(o for o in s.objects if o.type=='ARMATURE')
s.cycles.samples=2;s.cycles.use_denoising=True;s.render.resolution_percentage=50
py=os.environ.get('PYTHON_COM_PILLOW','python')
for name,end in [('Idle',151),('Imponencia',181)]:
 for tr in rig.animation_data.nla_tracks:tr.mute=tr.name!=name
 with tempfile.TemporaryDirectory(dir=D) as tmp:
  start=None;max_lift=0
  for f in sorted(set(range(1,end,3))|{end}):
   s.frame_set(f)
   joints={p.name:p.matrix.copy() for p in rig.pose.bones}
   if start is None:start=joints
   for b in ('fore_L','fore_R','heel_L','heel_R'):
    assert (joints[b].translation-start[b].translation).length<.0001
   max_lift=max(max_lift,(joints['head'].translation-start['head'].translation).length)
   if f==end:
    assert all(max(abs(joints[b][i][j]-start[b][i][j]) for i in range(4) for j in range(4))<.0001 for b in joints)
    break
   s.render.filepath=str(Path(tmp)/f'{f:03}.png');bpy.ops.render.render(write_still=True)
  print(name,'head displacement',max_lift,flush=True)
  subprocess.run([str(py),'-c',"""from PIL import Image
from pathlib import Path
import sys
frames=[Image.open(p).convert('RGB') for p in sorted(Path(sys.argv[1]).glob('*.png'))]
w,h=frames[0].size
strip=Image.new('RGB',(w,h*3))
for i in range(3):strip.paste(frames[i*len(frames)//3],(0,h*i))
pal=strip.quantize(colors=240)
imgs=[x.quantize(palette=pal,dither=Image.Dither.NONE) for x in frames]
imgs[0].save(sys.argv[2],save_all=True,append_images=imgs[1:],duration=100,loop=0,disposal=1)
""",tmp,str(D/(name+'.gif'))],check=True)
