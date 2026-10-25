export function createEngine() {
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  const tamers=(()=>{const maxLevel=100,xpForLevel=value=>{const n=clamp(Math.trunc(Number(value)||1),1,100)-1;return 20*n+3*n*n;};function progress(value){const maxXp=xpForLevel(100),xp=clamp(Math.trunc(Number(value)||0),0,maxXp);let level=1;while(level<100&&xp>=xpForLevel(level+1))level++;const start=xpForLevel(level),next=level===100?null:xpForLevel(level+1);return {xp,level,maxLevel,maxXp,start,next,percent:next===null?100:(xp-start)/(next-start)*100};}return {maxLevel,xpForLevel,progress};})();
  const classes={velocista:{name:'Velocista',advanced:'Rastro dos Ventos',final:'Arauto da Tempestade',description:'Mais velocidade e esquiva, com uma linha mais delicada.'},rabbitknight:{name:'Rabbitknight',advanced:'Rabbitknight',description:'Luvas de boxe e máscara bucal de guerreiro. Classe especial sem evoluções.'},condutor:{name:'Condutor',advanced:'Mestre dos Fios',final:'Tecelão da Aurora',description:'Mais precisão e recuperação de energia, com voo mais lento.'}};
  // Individual Pipamon progression. AI difficulty and the player's account level are separate.
  const pipamons=(()=>{
    const maxLevel=50,xpForLevel=l=>{const n=clamp(Math.trunc(Number(l)||1),1,maxLevel)-1;return 40*n+10*n*n;},maxXp=xpForLevel(maxLevel);
    const tiers=[{id:'aura',name:'Aura',min:50,color:'#edb7ff'},{id:'diamond',name:'Diamante',min:45,color:'#8be5ff'},{id:'platinum',name:'Platina',min:40,color:'#b8f4de'},{id:'gold',name:'Ouro',min:30,color:'#ffd46a'},{id:'silver',name:'Prata',min:20,color:'#dce5f5'}];
    const level=value=>clamp(Math.trunc(Number.isFinite(Number(value))?Number(value):1),1,maxLevel);
    const statCache=new Map();
    function stats(value,specialization=null,rank=0,craftBonus=0){const l=level(value),r=classes[specialization]?clamp(Math.trunc(rank)||0,0,3):0,bonus=clamp(Number(craftBonus)||0,0,12),key=l+':'+specialization+':'+r+':'+bonus;if(statCache.has(key))return statCache.get(key);const f=(l-1)/49,s={line:Math.round(100+20*f),energy:Math.round(100+15*f),attack:1+.12*f,defense:1+.10*f,speed:165*(1+.08*f),regen:18*(1+.10*f)};if(r&&specialization==='velocista'){s.speed*=1+.08*r;s.line=Math.round(s.line*.95);s.regen*=1+.04*r;}if(r&&specialization==='condutor'){s.attack*=1+.04*r;s.regen*=1+.08*r;s.speed*=.95;}if(r&&specialization==='rabbitknight'){s.attack*=1.15;s.defense*=1.08;s.speed*=.92;s.regen*=.95;}if(bonus)for(const stat of Object.keys(s))s[stat]=Math.round(s[stat]*(1+bonus/100)*1e6)/1e6;Object.freeze(s);statCache.set(key,s);return s;}
    function progress(value){const xp=clamp(Math.trunc(Number.isFinite(Number(value))?Number(value):0),0,maxXp);let l=1;while(l<maxLevel&&xp>=xpForLevel(l+1))l++;const start=xpForLevel(l),next=l===maxLevel?null:xpForLevel(l+1);return {xp,level:l,maxLevel,maxXp,start,next,into:xp-start,needed:next===null?0:next-start,percent:next===null?100:(xp-start)/(next-start)*100,tier:tiers.find(t=>l>=t.min)||null,stats:stats(l)};}
    return {maxLevel,maxXp,xpForLevel,level,stats,progress,tiers,tier:value=>tiers.find(t=>level(value)>=t.min)||null};
  })();
  // Only server-created bots receive this role. Inputs cannot set stats or roles.
  const bossStats=Object.freeze({line:250,energy:125,attack:1.18,defense:1.05,speed:157,regen:19});
  const pipamonStats=p=>p.bot&&p.bossId==='lacertubo'?bossStats:pipamons.stats(p.pipamonLevel,p.pipamonClass,p.classRank,p.craftBonus);
  function daily(now=Date.now()){
    const day=Math.floor(now/86400000),weather=['wind','wax','rain','fog'][((day%4)+4)%4];
    const details={wind:['Ventania','Rajadas três vezes mais fortes. Antecipe a direção da pipa.'],wax:['Linha encerada','Os acertos desgastam 25% mais a linha dos dois jogadores.'],rain:['Garoa','A energia dos dois jogadores recupera 30% mais devagar.'],fog:['Neblina','O cenário fica encoberto; pipas e miras continuam visíveis.']}[weather];
    return {date:new Date(now).toISOString().slice(0,10),weather,name:details[0],description:details[1],reward:25};
  }
  const types=[
    {name:'Precisa',skill:'Puxão preciso',description:'Por 2 s, seu próximo acerto causa +8 de desgaste.',duration:2},
    {name:'Ágil',skill:'Dash lateral',description:'Avance 96 px à esquerda ou à direita para reposicionar a linha.',duration:.22},
    {name:'Guardiã',skill:'Linha firme',description:'Receba 60% menos desgaste durante 1,5 s.',duration:1.5},
    {name:'Técnica',skill:'Foco',description:'Por 2,5 s, alcance uma faixa maior da linha inimiga.',duration:2.5}
  ];
  const SHIELD=2.5,COUNTDOWN=3000,INTERMISSION=3200,ROUND=60000,MATCH=180000,ROUNDS_TO_WIN=3,ANCHORS=[90,910,325,675,207,793,442,558];
  const type=p=>types[clamp(Math.trunc(Number(p.color)||0),0,3)];
  const lineSkills=[
    {id:'puxao',name:'Puxão',cost:28,cooldown:4,duration:1.05,description:'Mergulho e subida: crítico na retomada, com contato válido.'},
    {id:'chicote',name:'Chicote lateral',cost:26,cooldown:4.5,duration:.8,description:'Varredura lateral. Erro deixa recuperação mais longa.'},
    {id:'estilingue',name:'Estilingue',cost:32,cooldown:5,duration:1,description:'Recue e dispare para buscar o cruzamento.'},
    {id:'laco',name:'Laço',cost:30,cooldown:5,duration:1.2,description:'Mude o ângulo numa volta. Acerto recebido interrompe.'},
    {id:'folha',name:'Folha solta',cost:20,cooldown:3.5,duration:1.1,description:'Ceda linha e reposicione. Sem dano ou invulnerabilidade.'},
    {id:'duplo',name:'Duplo toque',cost:30,cooldown:4.5,duration:1.1,description:'Dois pulsos: o segundo desfaz uma Linha firme ativa.'}
  ];
  function sanitizeInput(i={}) {const out={x:Number.isFinite(i?.x)?clamp(i.x,-1,1):0,y:Number.isFinite(i?.y)?clamp(i.y,-1,1):0,cut:!!i?.cut,skill:i?.skill===-1?-1:i?.skill===1?1:0,dodge:!!i?.dodge,guard:!!i?.guard,signature:!!i?.signature};if(Number.isSafeInteger(i?.lineNonce)&&i.lineNonce>0&&i.lineNonce<=2147483647){out.lineNonce=i.lineNonce;out.lineId=lineSkills.some(s=>s.id===i.lineId)?i.lineId:'';out.lineHeld=i.lineHeld===true;out.lineSide=i.lineSide===-1?-1:1;}return out;}
  function lineMotion(k,t){
    t=clamp(t,0,1);const d=k.side;
    if(k.id==='puxao')return {x:0,y:t<.42?110*Math.sin(t/.42*Math.PI/2):110*Math.cos((t-.42)/.58*Math.PI/2)};
    if(k.id==='chicote')return {x:d*140*Math.sin(t*Math.PI),y:30*Math.sin(t*Math.PI*2)};
    if(k.id==='estilingue'){const n=t<.3?-45*t/.3:-45+170*Math.sin((t-.3)/.7*Math.PI/2);return {x:k.forward.x*n,y:k.forward.y*n};}
    if(k.id==='laco')return {x:d*80*Math.sin(t*Math.PI*2),y:-55*(1-Math.cos(t*Math.PI*2))};
    if(k.id==='folha')return {x:d*95*Math.sin(t*Math.PI/2),y:85*Math.sin(t*Math.PI)};
    return {x:d*22*Math.sin(t*Math.PI*2),y:-50*Math.sin(t*Math.PI*4)};
  }
  function lineWindow(id,t){if(id==='puxao')return t>=.45&&t<.9?{slot:0,damage:32,crit:true}:null;if(id==='chicote')return t>.18&&t<.65?{slot:0,damage:24}:null;if(id==='estilingue')return t>.4&&t<.86?{slot:0,damage:28}:null;if(id==='laco')return t>.2&&t<.88?{slot:0,damage:20}:null;if(id==='duplo')return t>.15&&t<.4?{slot:0,damage:8}:t>.63&&t<.9?{slot:1,damage:18,breakGuard:true}:null;return null;}
  function moveLine(p,i,dt){
    if(i.lineNonce>(p.lineSeen||0)){
      p.lineSeen=i.lineNonce;const d=lineSkills.find(d=>d.id===i.lineId);
      if(d&&!p.lineMove&&!(p.lineCooldown>0)&&!(p.evade>0)&&p.energy>=d.cost){const a=line(p).a,len=Math.hypot(p.x-a.x,p.y-a.y)||1;p.energy-=d.cost;p.lineCooldown=d.cooldown;p.shield=0;p.lineCount=(p.lineCount||0)+1;p.lineMove={id:d.id,side:i.lineSide,phase:'charge',held:0,elapsed:0,origin:{x:p.x,y:p.y},forward:{x:(p.x-a.x)/len,y:(p.y-a.y)/len},hits:[]};}
    }
    const k=p.lineMove;if(!k)return;
    if(k.phase==='charge'){k.held+=dt;if(!i.lineHeld||k.held>=1.2){k.phase='move';k.origin={x:p.x,y:p.y};}else return;}
    const d=lineSkills.find(d=>d.id===k.id);k.elapsed+=dt;const t=clamp(k.elapsed/d.duration,0,1),offset=lineMotion(k,t);
    p.x=clamp(k.origin.x+offset.x,55,945);p.y=clamp(k.origin.y+offset.y,70,480);
    const window=lineWindow(k.id,t);if(window&&!k.hits.includes(window.slot))p.lineStrike={...window,id:k.id};
    if(t===1){p.lineMove=null;p.attackCooldown=Math.max(p.attackCooldown,k.id==='chicote'&&!k.hits.length?.85:.25);}
  }
  // Dodge: a short burst during which strikes slide off. Dodging the instant a rival pulls is a
  // perfect dodge: the energy comes back and the next hit within COUNTER seconds is critical.
  const DODGE={cost:18,cooldown:2.2,time:.28,speed:3.2},COUNTER=2,GUARD={time:.5,cooldown:20};
  // Cut quality: open angle (clean), moving kite (relada), golden centre; all three together is critical.
  function cutDamage(p,c){
    const clean=c.angle>=.85,shallow=c.angle<.45,moving=Math.hypot(p.vx||0,p.vy||0)>=110,crit=(c.perfect&&clean&&moving)||p.counter>0;
    const base=c.perfect?24:18,damage=crit?base*1.75:base*(1+(clean?.2:0)-(shallow?.2:0)+(moving?.15:0));
    return {damage,crit,clean,moving,shallow};
  }
  function player(name,color,id,now) {return {id,name:String(name||'Pipeiro').slice(0,18),color:clamp(Math.trunc(Number(color)||0),0,3),x:220+Math.random()*560,y:160+Math.random()*240,hp:100,energy:100,score:0,cuts:0,input:{},seen:now,respawn:0,attack:false,attackCooldown:0,skillCooldown:0,skillTime:0,skillCount:0};}
  // Without options the match is live at once (legacy/tests). Rooms and practice pass a mode and start in 'waiting'.
  // Quick match: wait a few seconds for people, then fill the empty seats with bots and start.
  const QUICK={wait:10000,size:4,level:4},BOT_NAMES=['Zeca','Bia','Nando','Lia','Juninho','Mel','Tião','Kauã','Nina','Caio'];
  function create(now=Date.now(),opts) {const s={id:crypto.randomUUID(),rules:'casual',cutSequence:0,players:[],last:now,end:now+MATCH,events:[],wind:0};if(opts){s.mode=opts.mode==='time'?'time':'rounds';s.phase='waiting';s.round=0;s.roundsToWin=clamp(Math.trunc(opts.roundsToWin)||ROUNDS_TO_WIN,1,5);s.end=now+3600000;if(opts.quick)s.quick={fillAt:now+QUICK.wait,size:QUICK.size,level:QUICK.level};}return s;}
  function fillBots(s,now){const used=new Set(s.players.map(p=>p.name));let n=0;while(s.players.length<s.quick.size){const name=BOT_NAMES.find(x=>!used.has(x))||'Pipeiro '+(++n);used.add(name);const b=player(name,Math.floor(Math.random()*4),'bot-'+crypto.randomUUID(),now);b.bot=true;b.ai={level:s.quick.level};admit(s,b,now);}}
  // A player joining mid-round in rounds mode watches until the next round starts.
  function admit(s,p,now){seat(s,p);p.pipamonLevel=pipamons.level(p.pipamonLevel);p.hp=pipamonStats(p).line;p.hullMax=pipamonStats(p).line;p.hull=p.hullMax*(p.conditionHull??100)/100;p.wearLine=p.conditionLine??100;p.energy=pipamonStats(p).energy;p.shield=SHIELD;if(s.mode==='rounds'&&(s.phase==='live'||s.phase==='intermission'))p.respawn=now;s.players.push(p);return p;}
  function visible(s){const {_pendingCuts,dailyResult,trailResult,trailOwner,wildResult,wildOwner,departedCare,impactPairs,...publicState}=s;return {...publicState,players:s.players.map(({key,accountId,kiteId,basicKiteId,strike,lineStrike,...p})=>p),events:s.events.map(({id,text,at,capture,winnerId,loserId,kind,round})=>({id,text,at,capture,winnerId,loserId,kind,round}))};}
  // Fixed anchors and straight segments are also used by the renderer. Fractions run ground -> kite.
  // The seat also fixes the player number (P1..P8) shown with the player's colour.
  function seat(s,p){if(!Number.isFinite(p.anchorX))p.anchorX=ANCHORS.find(x=>!s.players.some(q=>q!==p&&q.anchorX===x))??500;if(!Number.isInteger(p.slot)){const i=ANCHORS.indexOf(p.anchorX);p.slot=i>=0?i:s.players.indexOf(p)%8;}return p;}
  function reset(p){const first=!p.combatStarted;p.combatStarted=true;p.hullMax=pipamonStats(p).line;p.hull??=p.hullMax*(p.conditionHull??100)/100;Object.assign(p,{signatureWindup:0,signatureBurst:0,guardTime:0,hp:pipamonStats(p).line*(first?(p.conditionLine??100)/100:1),energy:pipamonStats(p).energy,respawn:0,skillTime:0,skillCooldown:0,attackCooldown:0,lineMove:null,lineStrike:null,lineCooldown:0,shield:0,hitFlash:0,flash:0,botFocus:-.4,attack:false,x:clamp(500+(p.anchorX-500)*.8,55,945),y:290});}
  function startRound(s,now){s.phase='countdown';s.phaseUntil=now+(s.boss?6600:COUNTDOWN);if(s.mode==='rounds')s.round=(s.round||0)+1;for(const p of s.players){reset(p);if(p.bossId){p.bossCharge=0;p.bossRecovery=0;p.bossPhase=1;p.bossTelegraph=0;p.facing=-1;}}}
  function finishRound(s,now){
    const alive=s.players.filter(p=>!p.respawn).sort((a,b)=>b.hp-a.hp);
    // Last kite standing wins; on timeout the healthiest line wins, a tie is a draw.
    const winner=s.boss&&alive.length>1?alive.find(p=>p.bossId):alive.length===1||(alive.length>1&&alive[0].hp>alive[1].hp)?alive[0]:null;
    if(winner)winner.rounds=(winner.rounds||0)+1;
    s.events.unshift({kind:'round',round:s.round,text:winner?winner.name+' venceu a rodada '+s.round:'Rodada '+s.round+' empatada',at:now,id:s.id+':r'+s.round,winnerId:winner?.id});s.events=s.events.slice(0,4);
    for(const p of s.players){p.lineMove=null;p.lineStrike=null;p.strike=false;}
    s.phase='intermission';s.phaseUntil=now+INTERMISSION;
    if(!winner&&!alive.length&&s.players.some(p=>p.hull<=0)){s.end=now+INTERMISSION;if(s.wild)s.wildResult={userId:s.wildOwner,matchId:s.id,outcome:'lost'};if(s.trail)s.trailResult={userId:s.trailOwner,stage:s.trail,won:false,roundsLost:s.roundsToWin};}
    if(winner&&winner.rounds>=s.roundsToWin){s.end=now+INTERMISSION;if(s.wild){const own=s.players.find(p=>p.accountId===s.wildOwner);if(own)s.wildResult={userId:s.wildOwner,matchId:s.id,outcome:winner.id===own.id?'won':'lost'};}if(s.daily)s.dailyResult={winnerId:winner.id,accountId:winner.accountId||null};if(s.trail){const owner=s.players.find(p=>p.accountId===s.trailOwner);if(owner)s.trailResult={userId:s.trailOwner,stage:s.trail,won:winner.id===owner.id,roundsLost:s.players.filter(p=>p.id!==owner.id).reduce((n,p)=>n+(p.rounds||0),0)};}}
  }
  function advance(s,now){
    if(s.phase==='waiting'){if(s.quick){if(s.players.length>=s.quick.size||now>=s.quick.fillAt){fillBots(s,now);startRound(s,now);}}else if(s.players.length>=2)startRound(s,now);}
    else if(s.phase==='countdown'){if(now>=s.phaseUntil){s.phase='live';if(s.mode==='time'){s.end=now+MATCH;s.phaseUntil=s.end;}else{s.phaseUntil=now+(s.boss?120000:ROUND);if(s.round===1)s.end=now+12*60000;}}}
    else if(s.phase==='intermission'){if(now>=s.phaseUntil)startRound(s,now);}
    else if(s.phase==='live'&&s.mode==='rounds'){if(s.players.length<2){s.phase='waiting';for(const p of s.players)reset(p);}else if(now>=s.phaseUntil)finishRound(s,now);}
  }
  function line(p){return {a:{x:Number.isFinite(p.anchorX)?p.anchorX:110+(p.color*219)%800,y:585},b:{x:p.x,y:p.y}};}
  // The same close-range gate is used by the authoritative attack and the HUD.
  const SIGNATURES={rabbito:{id:'rabbito',name:'Pulo do Elo',windup:1.4,cooldown:24,cost:40,damage:38,radius:85},nozinho:{id:'nozinho',name:'Nó de Vendaval',windup:1.65,cooldown:22,cost:35,damage:32,radius:78},lacertubo:{id:'lacertubo',name:'Ruptura dos Canos',windup:1.5,cooldown:20,cost:0,damage:44,radius:95}};
  function signature(p){return p.bossId==='lacertubo'?SIGNATURES.lacertubo:['rabbito','nozinho'].includes(p.soul)?SIGNATURES[p.soul]:null;}
  function signatureTarget(s,p){return s.players.filter(q=>q.id!==p.id&&!q.respawn&&!(q.shield>0)&&Math.hypot(q.x-p.x,q.y-p.y)<=440).sort((a,b)=>Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y)||a.id.localeCompare(b.id))[0];}
  function signatureStep(s,p,dt,live){
    p.signatureBurst=Math.max(0,(p.signatureBurst||0)-dt);const def=signature(p);if(!def||!live||p.respawn)return null;
    p.signatureCooldown=Math.max(0,(p.signatureCooldown??(p.bossId?6:0))-dt);
    if(p.signatureWindup>0){
      p.signatureWindup=Math.max(0,p.signatureWindup-dt);if(p.signatureWindup>0)return null;
      p.signatureBurst=.45;p.signatureResolved=(p.signatureResolved||0)+1;p.signatureOutcome='miss';p.attackCooldown=Math.max(.65,p.attackCooldown||0);if(p.bossId)p.bossRecovery=2.2;const target=s.players.find(q=>q.id===p.signatureTarget);
      if(!target||target.respawn||target.shield>0||Math.hypot(target.x-p.signatureAim.x,target.y-p.signatureAim.y)>def.radius){p.aim='miss';return null;}
      if(target.guardTime>0){target.guardFlash=.35;target.blocks=(target.blocks||0)+1;p.aim=p.signatureOutcome='blocked';return null;}
      if(target.evade>0){target.perfectDodges=(target.perfectDodges||0)+1;target.counter=COUNTER;p.aim=p.signatureOutcome='dodged';return null;}
      p.aim=p.signatureOutcome='hit';p.hits=(p.hits||0)+1;p.signatureHits=(p.signatureHits||0)+1;return {p,q:target,signature:true,damage:def.damage*pipamonStats(p).attack/pipamonStats(target).defense,body:true,c:{x:target.x,y:target.y},cut:{crit:false,moving:true}};
    }
    const held=!!p.input?.signature,wants=p.bossId||held&&!p.signatureHeld;p.signatureHeld=held;
    if(!wants||p.signatureCooldown>0||p.energy<def.cost||p.guardTime>0||p.evade>0||p.lineMove)return null;
    const target=signatureTarget(s,p);if(!target)return null;
    p.energy-=def.cost;p.signatureCooldown=def.cooldown;p.signatureWindup=def.windup;p.signatureCount=(p.signatureCount||0)+1;p.signatureTarget=target.id;p.signatureAim={x:target.x,y:target.y};p.strike=false;p.lineStrike=null;p.bossCharge=0;p.bossTelegraph=0;if(p.bossId)p.bossRecovery=0;return null;
  }
  function bodyContact(p,q){
    // Conservative radii inside the 96px normal / larger guardian artwork.
    const reach=(p.bossId?42:24)+(q.bossId?42:24);
    if(p.id===q.id||p.respawn||q.respawn||q.shield>0||Math.hypot(q.x-p.x,q.y-p.y)>reach)return null;
    return {x:q.x,y:q.y,angle:1,perfect:false,valid:true};
  }
  function contact(p,q){
    if(p.id===q.id||p.respawn||q.respawn)return null;
    const l=line(p),m=line(q),r={x:l.b.x-l.a.x,y:l.b.y-l.a.y},v={x:m.b.x-m.a.x,y:m.b.y-m.a.y};
    const cross=(a,b)=>a.x*b.y-a.y*b.x,den=cross(r,v),angle=Math.abs(den)/Math.max(1,Math.hypot(r.x,r.y)*Math.hypot(v.x,v.y));
    if(angle<.20)return null;
    const d={x:m.a.x-l.a.x,y:m.a.y-l.a.y},u=cross(d,v)/den,w=cross(d,r)/den;
    if(u<=.05||u>=.98||w<=.05||w>=.98)return null;
    const focus=p.color===3&&p.skillTime>0;
    const shielded=q.shield>0;
    return {x:l.a.x+r.x*u,y:l.a.y+r.y*u,own:u,enemy:w,angle,shielded,valid:!shielded&&u>=.35&&u<=.95&&w>=(focus?.15:.3)&&w<=(focus?.92:.85),perfect:w>=.52&&w<=.68};
  }
  function move(p,input,dt,wind=0,weather){
    p.strike=false;p.lineStrike=null;if(p.respawn)return;
    dt=clamp(Number(dt)||0,0,.25);const i=sanitizeInput(input);if(p.signatureWindup>0){i.cut=false;i.skill=0;i.dodge=false;i.guard=false;i.lineNonce=0;i.x*=.2;i.y*=.2;}
    // Persist visual direction through idle/vertical movement and network snapshots.
    if(Math.abs(i.x)>.05)p.facing=i.x<0?-1:1;
    else if(p.facing!==-1&&p.facing!==1)p.facing=1;
    p.attackCooldown=Math.max(0,(p.attackCooldown||0)-dt);
    p.skillCooldown=Math.max(0,(p.skillCooldown||0)-dt);
    p.skillTime=Math.max(0,(p.skillTime||0)-dt);p.guardTime=Math.max(0,(p.guardTime||0)-dt);p.guardCooldown=Math.max(0,(p.guardCooldown||0)-dt);p.guardFlash=Math.max(0,(p.guardFlash||0)-dt);if(i.guard&&!p.guardHeld&&!p.lineMove&&!(p.evade>0)&&p.guardCooldown<=0){p.guardTime=GUARD.time;p.guardCooldown=GUARD.cooldown;}p.guardHeld=i.guard;
    p.lineCooldown=Math.max(0,(p.lineCooldown||0)-dt);
    p.flash=Math.max(0,(p.flash||0)-dt);p.hitFlash=Math.max(0,(p.hitFlash||0)-dt);p.shield=Math.max(0,(p.shield||0)-dt);
    p.evade=Math.max(0,(p.evade||0)-dt);p.dodgeCooldown=Math.max(0,(p.dodgeCooldown||0)-dt);p.counter=Math.max(0,(p.counter||0)-dt);
    if(i.dodge&&!(p.guardTime>0)&&!p.lineMove&&p.dodgeCooldown<=0&&p.energy>=DODGE.cost){const d=Math.hypot(i.x,i.y);p.energy-=DODGE.cost;p.dodgeCooldown=DODGE.cooldown;p.evade=DODGE.time;p.dodgeDir=d>.1?{x:i.x/d,y:i.y/d}:{x:0,y:-1};p.dodges=(p.dodges||0)+1;}
    if(i.skill&&!(p.guardTime>0)&&!p.lineMove&&p.skillCooldown<=0&&p.energy>=25){
      p.energy-=25;p.skillCooldown=7;p.skillTime=type(p).duration;p.skillCount=(p.skillCount||0)+1;
      if(p.color===1){p.x=clamp(p.x+i.skill*96,55,945);p.dashDirection=i.skill;p.facing=i.skill;}
    }
    const m=Math.max(1,Math.hypot(i.x,i.y)),ox=p.x,oy=p.y;if(p.guardTime>0){i.x*=.4;i.y*=.4;i.cut=false;i.lineNonce=0;}
    if(p.evade>0&&p.dodgeDir){p.x=clamp(p.x+(p.dodgeDir.x*165*DODGE.speed+wind)*dt,55,945);p.y=clamp(p.y+p.dodgeDir.y*165*DODGE.speed*dt,70,480);}
    else if(!p.lineMove||p.lineMove.phase==='charge'){p.x=clamp(p.x+(i.x/m*pipamonStats(p).speed+wind)*dt,55,945);p.y=clamp(p.y+i.y/m*pipamonStats(p).speed*dt,70,480);}
    moveLine(p,i,dt);
    if(dt>0){p.vx=(p.x-ox)/dt;p.vy=(p.y-oy)/dt;}
    p.attack=i.cut&&p.energy>=12&&!(p.evade>0)&&!p.lineMove;
    if(p.attack&&p.attackCooldown<=0){p.energy-=12;p.attackCooldown=.65;p.strike=true;p.flash=.16;p.shield=0;p.strikes=(p.strikes||0)+1;}
    p.energy=clamp(p.energy+(i.cut?6:pipamonStats(p).regen)*dt*(weather==='rain'?.7:1),0,pipamonStats(p).energy);p.input=i;
  }
  // Bot brain. p.ai.level (1-10) scales reaction, rest between pulls, speed, aim, dodging,
  // energy discipline and skill timing. Bots without a level keep the practice defaults.
  function brain(level,style){
    if(!level)return {focus:.7,rest:.9,speed:.8,jitter:0,dodge:0,reserve:0,smart:false,weakest:false,evade:0,sweep:false,tip:.7};
    const k=Math.pow((clamp(level,1,10)-1)/9,.75);
    const b={focus:.95-.8*k,rest:1.15-.95*k,speed:.6+.4*k,jitter:.16*(1-k),dodge:clamp((level-2)/8,0,1),reserve:level>=5?24:0,smart:level>=3,weakest:level>=6,evade:level>=4?.04+.025*(level-4):0,sweep:level>=7,tip:level>=8?.88:.7};
    // Rivals trade strengths without changing damage, costs or cooldowns.
    if(style==='patient'){b.focus*=1.15;b.rest*=1.1;b.speed*=.95;}
    else if(style==='mobile'){b.speed=Math.min(1,b.speed+.1);b.jitter=Math.min(.22,b.jitter+.04);b.focus*=1.15;}
    else if(style==='guard'){b.reserve=Math.max(b.reserve,10);b.dodge=Math.max(b.dodge,.25);b.focus*=1.1;}
    else if(style==='reader'){b.reserve=Math.max(b.reserve,18);b.dodge=Math.min(.9,b.dodge+.1);b.focus*=1.1;}
    return b;
  }
  function botInput(s,p,dt){
    const b=brain(p.ai?.level,p.ai?.style),foes=s.players.filter(q=>q.id!==p.id&&!q.respawn&&!(q.shield>0));
    // Leveled bots spread out: a kite another bot is already hunting is a worse target, so free-for-all
    // stages stay every-pilot-for-himself instead of turning into bots ganging up on the player.
    const hunters=q=>p.ai?s.players.filter(o=>o.bot&&o!==p&&!o.respawn&&o.aiTarget===q.id).length:0;
    const target=foes.sort((a,c)=>hunters(a)-hunters(c)||Number(!!contact(p,c)?.valid)-Number(!!contact(p,a)?.valid)||(b.weakest?a.hp-c.hp:0)||Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(c.x-p.x,c.y-p.y)||a.id.localeCompare(c.id))[0];
    p.aiTarget=target?.id;
    // Seek a crossing on the target line rather than chasing its kite; weaker bots wobble around the golden centre.
    const frac=.6+b.jitter*Math.sin(s.last/650+(p.slot||0)*1.7);
    let x=500,y=180;
    if(target){const l=line(target),a=line(p).a,c={x:l.a.x+(l.b.x-l.a.x)*frac,y:l.a.y+(l.b.y-l.a.y)*frac};x=clamp(a.x+(c.x-a.x)/b.tip,55,945);y=clamp(a.y+(c.y-a.y)/b.tip,70,480);}
    const c=target&&contact(p,target);
    // Dodge: when a rival can cut us and we cannot answer, slide the kite away from the crossing.
    const threat=b.dodge?s.players.map(q=>q.id!==p.id&&!q.respawn?contact(q,p):null).find(t=>t?.valid):null;
    if(threat&&!c?.valid){const dx=p.x-threat.x,dy=p.y-threat.y,d=Math.hypot(dx,dy)||1;x=p.x+dx/d*120*b.dodge+(x-p.x)*(1-b.dodge);y=p.y+dy/d*120*b.dodge+(y-p.y)*(1-b.dodge);}
    // Aim for a moment before pulling and rest after each pull, so a human can react.
    p.botFocus=c?.valid?(p.botFocus||0)+dt:Math.min(0,p.botFocus||0)+dt;
    const pull=!!c?.valid&&p.botFocus>=b.focus&&(p.energy>=12+b.reserve||target.hp<=24);
    if(pull&&p.attackCooldown<=0&&p.energy>=12)p.botFocus=-b.rest;
    let skill=0;
    if(!b.smart)skill=pull&&p.energy>=40?(p.x<500?1:-1):0;
    else if(p.skillCooldown<=0&&p.energy>=25+b.reserve/2){
      if(p.color===0&&pull)skill=1;
      else if(p.color===1&&Math.abs(x-p.x)>140)skill=x<p.x?-1:1;
      else if(p.color===2&&threat)skill=1;
      else if(p.color===3&&c&&!c.valid)skill=1;
    }
    // Evasion: once a rival has had us in its sights for a moment and is about to pull, burst away from the crossing.
    let dodge=false;const hunter=b.evade?s.players.find(q=>q.id!==p.id&&!q.respawn&&q.input?.cut&&q.energy>=12&&contact(q,p)?.valid):null;
    p.threatTime=hunter?(p.threatTime||0)+dt:0;
    if(hunter&&!c?.valid&&p.dodgeCooldown<=0&&p.energy>=DODGE.cost+12&&p.threatTime>=b.focus*.6&&(hunter.attackCooldown||0)<=b.evade){const t=contact(hunter,p),dx=p.x-t.x,dy=p.y-t.y,d=Math.hypot(dx,dy)||1;return {x:dx/d,y:dy/d,cut:false,skill:0,dodge:true};}
    // Sweep (relada): strong bots slide along their own line while pulling, which keeps the crossing and earns cut speed.
    if(b.sweep&&c?.valid){const a=line(p).a,dx=p.x-a.x,dy=p.y-a.y,d=Math.hypot(dx,dy)||1,dir=Math.sin(s.last/260+(p.slot||0))>0?1:-1;return {x:dx/d*.8*dir,y:dy/d*.8*dir,cut:pull,skill};}
    return {x:clamp((x-p.x)/80,-b.speed,b.speed),y:clamp((y-p.y)/80,-b.speed,b.speed),cut:pull,skill};
  }
  function bossInput(s,p,dt){
    const phase=Math.min(p.hp,p.hull??p.hp)<=bossStats.line*.55?2:1;
    if(phase!==p.bossPhase){p.bossPhase=phase;p.bossCharge=0;p.bossRecovery=1.8;p.bossTelegraph=0;p.bossRoar=1.8;}
    p.bossRoar=Math.max(0,(p.bossRoar||0)-dt);
    if(p.signatureWindup>0){p.bossTelegraph=0;return {x:0,y:0,cut:false,skill:0};}
    p.ai={level:phase===2?7:6,style:'patient'};
    const input=botInput(s,p,dt);input.cut=false;input.skill=0;input.dodge=false;
    if(p.bossRecovery>0){p.bossRecovery=Math.max(0,p.bossRecovery-dt);p.bossTelegraph=0;return {...input,x:input.x*.25,y:input.y*.25};}
    const target=s.players.find(q=>!q.bot&&!q.respawn),contactNow=target&&contact(p,target);
    const duration=phase===2?.8:1.15;
    if(p.bossCharge>0||contactNow?.valid){p.bossCharge=(p.bossCharge||0)+dt;p.bossTelegraph=Math.min(1,p.bossCharge/duration);
      // Lock the last part of the wind-up, so the announced strike can be dodged.
      if(p.bossTelegraph>.6){input.x=0;input.y=0;}
      if(p.bossCharge>=duration){input.cut=true;p.bossCharge=0;p.bossTelegraph=0;p.bossRecovery=phase===2?1.15:1.5;}
    }else p.bossTelegraph=0;
    return input;
  }
  // Only the authenticated owner of a private campaign room can freeze its simulation.
  function setSoloPause(s,p,paused,now){
    if(!(s.trail||s.wild)||!p?.accountId||p.accountId!==(s.trailOwner||s.wildOwner)||s.players.some(q=>!q.bot&&q.id!==p.id)||now>=s.end)return false;
    s.soloPaused=paused===true;p.input={};p.seen=now;return true;
  }
  function step(s,now) {
    s._pendingCuts=[];
    if(s.soloPaused&&(s.trail||s.wild)){
      const owner=s.players.find(p=>!p.bot&&p.accountId===(s.trailOwner||s.wildOwner)&&now-p.seen<60000);
      if(owner){const elapsed=Math.max(0,now-s.last);s.end+=elapsed;if(s.phaseUntil)s.phaseUntil+=elapsed;for(const p of s.players)if(p.respawn)p.respawn+=elapsed;for(const event of s.events)event.at+=elapsed;s.last=now;return s;}
      s.soloPaused=false;
    }
    const dt=clamp((now-s.last)/1000,0,.25);s.last=now;s.wind=Math.sin(now/9000)*(s.daily?.weather==='wind'?36:12);
    if(now>=s.end)return s;s.players=s.players.filter(p=>p.bot||now-p.seen<60000);
    if((s.daily||s.trail||s.wild)&&!s.players.some(p=>!p.bot)){s.end=now;return s;}
    // A quick room with nobody real left in it closes instead of letting bots fly alone.
    if(s.quick&&s.quick.fillAt<=now&&!s.players.some(p=>!p.bot)){s.end=now;return s;}
    for(const p of s.players)seat(s,p);
    if(s.phase)advance(s,now);
    const live=!s.phase||s.phase==='live',rounds=s.mode==='rounds';
    for(const p of s.players){
      if(s.phase==='intermission'){p.strike=false;p.lineStrike=null;p.lineMove=null;continue;}
      if(p.respawn){if(rounds||now<p.respawn)continue;p.respawn=0;p.hull=pipamonStats(p).line;p.hp=pipamonStats(p).line;p.energy=pipamonStats(p).energy;p.skillTime=0;p.lineMove=null;p.lineStrike=null;p.lineCooldown=Math.max(2,p.lineCooldown||0);p.attackCooldown=.65;p.skillCooldown=Math.max(2,p.skillCooldown||0);p.x=160+Math.random()*680;p.y=160+Math.random()*220;p.shield=SHIELD;p.botFocus=0;}
      if(p.bot)p.input=p.bossId?(live?bossInput(s,p,dt):{}):botInput(s,p,dt);
      if(live)move(p,p.input,dt,s.wind,s.daily?.weather);else{const held=p.input;p.lineSeen=Math.max(p.lineSeen||0,held?.lineNonce||0);move(p,{...held,cut:false,skill:0,guard:false,signature:false,lineNonce:0},dt,s.wind,s.daily?.weather);p.input=held;}
    }
    // Resolve simultaneous strikes together, independent of who created the room.
    const hits=[];
    for(const p of s.players){const hit=signatureStep(s,p,dt,live);if(hit)hits.push(hit);}
    for(const p of s.players){if((!p.strike&&!p.lineStrike)||p.respawn)continue;
      // One attack hits one target: nearby body first, otherwise the crossed line.
      // Overlap alone never deals damage, regardless of approach speed.
      const nearby=live&&p.strike?s.players.map(q=>({q,c:bodyContact(p,q)})).filter(t=>t.c).sort((a,b)=>Math.hypot(a.q.x-p.x,a.q.y-p.y)-Math.hypot(b.q.x-p.x,b.q.y-p.y)||a.q.id.localeCompare(b.q.id))[0]:null;
      const targets=s.players.map(q=>({q,c:contact(p,q)})).filter(t=>t.c?.valid).sort((a,b)=>Math.abs(a.c.enemy-.6)-Math.abs(b.c.enemy-.6)||a.q.id.localeCompare(b.q.id));
      const t=nearby||targets[0],body=!!nearby;p.aim=t?'hit':'miss';if(!t)continue;
      const maneuver=nearby?null:p.lineStrike;if(maneuver&&p.lineMove&&!p.lineMove.hits.includes(maneuver.slot))p.lineMove.hits.push(maneuver.slot);
      if(body&&t.q.guardTime>0){p.aim='blocked';t.q.guardFlash=.35;t.q.blocks=(t.q.blocks||0)+1;continue;}if(t.q.evade>0){p.aim='dodged';t.q.perfectDodges=(t.q.perfectDodges||0)+1;t.q.energy=clamp(t.q.energy+DODGE.cost,0,pipamonStats(t.q).energy);t.q.counter=COUNTER;continue;}
      const cut=maneuver?{damage:maneuver.damage,crit:!!maneuver.crit,clean:t.c.angle>=.85,moving:true,shallow:t.c.angle<.45}:cutDamage(p,t.c);let damage=cut.damage;if(cut.crit){p.crits=(p.crits||0)+1;p.counter=0;}
      if(!maneuver&&p.color===0&&p.skillTime>0){damage+=8;p.skillTime=0;}
      const breakGuard=!!maneuver?.breakGuard&&t.q.color===2&&t.q.skillTime>0;
      if(t.q.color===2&&t.q.skillTime>0&&!breakGuard)damage*=.4;
      if(s.daily?.weather==='wax')damage*=1.25;
      damage*=pipamonStats(p).attack/pipamonStats(t.q).defense;
      if(p.bossId&&p.bossPhase===2)damage*=1.12;
      const armored=!!t.q.bossId&&!(t.q.bossRecovery>0);
      if(t.q.bossId)damage*=armored ? .18 : 1.2;
      if(maneuver)p.flash=.16;hits.push({p,q:t.q,damage,c:t.c,cut,breakGuard,body,armored});p.hits=(p.hits||0)+1;
    }
    for(const h of hits){if(h.body)h.q.hull=Math.max(0,(h.q.hull??pipamonStats(h.q).line)-h.damage);else h.q.hp=Math.max(0,h.q.hp-h.damage);h.q.hitFlash=.25;if(h.breakGuard)h.q.skillTime=0;if(h.q.lineMove?.id==='laco'){h.q.lineMove=null;h.q.lineStrike=null;}h.q.lastHit={x:h.c.x,y:h.c.y,damage:Math.round(h.damage),body:!!h.body,signature:!!h.signature,armored:!!h.armored,crit:h.cut.crit,clean:h.cut.clean,moving:h.cut.moving,breakGuard:h.breakGuard};}
    for(const q of s.players){if((q.hp>0&&(q.hull??100)>0)||q.respawn)continue;
      const winner=hits.filter(h=>h.q===q).sort((a,b)=>b.damage-a.damage||a.p.id.localeCompare(b.p.id))[0];if(!winner)continue;
      const p=winner.p;if(q.hull<=0){q.breakReason='hull';if(rounds)p.rounds=Math.max(p.rounds||0,s.roundsToWin-1);}q.respawn=rounds?now:now+3000;q.attack=false;q.lineMove=null;q.lineStrike=null;p.score+=100;p.cuts++;
      const cut={text:p.name+(q.hull<=0?' quebrou a armação de ':' cortou ')+q.name,broken:q.hull<=0,at:now,id:s.id+':'+(++s.cutSequence),winnerId:p.id,loserId:q.id,matchId:s.id,winnerAccountId:p.accountId,loserAccountId:q.accountId,kiteId:q.kiteId,capture:s.rules==='capture'&&(q.hull??100)>0&&!q.kitePermanent};
      s.events.unshift(cut);s._pendingCuts.push(cut);s.events=s.events.slice(0,4);
      if(s.rules==='capture'&&(q.hull??100)>0&&q.accountId&&q.basicKiteId){q.kiteId=q.basicKiteId;q.kitePermanent=true;q.color=q.basicColor??0;q.soul=q.basicSoul||null;q.partnerName=q.basicPartnerName||null;q.pipamonLevel=pipamons.level(q.basicPipamonLevel);q.pipamonClass=q.basicPipamonClass||null;q.classRank=q.basicClassRank||0;q.craftBonus=q.basicCraftBonus||0;q.soulVariant=!!q.basicSoulVariant;q.skillTime=0;}
    }
    if(s.conditionPersistent)for(const p of s.players)if(!p.bot)p.wearLine=Math.min(p.wearLine??100,clamp(p.hp/pipamonStats(p).line*100,0,100));
    if(rounds&&s.phase==='live'&&s.players.filter(p=>!p.respawn).length<=1)finishRound(s,now);
    return s;
  }
  function practiceStep(s,id,input,now){const p=s.players.find(p=>p.id===id);if(p){p.input=sanitizeInput(input);p.seen=now;}return step(s,now);}
  return {setSoloPause,tamers,classes,pipamons,pipamonStats,daily,QUICK,fillBots,SHIELD,DODGE,GUARD,COUNTER,cutDamage,brain,create,admit,player,step,move,visible,practiceStep,line,contact,bodyContact,signature,signatureTarget,types,type,sanitizeInput,seat,lineSkills,lineMotion,lineWindow};
}
