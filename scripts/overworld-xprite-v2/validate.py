from pathlib import Path
from PIL import Image
from collections import deque
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
out=ROOT/"art/creatures/soulmonsters-overworld-v2"
manifest=json.loads((out/"manifest.json").read_text(encoding="utf-8"))
records=[]
for asset in manifest["assets"]:
    id_=asset["id"]
    file=out/asset["sheet"]
    im=Image.open(file).convert("RGBA")
    colors={p[:3] for p in im.get_flattened_data() if p[3]}
    checks=dict(size=im.size==(224,112),palette=len(colors)<=20,binaryAlpha=set(im.getchannel("A").get_flattened_data())<={0,255},editable=(out/asset["editable"]).exists())
    views=[]
    for i in range(2):
        cell=im.crop((112*i,0,112*(i+1),112))
        pixels=cell.load()
        occupied={(x,y) for y in range(112) for x in range(112) if pixels[x,y][3]}
        singles=[]
        for x,y in occupied:
            if not any((x+dx,y+dy) in occupied for dx in (-1,0,1) for dy in (-1,0,1) if dx or dy):singles.append([x,y])
        box=cell.getbbox()
        views.append(dict(bounds=list(box),height=box[3]-box[1],bottom=box[3],opaque=len(occupied),opaqueSingles8=singles))
    checks["height"]=all(v["height"]==asset["height"] for v in views)
    checks["ground"]=all(v["bottom"]==100 for v in views)
    checks["opaqueSingletons"]=all(not v["opaqueSingles8"] for v in views)
    runtime=ROOT/"godot/assets/campaign/overworld-v2"/id_/"duas-vistas.png"
    checks["runtimeMatches"]=hashlib.sha256(runtime.read_bytes()).hexdigest()==hashlib.sha256(file.read_bytes()).hexdigest()
    records.append(dict(id=id_,colors=len(colors),views=views,checks=checks,pass_=all(checks.values())))
report=dict(count=len(records),views=len(records)*2,passed=sum(r["pass_"] for r in records),records=records,notes="A contagem de pixels opacos soltos usa oito vizinhos. A revisão visual de clusters e detalhes internos é registrada em REVISAO.md.")
(out/"validacao.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
print(report["passed"],"/",report["count"],"sheets,",report["views"],"views")
for row in records:
    if not row["pass_"]:print(row["id"],row["checks"])
assert report["passed"]==194
