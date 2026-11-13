"""Verify stationary source-authored idle regions in a configured prancha batch."""
from pathlib import Path
from PIL import Image
import argparse,json
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser()
p.add_argument('--batch',type=Path,required=True)
args=p.parse_args()
batch=json.loads(args.batch.read_text(encoding='utf-8-sig'))
for model in batch['models']:
 if not model.get('authored_idle'):continue
 source=Image.open(ROOT/model['source']).convert('RGBA')
 folder=ROOT/model['folder']
 idle=Image.open(folder/'idle.png').convert('RGBA')
 records=[]
 for row,view in enumerate(('sw','nw')):
  base=source.crop((row*112,0,(row+1)*112,112))
  region=model['authored_idle']['views'][view]['region']
  for f in range(4):
   cell=idle.crop((f*112,row*112,(f+1)*112,(row+1)*112))
   assert cell.getchannel('A').tobytes()==base.getchannel('A').tobytes(),(model['id'],view,f,'silhouette moved')
   changed=[]
   for y in range(112):
    for x in range(112):
     if cell.getpixel((x,y))!=base.getpixel((x,y)):
      assert region[0]<=x<region[2]and region[1]<=y<region[3],(model['id'],view,f,'protected pixel changed')
      changed.append([x,y])
   records.append(dict(view=view,pose=f,changed_pixels=len(changed),coordinates=changed,
                       source_silhouette_exact=True,protected_source_regions_exact=True))
 report=dict(id=model['id'],source=model['source'],durations_ms=[750,200,750,200],
             anchor=[56,100],translation=[0,0],frames=records)
 (folder/'idle-regioes-protegidas.json').write_text(json.dumps(report,indent=2)+'\n')
 print(model['id'],'source silhouette and protected regions exact;max changed',max(r['changed_pixels']for r in records))
