import http from 'node:http';
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
fs.mkdirSync('.local',{recursive:true});const sqlite=new DatabaseSync('.local/game.db');
const DB={prepare(sql){let values=[];return {bind(...v){values=v;return this;},async run(){const r=sqlite.prepare(sql).run(...values);return {meta:{changes:Number(r.changes)}};},async first(){return sqlite.prepare(sql).get(...values);}};}};
const {default:worker}=await import('./worker/index.js');
http.createServer(async(req,res)=>{try{const body=[];for await(const c of req)body.push(c);const r=await worker.fetch(new Request('http://'+req.headers.host+req.url,{method:req.method,headers:req.headers,...(body.length?{body:Buffer.concat(body)}:{})}),{DB});res.writeHead(r.status,Object.fromEntries(r.headers));res.end(Buffer.from(await r.arrayBuffer()));}catch(e){console.error(e);res.writeHead(500);res.end('Server error');}}).listen(5193,'0.0.0.0',()=>console.log('Local: http://localhost:5193'));
