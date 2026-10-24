import path from 'node:path';
import {workshopFile,workshopMime} from '../scripts/workshop-v3-build.mjs';
export async function serveWorkshopV3(request){
 const url=new URL(request.url);if(url.pathname!=='/oficina-v3'&&!url.pathname.startsWith('/oficina-v3/'))return null;
 if(!['GET','HEAD'].includes(request.method))return new Response(null,{status:405,headers:{Allow:'GET, HEAD'}});
 if(url.pathname==='/oficina-v3'){url.pathname+='/';return Response.redirect(url,307);}
 const name=url.pathname.slice('/oficina-v3/'.length)||'index.html',data=workshopFile(name);
 if(!data)return new Response('Arquivo não encontrado.',{status:404});
 return new Response(request.method==='HEAD'?null:data,{headers:{'Content-Type':workshopMime[path.extname(name)],'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'same-origin',
 'Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; frame-ancestors 'self'; object-src 'none'; base-uri 'none'"}});
}
