"""Index native result/milestone captures, preserving their original pixels."""
from pathlib import Path
import json, hashlib, struct, html
root=Path(__file__).resolve().parents[1]
dest=root/"documentation/hud-v2/pip-136"
captures=[]
for path in sorted((dest/"capturas").glob("*.png")):
    raw=path.read_bytes();dimensions=struct.unpack(">II",raw[16:24])
    assert dimensions==tuple(map(int,path.name.split("-")[0].split("x"))),path
    captures.append({"file":path.relative_to(dest).as_posix(),"size":dimensions,"sha256":hashlib.sha256(raw).hexdigest()})
assert len(captures)==72,len(captures)
(dest/"integridade.json").write_text(json.dumps({"renderer":"Godot 4.7.2 native OpenGL compatibility","method":"Viewport PNG, unchanged pixels, one resolution per process","fixture":"standalone production encounter/milestone views with in-memory player state, not a full campaign playthrough","source":"res://tools/mural_result_capture.gd","captures":captures},indent=2,ensure_ascii=False),encoding="utf-8")
cards="\n".join(f'<figure data-state="{Path(c["file"]).stem.split("-")[1]}"><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(Path(c["file"]).stem)}"></a><figcaption>{html.escape(Path(c["file"]).stem)}</figcaption></figure>' for c in captures)
filters=[("all","Todos"),("won","Vitória"),("lost","Derrota"),("fled","Recuo"),("morro","Bairro"),("boss","Boss"),("blocked","Falha ao salvar"),("item","Item"),("emblem","Insígnia"),("level","Nível")]
buttons="".join(f'<button data-filter="{key}" aria-pressed="{str(key=="all").lower()}">{label}</button>' for key,label in filters)
(dest/"index.html").write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>PIP-136 · Resultados e conquistas</title>
<style>body{margin:0;background:#0c2530;color:#fff1d2;font:18px system-ui}header{padding:32px;max-width:1100px}a{color:#77d0bc}button{font:inherit;padding:12px;margin:6px;background:#fff1d2;color:#123442;border:2px solid #77d0bc;cursor:pointer}button[aria-pressed=true]{background:#ffc53e}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,520px),1fr));gap:24px;padding:0 24px 32px}figure{margin:0;background:#123442;padding:12px}figure[hidden]{display:none}img{width:100%;height:auto}figcaption{padding-top:12px;overflow-wrap:anywhere}</style>
<header><h1>Resultados e conquistas do Elo</h1><p>Vitória com rabiolas abertas, derrota com fio rompido e recuo com linha recolhida. Recompensas previstas ficam explícitas; nível só comemora depois da gravação.</p><p>72 capturas nativas, quatro resoluções, texto 100/150%. São estados isolados dos componentes reais, sem alterar o save do jogador.</p><a href="REVISAO.md">Revisão e limites</a> · <a href="testes.json">Testes</a> · <a href="integridade.json">Dimensões e hashes</a><nav aria-label="Filtrar estados">'''+buttons+'</nav></header><main>'+cards+'''</main><script>document.querySelectorAll('[data-filter]').forEach(button=>button.onclick=()=>{document.querySelectorAll('[data-filter]').forEach(other=>other.setAttribute('aria-pressed',String(other===button)));document.querySelectorAll('figure').forEach(card=>card.hidden=button.dataset.filter!=='all'&&card.dataset.state!==button.dataset.filter)});</script></html>''',encoding="utf-8")
print(f"{len(captures)} native captures verified and indexed")
