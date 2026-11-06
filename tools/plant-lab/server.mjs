import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {ASSETS,validateLayout} from './model.mjs';
import {zip} from './zip.mjs';
const app=fileURLToPath(new URL('./',import.meta.url)),root=fileURLToPath(new URL('../../',import.meta.url));
const assets=new Map(ASSETS.map(a=>[a.id,path.join(root,a.id==='kael'?'art/characters/kael/overworld-diagonal-v1/frente-sw.png':'art/environment/topdown-plants-pixel-v1/'+a.id+'.png')]));
assets.set('kael-back',path.join(root,'art/characters/kael/overworld-diagonal-v1/costas-nw.png'));
const pages=new Map(['index.html','style.css','app.mjs','model.mjs','terrain.mjs'].map(n=>['/'+n,path.join(app,n)]));pages.set('/',path.join(app,'index.html'));
const mime={'.html':'text/html; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png'};
export async function exportProject(raw){const layout=validateLayout(raw),files=[];for(const name of ['project.godot','main.tscn','lab.gd','terrain.gd','README.md'])files.push([name,await fs.readFile(path.join(app,'godot-template',name))]);files.push(['layout.json',JSON.stringify(layout,null,2)]);for(const [id,file]of assets)files.push(['assets/'+id+'.png',await fs.readFile(file)]);return zip(files);}
export async function serve(req,res){const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' blob:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'"};
  const end=(code,text)=>{res.writeHead(code,{...headers,'Content-Type':'text/plain; charset=utf-8'});res.end(text);};
  try{const u=new URL(req.url,'http://localhost');
    if(u.pathname==='/api/export-godot'){
      if(req.method!=='POST')return end(405,'Use POST.');
      const origin=req.headers.origin;if(origin&&origin!==`http://${req.headers.host}`)return end(403,'Origem não permitida.');
      if(!String(req.headers['content-type']||'').startsWith('application/json'))return end(415,'Envie JSON.');
      const chunks=[];let size=0;for await(const b of req){size+=b.length;if(size>1_500_000)return end(413,'Projeto muito grande.');chunks.push(b);}
      let data;try{data=JSON.parse(Buffer.concat(chunks).toString());}catch{return end(400,'JSON inválido.');}
      let file;try{file=await exportProject(data);}catch(e){return end(400,e.message);}
      res.writeHead(200,{...headers,'Content-Type':'application/zip','Content-Disposition':'attachment; filename="jardim-kronasta-godot.zip"'});res.end(file);return;
    }
    if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura.');
    const match=/^\/assets\/([a-z0-9-]+)\.png$/.exec(u.pathname),file=match?assets.get(match[1]):pages.get(u.pathname);if(!file)return end(404,'Arquivo não encontrado.');
    const data=await fs.readFile(file);res.writeHead(200,{...headers,'Content-Type':mime[path.extname(file)]||'application/octet-stream'});res.end(req.method==='HEAD'?undefined:data);
  }catch(e){console.error(e.message);end(500,'Não foi possível atender a solicitação.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.PLANT_LAB_PORT||5256);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Jardim de Kronasta: http://127.0.0.1:'+port));}
