from pathlib import Path
from PIL import Image,ImageChops,ImageOps
import json,hashlib,unicodedata,shutil

ROOT=Path(__file__).resolve().parents[2]
SCRATCH=ROOT/"tmp/overworld-xprite-v2"
OUT=ROOT/"art/creatures/soulmonsters-overworld-v2"
inventory=SCRATCH/"inventory.json"
if not inventory.exists():inventory=Path(__file__).with_name("roster.json")
SCRATCH.mkdir(parents=True,exist_ok=True)
rows=json.loads(inventory.read_text(encoding="utf-8"))
def plain(text):
    return "".join(c for c in unicodedata.normalize("NFD",text.lower()) if not unicodedata.combining(c))
def height_for(row):
    stage=plain(row["stage"])
    if "bebe" in stage:return 41
    if "crianca" in stage or row["id"]=="rabbito":return 55
    if "jovem" in stage:return 70
    if "adult" in stage or "guerreiro" in stage:return 84
    if row["id"] in ["rabbitknight","mestre-dos-fios","rastro-dos-ventos"]:return 84
    if row["id"] in ["nozinho","capimansa","micofolha","platyx","araruna-memoria","caimbira-memoria"]:return 55
    # Undecided canon stages keep the visual body class of the existing study.
    return 84
def orientation_error(source,reference):
    def fitted(image):
        mask=image.getchannel("A").point(lambda v:255 if v>=128 else 0)
        box=mask.getbbox()
        image=image.crop(box)
        return image.resize((48,48),Image.Resampling.NEAREST)
    source=fitted(source)
    reference=fitted(reference)
    a=list(source.get_flattened_data())
    b=list(reference.get_flattened_data())
    return sum((sum((x[c]-y[c])**2 for c in range(3)) if x[3] and y[3] else 60000 if bool(x[3])!=bool(y[3]) else 0) for x,y in zip(a,b))/len(a)

for row in rows:
    id_=row["id"]
    row["targetHeight"]=height_for(row)
    folder=OUT/id_
    folder.mkdir(parents=True,exist_ok=True)
    old=ROOT/f"godot/assets/campaign/overworld-companions/{id_}.png"
    if not old.exists():
        old=ROOT/f"art/creatures/soulmonsters-overworld-concepts-novos-v1/{id_}/duas-vistas.png"
    row["old"]=old.relative_to(ROOT).as_posix()
    row["oldHash"]=hashlib.sha256(old.read_bytes()).hexdigest()
    if row["method"]=="native-drawing":
        continue
    source=(ROOT/row["source"]).resolve()
    if id_=="alvacordo":
        source=ROOT/"art/creatures/alvacordo-family-v1/alvacordo/overworld-diagonal-v1/geracao-v2.png"
    if not source.is_file():raise FileNotFoundError(source)
    row["sourceHash"]=hashlib.sha256(source.read_bytes()).hexdigest()
    target=folder/"geracao.png"
    if not target.exists() or id_=="alvacordo":shutil.copy2(source,target)
    row["source"]=target.relative_to(ROOT).as_posix()
    image=Image.open(source).convert("RGBA")
    if id_=="glacerol":
        image=Image.open(folder/"geracao-transparente.png").convert("RGBA")
        row["backgroundCleanup"]="Xprite edge-seeded flood, white tolerance 28"
    rear_override=None
    if id_=="tramino":
        original=folder/"geracao-frente.png"
        separate=folder/"geracao-costas.png"
        if not original.exists():
            original=ROOT/"../pipa-club-overworld-campanha/art/creatures/cavaleiros-pre-evos-overworld-v1/tramino/geracao.png"
            shutil.copy2(original,folder/"geracao-frente.png")
        if not separate.exists():
            separate=ROOT/"../pipa-club-overworld-campanha/art/creatures/cavaleiros-pre-evos-overworld-v1/tramino/geracao-costas-v2.png"
            shutil.copy2(separate,folder/"geracao-costas.png")
        image=Image.open(original).convert("RGBA")
        rear_override=Image.open(separate).convert("RGBA")
        row["rearSource"]=(folder/"geracao-costas.png").relative_to(ROOT).as_posix()
    reference=Image.open(old).convert("RGBA")
    oldsize=reference.width//2
    poses=[]
    for i in range(2):
        panel=image.crop((image.width//2*i,0,image.width//2*(i+1),image.height))
        if rear_override is not None and i==1:panel=rear_override
        mask=panel.getchannel("A").point(lambda v:255 if v>=128 else 0)
        box=mask.getbbox()
        if box is None:raise ValueError((id_,i,"empty"))
        panel=panel.crop(box)
        panel.putalpha(panel.getchannel("A").point(lambda v:255 if v>=128 else 0))
        oldcell=reference.crop((oldsize*i,0,oldsize*(i+1),reference.height))
        straight=orientation_error(panel,oldcell)
        mirrored=orientation_error(ImageOps.mirror(panel),oldcell)
        flip=mirrored < straight*.91
        if flip:panel=ImageOps.mirror(panel)
        poseHeight=row["targetHeight"]
        proportional=round(panel.width*poseHeight/panel.height)
        targetWidth=min(110,proportional)
        if i==1 and id_ in ["lupisco","tramino"]:
            targetWidth=min(110,round(targetWidth*(1.24 if id_=="lupisco" else 1.18)))
            row["rearWidthReview"]="Correção da massa corporal a partir da fonte original"
        raw=SCRATCH/f"{id_}-{i}.rgba"
        raw.write_bytes(panel.tobytes())
        poses.append(dict(width=panel.width,height=panel.height,targetWidth=targetWidth,targetHeight=poseHeight,sourceBounds=list(box),mirroredToMatchReviewedView=flip,widthRatio=targetWidth/proportional))
    row["poses"]=poses
    if id_=="azulfazo": row["reuseApproved"]="art/creatures/soulmonsters-overworld-v2/azulfazo-xprite/duas-vistas.png"
(SCRATCH/"batch.json").write_text(json.dumps(rows,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
print("Prepared",len(rows),"sheets",sum(r["method"]!="native-drawing" for r in rows),"Xprite inputs")
print("Width constrained",[(r["id"],round(min(p["widthRatio"] for p in r.get("poses",[dict(widthRatio=1)])),2)) for r in rows if any(p["widthRatio"]<.9 for p in r.get("poses",[]))])
