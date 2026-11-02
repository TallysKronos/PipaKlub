"""Index actual native captures and verify dimensions, without editing image pixels."""
from pathlib import Path
import hashlib
import html
import json
import struct
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "documentation/hud-v2/pip-135"
captures = []
for path in sorted((DEST / "capturas").glob("*.png")):
    raw = path.read_bytes()
    dimensions = struct.unpack(">II", raw[16:24])
    assert dimensions == tuple(map(int, path.name.split("-")[0].split("x"))), path
    captures.append({"file": path.relative_to(DEST).as_posix(), "size": dimensions,
                     "sha256": hashlib.sha256(raw).hexdigest()})
assert len(captures) == 40, len(captures)
(DEST / "integridade.json").write_text(json.dumps({
    "renderer": "Godot 4.7.2 native OpenGL compatibility",
    "source": "res://tools/mural_menu_capture.gd",
    "method": "Viewport PNG; unmodified pixels; one resolution per process",
    "state": "isolated in-memory player fixture, no player save modified",
    "artSource": "art/ui/soulmonsters-v2/pip-135-v2/manifest.json",
    "captures": captures}, indent=2, ensure_ascii=False), encoding="utf-8")
cards = "\n".join(
    f'<figure data-screen="{Path(c["file"]).stem.split("-")[1]}"><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(Path(c["file"]).stem)}"></a><figcaption>{html.escape(Path(c["file"]).stem)}</figcaption></figure>'
    for c in captures)
(DEST / "index.html").write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>PIP-135 · Menus do Elo</title>
<style>body{margin:0;background:#0c2530;color:#fff1d2;font:18px system-ui}header{padding:32px;max-width:1050px}
a{color:#77d0bc}button{font:inherit;padding:12px;margin:6px;color:#123442;background:#fff1d2;border:2px solid #77d0bc;cursor:pointer}button[aria-pressed=true]{background:#ffc53e}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,520px),1fr));gap:24px;padding:0 24px 32px}figure{margin:0;background:#123442;padding:12px}img{width:100%;height:auto}figcaption{padding:12px 0;overflow-wrap:anywhere}figure[hidden]{display:none}</style>
<header><h1>Menus do Elo · revisão de personalidade</h1><p>Varal com etiquetas presas, Dex encadernada, diagrama de varetas e estojo costurado.
Arte modular com textos, atributos e controles nativos. Quatro resoluções; texto 100/150%.</p>
<p><a href="REVISAO.md">Revisão e limites</a> · <a href="testes.json">Testes</a> · <a href="integridade.json">Integridade das capturas</a></p>
<nav aria-label="Filtrar capturas">''' + "".join(f'<button data-filter="{key}" aria-pressed="{str(key=="all").lower()}">{label}</button>' for key,label in [("all","Todos"),("varal","Varal"),("dex","Dex"),("evolution","Evolução"),("emblems","Emblemas"),("lobby","Lobby")]) + '</nav></header><main>' + cards + '''</main><script>
document.querySelectorAll('[data-filter]').forEach(button=>button.onclick=()=>{document.querySelectorAll('[data-filter]').forEach(other=>other.setAttribute('aria-pressed',String(button===other)));document.querySelectorAll('figure').forEach(card=>card.hidden=button.dataset.filter!=='all'&&card.dataset.screen!==button.dataset.filter)});
</script></html>''', encoding="utf-8")
print(f"{len(captures)} native captures indexed; dimensions verified")
