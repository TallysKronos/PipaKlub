export function createEngine() {
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  const types=[
    {name:'Precisa',skill:'Puxão preciso',description:'Por 2 s, seu próximo acerto causa +8 de desgaste.',duration:2},
    {name:'Ágil',skill:'Dash lateral',description:'Avance 96 px à esquerda ou à direita para reposicionar a linha.',duration:.22},
    {name:'Guardiã',skill:'Linha firme',description:'Receba 60% menos desgaste durante 1,5 s.',duration:1.5},
    {name:'Técnica',skill:'Foco',description:'Por 2,5 s, alcance uma faixa maior da linha inimiga.',duration:2.5}
  ];
  const SHIELD=2.5,COUNTDOWN=3000,INTERMISSION=3200,ROUND=60000,MATCH=180000,ROUNDS_TO_WIN=3,ANCHORS=[90,910,325,675,207,793,442,558];
  const type=p=>types[clamp(Math.trunc(Number(p.color)||0),0,3)];
  function sanitizeInput(i={}) {return {x:Number.isFinite(i?.x)?clamp(i.x,-1,1):0,y:Number.isFinite(i?.y)?clamp(i.y,-1,1):0,cut:!!i?.cut,skill:i?.skill===-1?-1:i?.skill===1?1:0,dodge:!!i?.dodge};}
  // Dodge: a short burst during which strikes slide off. Dodging the instant a rival pulls is a
  // perfect dodge: the energy comes back and the next hit within COUNTER seconds is critical.
  const DODGE={cost:18,cooldown:2.2,time:.28,speed:3.2},COUNTER=2;
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
  function admit(s,p,now){seat(s,p);p.shield=SHIELD;if(s.mode==='rounds'&&(s.phase==='live'||s.phase==='intermission'))p.respawn=now;s.players.push(p);return p;}
  function visible(s){const {_pendingCuts,...publicState}=s;return {...publicState,players:s.players.map(({key,accountId,kiteId,basicKiteId,strike,...p})=>p),events:s.events.map(({id,text,at,capture,winnerId,loserId,kind,round})=>({id,text,at,capture,winnerId,loserId,kind,round}))};}
  // Fixed anchors and straight segments are also used by the renderer. Fractions run ground -> kite.
  // The seat also fixes the player number (P1..P8) shown with the player's colour.
  function seat(s,p){if(!Number.isFinite(p.anchorX))p.anchorX=ANCHORS.find(x=>!s.players.some(q=>q!==p&&q.anchorX===x))??500;if(!Number.isInteger(p.slot)){const i=ANCHORS.indexOf(p.anchorX);p.slot=i>=0?i:s.players.indexOf(p)%8;}return p;}
  function reset(p){Object.assign(p,{hp:100,energy:100,respawn:0,skillTime:0,skillCooldown:0,attackCooldown:0,shield:0,hitFlash:0,flash:0,botFocus:-.4,attack:false,x:clamp(500+(p.anchorX-500)*.8,55,945),y:290});}
  function startRound(s,now){s.phase='countdown';s.phaseUntil=now+COUNTDOWN;if(s.mode==='rounds')s.round=(s.round||0)+1;for(const p of s.players)reset(p);}
  function finishRound(s,now){
    const alive=s.players.filter(p=>!p.respawn).sort((a,b)=>b.hp-a.hp);
    // Last kite standing wins; on timeout the healthiest line wins, a tie is a draw.
    const winner=alive.length===1||(alive.length>1&&alive[0].hp>alive[1].hp)?alive[0]:null;
    if(winner)winner.rounds=(winner.rounds||0)+1;
    s.events.unshift({kind:'round',round:s.round,text:winner?winner.name+' venceu a rodada '+s.round:'Rodada '+s.round+' empatada',at:now,id:s.id+':r'+s.round,winnerId:winner?.id});s.events=s.events.slice(0,4);
    s.phase='intermission';s.phaseUntil=now+INTERMISSION;
    if(winner&&winner.rounds>=s.roundsToWin)s.end=now+INTERMISSION;
  }
  function advance(s,now){
    if(s.phase==='waiting'){if(s.quick){if(s.players.length>=s.quick.size||now>=s.quick.fillAt){fillBots(s,now);startRound(s,now);}}else if(s.players.length>=2)startRound(s,now);}
    else if(s.phase==='countdown'){if(now>=s.phaseUntil){s.phase='live';if(s.mode==='time'){s.end=now+MATCH;s.phaseUntil=s.end;}else{s.phaseUntil=now+ROUND;if(s.round===1)s.end=now+12*60000;}}}
    else if(s.phase==='intermission'){if(now>=s.phaseUntil)startRound(s,now);}
    else if(s.phase==='live'&&s.mode==='rounds'){if(s.players.length<2){s.phase='waiting';for(const p of s.players)reset(p);}else if(now>=s.phaseUntil)finishRound(s,now);}
  }
  function line(p){return {a:{x:Number.isFinite(p.anchorX)?p.anchorX:110+(p.color*219)%800,y:585},b:{x:p.x,y:p.y}};}
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
  function move(p,input,dt,wind=0){
    p.strike=false;if(p.respawn)return;
    dt=clamp(Number(dt)||0,0,.25);const i=sanitizeInput(input);
    // Persist visual direction through idle/vertical movement and network snapshots.
    if(Math.abs(i.x)>.05)p.facing=i.x<0?-1:1;
    else if(p.facing!==-1&&p.facing!==1)p.facing=1;
    p.attackCooldown=Math.max(0,(p.attackCooldown||0)-dt);
    p.skillCooldown=Math.max(0,(p.skillCooldown||0)-dt);
    p.skillTime=Math.max(0,(p.skillTime||0)-dt);
    p.flash=Math.max(0,(p.flash||0)-dt);p.hitFlash=Math.max(0,(p.hitFlash||0)-dt);p.shield=Math.max(0,(p.shield||0)-dt);
    p.evade=Math.max(0,(p.evade||0)-dt);p.dodgeCooldown=Math.max(0,(p.dodgeCooldown||0)-dt);p.counter=Math.max(0,(p.counter||0)-dt);
    if(i.dodge&&p.dodgeCooldown<=0&&p.energy>=DODGE.cost){const d=Math.hypot(i.x,i.y);p.energy-=DODGE.cost;p.dodgeCooldown=DODGE.cooldown;p.evade=DODGE.time;p.dodgeDir=d>.1?{x:i.x/d,y:i.y/d}:{x:0,y:-1};p.dodges=(p.dodges||0)+1;}
    if(i.skill&&p.skillCooldown<=0&&p.energy>=25){
      p.energy-=25;p.skillCooldown=7;p.skillTime=type(p).duration;p.skillCount=(p.skillCount||0)+1;
      if(p.color===1){p.x=clamp(p.x+i.skill*96,55,945);p.dashDirection=i.skill;p.facing=i.skill;}
    }
    const m=Math.max(1,Math.hypot(i.x,i.y)),ox=p.x,oy=p.y;
    if(p.evade>0&&p.dodgeDir){p.x=clamp(p.x+(p.dodgeDir.x*165*DODGE.speed+wind)*dt,55,945);p.y=clamp(p.y+p.dodgeDir.y*165*DODGE.speed*dt,70,480);}
    else{p.x=clamp(p.x+(i.x/m*165+wind)*dt,55,945);p.y=clamp(p.y+i.y/m*165*dt,70,480);}
    if(dt>0){p.vx=(p.x-ox)/dt;p.vy=(p.y-oy)/dt;}
    p.attack=i.cut&&p.energy>=12&&!(p.evade>0);
    if(p.attack&&p.attackCooldown<=0){p.energy-=12;p.attackCooldown=.65;p.strike=true;p.flash=.16;p.shield=0;p.strikes=(p.strikes||0)+1;}
    p.energy=clamp(p.energy+(i.cut?6:18)*dt,0,100);p.input=i;
  }
  // Bot brain. p.ai.level (1-10) scales reaction, rest between pulls, speed, aim, dodging,
  // energy discipline and skill timing. Bots without a level keep the practice defaults.
  function brain(level){
    if(!level)return {focus:.7,rest:.9,speed:.8,jitter:0,dodge:0,reserve:0,smart:false,weakest:false,evade:0,sweep:false,tip:.7};
    const k=Math.pow((clamp(level,1,10)-1)/9,.75);
    return {focus:.95-.8*k,rest:1.15-.95*k,speed:.6+.4*k,jitter:.16*(1-k),dodge:clamp((level-2)/8,0,1),reserve:level>=5?24:0,smart:level>=3,weakest:level>=6,evade:level>=4?.04+.025*(level-4):0,sweep:level>=7,tip:level>=8?.88:.7};
  }
  function botInput(s,p,dt){
    const b=brain(p.ai?.level),foes=s.players.filter(q=>q.id!==p.id&&!q.respawn&&!(q.shield>0));
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
  function step(s,now) {
    s._pendingCuts=[];const dt=clamp((now-s.last)/1000,0,.25);s.last=now;s.wind=Math.sin(now/9000)*12;
    if(now>=s.end)return s;s.players=s.players.filter(p=>p.bot||now-p.seen<15000);
    // A quick room with nobody real left in it closes instead of letting bots fly alone.
    if(s.quick&&s.quick.fillAt<=now&&!s.players.some(p=>!p.bot)){s.end=now;return s;}
    for(const p of s.players)seat(s,p);
    if(s.phase)advance(s,now);
    const live=!s.phase||s.phase==='live',rounds=s.mode==='rounds';
    for(const p of s.players){
      if(s.phase==='intermission'){p.strike=false;continue;}
      if(p.respawn){if(rounds||now<p.respawn)continue;p.respawn=0;p.hp=100;p.energy=100;p.skillTime=0;p.attackCooldown=.65;p.skillCooldown=Math.max(2,p.skillCooldown||0);p.x=160+Math.random()*680;p.y=160+Math.random()*220;p.shield=SHIELD;p.botFocus=0;}
      if(p.bot)p.input=botInput(s,p,dt);
      if(live)move(p,p.input,dt,s.wind);else{const held=p.input;move(p,{...held,cut:false,skill:0},dt,s.wind);p.input=held;}
    }
    // Resolve simultaneous strikes together, independent of who created the room.
    const hits=[];
    for(const p of s.players){if(!p.strike||p.respawn)continue;
      const targets=s.players.map(q=>({q,c:contact(p,q)})).filter(t=>t.c?.valid).sort((a,b)=>Math.abs(a.c.enemy-.6)-Math.abs(b.c.enemy-.6)||a.q.id.localeCompare(b.q.id));
      const t=targets[0];p.aim=t?'hit':'miss';if(!t)continue;
      if(t.q.evade>0){p.aim='dodged';t.q.perfectDodges=(t.q.perfectDodges||0)+1;t.q.energy=clamp(t.q.energy+DODGE.cost,0,100);t.q.counter=COUNTER;continue;}
      const cut=cutDamage(p,t.c);let damage=cut.damage;if(cut.crit){p.crits=(p.crits||0)+1;p.counter=0;}
      if(p.color===0&&p.skillTime>0){damage+=8;p.skillTime=0;}
      if(t.q.color===2&&t.q.skillTime>0)damage*=.4;
      hits.push({p,q:t.q,damage,c:t.c,cut});p.hits=(p.hits||0)+1;
    }
    for(const h of hits){h.q.hp=Math.max(0,h.q.hp-h.damage);h.q.hitFlash=.25;h.q.lastHit={x:h.c.x,y:h.c.y,damage:Math.round(h.damage),crit:h.cut.crit,clean:h.cut.clean,moving:h.cut.moving};}
    for(const q of s.players){if(q.hp>0||q.respawn)continue;
      const winner=hits.filter(h=>h.q===q).sort((a,b)=>b.damage-a.damage||a.p.id.localeCompare(b.p.id))[0];if(!winner)continue;
      const p=winner.p;q.respawn=rounds?now:now+3000;q.attack=false;p.score+=100;p.cuts++;
      const cut={text:p.name+' cortou '+q.name,at:now,id:s.id+':'+(++s.cutSequence),winnerId:p.id,loserId:q.id,matchId:s.id,winnerAccountId:p.accountId,loserAccountId:q.accountId,kiteId:q.kiteId,capture:s.rules==='capture'&&!q.kitePermanent};
      s.events.unshift(cut);s._pendingCuts.push(cut);s.events=s.events.slice(0,4);
      if(s.rules==='capture'&&q.accountId&&q.basicKiteId){q.kiteId=q.basicKiteId;q.kitePermanent=true;q.color=0;q.soul=null;q.skillTime=0;}
    }
    if(rounds&&s.phase==='live'&&s.players.filter(p=>!p.respawn).length<=1)finishRound(s,now);
    return s;
  }
  function practiceStep(s,id,input,now){const p=s.players.find(p=>p.id===id);if(p){p.input=sanitizeInput(input);p.seen=now;}return step(s,now);}
  return {QUICK,fillBots,SHIELD,DODGE,COUNTER,cutDamage,brain,create,admit,player,step,move,visible,practiceStep,line,contact,types,type,sanitizeInput,seat};
}
