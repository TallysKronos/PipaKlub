// Supabase credentials stay on the server. Browser sessions use HttpOnly cookies.
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export class AccountError extends Error{constructor(message,status=400){super(message);this.status=status;}}
const cookieValues=request=>Object.fromEntries((request.headers.get('cookie')||'').split(';').map(v=>v.trim().split(/=(.*)/s).slice(0,2)).filter(v=>v.length===2));
export function createAccounts(env,{fetcher=fetch,db=null,gameDatabase=null,matchProgress=()=>({found:false,pending:false,finished:false})}={}){
 const url=(env.SUPABASE_URL||'').replace(/\/$/,''),key=env.SUPABASE_PUBLISHABLE_KEY||env.SUPABASE_ANON_KEY||'';
 const enabled=!!(url&&key&&gameDatabase),sessions=new Map(),limits=new Map();
 const json=(data,status=200,cookies=[])=>{const headers=new Headers({'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});for(const c of cookies)headers.append('Set-Cookie',c);return new Response(JSON.stringify(data),{status,headers});};
 async function remote(path,{method='GET',body,token}={}){
  if(!enabled)throw new AccountError('Contas ainda não estão conectadas. Você pode jogar como visitante.',503);
  const headers={apikey:key,'Content-Type':'application/json'};
  if(token)headers.Authorization='Bearer '+token;
  let r;try{r=await fetcher(url+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(8000)});}catch{throw new AccountError('O serviço de contas demorou a responder. Tente novamente.',503);}
  const text=await r.text();let data;try{data=text?JSON.parse(text):null;}catch{data=null;}
  if(!r.ok){
   const message=data?.message||data?.msg||data?.error_description||'';
   if(r.status===401||data?.error_code==='invalid_credentials')throw new AccountError('E-mail ou senha inválidos, ou sessão expirada.',401);
   if(r.status===429)throw new AccountError('Muitas tentativas. Aguarde um pouco e tente novamente.',429);
   if(data?.error_code==='email_not_confirmed')throw new AccountError('Confirme seu e-mail antes de entrar.',403);
   if(data?.code?.startsWith('PGRST')||data?.code==='42883')throw new AccountError('O banco de contas ainda precisa ser configurado.',503);
   if(message.startsWith('Troca:')||message.includes('Saia da partida')||message.includes('outra partida')||message.includes('colecionável')||message.includes('coleção')||message.includes('caracteres'))throw new AccountError(message,409);
   if(data?.error_code==='over_email_send_rate_limit'||data?.error_code==='email_address_not_authorized')throw new AccountError('O envio de confirmação está indisponível. O administrador precisa configurar o e-mail do jogo.',503);
   throw new AccountError(r.status>=500?'O serviço de contas está indisponível. Tente novamente.':'Não foi possível concluir. Confira os dados e tente novamente.',r.status>=500?503:400);
  }return data;
 }
 async function rpc(name,body,token,admin=false){
  if(!admin)return remote('/rest/v1/rpc/'+name,{method:'POST',body,token});
  try{return await gameDatabase.rpc(name,body);}catch(e){
   const message=String(e.message||'');
   if(e.code==='P0001'&&/Saia da partida|outra partida|colecionável|coleção|caracteres|Partida encerrada/.test(message))throw new AccountError(message,409);
   throw new AccountError('O banco do jogo não respondeu. Aguarde e tente novamente.',503);
  }
 }
 function checkPending(user){if(db&&db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.type')='cut' AND json_extract(payload,'$.loserAccountId')=? LIMIT 1").get(user))throw new AccountError('O resultado da sua última disputa está sendo salvo. Aguarde alguns segundos.',409);}
 function makeCookies(request,session){
  const secure=new URL(request.url).protocol==='https:',prefix=secure?'__Host-':'',flags='; Path=/; HttpOnly; SameSite=Lax'+(secure?'; Secure':'');
  return [prefix+'pipa_access='+(session?.access_token||'')+'; Max-Age='+(session?Math.max(60,Math.min(session.expires_in||3600,86400)):0)+flags,prefix+'pipa_refresh='+(session?.refresh_token||'')+'; Max-Age='+(session?604800:0)+flags];
 }
 async function identity(request,refresh=false){
  const cookies=cookieValues(request),secure=new URL(request.url).protocol==='https:',prefix=secure?'__Host-':'';
  let access=cookies[prefix+'pipa_access'];const renewal=cookies[prefix+'pipa_refresh'];let setCookies=[];
  if(!access&&!renewal)return null;
  const cached=access&&sessions.get(access);if(cached&&cached.until>Date.now())return {...cached,setCookies};
  let user;
  if(access){try{user=await remote('/auth/v1/user',{token:access});}catch(e){if(e.status!==401)throw e;}}
  if(!user&&refresh&&renewal){try{const s=await remote('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token:renewal}});access=s.access_token;user=s.user;setCookies=makeCookies(request,s);}catch(e){if(e.status===401)return null;throw e;}}
  if(!user?.id||!UUID.test(user.id))return null;
  if(sessions.size>1000)sessions.clear();const result={id:user.id,access,until:Date.now()+30000};sessions.set(access,result);return {...result,setCookies};
 }
 async function accountFor(who){
  let data=await rpc('get_player_account',{},who.access);
  // A restart of the free game server must not leave equipment locked for six minutes.
  if(db&&data.profile?.active_match){
   const row=db.prepare('SELECT state FROM pipa_rooms WHERE state LIKE ?').get('%'+data.profile.active_match+'%');
   const s=row&&JSON.parse(row.state),p=s?.players.find(p=>p.accountId===who.id);
   const pending=db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.matchId')=? LIMIT 1").get(data.profile.active_match);
   if(!pending&&(!p||Date.now()-p.seen>15000||Date.now()>=s.end)){await rpc('release_player_match',{p_user:who.id,p_match:data.profile.active_match},null,true);data=await rpc('get_player_account',{},who.access);}
  }
  const xp=Number(data.profile.xp)||0,level=1+Math.floor(Math.sqrt(xp/100));
  return {...data,profile:{...data.profile,level,next_level_xp:level*level*100}};
 }
 function rateLimit(request,action){
  const ip=(request.headers.get('x-forwarded-for')||'local').split(',')[0],id=action+':'+ip,now=Date.now();
  if(limits.size>5000)for(const [k,v] of limits)if(v.until<now)limits.delete(k);
  let entry=limits.get(id);if(!entry||entry.until<now){entry={count:0,until:now+900000};limits.set(id,entry);}if(++entry.count>12)throw new AccountError('Muitas tentativas. Aguarde 15 minutos.',429);
 }
 async function handle(request){
  const path=new URL(request.url).pathname;
  if(!path.startsWith('/account/'))return null;
  try{
   if(request.headers.get('origin')&&request.headers.get('origin')!==new URL(request.url).origin)throw new AccountError('Origem inválida.',403);
   const action=path.slice('/account/'.length);
   if(action==='config'&&request.method==='GET')return json({enabled,features:{inventory:enabled,xp:enabled,capture:enabled}});
   if(!enabled)throw new AccountError('Contas ainda não estão conectadas. Você pode jogar como visitante.',503);
   if(action==='session'&&request.method==='GET'){const who=await identity(request,true);if(!who)return json({account:null},200,makeCookies(request,null));return json({account:await accountFor(who)},200,who.setCookies);}
   if(action==='history'&&request.method==='GET'){const who=await identity(request,true);if(!who)throw new AccountError('Entre na sua conta para continuar.',401);return json({matches:await rpc('get_player_recent_matches',{},who.access)},200,who.setCookies);}
   if(request.method!=='POST'||!request.headers.get('content-type')?.includes('application/json'))throw new AccountError('Pedido inválido.',405);
   const raw=await request.text();if(raw.length>4096)throw new AccountError('Pedido muito grande.',413);let b;try{b=JSON.parse(raw);}catch{throw new AccountError('Pedido inválido.');}
   if(action==='login'||action==='signup'){
    rateLimit(request,action);
    const email=String(b.email||'').trim(),password=String(b.password||'');
    if(email.length>254||!/^\S+@\S+\.\S+$/.test(email)||password.length<8||password.length>128)throw new AccountError('Use um e-mail válido e uma senha com pelo menos 8 caracteres.');
    const nickname=String(b.nickname||'Pipeiro').trim();if(action==='signup'&&(nickname.length<2||nickname.length>18))throw new AccountError('Use um apelido de 2 a 18 caracteres.');
    const s=await remote(action==='signup'?'/auth/v1/signup':'/auth/v1/token?grant_type=password',{method:'POST',body:{email,password,...(action==='signup'?{data:{nickname}}:{})}});
    if(!s.access_token)return json({confirmation:true,message:'Confira seu e-mail para confirmar a conta. Depois volte e entre.'});
    const who={id:s.user.id,access:s.access_token};return json({account:await accountFor(who)},200,makeCookies(request,s));
   }
   if(action==='logout'){const values=cookieValues(request),access=values['__Host-pipa_access']||values.pipa_access;if(access){sessions.delete(access);try{await remote('/auth/v1/logout',{method:'POST',token:access});}catch{}}return json({ok:true},200,makeCookies(request,null));}
   const who=await identity(request,true);
   if(!who)throw new AccountError('Entre na sua conta para continuar.',401);
   if(action==='trade'){
    if(!['create','join','read','offer','confirm','cancel','history'].includes(b.action))throw new AccountError('Ação de troca inválida.');
    if(b.code!=null&&!/^[A-Z0-9]{12}$/i.test(String(b.code)))throw new AccountError('Código de convite inválido.');
    if(b.kiteId!=null&&!UUID.test(String(b.kiteId)))throw new AccountError('Pipa inválida.');
    if(b.revision!=null&&(!Number.isSafeInteger(b.revision)||b.revision<0))throw new AccountError('Oferta inválida.');
    if(b.action==='create'||b.action==='join')rateLimit(request,'trade-'+b.action);
    checkPending(who.id);
    return json({trade:await rpc('player_trade',{p_action:b.action,p_code:b.code||null,p_kite:b.kiteId||null,p_revision:b.revision??null},who.access)},200,who.setCookies);
   }
   if(action==='match-result'){
    if(!UUID.test(String(b.matchId)))throw new AccountError('Partida inválida.');
    // Authorize in Postgres before inspecting the local outbox or finalizing a match.
    const result=await rpc('get_player_match_result',{p_match:b.matchId},who.access),progress=matchProgress(b.matchId);
    const status=result.match.endedAt&&!progress.pending?'saved':progress.found&&!progress.finished?'playing':progress.found||progress.pending?'saving':'unconfirmed';
    return json({result,status},200,who.setCookies);
   }
   if(action==='kite-history'){
    if(!UUID.test(String(b.kiteId)))throw new AccountError('Pipa inválida.');
    return json({history:await rpc('get_kite_history',{p_kite:b.kiteId},who.access)},200,who.setCookies);
   }
   if(action==='equip'){checkPending(who.id);if(!UUID.test(String(b.kiteId)))throw new AccountError('Pipa inválida.');await rpc('equip_player_kite',{p_kite:b.kiteId},who.access);}
   else if(action==='profile'){const nickname=String(b.nickname||'').trim();if(nickname.length<2||nickname.length>18)throw new AccountError('Use um apelido de 2 a 18 caracteres.');await rpc('update_player_name',{p_nickname:nickname},who.access);}
   else throw new AccountError('Ação não encontrada.',404);
   return json({account:await accountFor(who)},200,who.setCookies);
  }catch(e){if(!(e instanceof AccountError))console.error('Account request failed:',e.name);return json({error:e instanceof AccountError?e.message:'Não foi possível acessar sua conta.'},e.status||500);}
 }
 async function preparePlayer(request,s){
  const who=enabled?await identity(request):null;
  if(!who){if(s.rules==='capture')throw new AccountError('Entre na sua conta para jogar Vale pipa.',401);return null;}
  checkPending(who.id);
  if(s.players.some(p=>p.accountId===who.id))throw new AccountError('Você já entrou nesta sala.',409);
  return rpc('reserve_player_match',{p_user:who.id,p_match:s.id,p_code:s.code,p_mode:s.rules},null,true);
 }
 const release=(user,match)=>enabled&&UUID.test(user||'')?rpc('release_player_match',{p_user:user,p_match:match},null,true):Promise.resolve();
 const settle=e=>rpc('settle_player_cut',{p_event:e.id,p_match:e.matchId,p_winner:e.winnerAccountId,p_loser:e.loserAccountId,p_kite:e.kiteId||null},null,true);
 const finish=match=>rpc('finish_player_match',{p_match:match},null,true);
 return {enabled,handle,preparePlayer,release,settle,finish};
}
