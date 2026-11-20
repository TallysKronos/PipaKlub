from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,shutil
root=Path(__file__).resolve().parents[2]
scratch=root/"tmp/overworld-xprite-v2"
out=root/"art/creatures/soulmonsters-overworld-v2"
rows=json.loads((scratch/"batch.json").read_text(encoding="utf-8"))
ready=[]
for row in rows:
    if row["method"]=="native-drawing":continue
    raw=scratch/(row["id"]+"-xprite.rgba")
    if not raw.exists():continue
    image=Image.frombytes("RGBA",(224,112),raw.read_bytes())
    if row.get("reuseApproved"):
        image=Image.open(root/row["reuseApproved"]).convert("RGBA")
    image.save(scratch/(row["id"]+"-base.png"))
    ready.append(row)
(scratch/"export-ids.txt").write_text("\n".join(r["id"] for r in ready),encoding="ascii")
font=ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf",13)
small=ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf",11)
for start in range(0,len(ready),16):
    batch=ready[start:start+16]
    canvas=Image.new("RGBA",(1200,4*278),"#35454e")
    draw=ImageDraw.Draw(canvas)
    for i,row in enumerate(batch):
        left=i%4*300
        top=i//4*278
        draw.text((left+8,top+4),row["id"],font=font,fill="#f4ead5")
        draw.text((left+8,top+23),str(row["targetHeight"])+" px · "+row["stage"],font=small,fill="#bccbd0")
        image=Image.open(scratch/(row["id"]+"-base.png")).convert("RGBA")
        # Exact 1x reference plus 2x front, no interpolating preview.
        canvas.alpha_composite(image,(left+8,top+45))
        front=image.crop((0,0,112,112)).resize((224,224),Image.Resampling.NEAREST)
        front=front.crop((0,52,224,224))
        canvas.alpha_composite(front,(left+45,top+106))
    canvas.save(scratch/("review-"+str(start//16).zfill(2)+".png"))
print("Ready",len(ready))
