// Explicit opt-in demo. Production dev.mjs never imports this authentication adapter.
import http from 'node:http';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {DatabaseSync} from 'node:sqlite';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from '../src/accounts.js';
import {createProgression} from '../src/progression.js';
import {createAssetHandler} from '../src/static-assets.js';
import {attachRealtime} from '../src/realtime.js';

const port=Number(process.env.LOCAL_TRADE_PORT||5194);
if(!Number.isInteger(port)||port<1024||port>65535)throw Error('LOCAL_TRADE_PORT inválida.');
fs.mkdirSync('.local/trade-demo',{recursive:true});
const postgres=new PGlite('.local/trade-demo/postgres');await postgres.waitReady;
if(!(await postgres.query("select to_regclass('public.kite_trades') installed")).rows[0].installed){
 await postgres.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
 for(const name of fs.readdirSync('supabase/migrations').filter(n=>n.endsWith('.sql')).sort())await postgres.exec(fs.readFileSync('supabase/migrations/'+name,'utf8'));
}
const players={ana:{id:'11111111-1111-4111-8111-111111111111',nickname:'Ana Local'},beto:{id:'22222222-2222-4222-8222-222222222222',nickname:'Beto Local'}};
for(const p of Object.values(players))await postgres.query('insert into auth.users values($1,$2) on conflict(id) do nothing',[p.id,{nickname:p.nickname}]);
await postgres.query("select public.grant_event_soul($1,'flautrevo','local-demo')",[players.ana.id]);
const operations={get_player_account:[],get_player_recent_matches:[],get_player_match_result:['p_match'],get_kite_history:['p_kite'],equip_player_kite:['p_kite'],update_player_name:['p_nickname'],player_trade:['p_action','p_code','p_kite','p_revision']};
const serverOperations={reserve_player_match:['p_user','p_match','p_code','p_mode'],release_player_match:['p_user','p_match'],settle_player_cut:['p_event','p_match','p_winner','p_loser','p_kite'],finish_player_match:['p_match']};
async function rpc(name,body,uid){
 const args=Object.hasOwn(uid?operations:serverOperations,name)&&(uid?operations:serverOperations)[name];
 if(!args)throw Error('RPC local não permitida.');
 return postgres.transaction(async tx=>{
  await tx.exec('set local role '+(uid?'authenticated':'pipa_server'));
  if(uid)await tx.query("select set_config('request.jwt.claim.sub',$1,true)",[uid]);
  return (await tx.query('select public.'+name+'('+args.map((_,i)=>'$'+(i+1)).join(',')+') result',args.map(k=>body[k]??null))).rows[0].result;
 });
}
const tokens=new Map();
const response=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json'}});
async function localAuth(url,options={}){
 const path=new URL(url).pathname,body=options.body?JSON.parse(options.body):{},token=options.headers?.Authorization?.replace(/^Bearer /,'');
 if(path==='/auth/v1/token'){
  const username=body.email?.split('@')[0],player=players[username];
  if(body.refresh_token&&tokens.has(body.refresh_token))return response({access_token:body.refresh_token,refresh_token:body.refresh_token,expires_in:86400,user:{id:tokens.get(body.refresh_token)}});
  if(!player||body.email!==username+'@local.test'||body.password!=='TesteLocal123!')return response({error_code:'invalid_credentials'},401);
  const access=randomUUID();tokens.set(access,player.id);return response({access_token:access,refresh_token:access,expires_in:86400,user:{id:player.id}});
 }
 if(path==='/auth/v1/user')return tokens.has(token)?response({id:tokens.get(token)}):response({},401);
 if(path==='/auth/v1/logout'){tokens.delete(token);return response({});}
 if(path.startsWith('/rest/v1/rpc/')){
  if(!tokens.has(token))return response({},401);
  try{return response(await rpc(path.slice('/rest/v1/rpc/'.length),body,tokens.get(token)));}
  catch(e){return response({message:e.message,code:e.code||'P0001'},400);}
 }
 return response({message:'Cadastro indisponível no ambiente local. Use Ana ou Beto.'},400);
}
const sqlite=new DatabaseSync('.local/trade-demo/rooms.db');
sqlite.exec('PRAGMA journal_mode=WAL;CREATE TABLE IF NOT EXISTS pipa_rooms (code TEXT PRIMARY KEY,state TEXT NOT NULL,rev INTEGER NOT NULL DEFAULT 0,updated INTEGER NOT NULL)');
const DB={prepare(sql){let values=[];return {bind(...v){values=v;return this;},async run(){const r=sqlite.prepare(sql).run(...values);return {meta:{changes:Number(r.changes)}};},async first(){return sqlite.prepare(sql).get(...values);}};}};
const accounts=createAccounts({SUPABASE_URL:'http://local-auth.invalid',SUPABASE_PUBLISHABLE_KEY:'local-only'},{fetcher:localAuth,db:sqlite,gameDatabase:{rpc:(name,body)=>rpc(name,body)},matchProgress:id=>progression.status(id)});
const progression=createProgression(sqlite,accounts),serveAsset=createAssetHandler();
const {default:worker}=await import('../worker/index.js');
const server=http.createServer(async(req,res)=>{
 try{
  if(!['127.0.0.1:'+port,'localhost:'+port].includes(req.headers.host)){res.writeHead(403);res.end('Ambiente disponível somente em localhost.');return;}
  const chunks=[];let size=0;for await(const chunk of req){size+=chunk.length;if(size>4096){res.writeHead(413);res.end();return;}chunks.push(chunk);}
  const origin='http://'+req.headers.host;
  let request=new Request(origin+req.url,{method:req.method,headers:req.headers,...(chunks.length?{body:Buffer.concat(chunks)}:{})});
  let r;
  const demo=/^\/local\/(ana|beto)$/.exec(new URL(request.url).pathname);
  if(demo){
   const login=await accounts.handle(new Request(origin+'/account/login',{method:'POST',headers:{'Content-Type':'application/json',Origin:origin},body:JSON.stringify({email:demo[1]+'@local.test',password:'TesteLocal123!'})}));
   const headers=new Headers({Location:'/'});for(const cookie of login.headers.getSetCookie())headers.append('Set-Cookie',cookie);
   r=login.ok?new Response(null,{status:303,headers}):login;
  }else r=await serveAsset(request)||await accounts.handle(request)||await worker.fetch(request,{DB,ACCOUNTS:accounts,PROGRESSION:progression});
  if(new URL(request.url).pathname==='/'&&r.headers.get('content-type')?.includes('text/html')){
   const html=(await r.text()).replace('<body>','<body><div style="background:#ffe9a8;padding:10px;text-align:center;font:14px sans-serif">TESTE LOCAL · Banco isolado · Sem dados de produção · '+(req.headers.host.startsWith('localhost')?'Beto':'Ana')+'</div>');
   r=new Response(html,{status:r.status,headers:r.headers});
  }
  const headers=Object.fromEntries(r.headers),cookies=r.headers.getSetCookie();if(cookies.length)headers['set-cookie']=cookies;
  res.writeHead(r.status,headers);res.end(Buffer.from(await r.arrayBuffer()));
 }catch(e){console.error('Local demo:',e.message);res.writeHead(500);res.end('Falha no ambiente local.');}
});
const closeRealtime=attachRealtime(server,sqlite,progression);
server.listen(port,'127.0.0.1',()=>console.log('TESTE LOCAL — Ana: http://127.0.0.1:'+port+'/local/ana\nBeto: http://localhost:'+port+'/local/beto\nBanco persistente em .local/trade-demo. Nenhum acesso ao Supabase real.'));
let stopping=false;
const stop=()=>{if(stopping)return;stopping=true;closeRealtime();progression.stop();server.close(async()=>{sqlite.close();await postgres.close();process.exit(0);});};
process.on('SIGTERM',stop);process.on('SIGINT',stop);
