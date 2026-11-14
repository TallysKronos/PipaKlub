"""Referências públicas para inspeção; não são assets do jogo nem inputs de geração."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urljoin
from html.parser import HTMLParser
from concurrent.futures import ThreadPoolExecutor
import json, hashlib, re, argparse

BASE = Path(__file__).resolve().parent
class Images(HTMLParser):
    def __init__(self): super().__init__(); self.images=[]
    def handle_starttag(self, tag, attrs):
        if tag=='img': self.images.append(dict(attrs))

PAGES=[
 ('rowlet','pokemon','https://sg.portal-pokemon.com/pokedex/0722/','Rowlet'),
 ('dartrix','pokemon','https://sg.portal-pokemon.com/pokedex/0723/','Dartrix'),
 ('applin','pokemon','https://sg.portal-pokemon.com/pokedex/0840/','Applin'),
 ('toxel','pokemon','https://sg.portal-pokemon.com/pokedex/0848/','Toxel'),
 ('decidueye','pokemon','https://sg.portal-pokemon.com/pokedex/0724/','5bcab6'),
 ('flapple','pokemon','https://sg.portal-pokemon.com/pokedex/0841/','b2f692'),
 ('appletun','pokemon','https://sg.portal-pokemon.com/pokedex/0842/','e8daf2'),
 ('corviknight','pokemon','https://sg.portal-pokemon.com/pokedex/0823/','/images/pokedex/'),
 ('toxtricity','pokemon','https://sg.portal-pokemon.com/pokedex/0849/','/images/pokedex/'),
 ('yokai-nintendo','yokai','https://www.nintendo.com/en-gb/Games/Nintendo-3DS-games/YO-KAI-WATCH--1026246.html','YoKaiWatch_transform|YoKaiWatch_Komane|YoKaiWatch_Doubletrouble'),
 ('persona-ryuji','persona','https://p5r.jp/character/ryuji/','persona'),
 ('persona-makoto','persona','https://p5r.jp/character/makoto/','persona'),
 ('persona-kasumi','persona','https://p5r.jp/character/kasumi/','persona'),
 ('persona-morgana','persona','https://p5r.jp/character/morgana/','persona'),
]

def fetch(url):
    with urlopen(Request(url,headers={'User-Agent':'Mozilla/5.0 SoulmonstersResearch/1.0'}),timeout=25) as r: return r.read(),r.headers.get('Content-Type','')
def collect(row):
    id,series,page,patterns=row; out=[]
    try:
        raw,_=fetch(page); html=raw.decode('utf-8','replace'); p=Images();p.feed(html)
        if series=='persona':
            urls=list(dict.fromkeys(re.findall(r'[^\s\"\'()<>]*persona[^\s\"\'()<>]*\.png',html)))
            p.images=[{'src':u,'alt':id} for u in urls if re.search(r'/persona[12]?_[a-f0-9]{32}\.png$',u)]
        seen=set()
        for a in p.images:
            src=a.get('data-xs') or a.get('data-src') or a.get('src',''); label=a.get('alt','')
            if not any(q.lower() in (src+' '+label).lower() for q in patterns.split('|')): continue
            url=urljoin(page,src)
            key=url.split('?')[0]
            if key in seen: continue
            seen.add(key)
            try:
                data,typ=fetch(url)
                if not typ.startswith('image/'): continue
                suffix='.png' if 'png' in typ else '.webp' if 'webp' in typ else '.jpg'
                target=BASE/'referencias'/f'{id}-{len(out)+1}{suffix}';target.parent.mkdir(exist_ok=True)
                target.write_bytes(data)
                out.append(dict(id=id,series=series,page=page,url=url,alt=label,path=target.relative_to(BASE).as_posix(),sha256=hashlib.sha256(data).hexdigest(),purpose='Inspeção de benchmark; não integrar nem usar em geração'))
                if len(out)>=6:break
            except Exception as e: print('Imagem indisponível',id,type(e).__name__)
    except Exception as e: print('Página indisponível',id,type(e).__name__)
    return out

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--only');args=parser.parse_args()
    manifest=BASE/'referencias.json'
    rows=json.loads(manifest.read_text(encoding='utf-8')) if args.only and manifest.exists() else []
    rows=[r for r in rows if r['id']!=args.only]
    with ThreadPoolExecutor(max_workers=6) as pool:
        for result in pool.map(collect,[p for p in PAGES if not args.only or p[0]==args.only]): rows.extend(result)
    for name in ([] if args.only else ['fladramon','lighdramon','paildramon','dinobeemon','dukemon','megidramon']):
        url=f'https://digimon.net/cimages/digimon/{name}.jpg'
        try:
            data,_=fetch(url);target=BASE/'referencias'/f'{name}.jpg';target.write_bytes(data)
            rows.append(dict(id=name,series='digimon',page=f'https://digimon.net/reference_en/detail.php?directory_name={name}',url=url,alt=name,path=target.relative_to(BASE).as_posix(),sha256=hashlib.sha256(data).hexdigest(),purpose='Inspeção de benchmark; não integrar nem usar em geração'))
        except Exception as e:print('Imagem indisponível',name,type(e).__name__)
    (BASE/'referencias.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'imagens':len(rows),'series':sorted(set(r['series'] for r in rows))},ensure_ascii=False))
