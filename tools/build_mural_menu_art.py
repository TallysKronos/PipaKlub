"""Mechanical alpha bounding-box crop and uniform resize of generated UI art."""
from pathlib import Path
from PIL import Image
import hashlib
import json
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/ui/soulmonsters-v2/pip-135-v2"
DEST = ROOT / "godot/assets/ui/mural-v1/menus-v2"
manifest = {"method": "Alpha >=64 bounding box, crop, uniform LANCZOS resize to width 1200; no repaint",
            "styleReference": "art/ui/soulmonsters-v2/pip-128-v2/B-prancha.png", "assets": []}
for name in ("cloth", "dex", "evolution", "case", "tag"):
    source = SOURCE / "fontes" / (name+("-scalable" if name != "tag" else "")+".png")
    image = Image.open(source).convert("RGBA")
    box = image.getchannel("A").point(lambda value: 255 if value >= 64 else 0).getbbox()
    crop = image.crop(box)
    crop = crop.resize((1200, round(crop.height*1200/crop.width)), Image.Resampling.LANCZOS)
    target = DEST / (name+".png")
    crop.save(target)
    assert crop.getchannel("A").getextrema() == (0, 255)
    manifest["assets"].append({"id":name, "source":source.relative_to(ROOT).as_posix(),
                              "sourceSHA256":hashlib.sha256(source.read_bytes()).hexdigest(),
                              "crop":box, "size":crop.size, "file":target.relative_to(ROOT).as_posix()})
(SOURCE/"manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("5 alpha assets cropped and uniformly resized; source files preserved")
