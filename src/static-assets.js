import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const manifest=JSON.parse(await fs.readFile(new URL('../assets/atlas.json',import.meta.url),'utf8'));
const files=[...Object.values(manifest.atlases).map(a=>a.meta.image),'vfx/trade-celestial.png','vfx/trade-sky.png'];
export function createAssetHandler(){
 const cache=new Map();
 return async request=>{
  const url=new URL(request.url);if(!url.pathname.startsWith('/assets/'))return null;
  const file=url.pathname.slice(8);if(!files.includes(file))return new Response('Asset not found',{status:404});
  if(!['GET','HEAD'].includes(request.method))return new Response(null,{status:405,headers:{Allow:'GET, HEAD'}});
  let item=cache.get(file);
  if(!item){try{const data=await fs.readFile(new URL('../assets/'+file,import.meta.url)),hash=createHash('sha256').update(data).digest('hex').slice(0,12);item={data,hash};cache.set(file,item);}catch{return new Response('Asset unavailable',{status:503});}}
  const etag='"'+item.hash+'"',headers={'Content-Type':'image/png','X-Content-Type-Options':'nosniff','Cache-Control':url.searchParams.get('v')===item.hash?'public, max-age=31536000, immutable':'public, max-age=300',ETag:etag};
  if(request.headers.get('if-none-match')===etag)return new Response(null,{status:304,headers});
  return new Response(request.method==='HEAD'?null:item.data,{headers});
 };
}
