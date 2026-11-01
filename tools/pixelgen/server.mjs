import http from 'node:http';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {createCharacterService} from './character-service.mjs';
const app=new URL('./',import.meta.url);
const characters=createCharacterService(fileURLToPath(new URL('../../',app)));
const allowed=new Map([['/','index.html'],...['style.css','app.mjs','core.mjs','animation.mjs','document.mjs','storage.mjs','quality.mjs','godot.mjs','worker.mjs','aseprite.mjs','legibility.mjs','rig.mjs'].map(f=>['/'+f,f])]);
allowed.set('/professor-walk.pixelgen.json','examples/professor-walk.pixelgen.json');
allowed.set('/kael-walk.pixelgen.json','examples/kael-walk.pixelgen.json');
allowed.set('/kael-library.pixelgen.json','../../art/characters/kael-eight-directions-v1/kael-library.pixelgen.json');
allowed.set('/kael-stairs.pixelgen.json','../../art/characters/kael-stairs-study-v1/kael-stairs.pixelgen.json');
allowed.set('/character-style.mjs','character-style.mjs');
allowed.set('/skeleton.mjs','skeleton.mjs');
allowed.set('/kael-video.pixelgen.json','../../art/characters/kael-video-sprite-v1/folha-64x96/video.pixelgen.json');
allowed.set('/kael-video-angles.pixelgen.json','../../art/characters/kael-video-eight-directions-v1/pacote/kael-eight.pixelgen.json');
allowed.set('/kael-video-jump.pixelgen.json','../../art/characters/kael-video-jump-v1/pacote/kael-jump.pixelgen.json');
allowed.set('/kael-video-item.pixelgen.json','../../art/characters/kael-video-item-v1/pacote/kael-item.pixelgen.json');
allowed.set('/sheet-pack.mjs','sheet-pack.mjs');
allowed.set('/album.mjs','album.mjs');
allowed.set('/album.css','album.css');
const types={html:'text/html; charset=utf-8',css:'text/css; charset=utf-8',mjs:'text/javascript; charset=utf-8',png:'image/png',json:'application/json; charset=utf-8'};
export async function serve(req,res){
 const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; worker-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
 const end=(code,text)=>{res.writeHead(code,headers);res.end(text);};
 try{
  const pathname=new URL(req.url,'http://localhost').pathname;
  if(pathname.startsWith('/api/characters')){
   const host=req.headers.host||'';
   if(!/^(127\.0\.0\.1|localhost|\[::1\])(:\d+)?$/.test(host))return end(403,'Use o endereço local do Pixelgen.');
   if(req.headers.origin&&req.headers.origin!==`http://${host}`)return end(403,'Origem não autorizada.');
   if(req.headers['sec-fetch-site']==='cross-site')return end(403,'Origem não autorizada.');
   const json=(code,data)=>{res.writeHead(code,{...headers,'Content-Type':types.json});res.end(req.method==='HEAD'?undefined:JSON.stringify(data));};
   try{
    if(pathname==='/api/characters'&&['GET','HEAD'].includes(req.method))return json(200,await characters.list());
    const match=/^\/api\/characters\/([a-z0-9-]+)(\/preview)?$/.exec(pathname);
    if(!match)return json(404,{error:'Personagem não encontrado.'});
    if(['GET','HEAD'].includes(req.method)){
     if(match[2]){const bytes=await characters.preview(match[1]);res.writeHead(200,{...headers,'Content-Type':types.png});return res.end(req.method==='HEAD'?undefined:bytes);}
     return json(200,await characters.open(match[1]));
    }
    if(req.method!=='PUT'||match[2])return json(405,{error:'Método não permitido.'});
    if(!req.headers['content-type']?.startsWith('application/json'))return json(415,{error:'Envie JSON.'});
    let size=0;const chunks=[];for await(const chunk of req){size+=chunk.length;if(size>12*1024*1024)return json(413,{error:'Projeto acima de 12 MB.'});chunks.push(chunk);}
    let value;try{value=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{return json(400,{error:'JSON inválido.'});}
    return json(200,await characters.save(match[1],value));
   }catch(e){return json(e.status||500,{error:e.status?e.message:'Não foi possível acessar os arquivos do personagem. Tente novamente.'});}
  }
  if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura.');
  const file=pathname==='/demo.png'?new URL('../../art/characters/rpg-overworld-study-v1/kael-professor-4-direcoes.png',app):allowed.has(pathname)?new URL(allowed.get(pathname),app):null;
  if(!file)return end(404,'Não encontrado.');
  const bytes=await fs.readFile(file);res.writeHead(200,{...headers,'Content-Type':types[file.pathname.split('.').pop()]||'application/octet-stream'});res.end(req.method==='HEAD'?undefined:bytes);
 }catch{end(404,'Arquivo indisponível.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 let port=Number(process.env.PIXELGEN_PORT||5264),attempts=0;
 if(!Number.isInteger(port)||port<1024||port>65525)throw Error('Porta inválida.');
 const server=http.createServer(serve);server.on('error',error=>{if(error.code==='EADDRINUSE'&&attempts++<10)server.listen(++port,'127.0.0.1');else throw error;});
 server.on('listening',()=>console.log(`Pixelgen: http://127.0.0.1:${port} — álbum conectado aos sprites locais do Godot.`));server.listen(port,'127.0.0.1');
}
