import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import './build-workshop-craft-preview.mjs';
const manifest=JSON.parse(fs.readFileSync('assets/workshop/v1/manifest.json','utf8'));
const files=new Map([['/','art/workshop-v2/index.html'],['/v1','art/workshop-v1/index.html'],...Object.values(manifest.images).map(a=>['/assets/'+a.image,'assets/'+a.image])]);
http.createServer((req,res)=>{const url=new URL(req.url,'http://localhost'),file=files.get(url.pathname);if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}

 const sizes={'/mobile':[390,844],'/landscape':[844,390]},size=sizes[url.pathname];
 if(size){const [w,h]=size;res.setHeader('Content-Type','text/html; charset=utf-8');res.end('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Oficina · viewport '+w+'×'+h+'</title><style>body{background:#263f3e;color:#fff4dc;font:14px system-ui;text-align:center}iframe{width:'+w+'px;height:'+h+'px;border:0;display:block;margin:16px auto;background:#fff4dc}a{color:inherit}</style><p>Revisão de layout · viewport interno '+w+'×'+h+' · não representa aparelho físico</p><a href="/">Voltar à prévia ampla</a><iframe title="Oficina em viewport móvel" src="/"></iframe></html>');return;}

 if(!file){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',path.extname(file)==='.png'?'image/png':'text/html; charset=utf-8');res.setHeader('Cache-Control','no-store');if(req.method==='HEAD')res.end();else fs.createReadStream(file).pipe(res);}).listen(Number(process.env.WORKSHOP_PREVIEW_PORT||5237),'127.0.0.1',()=>console.log('Oficina: http://127.0.0.1:'+(process.env.WORKSHOP_PREVIEW_PORT||5237)+'/'));
