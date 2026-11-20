from pathlib import Path
from PIL import Image
import json
p=Path("tmp/overworld-xprite-v2")
rows=json.loads((p/"batch.json").read_text(encoding="utf-8"))
problems=[]
for row in rows:
    path=Path("art/creatures/soulmonsters-overworld-v2")/row["id"]/"duas-vistas.png"
    if not path.exists():problems.append((row["id"],"missing"));continue
    im=Image.open(path).convert("RGBA")
    if im.size!=(224,112):problems.append((row["id"],"size",im.size));continue
    views=[]
    for n in range(2):
        cell=im.crop((112*n,0,112*(n+1),112))
        b=cell.getbbox()
        views.append(dict(bounds=b,area=sum(pixel[3]>0 for pixel in cell.get_flattened_data())))
    heights=[v["bounds"][3]-v["bounds"][1] for v in views]
    floors=[v["bounds"][3] for v in views]
    if heights!=[row["targetHeight"]]*2 or floors!=[100,100]:
        problems.append((row["id"],"height/floor",row["targetHeight"],heights,floors))
    areas=[v["area"] for v in views]
    drift=(max(areas)-min(areas))/max(areas)
    if drift>.30:problems.append((row["id"],"area-drift",round(drift,2),areas))
print("Problems",len(problems))
for issue in problems:print(issue)
