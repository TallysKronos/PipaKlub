'use strict';
const fs=require('node:fs/promises');
const path=require('node:path');
const {createHash}=require('node:crypto');
function serverOrigin(value){
 const u=new URL(value);
 if(u.protocol!=='https:'||u.username||u.password||u.port||u.pathname!=='/'||u.search||u.hash)throw Error('Servidor desktop deve ser uma origem HTTPS sem credenciais ou caminho.');
 return u.origin;
}
function navigationAllowed(value,origin){try{const u=new URL(value);return u.origin===origin&&!u.username&&!u.password&&u.pathname==='/';}catch{return false;}}
function externalAllowed(value,origin){try{const u=new URL(value);return u.protocol==='https:'&&!u.username&&!u.password&&!u.port&&[new URL(origin).hostname,'store.steampowered.com','steamcommunity.com','help.steampowered.com'].includes(u.hostname);}catch{return false;}}
function contentPolicy(html,origin){
 // HTML parsing normalizes CRLF/CR before CSP computes inline-script hashes.
 const hashes=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)].map(m=>"'sha256-"+createHash('sha256').update(m[1].replace(/\r\n?/g,'\n')).digest('base64')+"'");
 return ["default-src 'none'","script-src "+hashes.join(' '),"style-src 'self' 'unsafe-inline'","img-src 'self' data: blob:","font-src 'self'","media-src 'self' blob:","connect-src 'self' "+origin.replace('https:','wss:'),"object-src 'none'","base-uri 'none'","frame-src 'none'","frame-ancestors 'none'","form-action 'self'","worker-src 'none'"].join('; ');
}
async function createBundleHandler({root,origin,delegate,offline=false,onLocal=()=>{}}){
 const manifest=JSON.parse(await fs.readFile(path.join(root,'bundle.json'),'utf8')),files=new Set(manifest.files),html=await fs.readFile(path.join(root,'index.html'),'utf8'),csp=contentPolicy(html,origin);
 return async request=>{
  const u=new URL(request.url);
  if(u.origin!==origin||u.username||u.password)return new Response('Forbidden',{status:403});
  if(u.pathname.startsWith('/api/')||u.pathname.startsWith('/account/')||u.pathname==='/health'){
   if(offline)return Response.json({error:'Sem conexão. O treino local continua disponível.'},{status:503});
   // Original Request and headers stay intact; the same Electron session handles cookies.
   return delegate(request);
  }
  if(!['GET','HEAD'].includes(request.method))return new Response('Method not allowed',{status:405});
  let file;try{file=decodeURIComponent(u.pathname).slice(1)||'index.html';}catch{return new Response('Invalid path',{status:400});}
  if(file.includes('\\')||file.includes('\0')||file.split('/').some(p=>p==='..'||p==='.')||!files.has(file))return new Response('Not found',{status:404});
  const absolute=path.resolve(root,file),relative=path.relative(root,absolute);
  if(relative.startsWith('..')||path.isAbsolute(relative))return new Response('Forbidden',{status:403});
  const types={'.html':'text/html; charset=utf-8','.png':'image/png','.woff':'font/woff','.woff2':'font/woff2'},headers={'Content-Type':types[path.extname(file)]||'application/octet-stream','X-Content-Type-Options':'nosniff','Referrer-Policy':'same-origin','Cache-Control':'no-store'};
  if(file==='index.html')headers['Content-Security-Policy']=csp;
  try{const bytes=await fs.readFile(absolute);onLocal(file);return new Response(request.method==='HEAD'?null:bytes,{headers});}catch{return new Response('Missing bundled resource',{status:404});}
 };
}
module.exports={serverOrigin,navigationAllowed,externalAllowed,contentPolicy,createBundleHandler};
