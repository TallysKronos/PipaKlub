import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const manifest=JSON.parse(await fs.readFile(new URL('../assets/atlas.json',import.meta.url),'utf8'));
const items=JSON.parse(await fs.readFile(new URL('../assets/pipa-items.json',import.meta.url),'utf8')).items;
const hud=JSON.parse(await fs.readFile(new URL('../assets/ui/hud-papel-bambu-v1/manifest.json',import.meta.url),'utf8'));
const kit=JSON.parse(await fs.readFile(new URL('../assets/ui/kit-switch-v1/manifest.json',import.meta.url),'utf8'));
const encounterFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/encounter-scenes.json',import.meta.url),'utf8'))).map(s=>s.image);
const rivalFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/rival-art.json',import.meta.url),'utf8'))).map(s=>s.image);
const districtFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/district-places.json',import.meta.url),'utf8'))).map(p=>p.image);
const plazaFiles=JSON.parse(await fs.readFile(new URL('../assets/hub/praca-v1/manifest.json',import.meta.url),'utf8')).files.map(f=>'hub/praca-v1/'+f);
const worldFiles=JSON.parse(await fs.readFile(new URL('../assets/world/identity-v2/manifest.json',import.meta.url),'utf8')).files.map(f=>'world/identity-v2/'+f);
const worldKitFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/world/morro-kit-v1/manifest.json',import.meta.url),'utf8')).sheets).map(s=>s.image);
worldKitFiles.push(...Object.values(JSON.parse(await fs.readFile(new URL('../assets/world/quintal-kit-v1/manifest.json',import.meta.url),'utf8')).sheets).map(s=>s.image));
const worldActorFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/characters/overworld-v1/manifest.json',import.meta.url),'utf8')).characters).map(a=>a.image);
worldActorFiles.push(...Object.values(JSON.parse(await fs.readFile(new URL('../assets/creatures/overworld-v1/manifest.json',import.meta.url),'utf8')).species).map(a=>a.image));
const paintedWorldFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/world/morro-plaza-v1/manifest.json',import.meta.url),'utf8')).sheets).map(s=>s.image);
paintedWorldFiles.push(...Object.values(JSON.parse(await fs.readFile(new URL('../assets/world/morro-road-v1/manifest.json',import.meta.url),'utf8')).sheets).map(s=>s.image));
paintedWorldFiles.push(...Object.values(JSON.parse(await fs.readFile(new URL('../assets/world/street-v1/manifest.json',import.meta.url),'utf8')).sheets).map(s=>s.image));
const kitFiles=[...Object.values(kit.components),...Object.values(kit.icons)].map(c=>c.image).filter(f=>f.endsWith('.png')).map(f=>'ui/kit-switch-v1/'+f);
const openingFiles=Object.values(JSON.parse(await fs.readFile(new URL('../assets/story/kael-birthday-v1/manifest.json',import.meta.url),'utf8')).images).map(s=>s.image);
openingFiles.push(...Object.values(JSON.parse(await fs.readFile(new URL('../assets/title/elo-das-ruinas-v1/manifest.json',import.meta.url),'utf8')).images).map(s=>s.image));
const files=[...openingFiles,...paintedWorldFiles,...worldKitFiles,...rivalFiles,...encounterFiles,...districtFiles,...kitFiles,...Object.values(hud.sheets).map(s=>s.image),...Object.values(manifest.atlases).map(a=>a.meta.image),...items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',"ui/club-collection-v2.png","ui/club-trades-v2.png","ui/club-summon-v2.png","ui/club-farm-v2.png","ui/club-profile-v2.png","ui/club-history-v2.png"];
export function createAssetHandler(){
 const cache=new Map();
 return async request=>{
  const url=new URL(request.url);if(!url.pathname.startsWith('/assets/'))return null;
  const file=url.pathname.slice(8);if(!files.includes(file)&&!plazaFiles.includes(file)&&!worldFiles.includes(file)&&!worldActorFiles.includes(file)&&!['backgrounds/quintal-clube-v1.png','packs/cidade-v1/mapa.png','packs/cidade-v1/insignias.png'].includes(file))return new Response('Asset not found',{status:404});
  if(!['GET','HEAD'].includes(request.method))return new Response(null,{status:405,headers:{Allow:'GET, HEAD'}});
  let item=cache.get(file);
  if(!item){try{const data=await fs.readFile(new URL('../assets/'+file,import.meta.url)),hash=createHash('sha256').update(data).digest('hex').slice(0,12);item={data,hash};cache.set(file,item);}catch{return new Response('Asset unavailable',{status:503});}}
  const etag='"'+item.hash+'"',headers={'Content-Type':'image/png','X-Content-Type-Options':'nosniff','Cache-Control':url.searchParams.get('v')===item.hash?'public, max-age=31536000, immutable':'public, max-age=300',ETag:etag};
  if(request.headers.get('if-none-match')===etag)return new Response(null,{status:304,headers});
  return new Response(request.method==='HEAD'?null:item.data,{headers});
 };
}
