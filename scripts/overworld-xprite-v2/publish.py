from pathlib import Path
from PIL import Image,ImageFont,ImageDraw
import json,hashlib,shutil,html
ROOT=Path(__file__).resolve().parents[2]
scratch=ROOT/"tmp/overworld-xprite-v2"
out=ROOT/"art/creatures/soulmonsters-overworld-v2"
runtime=ROOT/"godot/assets/campaign/overworld-v2"
rows=json.loads((scratch/"batch.json").read_text(encoding="utf-8"))
assets=[]
problems=[]
for row in rows:
    id_=row["id"]
    folder=out/id_
    path=folder/"duas-vistas.png"
    ase=folder/(id_+"-overworld.aseprite")
    image=Image.open(path).convert("RGBA")
    assert image.size==(224,112),id_
    assert ase.is_file(),id_
    colors={p[:3] for p in image.get_flattened_data() if p[3]}
    assert len(colors)<=20,(id_,len(colors))
    assert set(image.getchannel("A").get_flattened_data())<={0,255},id_
    frames=[]
    for i,direction in enumerate(["frente-sw","costas-nw"]):
        cell=image.crop((112*i,0,112*(i+1),112))
        bounds=cell.getbbox()
        left,top,right,bottom=bounds
        assert bottom==100 and bottom-top==row["targetHeight"],(id_,direction,bounds,row["targetHeight"])
        assert left>=0 and right<=112,id_
        frames.append(dict(filename=direction,frame=dict(x=112*i,y=0,w=112,h=112),rotated=False,trimmed=False,sourceSize=dict(w=112,h=112),contentBounds=dict(x=left,y=top,width=right-left,height=bottom-top),pivot=dict(x=56,y=100)))
    metadata=dict(frames=frames,meta=dict(image="duas-vistas.png",size=dict(w=224,h=112),scale="1",sampling="nearest",slices=[dict(name="chao",keys=[dict(frame=0,bounds=dict(x=0,y=0,w=112,h=112),pivot=dict(x=56,y=100))])]))
    (folder/"duas-vistas.json").write_text(json.dumps(metadata,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    dest=runtime/id_
    dest.mkdir(parents=True,exist_ok=True)
    shutil.copy2(path,dest/"duas-vistas.png")
    shutil.copy2(folder/"duas-vistas.json",dest/"duas-vistas.json")
    assets.append(dict(id=id_,name=row["name"],family=row["family"],stage=row["stage"],height=row["targetHeight"],colors=len(colors),image=f"res://assets/campaign/overworld-v2/{id_}/duas-vistas.png",sheet=f"{id_}/duas-vistas.png",editable=f"{id_}/{id_}-overworld.aseprite",old="../../../"+row["old"],sha256=hashlib.sha256(path.read_bytes()).hexdigest(),source=row.get("source"),sourceHash=row.get("sourceHash"),method=row["method"],frontMirroredAfterReview=id_ in ["araruna-memoria","capibaluarte","mestre-dos-fios"]))
manifest=dict(version=2,count=len(assets),cell=dict(width=112,height=112),sheet=dict(width=224,height=112),pivot=dict(x=56,y=100),assets=assets)
(out/"manifest.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
(runtime/"manifest.json").write_text(json.dumps({a["id"]:a for a in assets},indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
font=ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf",13)
for first in range(0,len(assets),24):
    canvas=Image.new("RGBA",(1200,6*146),"#273943")
    draw=ImageDraw.Draw(canvas)
    for i,a in enumerate(assets[first:first+24]):
        x=i%4*300;y=i//4*146
        draw.text((x+8,y+4),a["id"],font=font,fill="#f4ead5")
        canvas.alpha_composite(Image.open(out/a["sheet"]).convert("RGBA"),(x+36,y+25))
    canvas.save(out/f"prancha-{first//24+1:02}.png")
cards=[]
for a in assets:
    esc=lambda value:html.escape(str(value),quote=True)
    search=esc(" ".join([a["id"],a["name"],a["family"],a["stage"]]))
    cards.append(f'<article data-search="{search}"><h2>{esc(a["id"])}</h2><p>{esc(a["stage"])} · {a["height"]} px · {a["colors"]} cores</p><div class="pair"><figure><img src="{esc(a["old"])}" alt="Versão anterior" loading="lazy"><figcaption>Anterior · 80 px</figcaption></figure><figure><img class="new" src="{esc(a["sheet"])}" alt="Versão nova" loading="lazy"><figcaption>Nova · 112 px</figcaption></figure></div><footer><a href="{esc(a["editable"])}">Aseprite</a> <a href="{esc(a["sheet"])}">PNG</a></footer></article>')
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soulmonsters · Overworld v2</title>
<style>:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#182830;color:#f2eada}body{margin:auto;max-width:1560px;padding:28px}h1{margin-bottom:6px}p{color:#c2d2d6}input,button{font:inherit;padding:9px 12px;background:#293e48;color:#f2eada;border:1px solid #63818c;border-radius:4px}nav{display:flex;flex-wrap:wrap;gap:12px;margin:20px 0}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(450px,1fr));gap:16px}article{padding:16px;background:#243944;border:1px solid #47616a;border-radius:6px}h2{font-size:18px;margin:0}.pair{display:grid;grid-template-columns:1fr 1fr;align-items:end;min-height:176px;background:#52616a}figure{margin:10px 0;text-align:center}img{image-rendering:pixelated;display:block;margin:auto}figcaption{font-size:12px;margin-top:10px;color:white}footer{margin-top:12px}a{color:#8cdec9;margin-right:15px}article[hidden]{display:none}body.zoom img{width:100%;height:auto}body.light .pair{background:#d9d9c9}@media(max-width:540px){main{grid-template-columns:1fr}.pair{grid-template-columns:1fr}}</style>
<h1>194 Soulmonsters · Overworld v2</h1><p>Frente e costas no tamanho nativo. As folhas anteriores estão preservadas para comparação.</p><nav><input id="q" type="search" placeholder="Nome, família ou estágio"><button id="zoom">Ampliar</button><button id="background">Fundo claro</button><output id="count">194 formas</output></nav><main>'''+''.join(cards)+'''</main><script>
const cards=[...document.querySelectorAll("article")],q=document.querySelector("#q"),normalize=s=>s.normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();q.oninput=()=>{let n=0;for(const c of cards){c.hidden=!normalize(c.dataset.search).includes(normalize(q.value));if(!c.hidden)n++}document.querySelector("#count").textContent=n+" formas"};document.querySelector("#zoom").onclick=()=>document.body.classList.toggle("zoom");document.querySelector("#background").onclick=()=>document.body.classList.toggle("light");
</script></html>'''
(out/"index.html").write_text(page,encoding="utf-8")
print("Published",len(assets),"native sheets and sources into game catalog.")
