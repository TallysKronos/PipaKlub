// Supabase credentials stay on the server. Browser sessions use HttpOnly cookies.
import {workshopV3} from './workshop-v3-service.js';
import {createEngine} from './engine.js';
import {validWorkshopPayload} from './workshop-model.js';
import fs from 'node:fs';
const publicModelNames=new Map(JSON.parse(fs.readFileSync(new URL('../assets/pipa-dex.json',import.meta.url),'utf8')).entries.map(e=>[e.model,e.name]));
const progressionEngine=createEngine(),pipamonProgression=progressionEngine.pipamons;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export class AccountError extends Error{constructor(message,status=400){super(message);this.status=status;}}
const cookieValues=request=>Object.fromEntries((request.headers.get('cookie')||'').split(';').map(v=>v.trim().split(/=(.*)/s).slice(0,2)).filter(v=>v.length===2));
export function createAccounts(env,{fetcher=fetch,db=null,gameDatabase=null,matchProgress=()=>({found:false,pending:false,finished:false}),diagnostics=entry=>console.warn('Account provider rejected:',JSON.stringify(entry))}={}){
 const url=(env.SUPABASE_URL||'').replace(/\/$/,''),key=env.SUPABASE_PUBLISHABLE_KEY||env.SUPABASE_ANON_KEY||'';
 const enabled=!!(url&&key&&gameDatabase),sessions=new Map(),limits=new Map();
 const json=(data,status=200,cookies=[])=>{const headers=new Headers({'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});for(const c of cookies)headers.append('Set-Cookie',c);return new Response(JSON.stringify(data),{status,headers});};
 async function remote(path,{method='GET',body,token,op}={}){
  if(!enabled)throw new AccountError('Contas ainda não estão conectadas. Você pode jogar como visitante.',503);
  const headers={apikey:key,'Content-Type':'application/json'};
  if(token)headers.Authorization='Bearer '+token;
  let r;try{r=await fetcher(url+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(8000)});}catch{throw new AccountError('O serviço de contas demorou a responder. Tente novamente.',503);}
  const text=await r.text();let data;try{data=text?JSON.parse(text):null;}catch{data=null;}
  if(!r.ok){
   const message=data?.message||data?.msg||data?.error_description||'';
   const operation=op||(path.startsWith('/rest/')?'profile':path.includes('grant_type=password')?'login':path.includes('grant_type=refresh_token')?'refresh':path.startsWith('/auth/v1/recover')?'recover':path.startsWith('/auth/v1/user')?(method==='PUT'?'reset':'session'):'auth');
   const rawCode=data?.error_code||data?.code||'',providerCode=/^(?:PGRST\d{3}|42501|42883|invalid_credentials|email_not_confirmed|anonymous_provider_disabled|email_exists|bad_jwt|session_not_found|refresh_token_not_found|refresh_token_already_used|over_email_send_rate_limit|email_address_not_authorized)$/.test(rawCode)?rawCode:'unclassified';
   const keyRejected=/invalid api key|no api key|invalid apikey|api key.*(?:invalid|missing)/i.test(message);
   // Diagnostics contain only a fixed operation, status and allowlisted code. Never log provider bodies, credentials, tokens or identities.
   diagnostics({operation,status:r.status,code:providerCode,keyRejected});
   if(keyRejected)throw new AccountError('A conexão do jogo com o serviço de contas precisa ser corrigida. Código CONTA-CONEXAO.',503);
   if(operation==='profile'&&(r.status===401||r.status===403))throw new AccountError('O serviço de perfil recusou o acesso à sua conta. Código CONTA-PERFIL. Não é necessário trocar sua senha novamente.',503);
   if(data?.error_code==='invalid_credentials')throw new AccountError('E-mail ou senha inválidos.',401);
   if(data?.error_code==='anonymous_provider_disabled'||operation==='guest'&&r.status===422)throw new AccountError('O modo sem conta ainda não foi ativado no servidor. Código CONTA-VISITANTE.',503);
   if(data?.error_code==='email_exists'||operation==='guest-save'&&/already|registered|exists/i.test(message))throw new AccountError('Este e-mail já tem uma conta. Entre com ele; o progresso de visitante continua separado neste aparelho.',409);
   if(r.status===401){if(operation==='login')throw new AccountError('O serviço de autenticação recusou a conexão do jogo. Código CONTA-AUTH.',503);throw new AccountError(operation==='reset'?'O link de recuperação é inválido ou expirou. Solicite um novo link.':'Sua sessão expirou. Entre novamente.',401);}
   if(r.status===429)throw new AccountError('Muitas tentativas. Aguarde um pouco e tente novamente.',429);
   if(data?.error_code==='email_not_confirmed')throw new AccountError('Confirme seu e-mail antes de entrar.',403);
   if(data?.code?.startsWith('PGRST')||data?.code==='42883')throw new AccountError('O banco de contas ainda precisa ser configurado.',503);
   if(message.startsWith('Sua pipa precisa')||message.startsWith('Termine o encontro')||message.startsWith('Oficina:'))throw new AccountError(message,409);
   if(message.startsWith('Classes:')||message.startsWith('Exploração:')||message.startsWith('Progressão:')||message.startsWith('Save:')||message.startsWith('Save alterado')||message.startsWith('Depósito:')||message.startsWith('Digite EXCLUIR')||message.startsWith('Encerre sua troca')||message.startsWith('Conclua sua invocação')||message.startsWith('Conclua o primeiro voo')||message.startsWith('Sua coleção mudou')||message.startsWith('Primeiro voo:')||message.startsWith('Linhas:')||message.startsWith('Trilhas:')||message.startsWith('Invocação:')||message.startsWith('Troca:')||message.includes('Saia da partida')||message.includes('outra partida')||message.includes('colecionável')||message.includes('coleção')||message.includes('caracteres'))throw new AccountError(message,409);
   if(data?.error_code==='over_email_send_rate_limit'||data?.error_code==='email_address_not_authorized')throw new AccountError('O envio de confirmação está indisponível. O administrador precisa configurar o e-mail do jogo.',503);
   throw new AccountError(r.status>=500?'O serviço de contas está indisponível. Tente novamente.':'Não foi possível concluir. Confira os dados e tente novamente.',r.status>=500?503:400);
  }return data;
 }
 async function rpc(name,body,token,admin=false){
  if(!admin)return remote('/rest/v1/rpc/'+name,{method:'POST',body,token});
  try{return await gameDatabase.rpc(name,body);}catch(e){
   const message=String(e.message||'');
   if(e.code==='P0001'&&/Sua pipa precisa|Termine o encontro|Oficina:|Exploração:|Classes:|Depósito:|Save:|Trilhas:|Troca:|Saia da partida|outra partida|colecionável|coleção|caracteres|Partida encerrada/.test(message))throw new AccountError(message,409);
   throw new AccountError('O banco do jogo não respondeu. Aguarde e tente novamente.',503);
  }
 }
 function checkPending(user){if(db&&db.prepare("SELECT 1 FROM pipa_rewards WHERE ((json_extract(payload,'$.type')='cut' AND json_extract(payload,'$.loserAccountId')=?) OR (json_extract(payload,'$.type')='care' AND json_extract(payload,'$.userId')=?)) LIMIT 1").get(user,user))throw new AccountError('O resultado da sua última disputa está sendo salvo. Aguarde alguns segundos.',409);}
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
  if(sessions.size>1000)sessions.clear();const result={id:user.id,access,anonymous:user.is_anonymous===true,until:Date.now()+30000};sessions.set(access,result);return {...result,setCookies};
 }
 async function accountFor(who){
  let data=await rpc('get_player_account',{},who.access);if(who.anonymous)data={...data,guest:true};
  // A restart of the free game server must not leave equipment locked for six minutes.
  if(db&&data.profile?.active_match){
   const row=db.prepare('SELECT state FROM pipa_rooms WHERE state LIKE ?').get('%'+data.profile.active_match+'%');
   const s=row&&JSON.parse(row.state),p=s?.players.find(p=>p.accountId===who.id);
   const pending=db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.matchId')=? LIMIT 1").get(data.profile.active_match);
   if(!pending&&(!p||Date.now()-p.seen>15000||Date.now()>=s.end)){await rpc('release_player_match',{p_user:who.id,p_match:data.profile.active_match},null,true);data=await rpc('get_player_account',{},who.access);}
  }
  const care=await rpc('player_kite_care',{p_action:'read'},who.access);data.inventory=(data.inventory||[]).map(k=>({...k,model:{...k.model,name:publicModelNames.get(k.model_id)||k.model.name},condition:care[k.id]||{line:100,hull:100}}));
  const legacy=data.profile.tamer_xp==null,xp=Number(legacy?data.profile.xp:data.profile.tamer_xp)||0,tamer=progressionEngine.tamers.progress(xp),level=legacy?Math.min(100,1+Math.floor(Math.sqrt(xp/100))):tamer.level;
  return {...data,inventory:(data.inventory||[]).map(k=>({...k,progression:{...pipamonProgression.progress(k.pipamon_xp),stats:pipamonProgression.stats(pipamonProgression.progress(k.pipamon_xp).level,k.pipamon_class,k.class_rank,k.craft_bonus)}})),profile:{...data.profile,xp,level,max_level:100,level_base_xp:legacy?(level-1)**2*100:tamer.start,next_level_xp:level===100?null:legacy?level*level*100:tamer.next}};
 }
 function rateLimit(request,action,max=12){
  const ip=(request.headers.get('x-forwarded-for')||'local').split(',')[0],id=action+':'+ip,now=Date.now();
  if(limits.size>5000)for(const [k,v] of limits)if(v.until<now)limits.delete(k);
  let entry=limits.get(id);if(!entry||entry.until<now){entry={count:0,until:now+900000};limits.set(id,entry);}if(++entry.count>max)throw new AccountError('Muitas tentativas. Aguarde 15 minutos.',429);
 }
 async function handle(request){
  const path=new URL(request.url).pathname;
  if(!path.startsWith('/account/'))return null;
  try{
   if(request.headers.get('origin')&&request.headers.get('origin')!==new URL(request.url).origin)throw new AccountError('Origem inválida.',403);
   const action=path.slice('/account/'.length);
   if(action==='config'&&request.method==='GET')return json({enabled,features:{inventory:enabled,xp:enabled,capture:enabled,guest:enabled&&env.GUEST_PLAY_ENABLED==='1'}});
   if(!enabled)throw new AccountError('Contas ainda não estão conectadas. Você pode jogar como visitante.',503);
   if(action==='session'&&request.method==='GET'){const who=await identity(request,true);if(!who)return json({account:null},200,makeCookies(request,null));return json({account:await accountFor(who)},200,who.setCookies);}
   if(action==='history'&&request.method==='GET'){const who=await identity(request,true);if(!who)throw new AccountError('Entre na sua conta para continuar.',401);return json({matches:await rpc('get_player_recent_matches',{},who.access)},200,who.setCookies);}
   if(request.method!=='POST'||!request.headers.get('content-type')?.includes('application/json'))throw new AccountError('Pedido inválido.',405);
   const raw=await request.text();if(raw.length>(action==='workshop-v3'?180000:4096))throw new AccountError('Pedido muito grande.',413);let b;try{b=JSON.parse(raw);}catch{throw new AccountError('Pedido inválido.');}
   if(action==='recover'){
    rateLimit(request,'recover',5);const email=String(b.email||'').trim();
    if(email.length>254||!/^\S+@\S+\.\S+$/.test(email))throw new AccountError('Informe um e-mail válido.');
    // The destination is derived from this server, never accepted from the client.
    const destination=new URL(request.url).origin+'/';
    await remote('/auth/v1/recover?redirect_to='+encodeURIComponent(destination),{method:'POST',body:{email}});
    return json({ok:true,message:'Se houver uma conta com este e-mail, você receberá um link para escolher uma nova senha.'});
   }
   if(action==='reset-password'){
    rateLimit(request,'reset-password',8);const password=String(b.password||''),token=String(b.token||'');
    if(password.length<8||password.length>128)throw new AccountError('Use uma senha de 8 a 128 caracteres.');
    if(token.length<20||token.length>3500)throw new AccountError('Abra um link de recuperação válido recebido no e-mail.',401);
    // Supabase validates the bearer and authorizes the change on that user; cookies and body user IDs cannot choose an account.
    const updated=await remote('/auth/v1/user',{method:'PUT',token,body:{password}});
    if(!UUID.test(updated?.id||'')||typeof updated?.email!=='string'||!/^\S+@\S+\.\S+$/.test(updated.email))throw new AccountError('O provedor não confirmou os dados da conta atualizada. Código CONTA-RECUPERACAO.',503);
    sessions.clear();
    // Confirm the freshly set password against the provider's email, never a client-chosen identity.
    // This also avoids asking the player to retype a password into a form with stale autofill.
    try{
     const session=await remote('/auth/v1/token?grant_type=password',{method:'POST',body:{email:updated.email,password}});
     if(!session?.access_token||session.user?.id!==updated.id)throw new AccountError('O provedor não confirmou a entrada na conta recuperada.',503);
     const account=await accountFor({id:updated.id,access:session.access_token});
     return json({ok:true,passwordUpdated:true,account,loginEmail:updated.email,message:'Senha atualizada e conta conectada. Sua coleção está pronta.'},200,makeCookies(request,session));
    }catch(e){
     // The password change already happened; do not report it as a failed change or encourage another reset.
     return json({ok:true,passwordUpdated:true,account:null,loginEmail:updated.email,message:'Senha atualizada, mas não foi possível concluir a entrada automática. Código CONTA-POS-RECUPERACAO. '+(e instanceof AccountError?e.message:'Tente entrar novamente.')},200,makeCookies(request,null));
    }
   }
   // Jogar sem conta: usuário anônimo do Supabase. O gatilho de cadastro cria o perfil e a coleção como para qualquer jogador.
   if(action==='guest'){
    if(env.GUEST_PLAY_ENABLED!=='1')throw new AccountError('O modo sem conta está temporariamente desativado.',503);
    rateLimit(request,'guest',4);
    const s=await remote('/auth/v1/signup',{method:'POST',op:'guest',body:{data:{nickname:'Visitante '+(1000+Math.floor(Math.random()*9000)),guest:true}}});
    if(!s?.access_token||!s.user?.id)throw new AccountError('O modo sem conta ainda não foi ativado no servidor. Código CONTA-VISITANTE.',503);
    return json({account:await accountFor({id:s.user.id,access:s.access_token,anonymous:true})},200,makeCookies(request,s));
   }
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
   if(action==='veredas'){if(b.chest!=null&&!['lookout','woodland','canal','ridge','courtyard'].includes(b.chest))throw new AccountError('Exploração: baú inválido.');checkPending(who.id);rateLimit(request,'veredas-'+who.id,60);return json({veredas:await rpc('player_veredas',{p_chest:b.chest??null},who.access),account:await accountFor(who)},200,who.setCookies);}
   if(action==='wild'){if(b.matchId!=null&&!UUID.test(String(b.matchId)))throw new AccountError('Exploração: encontro inválido.');return json({wild:await rpc('player_wild',{p_match:b.matchId||null},who.access),account:await accountFor(who)},200,who.setCookies);}
   if(action==='wild-abandon'){if(!UUID.test(String(b.matchId)))throw new AccountError('Exploração: encontro inválido.');await rpc('player_abandon_wild',{p_match:b.matchId},who.access);return json({account:await accountFor(who)},200,who.setCookies);}
   if(action==='classes'){if(!UUID.test(String(b.kiteId))||(b.nodeId!=null&&!/^[a-z0-9-]{1,64}$/.test(b.nodeId))||(b.nodeId!=null&&!Number.isSafeInteger(b.version)))throw new AccountError('Classes: opção inválida.');checkPending(who.id);rateLimit(request,'classes-'+who.id,120);const classes=await rpc('player_classes',{p_kite:b.kiteId,p_node:b.nodeId??null,p_version:b.version??null},who.access);return json({classes,account:await accountFor(who)},200,who.setCookies);}
   if(action==='specialization'){if(!UUID.test(String(b.kiteId))||!['velocista','condutor'].includes(b.classId)||typeof b.upgrade!=='boolean'||!Number.isSafeInteger(b.version))throw new AccountError('Classes: opção inválida.');checkPending(who.id);rateLimit(request,'classes-'+who.id,60);await rpc('player_specialization',{p_kite:b.kiteId,p_class:b.classId,p_upgrade:b.upgrade,p_version:b.version},who.access);return json({account:await accountFor(who)},200,who.setCookies);}
   if(action==='campaign'){
    if(!['read','save','autosave','settings','protect','reset','discard'].includes(b.action))throw new AccountError('Save: ação inválida.');
    if(b.action!=='read'&&(!Number.isSafeInteger(b.revision)||b.revision<0))throw new AccountError('Save: revisão inválida.');
    for(const list of ['keep','seen'])if(b[list]!=null&&(!Array.isArray(b[list])||b[list].length>(list==='keep'?20:5000)||b[list].some(id=>!UUID.test(String(id)))))throw new AccountError('Depósito: lista inválida.');
    if(['save','autosave'].includes(b.action)&&(!b.checkpoint||typeof b.checkpoint.scene!=='string'||!Number.isFinite(b.checkpoint.x)||!Number.isFinite(b.checkpoint.y)||!Number.isInteger(b.checkpoint.direction)))throw new AccountError('Save: posição inválida.');
    if(b.action==='settings'&&typeof b.checkpoint?.enabled!=='boolean')throw new AccountError('Save: configuração inválida.');
    if(b.action==='reset'&&b.confirmation!=='EXCLUIR SAVE')throw new AccountError('Digite EXCLUIR SAVE para confirmar.');
    checkPending(who.id);if(b.action!=='read')rateLimit(request,'campaign-'+who.id,b.action==='reset'?6:120);
    const campaign=await rpc('player_campaign',{p_action:b.action,p_revision:b.revision??null,p_checkpoint:b.checkpoint??null,p_keep:b.keep??null,p_seen:b.seen??null,p_confirmation:b.confirmation??null},who.access);
    return json({campaign,account:await accountFor(who),...(b.action==='reset'?{opening:await rpc('player_opening',{p_action:'read',p_step:null,p_name:null},who.access),journey:await rpc('player_journey',{p_action:'read',p_model:null,p_lesson:null},who.access),trails:await rpc('player_trails',{p_action:'read',p_operation:null,p_payload:{}},who.access)}:{})},200,who.setCookies);
   }
   if(action==='opening'){
    if(!['read','advance','name','checkpoint'].includes(b.action))throw new AccountError('Abertura: ação inválida.');
    if(b.step!=null&&(!Number.isInteger(b.step)||b.step<0||b.step>14))throw new AccountError('Abertura: cena inválida.');
    if(b.name!=null&&(typeof b.name!=='string'||[...b.name].length>24||/[\u0000-\u001f\u007f]/.test(b.name)))throw new AccountError('Nome do parceiro inválido.');
    checkPending(who.id);
    let opening;
    if(b.action==='checkpoint'){
     if(![3,4,5,7,9,10,12,14].includes(b.target))throw new AccountError('Abertura: marco inválido.');
     opening=await rpc('player_opening',{p_action:'read',p_step:null,p_name:null},who.access);
     if(b.target>10&&opening.step<11)throw new AccountError('Conclua o nascimento e confirme o nome primeiro.');
     // Existing owner-scoped transitions keep tail grants and naming authoritative.
     // Retrying a completed event returns its current state without replaying grants.
     while(opening.step<b.target)opening=await rpc('player_opening',{p_action:'advance',p_step:opening.step,p_name:null},who.access);
    }else opening=await rpc('player_opening',{p_action:b.action,p_step:b.step??null,p_name:b.name??null},who.access);
    return json({opening,...(opening.partner_id?{account:await accountFor(who)}:{}),...(opening.step===14?{journey:await rpc('player_journey',{p_action:'read',p_model:null,p_lesson:null},who.access)}:{})},200,who.setCookies);
   }
   if(action==='journey'){
    if(!['read','welcome','choose','advance','skip','finish','starter-choose','starter-finish'].includes(b.action))throw new AccountError('Primeiro voo: ação inválida.');
    if(b.modelId!=null&&!['basica','mata','azulao','raio'].includes(b.modelId))throw new AccountError('Primeiro voo: parceiro inválido.');
    if(b.lesson!=null&&(!Number.isInteger(b.lesson)||b.lesson<0||b.lesson>5))throw new AccountError('Primeiro voo: etapa inválida.');
    checkPending(who.id);
    if(b.action.startsWith('starter-'))await rpc('player_starter_tutorial',{p_action:b.action==='starter-choose'?'choose':'finish',p_model:b.modelId??null},who.access);
    const journey=await rpc('player_journey',{p_action:b.action.startsWith('starter-')?'read':b.action,p_model:b.modelId??null,p_lesson:b.lesson??null},who.access);
    return json({journey,...(['choose','starter-finish'].includes(b.action)?{account:await accountFor(who)}:{})},200,who.setCookies);
   }
   if(action==='daily')return json({daily:await rpc('player_daily',{},who.access)},200,who.setCookies);
   if(action==='lines'){
    if(!['read','buy','equip'].includes(b.action)||b.action!=='read'&&!/^(classic|azul|coral|menta|pontilhada|dourada)$/.test(String(b.styleId)))throw new AccountError('Visual de linha inválido.');
    if(b.action==='buy'&&!UUID.test(String(b.operationId)))throw new AccountError('Compra inválida.');
    if(b.action!=='read')rateLimit(request,'lines-'+who.id,120);
    return json({lines:await rpc('player_lines',{p_action:b.action,p_style:b.styleId||null,p_operation:b.operationId||null},who.access)},200,who.setCookies);
   }
   if(action==='trail-result'){
    if(!UUID.test(String(b.matchId)))throw new AccountError('Partida inválida.');
    const trails=await rpc('get_player_trail_result',{p_match:b.matchId},who.access),pending=matchProgress(b.matchId);
    return json({trails,status:trails.result?(pending.pending?'saving':'saved'):trails.ended?'abandoned':pending.pending?'saving':'playing'},200,who.setCookies);
   }
   if(action==='trails'){
    if(!['read','import','result'].includes(b.action)||b.action!=='read'&&!UUID.test(String(b.operationId)))throw new AccountError('Operação de trilha inválida.');
    const payload=b.payload??{};
    if(!payload||typeof payload!=='object'||Array.isArray(payload))throw new AccountError('Progresso inválido.');
    if(b.action==='result'&&(!/^(morro|praia|torres)-[1-5]$/.test(String(payload.stage))||typeof payload.won!=='boolean'||!Number.isInteger(payload.roundsLost)||payload.roundsLost<0||payload.roundsLost>5))throw new AccountError('Resultado de trilha inválido.');
    if(b.action!=='read')rateLimit(request,'trails-'+who.id,120);
    return json({trails:await rpc('player_trails',{p_action:b.action,p_operation:b.operationId||null,p_payload:payload},who.access)},200,who.setCookies);
   }
   if(action==='kite-care'){
    if(!['read','repair'].includes(b.action))throw new AccountError('Cuidado inválido.');checkPending(who.id);rateLimit(request,'kite-care-'+who.id,30);
    await rpc('player_kite_care',{p_action:b.action},who.access);return json({account:await accountFor(who)},200,who.setCookies);
   }
   if(action==='sighting'){
    if(typeof b.modelId!=='string'||!/^[a-z0-9-]{1,80}$/.test(b.modelId))throw new AccountError('Pipamon inválido.');
    await rpc('record_player_sighting',{p_model:b.modelId},who.access);return json({ok:true},200,who.setCookies);
   }
   if(action==='workshop-v3'){
    checkPending(who.id);if(!['read','save','start','cancel'].includes(b.action))throw new AccountError('Oficina: ação inválida.');
    // Autosaves happen every three seconds. They must not consume the start/read budget.
    rateLimit(request,'workshop-v3-'+b.action+'-'+who.id,({read:120,save:600,start:20,cancel:12})[b.action]);
    try{return json({workshop:await workshopV3(who.id,b,args=>rpc('server_workshop_v3',args,null,true))},200,who.setCookies);}
    catch(error){if(error instanceof AccountError)throw error;throw new AccountError(String(error.message||'Oficina: montagem inválida.'),400);}
   }
   if(action==='workshop'){
    if(!['inventory','start','advance','restore'].includes(b.action))throw new AccountError('Ação de oficina inválida.');
    for(const k of ['tailId','jobId','requestId'])if(b[k]!=null&&!UUID.test(String(b[k])))throw new AccountError('Montagem inválida.');
    if(b.targetModelId!=null&&(typeof b.targetModelId!=='string'||!/^[a-z0-9-]{1,80}$/.test(b.targetModelId)))throw new AccountError('Molde inválido.');
    if(b.action==='advance'&&(!validWorkshopPayload(b.stage,b.payload)||!b.requestId||!b.jobId))throw new AccountError('Oficina: complete os encaixes ou confira os ajustes desta etapa.');
    if(b.action==='start')rateLimit(request,'workshop-start');
    checkPending(who.id);
    return json({workshop:await rpc('player_workshop',{p_action:b.action,p_tail:b.tailId||null,p_job:b.jobId||null,p_target:b.targetModelId||null,p_stage:b.stage??null,p_payload:b.payload||null,p_request:b.requestId||null},who.access)},200,who.setCookies);
   }
   if(action==='summon'){
    return json({error:'O ritual de constelação foi substituído pela Oficina das Almas. Recarregue o jogo para construir seu parceiro.'},410,who.setCookies);
   }
   if(action==='guest-save'){
    if(!who.anonymous)throw new AccountError('Esta conta já tem e-mail.',409);rateLimit(request,'guest-save',5);
    const email=String(b.email||'').trim();if(email.length>254||!/^\S+@\S+\.\S+$/.test(email))throw new AccountError('Informe um e-mail válido.');
    await remote('/auth/v1/user',{method:'PUT',op:'guest-save',token:who.access,body:{email}});
    return json({ok:true,message:'Enviamos um link para '+email+'. Confirme o e-mail e depois use "Esqueci minha senha" para criar sua senha. Seu progresso continua nesta conta.'},200,who.setCookies);
   }
   if(action==='trade'){
    if(who.anonymous)throw new AccountError('Trocas exigem uma conta com e-mail. Salve seu progresso em Minha conta para trocar.',403);
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
  return rpc('reserve_player_match',{p_user:who.id,p_match:s.id,p_code:s.code,p_mode:s.conditionPersistent?'adventure':s.rules},null,true);
 }
 const release=(user,match)=>enabled&&UUID.test(user||'')?rpc('release_player_match',{p_user:user,p_match:match},null,true):Promise.resolve();
 const settle=e=>rpc('settle_player_cut',{p_event:e.id,p_match:e.matchId,p_winner:e.winnerAccountId,p_loser:e.loserAccountId,p_kite:e.kiteId||null},null,true);
 const finish=match=>rpc('finish_player_match',{p_match:match},null,true);
  const settleDaily=e=>rpc('settle_daily_challenge',{p_user:e.userId,p_match:e.matchId,p_day:e.day},null,true);
  const registerTrail=(user,match,stage)=>rpc('register_trail_run',{p_user:user,p_match:match,p_stage:stage},null,true);
  const settleTrail=e=>rpc('settle_trail_run',{p_user:e.userId,p_match:e.matchId,p_stage:e.stage,p_won:e.won,p_rounds_lost:e.roundsLost},null,true);
  const registerWild=(user,match,zone)=>rpc('register_wild_run',{p_user:user,p_match:match,p_zone:zone},null,true),settleWild=e=>rpc('settle_wild_run',{p_user:e.userId,p_match:e.matchId,p_outcome:e.outcome},null,true);
  const settleCare=e=>rpc('server_kite_wear',{p_user:e.userId,p_kite:e.kiteId,p_match:e.matchId,p_line:e.line,p_hull:e.hull},null,true);
  return {enabled,handle,registerWild,settleWild,preparePlayer,release,settle,finish,settleDaily,registerTrail,settleTrail,settleCare};
}
