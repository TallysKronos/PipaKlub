import http from 'node:http';
import fs from 'node:fs';
const file=new URL('../art/title-elo-das-ruinas-v1/review.html',import.meta.url);
const exported=new URL('../output/soulmonsters-elo-das-ruinas-abertura.html',import.meta.url);
http.createServer((req,res)=>{if(!['/','/export'].includes(req.url)||req.method!=='GET'){res.writeHead(404);res.end();return;}res.setHeader('Content-Type','text/html; charset=utf-8');res.setHeader('Cache-Control','no-store');res.end(fs.readFileSync(req.url==='/export'?exported:file));}).listen(5231,'127.0.0.1',()=>console.log('Title viewport review: http://127.0.0.1:5231/ (game must run on 5230)'));
