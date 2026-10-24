import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {hudAssets,hudSpriteCSS} from '../../scripts/hud-assets.mjs';
const app=fileURLToPath(new URL('./',import.meta.url)),repo=fileURLToPath(new URL('../../',import.meta.url));
const files=new Map(['index.html','tools.html','tools-preview.mjs','game.mjs','model.mjs','look.mjs','protocol.mjs','live-client.mjs','hand.mjs','style.css','atelier-v1.png','mesa.jpg','rabbito.png','assis.png'].map(f=>[f,path.join(app,f)]));
files.set('hud-skin.mjs',path.join(repo,'src/hud-skin.js'));
for(const sheet of ['panels','icons'])files.set('ui/'+sheet+'.png',path.join(repo,'assets/ui/hud-papel-bambu-v1/'+sheet+'.png'));
const hudStyle=hudSpriteCSS().replaceAll('assets/ui/hud-papel-bambu-v1/','/ui/'),hudAtlas=JSON.stringify(hudAssets());
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.jpg':'image/jpeg','.png':'image/png'};
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'self'"};
 const end=(code,message)=>{res.writeHead(code,headers);res.end(message);};
 try{
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura. Salve projetos pelo navegador.');
  const p=decodeURIComponent(new URL(req.url,'http://localhost').pathname),relative=p==='/'?'index.html':p.slice(1);
  if(relative==='hud.css'||relative==='hud.json'){res.writeHead(200,{...headers,'Content-Type':relative.endsWith('.css')?types['.css']:'application/json; charset=utf-8'});res.end(req.method==='HEAD'?undefined:relative.endsWith('.css')?hudStyle:hudAtlas);return;}
  const size={mobile:[390,844],landscape:[844,390]}[relative];
  if(size){res.writeHead(200,{...headers,'Content-Type':types['.html']});res.end(req.method==='HEAD'?undefined:`<!doctype html><meta charset="utf-8"><title>Oficina v3 · revisão ${size.join('×')}</title><style>body{background:#173e3d;color:#fff0ce;font:13px system-ui;text-align:center}iframe{display:block;width:${size[0]}px;height:${size[1]}px;margin:12px auto;border:0}</style><p>Revisão de layout · ${size.join('×')} · emulação, não aparelho físico</p><iframe title="Oficina em revisão de layout" src="/"></iframe>`);return;}
  if(!files.has(relative))return end(404,'Arquivo não encontrado.');
  const data=await fs.readFile(files.get(relative));res.writeHead(200,{...headers,'Content-Type':types[path.extname(relative)]});res.end(req.method==='HEAD'?undefined:data);
 }catch{return end(404,'Arquivo não encontrado.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.OFICINA_V3_PORT||5243);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Oficina v3: http://127.0.0.1:'+port+' — ferramenta local, sem contas ou banco.'));}
