from pathlib import Path
import json

root=Path(__file__).resolve().parents[3]
source=json.loads((Path(__file__).parent/'atlas.json').read_text(encoding='utf-8'))
for identifier,actor in source['characters'].items():
    actor['image']='characters/overworld-v1/'+identifier+'.png'
    actor.pop('status',None)
source.pop('tool',None)
(root/'assets/characters/overworld-v1/manifest.json').write_text(json.dumps(source,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for filename in ['build.mjs','build-pages.mjs']:
    path=root/filename
    text=path.read_text(encoding='utf-8')
    before="+fs.readFileSync('src/world-client.js','utf8')"
    after="+fs.readFileSync('src/world-actors.js','utf8').replace('export function','function')+'\\n'+fs.readFileSync('src/world-client.js','utf8')"
    assert before in text and 'src/world-actors.js' not in text
    path.write_text(text.replace(before,after),encoding='utf-8')
path=root/'src/courtyard-client.js'
text=path.read_text(encoding='utf-8')
before="...(homeArt.plaza?['plaza-kael']:[])"
assert before in text
path.write_text(text.replace(before,before+",...(homeArt.world?['world-npc-sr-assis']:[])"),encoding='utf-8')
path=root/'package.json'
package=json.loads(path.read_text(encoding='utf-8'))
package['scripts']['test']+=' world-actors.test.mjs'
path.write_text(json.dumps(package,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
