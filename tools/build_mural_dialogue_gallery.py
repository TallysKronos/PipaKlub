"""Index original Godot captures without modifying their pixels."""
from pathlib import Path
import hashlib
import html
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "documentation/hud-v2/pip-134"
captures = []
for path in sorted((DEST / "capturas").glob("*.png")):
    raw = path.read_bytes()
    width, height = struct.unpack(">II", raw[16:24])
    expected = tuple(map(int, path.name.split("-")[0].split("x")))
    assert (width, height) == expected, path
    captures.append({"file": path.relative_to(DEST).as_posix(), "width": width,
                     "height": height, "sha256": hashlib.sha256(raw).hexdigest()})
assert len(captures) == 40, len(captures)
(DEST / "integridade.json").write_text(json.dumps({
    "renderer": "Godot 4.7.2 native OpenGL compatibility",
    "source": "res://tools/mural_dialogue_capture.gd",
    "method": "Viewport PNG, unchanged pixels; opening captured one process per resolution",
    "fixtures": "24 shared-dialogue states over existing illustration; 16 isolated opening states",
    "captures": captures,
}, indent=2, ensure_ascii=False), encoding="utf-8")
cards = "\n".join(
    f'<figure><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(Path(c["file"]).stem)}"></a>'
    f'<figcaption>{html.escape(Path(c["file"]).stem)}</figcaption></figure>' for c in captures)
(DEST / "index.html").write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>PIP-134 · Diálogos Mural</title>
<style>body{margin:0;background:#0c2530;color:#fff1d2;font:18px system-ui}header{padding:32px;max-width:1000px}
h1{margin:0 0 16px}a{color:#77d0bc}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,520px),1fr));gap:24px;padding:0 24px 32px}
figure{margin:0;background:#123442;padding:12px}img{width:100%;height:auto}figcaption{padding:12px 0;overflow-wrap:anywhere}</style>
<header><h1>Conversas no Mural de Kronasta</h1><p>Papel para a fala, tinta para o nome e amarelo para a resposta selecionada.
40 capturas nativas, quatro resoluções, texto 100/150%. Clique para abrir em tamanho original.</p>
<p>Fala/escolhas/dupla são fixtures sobre uma ilustração existente. Abertura é a cena real em estado isolado de teste.</p>
<a href="REVISAO.md">Revisão e limites</a> · <a href="testes.json">Verificações</a> · <a href="integridade.json">Dimensões e hashes</a></header>
<main>''' + cards + '</main></html>', encoding="utf-8")
print(f"{len(captures)} original captures indexed; dimensions verified")
