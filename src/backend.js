const engine=createEngine();
const visible=engine.visible;
let initialized;
const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
async function init(db){if(!initialized)initialized=db.prepare('CREATE TABLE IF NOT EXISTS pipa_rooms (code TEXT PRIMARY KEY, state TEXT NOT NULL, rev INTEGER NOT NULL DEFAULT 0, updated INTEGER NOT NULL)').run().catch(e=>{initialized=null;throw e;});await initialized;}
async function api(request,env){
  if(request.method!=='POST')return json({error:'Método inválido.'},405);
  if(request.headers.get('origin')&&request.headers.get('origin')!==new URL(request.url).origin)return json({error:'Origem inválida.'},403);
  if(!env.DB)return json({error:'Servidor online indisponível. Você pode jogar no treino.'},503);
  if(Number(request.headers.get('content-length'))>4096)return json({error:'Pedido muito grande.'},413);
  let b;try{const raw=await request.text();if(raw.length>4096)throw Error();b=JSON.parse(raw);}catch{return json({error:'Pedido inválido.'},400);}
  await init(env.DB);let action=new URL(request.url).pathname.split('/').pop();const now=Date.now();
  if(action==='create')return json(await createRoom(request,env,b,now));
  // Quick match: join the open quick room when there is one, otherwise open a new one.
  if(action==='quick'){const open=await openQuickRoom(env,now);if(!open)return json(await createRoom(request,env,{name:b.name,color:b.color,mode:'rounds',quick:true},now));b={...b,code:open,rules:'casual',captureConsent:false};action='join';}
  const code=String(b.code||'').toUpperCase();if(!/^[A-F0-9]{6}$/.test(code))return json({error:'Use o código de 6 caracteres da sala.'},400);
  if(action==='inspect'){const row=await env.DB.prepare('SELECT state, rev FROM pipa_rooms WHERE code = ?').bind(code).first();if(!row)return json({error:'Sala não encontrada. Confira o código.'},404);const s=JSON.parse(row.state);if(now>=s.end)return json({error:s.next?'Esta partida terminou. A revanche está na sala '+s.next+'.':'Esta partida terminou. Crie uma nova sala.',next:s.next},409);return json({code,rules:s.rules||'casual',mode:s.mode||'time'});}
  // The account check is a network call: do it once, before the retry loop, so the realtime tick cannot win every retry.
  let account=null;
  if(action==='join'){
    const row=await env.DB.prepare('SELECT state, rev FROM pipa_rooms WHERE code = ?').bind(code).first();
    if(!row)return json({error:'Sala não encontrada. Confira o código.'},404);
    const s=JSON.parse(row.state);engine.step(s,now);
    if(s.rules==='capture'&&!b.captureConsent)return json({error:'Confirme a regra Vale pipa para entrar.'},400);
    if(s.players.length>=8)return json({error:'Sala cheia. O limite é de 8 jogadores.'},409);
    if(now>=s.end)return json({error:s.next?'Esta partida terminou. A revanche está na sala '+s.next+'.':'Esta partida terminou. Crie uma nova sala.',next:s.next},409);
    if(s.rules==='capture'&&!env.ACCOUNTS?.enabled)return json({error:'Vale pipa precisa de contas conectadas ao banco.'},503);
    account=env.ACCOUNTS?await env.ACCOUNTS.preparePlayer(request,s):null;
    if(!account&&(s.rules!=='casual'||s.mode!=='rounds'))return json({error:'Entre na conta para jogar modalidades especiais. Visitantes podem jogar a partida padrão.'},401);
  }
  for(let n=0;n<8;n++){
    let row=await env.DB.prepare('SELECT state, rev FROM pipa_rooms WHERE code = ?').bind(code).first();
    if(!row)return json({error:'Sala não encontrada. Confira o código.'},404);
    let s=JSON.parse(row.state);engine.step(s,now);let token=b.token,p=s.players.find(p=>p.key===token);
    if(action==='join'){
      // A person who arrives at a full quick room takes a bot's seat between rounds.
      if(s.quick&&s.players.length>=s.quick.size){const i=s.players.findIndex(q=>q.bot);if(i<0||s.phase==='live'){await releaseAccount(env,account,s);return json({error:'Sala cheia. Tente a partida rápida de novo.'},409);}s.players.splice(i,1);}
      if(s.players.length>=8){await releaseAccount(env,account,s);return json({error:'Sala cheia. O limite é de 8 jogadores.'},409);}
      if(account?.accountId&&s.players.some(q=>q.accountId===account.accountId)){await releaseAccount(env,account,s);return json({error:'Você já entrou nesta sala.'},409);}
      token=crypto.randomUUID();p=engine.player(account?.name||b.name,account?.color??b.color,crypto.randomUUID(),now);p.key=token;if(account)Object.assign(p,account);engine.admit(s,p,now);
    }else if(!p)return json({error:'Sua conexão expirou. Entre na sala novamente.'},401);
    if(action==='rematch'){
      // The rematch is a fresh room (fresh match id for rewards); the first player to ask creates it, the rest are pointed to it.
      if(now<s.end)return json({code,token,me:p.id,state:visible(s)});
      if(s.next)return json({next:s.next});
      const room=await createRoom(request,env,{name:p.name,color:p.color,rules:s.rules,mode:s.mode},now);
      s.next=room.code;await env.DB.prepare('UPDATE pipa_rooms SET state = ?, rev = rev + 1 WHERE code = ? AND rev = ?').bind(JSON.stringify(s),code,row.rev).run();
      return json(room);
    }
    if(action==='sync'){p.input=engine.sanitizeInput(b.input);p.seen=now;}
    else if(action==='leave')s.players=s.players.filter(q=>q.key!==token);
    else if(action!=='join')return json({error:'Ação inválida.'},400);
    const res=await env.DB.prepare('UPDATE pipa_rooms SET state = ?, rev = rev + 1, updated = ? WHERE code = ? AND rev = ?').bind(JSON.stringify(s),now,code,row.rev).run();
    if(res.meta.changes){env.PROGRESSION?.observe(s);if(action==='leave'&&p.accountId){if(env.PROGRESSION)env.PROGRESSION.release(p.accountId,s.id);else await env.ACCOUNTS?.release(p.accountId,s.id);}return json({code,token,me:p.id,state:visible(s)});}
  }
  if(action==='join'){const row=await env.DB.prepare('SELECT state FROM pipa_rooms WHERE code = ?').bind(code).first();if(row)await releaseAccount(env,account,JSON.parse(row.state));}
  return json({error:'Sala ocupada. Tente novamente.'},409);
}
// One pointer row names the quick room that is currently open; room codes are hex, so it never collides.
const QUICK_POINTER='QUICK!';
async function openQuickRoom(env,now){
  const pointer=await env.DB.prepare('SELECT state FROM pipa_rooms WHERE code = ?').bind(QUICK_POINTER).first();if(!pointer)return null;
  const code=JSON.parse(pointer.state).code,row=await env.DB.prepare('SELECT state FROM pipa_rooms WHERE code = ?').bind(code).first();if(!row)return null;
  const s=JSON.parse(row.state),humans=s.players.filter(p=>!p.bot&&now-p.seen<15000).length;
  if(!s.quick||now>=s.end||humans>=s.quick.size)return null;
  return s.phase==='waiting'||(s.phase!=='live'&&s.players.some(p=>p.bot))?code:null;
}
async function createRoom(request,env,b,now){
  const code=crypto.randomUUID().replaceAll('-','').slice(0,6).toUpperCase(),token=crypto.randomUUID(),s=engine.create(now,{mode:b.mode,quick:b.quick});
  s.code=code;s.rules=b.rules==='capture'?'capture':'casual';
  if(s.rules==='capture'&&!env.ACCOUNTS?.enabled)throw Object.assign(Error('Vale pipa precisa de contas conectadas ao banco.'),{status:503});
  const account=env.ACCOUNTS?await env.ACCOUNTS.preparePlayer(request,s):null;
  if(!account&&(s.rules!=='casual'||s.mode!=='rounds'))throw Object.assign(Error('Entre na conta para criar modalidades especiais. Visitantes podem convidar para a partida padrão.'),{status:401});
  const p=engine.player(account?.name||b.name,account?.color??b.color,crypto.randomUUID(),now);p.key=token;if(account)Object.assign(p,account);engine.admit(s,p,now);
  await env.DB.prepare('INSERT INTO pipa_rooms (code,state,updated) VALUES (?,?,?)').bind(code,JSON.stringify(s),now).run();
  if(s.quick)await env.DB.prepare('INSERT INTO pipa_rooms (code,state,updated) VALUES (?,?,?) ON CONFLICT(code) DO UPDATE SET state=excluded.state, updated=excluded.updated').bind(QUICK_POINTER,JSON.stringify({code}),now).run();
  await env.DB.prepare('DELETE FROM pipa_rooms WHERE updated < ?').bind(now-3600000).run();
  return {code,token,me:p.id,state:visible(s)};
}
async function releaseAccount(env,account,s){if(!account?.accountId)return;try{if(env.PROGRESSION)env.PROGRESSION.release(account.accountId,s.id);else await env.ACCOUNTS?.release(account.accountId,s.id);}catch{}}
export default {async fetch(request,env){try{const u=new URL(request.url);if(u.pathname.startsWith('/assets/'))return env.ASSETS?env.ASSETS.fetch(request):new Response('Asset not found',{status:404});if(u.pathname.startsWith('/api/'))return await api(request,env);if(u.pathname==='/health')return json({ok:true});return new Response(PAGE,{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'same-origin'}});}catch(e){console.error(e);return json({error:e.status?e.message:'Não foi possível conectar. Tente novamente ou entre no treino.'},e.status||500);}}};
