from pathlib import Path
from PIL import Image, ImageSequence
from collections import Counter
import json
p=Path(__file__).parent
atlas=json.loads((p/'alvacordo-64.json').read_text())
frames=atlas['frames']
im=Image.open(p/'alvacordo-64.png').convert('RGBA')
result={'atlas_size':im.size,'frames':len(frames),'tags':atlas['meta']['frameTags'],'gif':{},'frame_checks':[]}
for i,f in enumerate(frames):
 r=f['frame']; cell=im.crop((r['x'],r['y'],r['x']+r['w'],r['y']+r['h']))
 counts=Counter(cell.get_flattened_data())
 result['frame_checks'].append({'frame':i+1,'size':cell.size,'duration_ms':f['duration'],'visible_colors':sum(1 for c in counts if c[3]),'partial_alpha_pixels':sum(n for c,n in counts.items() if 0<c[3]<255)})
for name in ['idle','walk','victory','defeat']:
 g=Image.open(p/(name+'-4x.gif'))
 result['gif'][name]={'size':g.size,'encoded_frames':g.n_frames,'duration_ms':sum(f.info.get('duration',0) for f in ImageSequence.Iterator(g))}
assert len(frames)==32
assert im.size==(2048,64)
assert all(f['size']==(64,64) and f['partial_alpha_pixels']==0 for f in result['frame_checks'])
assert {t['name'] for t in result['tags']}=={'idle','walk','victory','defeat'}
(p/'validacao-exports.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='frame_checks'},indent=2))

