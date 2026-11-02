"""Reuse canonical Dex prose only for species with actual Godot combat assets."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
source = json.loads((ROOT / "assets/pipa-dex.json").read_text(encoding="utf-8"))
content = json.loads((ROOT / "godot/assets/campaign/content.json").read_text(encoding="utf-8"))
rows = [{key: entry.get(key, [] if key == "story" else "")
         for key in ("model", "name", "habitat", "story", "note")}
        for entry in source["entries"] if entry.get("model") and entry.get("atlas") in content["combat"]]
rows.append({"model": "doberman-c", "name": "Dóber de papel", "story": [],
             "habitat": "", "note": "Pode acompanhar o pipeiro como montaria."})
(ROOT / "godot/assets/campaign/mural-catalog.json").write_text(
    json.dumps(rows, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(f"{len(rows)} Godot species; no online-only obtain conditions copied")
