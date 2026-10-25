// Explicit opt-in demo. Production dev.mjs never imports this authentication adapter.
import http from 'node:http';
import {signaturePreview} from './signature-preview.mjs';
import {combatReviewControls} from './combat-review-controls.mjs';
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {DatabaseSync} from 'node:sqlite';
import {PGlite} from '@electric-sql/pglite';
import {createAccounts} from '../src/accounts.js';
import {createProgression} from '../src/progression.js';
import {serveWorkshopV3} from '../src/workshop-v3-assets.js';
import {createAssetHandler} from '../src/static-assets.js';
import {attachRealtime} from '../src/realtime.js';
import {localSessionCookies} from './local-session-cookies.mjs';
import {skipLocalOpening} from './local-skip-opening.mjs';

const port=Number(process.env.LOCAL_TRADE_PORT||5194);
const localCookies=localSessionCookies(port);
if(!Number.isInteger(port)||port<1024||port>65535)throw Error('LOCAL_TRADE_PORT inválida.');
const demoSlot=process.env.LOCAL_TRADE_SLOT||'trade-demo';if(!/^[a-z0-9-]{1,60}$/.test(demoSlot))throw Error('LOCAL_TRADE_SLOT inválido.');
const demoDirectory='.local/'+demoSlot;fs.mkdirSync(demoDirectory,{recursive:true});
const postgres=new PGlite(demoDirectory+'/postgres');await postgres.waitReady;
if(!(await postgres.query("select to_regclass('public.kite_trades') installed")).rows[0].installed){
 await postgres.exec("create role anon;create role authenticated;create role service_role;create schema auth;create table auth.users(id uuid primary key,raw_user_meta_data jsonb);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to authenticated,anon,service_role;grant execute on function auth.uid() to authenticated,anon,service_role;");
 for(const name of fs.readdirSync('supabase/migrations').filter(n=>n.endsWith('.sql')).sort())await postgres.exec(fs.readFileSync('supabase/migrations/'+name,'utf8'));
}
if(!(await postgres.query("select to_regclass('public.summon_tails') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/007_summoning.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.summon_recipes') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/008_summon_catalog.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.player_trails') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/009_trails_progress.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.line_styles') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/010_line_cosmetics.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.daily_challenge_rewards') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/011_daily_challenge.sql','utf8'));
await postgres.exec(fs.readFileSync('supabase/migrations/012_javali_biscoito.sql','utf8'));
await postgres.exec(fs.readFileSync('supabase/migrations/013_javali_summoning.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.trail_runs') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/014_verified_trail_rewards.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.player_journeys') installed" )).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/015_first_flight.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.pipamon_xp_events') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/016_pipamon_leveling.sql','utf8'));

if(!(await postgres.query("select to_regclass('public.player_openings') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/017_kael_opening.sql','utf8'));
await postgres.exec(fs.readFileSync('supabase/migrations/018_story_first_collection.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.player_campaign_saves') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/019_campaign_saves.sql','utf8'));
if(!(await postgres.query("select 1 from information_schema.columns where table_schema='public' and table_name='player_campaign_saves' and column_name='autosave_enabled'")).rows.length)await postgres.exec(fs.readFileSync('supabase/migrations/020_campaign_autosave.sql','utf8'));
if(!(await postgres.query("select 1 from information_schema.columns where table_schema='public' and table_name='player_profiles' and column_name='tamer_xp'")).rows.length)await postgres.exec(fs.readFileSync('supabase/migrations/021_tamers_and_classes.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.wild_runs') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/022_wild_encounters.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.pipamon_class_nodes') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/023_class_constellations.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.workshop_jobs') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/024_soul_workshop.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.workshop_v3_runs') installed")).rows[0].installed){await postgres.exec(fs.readFileSync('supabase/migrations/025_workshop_reveal.sql','utf8'));await postgres.exec(fs.readFileSync('supabase/migrations/026_workshop_v3.sql','utf8'));}
if(!(await postgres.query("select to_regclass('public.starter_tutorials') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/027_starter_tutorial.sql','utf8'));
if(!(await postgres.query("select to_regprocedure('public.register_wild_before_guardian(uuid,uuid,text)') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/028_park_guardian.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.veredas_chest_claims') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/029_veredas_exploration.sql','utf8'));
if(!(await postgres.query("select to_regprocedure('public.server_workshop_v3_before_cancel(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb)') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/030_workshop_cancel.sql','utf8'));
if(!(await postgres.query("select to_regclass('public.kite_conditions') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/031_kite_condition.sql','utf8'));
const players={kael:{id:'55555555-5555-4555-8555-555555555555',nickname:'Kael Local'},davi:{id:'44444444-4444-4444-8444-444444444444',nickname:'Kael Local'},ana:{id:'11111111-1111-4111-8111-111111111111',nickname:'Ana Local'},beto:{id:'22222222-2222-4222-8222-222222222222',nickname:'Beto Local'},cora:{id:'33333333-3333-4333-8333-333333333333',nickname:'Cora Local'}};
for(const p of Object.values(players))await postgres.query('insert into auth.users values($1,$2) on conflict(id) do nothing',[p.id,{nickname:p.nickname}]);
// Explicit workshop-only fixture: no changes to ordinary opening tests or production.
if(process.env.LOCAL_WORKSHOP_FIXTURE==='1'){
 await postgres.query("insert into public.player_pipamon_sightings(owner_id,model_id) select $1,id from public.kite_models on conflict do nothing",[players.ana.id]);
 await postgres.query("select public.grant_summon_tail($1,'rabbito','event','local-workshop-rabbito-v1')",[players.ana.id]);
 await postgres.query("insert into public.player_openings(owner_id,step,legacy) values($1,14,true) on conflict(owner_id) do update set step=14,legacy=true",[players.ana.id]);
}
await postgres.query("select public.grant_event_soul($1,'flautrevo','local-demo')",[players.ana.id]);
await postgres.query("select public.grant_event_soul($1,'javali-biscoito','local-demo-javali-v1')",[players.ana.id]);
for(const p of [players.ana,players.beto])for(const [i,model,source] of [[1,'mata','drop'],[2,'azulao','purchase'],[3,'marulume','event'],[4,'raio','drop'],[5,'mata','drop']])await postgres.query('select public.grant_summon_tail($1,$2,$3,$4)',[p.id,model,source,'local-summon-'+i]);
// Isolated Javali fixtures: failure, interruption, success and duplicate prevention.
for(let i=1;i<=4;i++)await postgres.query('select public.grant_summon_tail($1,$2,$3,$4)',[players.beto.id,'javali-biscoito','event','local-javali-summon-'+i]);
await postgres.query("insert into public.player_pipamon_sightings(owner_id,model_id) values($1,'javali-biscoito') on conflict do nothing",[players.beto.id]);
// Demo sightings include two creatures without a tail, to exercise locked cards.
for(const p of [players.ana,players.beto])await postgres.query("insert into public.player_pipamon_sightings(owner_id,model_id) select $1,id from public.kite_models where id in ('marulume','alvaneve','hiponilo') on conflict do nothing",[p.id]);
if(!(await postgres.query("select to_regclass('public.pipamon_class_nodes') installed")).rows[0].installed)await postgres.exec(fs.readFileSync('supabase/migrations/023_class_constellations.sql','utf8'));
const operations={player_kite_care:['p_action'],player_veredas:['p_chest'],player_starter_tutorial:['p_action','p_model'],player_workshop:['p_action','p_tail','p_job','p_target','p_stage','p_payload','p_request'],player_classes:['p_kite','p_node','p_version'],player_abandon_wild:['p_match'],player_wild:['p_match'],player_specialization:['p_kite','p_class','p_upgrade','p_version'],player_campaign:['p_action','p_revision','p_checkpoint','p_keep','p_seen','p_confirmation'],player_opening:['p_action','p_step','p_name'],player_journey:['p_action','p_model','p_lesson'],get_player_trail_result:['p_match'],player_daily:[],player_lines:['p_action','p_style','p_operation'],player_trails:['p_action','p_operation','p_payload'],get_player_account:[],get_player_recent_matches:[],get_player_match_result:['p_match'],get_kite_history:['p_kite'],equip_player_kite:['p_kite'],update_player_name:['p_nickname'],player_trade:['p_action','p_code','p_kite','p_revision'],player_summon:['p_action','p_tail','p_ritual','p_path','p_request','p_session','p_target'],record_player_sighting:['p_model']};
const serverOperations={server_kite_wear:['p_user','p_kite','p_match','p_line','p_hull'],server_workshop_v3:['p_user','p_action','p_job','p_tail','p_target','p_revision','p_request','p_state','p_result'],register_wild_run:['p_user','p_match','p_zone'],settle_wild_run:['p_user','p_match','p_outcome'],register_trail_run:['p_user','p_match','p_stage'],settle_trail_run:['p_user','p_match','p_stage','p_won','p_rounds_lost'],settle_daily_challenge:['p_user','p_match','p_day'],reserve_player_match:['p_user','p_match','p_code','p_mode'],release_player_match:['p_user','p_match'],settle_player_cut:['p_event','p_match','p_winner','p_loser','p_kite'],finish_player_match:['p_match']};
async function rpc(name,body,uid){
 const args=Object.hasOwn(uid?operations:serverOperations,name)&&(uid?operations:serverOperations)[name];
 if(!args)throw Error('RPC local não permitida.');
 return postgres.transaction(async tx=>{
  await tx.exec('set local role '+(uid?'authenticated':'pipa_server'));
  if(uid)await tx.query("select set_config('request.jwt.claim.sub',$1,true)",[uid]);
  return (await tx.query('select public.'+name+'('+args.map((_,i)=>'$'+(i+1)).join(',')+') result',args.map(k=>body[k]??null))).rows[0].result;
 });
}
// Demo-only wallet seed: same operation on every restart, never used by production.
// Optional review entry for the owner: Davi starts at the birth; Kael stays at the beginning.
// Does not rewind either player's existing progress, and never runs in production dev.mjs.
if(process.env.LOCAL_OPENING_REVIEW==='1'){
 await rpc('player_opening',{p_action:'read',p_step:null,p_name:null},players.davi.id);
 await postgres.query("update public.player_openings set step=9,tail_state='attached' where owner_id=$1 and step=0 and partner_id is null",[players.davi.id]);
}
await rpc('player_trails',{p_action:'import',p_operation:'99999999-0000-4000-8000-000000000010',p_payload:{coins:200}},players.ana.id);
// Isolated park audit fixture; opt-in only, never loaded by production dev.mjs.
if(process.env.LOCAL_PARK_FIXTURE==='1'){
 const uid=players.ana.id;
 await postgres.query("select public.grant_event_soul($1,'rabbito','local-park-audit-v1')",[uid]);
 await postgres.query("insert into public.player_openings(owner_id,step,legacy) values($1,14,true) on conflict(owner_id) do update set step=14,legacy=true",[uid]);
 await postgres.query("insert into public.player_journeys(owner_id,phase,lesson,starter_model) values($1,'complete',5,'rabbito') on conflict(owner_id) do update set phase='complete',lesson=5,starter_model='rabbito'",[uid]);
 await postgres.query("update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=$1 and model_id='rabbito' order by created_at limit 1) where id=$1",[uid]);
}
// Keep this isolated review login through hot restarts; never imported by production.
const localSessionsFile=demoDirectory+'/sessions.json';let savedSessions={};try{savedSessions=JSON.parse(fs.readFileSync(localSessionsFile,'utf8'));}catch{}
const tokens=new Map(Array.isArray(savedSessions.tokens)?savedSessions.tokens:[]),guests=new Set(Array.isArray(savedSessions.guests)?savedSessions.guests:[]);
const saveLocalSessions=()=>{fs.writeFileSync(localSessionsFile+'.tmp',JSON.stringify({tokens:[...tokens],guests:[...guests]}));fs.renameSync(localSessionsFile+'.tmp',localSessionsFile);};
const userOf=id=>({id,...(guests.has(id)?{is_anonymous:true}:{})});
const response=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json'}});
async function localAuth(url,options={}){
 const path=new URL(url).pathname,body=options.body?JSON.parse(options.body):{},token=options.headers?.Authorization?.replace(/^Bearer /,'');
 if(path==='/auth/v1/token'){
  const username=body.email?.split('@')[0],player=players[username];
  if(body.refresh_token&&tokens.has(body.refresh_token))return response({access_token:body.refresh_token,refresh_token:body.refresh_token,expires_in:86400,user:userOf(tokens.get(body.refresh_token))});
  if(!player||body.email!==username+'@local.test'||body.password!=='TesteLocal123!')return response({error_code:'invalid_credentials'},401);
  const access=randomUUID();tokens.set(access,player.id);saveLocalSessions();return response({access_token:access,refresh_token:access,expires_in:86400,user:{id:player.id}});
 }
 // Jogar sem conta: emula o login anônimo do Supabase (o gatilho real cria o perfil).
 if(path==='/auth/v1/signup'&&!body.email){const id=randomUUID(),access=randomUUID();guests.add(id);await postgres.query('insert into auth.users values($1,$2)',[id,body.data||{}]);tokens.set(access,id);saveLocalSessions();return response({access_token:access,refresh_token:access,expires_in:86400,user:userOf(id)});}
 if(path==='/auth/v1/user'){if(!tokens.has(token))return response({},401);if(options.method==='PUT')return response({...userOf(tokens.get(token)),new_email:body.email});return response(userOf(tokens.get(token)));}
 if(path==='/auth/v1/logout'){tokens.delete(token);saveLocalSessions();return response({});}
 if(path.startsWith('/rest/v1/rpc/')){
  if(!tokens.has(token))return response({},401);
  try{return response(await rpc(path.slice('/rest/v1/rpc/'.length),body,tokens.get(token)));}
  catch(e){return response({message:e.message,code:e.code||'P0001'},400);}
 }
 return response({message:'Cadastro indisponível no ambiente local. Use Ana, Beto ou Cora.'},400);
}
const sqlite=new DatabaseSync(demoDirectory+'/rooms.db');
sqlite.exec('PRAGMA journal_mode=WAL;CREATE TABLE IF NOT EXISTS pipa_rooms (code TEXT PRIMARY KEY,state TEXT NOT NULL,rev INTEGER NOT NULL DEFAULT 0,updated INTEGER NOT NULL)');
const DB={prepare(sql){let values=[];return {bind(...v){values=v;return this;},async run(){const r=sqlite.prepare(sql).run(...values);return {meta:{changes:Number(r.changes)}};},async first(){return sqlite.prepare(sql).get(...values);}};}};
const accounts=createAccounts({GUEST_PLAY_ENABLED:'1',SUPABASE_URL:'http://local-auth.invalid',SUPABASE_PUBLISHABLE_KEY:'local-only'},{fetcher:localAuth,db:sqlite,gameDatabase:{rpc:(name,body)=>rpc(name,body)},matchProgress:id=>progression.status(id)});
const progression=createProgression(sqlite,accounts),serveAsset=createAssetHandler();
const {default:worker}=await import('../worker/index.js');
const server=http.createServer(async(req,res)=>{
 try{
  if(!['127.0.0.1:'+port,'localhost:'+port].includes(req.headers.host)){res.writeHead(403);res.end('Ambiente disponível somente em localhost.');return;}
  const chunks=[];let size=0;for await(const chunk of req){size+=chunk.length;if(size>(req.url==='/account/workshop-v3'?180000:4096)){res.writeHead(413);res.end();return;}chunks.push(chunk);}
  const origin='http://'+req.headers.host;
  const requestHeaders=new Headers(req.headers);requestHeaders.set('cookie',localCookies.incoming(req.headers.cookie));
  let request=new Request(origin+req.url,{method:req.method,headers:requestHeaders,...(chunks.length?{body:Buffer.concat(chunks)}:{})});
  let r;
  const demo=/^\/local\/(ana|beto|cora|davi|kael)$/.exec(new URL(request.url).pathname);
  if(new URL(request.url).pathname==='/local/signatures'){r=new Response(signaturePreview(),{headers:{'Content-Type':'text/html;charset=utf-8'}});}
  else if(new URL(request.url).pathname==='/local/skip-opening'){
   if(req.method!=='POST'||request.headers.get('origin')!==origin){r=new Response('Use o botão Pular início no teste local.',{status:403});}
   else{
    const session=await accounts.handle(new Request(origin+'/account/session',{headers:requestHeaders})),data=await session.json(),owner=data.account?.profile?.id;
    if(!owner)r=new Response('Entre como visitante ou em uma conta de teste antes de pular o início.',{status:401});
    else try{const form=new URLSearchParams(Buffer.concat(chunks).toString());await skipLocalOpening(postgres,owner,form.get('model')||'basica');const headers=new Headers({Location:'/'});for(const cookie of session.headers.getSetCookie())headers.append('Set-Cookie',cookie);r=new Response(null,{status:303,headers});}
    catch(e){r=new Response(e.message,{status:409,headers:{'Content-Type':'text/plain;charset=utf-8'}});}
   }
  }else if(demo){
   const login=await accounts.handle(new Request(origin+'/account/login',{method:'POST',headers:{'Content-Type':'application/json',Origin:origin},body:JSON.stringify({email:demo[1]+'@local.test',password:'TesteLocal123!'})}));
   const headers=new Headers({Location:'/'});for(const cookie of login.headers.getSetCookie())headers.append('Set-Cookie',cookie);
   r=login.ok?new Response(null,{status:303,headers}):login;
  }else r=await serveWorkshopV3(request)||await serveAsset(request)||await accounts.handle(request)||await worker.fetch(request,{DB,ACCOUNTS:accounts,PROGRESSION:progression});
  if(new URL(request.url).pathname==='/'&&r.headers.get('content-type')?.includes('text/html')){
   const html=(await r.text()).replace('<body>','<body><div id="localDemoBar" style="background:#ffe9a8;padding:10px;text-align:center;font:14px sans-serif;position:fixed;bottom:0;right:0;max-width:100vw;z-index:100001"><details><summary>Ambiente local · atalhos</summary>Banco isolado · Sem dados de produção<form action="/local/skip-opening" method="post" style="display:inline-flex;gap:8px;align-items:center;flex-wrap:wrap;margin-left:12px"><label>Primeira pipa <select name="model" aria-label="Pipa para o atalho de teste"><option value="basica">Carcará</option><option value="mata">Mata Verde</option><option value="azulao">Azulão</option><option value="raio">Raio de Sol</option></select></label><button type="submit">Pular início · teste</button><small>Após a montagem com o professor · entre primeiro</small></form></details></div>');
   r=new Response(process.env.LOCAL_COMBAT_REVIEW==='1'?html.replace('</body>',combatReviewControls()+'</body>'):html,{status:r.status,headers:r.headers});
  }
  const headers=Object.fromEntries(r.headers),cookies=r.headers.getSetCookie().map(localCookies.outgoing);if(cookies.length)headers['set-cookie']=cookies;
  res.writeHead(r.status,headers);res.end(Buffer.from(await r.arrayBuffer()));
 }catch(e){console.error('Local demo:',e.message);res.writeHead(500);res.end('Falha no ambiente local.');}
});
const closeRealtime=attachRealtime(server,sqlite,progression);
server.listen(port,'127.0.0.1',()=>console.log('TESTE LOCAL — Abertura: http://127.0.0.1:'+port+'/local/kael\nAna: http://127.0.0.1:'+port+'/local/ana\nBeto: http://localhost:'+port+'/local/beto\nBanco persistente em '+demoDirectory+'. Nenhum acesso ao Supabase real.'));
let stopping=false;
const stop=()=>{if(stopping)return;stopping=true;closeRealtime();progression.stop();server.close(async()=>{sqlite.close();await postgres.close();process.exit(0);});};
process.on('SIGTERM',stop);process.on('SIGINT',stop);
