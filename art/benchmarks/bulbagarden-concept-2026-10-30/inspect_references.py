"""Fetch selected reference originals for close visual research, never runtime assets."""
import concurrent.futures
import hashlib
import html
import json
import re
import urllib.parse
import urllib.request
from pathlib import Path
from collect_index import ROOT, fetch

NAMES = [
 'Guzma SM concept art.png', 'Plumeria SM concept art.png', 'Team Skull Grunts SM concept art.png',
 'Mela concept art.jpg', 'Piers SwSh concept art.jpg', 'Raihan SwSh concept art.jpg',
 'Milo SwSh concept art.jpg', 'Opal SwSh concept art.jpg', 'Nessa SwSh concept art.jpg',
 'Kabu SwSh concept art.jpg', 'Gordie SwSh concept art.jpg', 'Bea SwSh concept art.jpg',
 'Acerola concept art.png', 'Kiawe concept art.png', 'Mallow concept art.png',
 'Sophocles concept art.png', 'Olivia concept art.png', 'Hala concept art.png',
 'Lusamine Concept Art.png', 'Wicke SM concept art.png', 'Faba SM concept art.png',
 'Grimsley SM concept art.jpg', 'Kukui SM concept art.png', 'Colress Concept Art.png',
 'Archie ORAS concept art.png', 'Maxie ORAS concept art.png', 'Valerie concept art.png',
 'Ramos concept art.png', 'Clemont concept art.png', 'Lysandre concept art.jpg',
 'Adaman concept art.jpg', 'Calaba concept art.jpg', 'Volo concept art.jpg',
 'Brassius concept art.jpg', 'Iono concept art.jpg', 'Larry concept art.jpg',
 'Atticus concept art.jpg', 'Eri concept art.jpg', 'Professor Sada concept art.jpg',
 'Alolan Marowak SM concept art.jpg', 'Mimikyu SM concept art.jpg',
 'Rotom Phone SwSh concept sketch.jpg', 'Base Camp (Interior) PLA concept art.jpg',
 'Characters 1 B2W2 concept art.jpg', 'Capsule Monsters Store.png',
 'N Concept Art.jpg', 'Ghetsis Concept Art.jpg', 'Elio and Selene SM concept art.png'
]

def main():
    catalogue = json.loads((ROOT/'catalogue.json').read_text(encoding='utf-8'))
    catalogue['subcategories'] = [c for c in catalogue['subcategories'] if c['title'].startswith('Category:Concept art from ') or c['title']=='Category:Capsule Monsters']
    files={f['name']:f for f in catalogue['files']}
    local=ROOT.parents[2]/'tmp'/'bulbagarden-concept-study'
    local.mkdir(parents=True, exist_ok=True)
    prior_path=ROOT/'reference-sources.json'
    prior={e['name']:e for e in json.loads(prior_path.read_text(encoding='utf-8'))} if prior_path.exists() else {}
    def get(pair):
        number, name = pair
        previous=prior.get(name,{})
        if previous.get('status')=='available_for_visual_inspection' and Path(previous['local_research_file']).exists():
            return previous
        entry={'id':f'REF-{number:02}', 'name':name, 'status':'pending'}
        try:
            entry.update(files[name])
            markup=fetch(entry['url'])
            full=re.search(r'<div class="fullImageLink"[^>]*>\s*<a href="([^"]+)"', markup)
            if not full:
                raise ValueError('No original image link')
            url=urllib.parse.urljoin(entry['url'],html.unescape(full[1]))
            request=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0 (Soulmonsters reference research)'})
            with urllib.request.urlopen(request,timeout=60) as response:
                data=response.read()
            destination=local/(entry['id']+Path(name).suffix.lower())
            destination.write_bytes(data)
            entry.update({'image_url':url,'local_research_file':str(destination),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'status':'available_for_visual_inspection','rights':'Third-party Pokémon concept reference; source archive claims fair use. Not a production asset or a reusable game license.'})
        except Exception as error:
            entry.update({'status':'fetch_failed','error':str(error)})
        return entry
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        entries=list(pool.map(get,enumerate(NAMES,1)))
    (ROOT/'reference-sources.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
    for e in entries:
        print(e['id'],e['name'],e['status'],e.get('error',''))

if __name__=='__main__':
    main()
