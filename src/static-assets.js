import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const manifest=JSON.parse(await fs.readFile(new URL('../assets/atlas.json',import.meta.url),'utf8'));
const items=JSON.parse(await fs.readFile(new URL('../assets/pipa-items.json',import.meta.url),'utf8')).items;
const files=[...Object.values(manifest.atlases).map(a=>a.meta.image),...items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',"ui/club-collection-v2.png","ui/club-trades-v2.png","ui/club-summon-v2.png","ui/club-farm-v2.png","ui/club-profile-v2.png","ui/club-history-v2.png"];
export function createAssetHandler(){
 const cache=new Map();
 return async request=>{
  const url=new URL(request.url);if(!url.pathname.startsWith('/assets/'))return null;
  const file=url.pathname.slice(8);if(!files.includes(file)&&!['backgrounds/quintal-clube-v1.png','packs/cidade-v1/mapa.png','packs/cidade-v1/insignias.png'].includes(file))return new Response('Asset not found',{status:404});
  if(!['GET','HEAD'].includes(request.method))return new Response(null,{status:405,headers:{Allow:'GET, HEAD'}});
  let item=cache.get(file);
  if(!item){try{const data=await fs.readFile(new URL('../assets/'+file,import.meta.url)),hash=createHash('sha256').update(data).digest('hex').slice(0,12);item={data,hash};cache.set(file,item);}catch{return new Response('Asset unavailable',{status:503});}}
  const etag='"'+item.hash+'"',headers={'Content-Type':'image/png','X-Content-Type-Options':'nosniff','Cache-Control':url.searchParams.get('v')===item.hash?'public, max-age=31536000, immutable':'public, max-age=300',ETag:etag};
  if(request.headers.get('if-none-match')===etag)return new Response(null,{status:304,headers});
  return new Response(request.method==='HEAD'?null:item.data,{headers});
 };
}
