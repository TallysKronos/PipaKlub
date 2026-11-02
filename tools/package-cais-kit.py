"""Normalize the six inspected atlas objects, preserving their generated alpha."""
from pathlib import Path
from PIL import Image, ImageFilter, ImageChops
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/overworld/kits/cais-v1/source.png"
OUTPUT = ROOT / "godot/assets/overworld/kits/cais-v1"
BOXES = {"fachada": (16,120,590,410), "telhado": (600,120,1085,405),
         "barco": (1090,15,1536,475), "mastro": (90,420,400,990),
         "materiais": (455,560,1006,998), "banca": (1010,440,1536,1005)}

def main_object(image):
    """Separate a detached neighbouring atlas fragment, not a painted background."""
    alpha = image.getchannel("A")
    w,h = image.size
    raw,seen,groups = alpha.tobytes(),bytearray(w*h),[]
    for seed in range(w*h):
        if seen[seed] or raw[seed] <= 40: continue
        seen[seed] = 1
        queue,group = [seed],[]
        while queue:
            n = queue.pop();group.append(n);x,y = n%w,n//w
            adjacent = ([n-1] if x else []) + ([n+1] if x+1<w else [])
            adjacent += ([n-w] if y else []) + ([n+w] if y+1<h else [])
            for j in adjacent:
                if not seen[j] and raw[j]>40: seen[j]=1;queue.append(j)
        groups.append(group)
    mask = bytearray(w*h)
    for n in max(groups,key=len): mask[n]=255
    keep = Image.frombytes("L",(w,h),bytes(mask)).filter(ImageFilter.MaxFilter(5))
    image.putalpha(ImageChops.multiply(alpha,keep))
    return image

atlas=Image.open(SOURCE).convert("RGBA")
OUTPUT.mkdir(parents=True,exist_ok=True)
assets={}
for name,box in BOXES.items():
    image=atlas.crop(box)
    image=image.crop(image.getchannel("A").point(lambda a:255 if a>40 else 0).getbbox())
    if name=="banca":image=main_object(image)
    image.save(OUTPUT/(name+".png"))
    assets[name]={"file":name+".png","size":list(image.size),"sourceBox":box}
(OUTPUT/"kit.json").write_text(json.dumps({"id":"cais-v1","source":"image_gen built-in",
    "state":"initial map art pending review","projection":"isometric64x32; facade/roof flat UV surfaces",
    "assets":assets},ensure_ascii=False,indent=2),encoding="utf-8")
