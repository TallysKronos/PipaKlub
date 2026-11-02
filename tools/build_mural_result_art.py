from pathlib import Path
from PIL import Image
import json, hashlib
root = Path(__file__).resolve().parents[1]
manifest = {"method":"alpha>=64 bbox crop; uniform resize to width 1200; no repaint", "assets":[]}
for name in ("won", "lost", "fled"):
    source = root / f"art/ui/soulmonsters-v2/pip-136/fontes/{name}.png"
    image = Image.open(source).convert("RGBA")
    box = image.getchannel("A").point(lambda a: 255 if a>=64 else 0).getbbox()
    image = image.crop(box)
    image = image.resize((1200,round(image.height*1200/image.width)),Image.Resampling.LANCZOS)
    target = root / f"godot/assets/ui/mural-v1/results-v1/{name}.png"
    image.save(target)
    manifest["assets"].append({"id":name,"crop":box,"size":image.size,"source":source.relative_to(root).as_posix(),"sha256":hashlib.sha256(source.read_bytes()).hexdigest()})
(root/"art/ui/soulmonsters-v2/pip-136/manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
print([(row["id"],row["size"]) for row in manifest["assets"]])
