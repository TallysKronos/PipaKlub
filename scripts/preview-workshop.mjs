import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import './build-workshop-preview.mjs';
const manifest=JSON.parse(fs.readFileSync('assets/workshop/v1/manifest.json','utf8'));
const files=new Map([['/','art/workshop-v1/index.html'],...Object.values(manifest.images).map(a=>['/assets/'+a.image,'assets/'+a.image])]);
http.createServer((req,res)=>{const url=new URL(req.url,'http://localhost'),file=files.get(url.pathname);if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
 if(url.pathname==='/mobile'){res.setHeader('Content-Type','text/html; charset=utf-8');res.end('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Oficina · viewport 390×844</title><style>body{background:#263f3e;color:#fff4dc;font:14px system-ui;text-align:center}iframe{width:390px;height:844px;border:0;display:block;margin:16px auto;background:#fff4dc}a{color:inherit}</style><p>Revisão de layout · viewport interno 390×844 · não representa aparelho físico</p><a href="/">Voltar à prévia ampla</a><iframe title="Oficina em viewport móvel" src="/"></iframe></html>');return;}
 if(!file){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',path.extname(file)==='.png'?'image/png':'text/html; charset=utf-8');res.setHeader('Cache-Control','no-store');if(req.method==='HEAD')res.end();else fs.createReadStream(file).pipe(res);}).listen(5237,'127.0.0.1',()=>console.log('Oficina: http://127.0.0.1:5237/'));
