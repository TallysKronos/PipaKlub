export function createEngine() {
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  const types=[
    {name:'Precisa',skill:'Puxão preciso',description:'Por 2 s, seu próximo acerto causa +8 de desgaste.',duration:2},
    {name:'Ágil',skill:'Dash lateral',description:'Avance 96 px à esquerda ou à direita para reposicionar a linha.',duration:.22},
    {name:'Guardiã',skill:'Linha firme',description:'Receba 60% menos desgaste durante 1,5 s.',duration:1.5},
    {name:'Técnica',skill:'Foco',description:'Por 2,5 s, alcance uma faixa maior da linha inimiga.',duration:2.5}
  ];
  const type=p=>types[clamp(Math.trunc(Number(p.color)||0),0,3)];
  function sanitizeInput(i={}) {return {x:Number.isFinite(i?.x)?clamp(i.x,-1,1):0,y:Number.isFinite(i?.y)?clamp(i.y,-1,1):0,cut:!!i?.cut,skill:i?.skill===-1?-1:i?.skill===1?1:0};}
  function player(name,color,id,now) {return {id,name:String(name||'Pipeiro').slice(0,18),color:clamp(Math.trunc(Number(color)||0),0,3),x:220+Math.random()*560,y:160+Math.random()*240,hp:100,energy:100,score:0,cuts:0,input:{},seen:now,respawn:0,attack:false,attackCooldown:0,skillCooldown:0,skillTime:0,skillCount:0};}
  function create(now=Date.now()) {return {id:crypto.randomUUID(),rules:'casual',cutSequence:0,players:[],last:now,end:now+180000,events:[],wind:0};}
  function visible(s){const {_pendingCuts,...publicState}=s;return {...publicState,players:s.players.map(({key,accountId,kiteId,basicKiteId,strike,...p})=>p),events:s.events.map(({id,text,at,capture,winnerId,loserId})=>({id,text,at,capture,winnerId,loserId}))};}
  // Fixed anchors and straight segments are also used by the renderer. Fractions run ground -> kite.
  function seat(s,p){if(!Number.isFinite(p.anchorX))p.anchorX=[90,910,325,675,207,793,442,558].find(x=>!s.players.some(q=>q!==p&&q.anchorX===x))??500;return p;}
  function line(p){return {a:{x:Number.isFinite(p.anchorX)?p.anchorX:110+(p.color*219)%800,y:585},b:{x:p.x,y:p.y}};}
  function contact(p,q){
    if(p.id===q.id||p.respawn||q.respawn)return null;
    const l=line(p),m=line(q),r={x:l.b.x-l.a.x,y:l.b.y-l.a.y},v={x:m.b.x-m.a.x,y:m.b.y-m.a.y};
    const cross=(a,b)=>a.x*b.y-a.y*b.x,den=cross(r,v),angle=Math.abs(den)/Math.max(1,Math.hypot(r.x,r.y)*Math.hypot(v.x,v.y));
    if(angle<.20)return null;
    const d={x:m.a.x-l.a.x,y:m.a.y-l.a.y},u=cross(d,v)/den,w=cross(d,r)/den;
    if(u<=.05||u>=.98||w<=.05||w>=.98)return null;
    const focus=p.color===3&&p.skillTime>0;
    return {x:l.a.x+r.x*u,y:l.a.y+r.y*u,own:u,enemy:w,valid:u>=.35&&u<=.95&&w>=(focus?.15:.3)&&w<=(focus?.92:.85),perfect:w>=.52&&w<=.68};
  }
  function move(p,input,dt,wind=0){
    p.strike=false;if(p.respawn)return;
    dt=clamp(Number(dt)||0,0,.25);const i=sanitizeInput(input);
    p.attackCooldown=Math.max(0,(p.attackCooldown||0)-dt);
    p.skillCooldown=Math.max(0,(p.skillCooldown||0)-dt);
    p.skillTime=Math.max(0,(p.skillTime||0)-dt);
    p.flash=Math.max(0,(p.flash||0)-dt);p.hitFlash=Math.max(0,(p.hitFlash||0)-dt);
    if(i.skill&&p.skillCooldown<=0&&p.energy>=25){
      p.energy-=25;p.skillCooldown=7;p.skillTime=type(p).duration;p.skillCount=(p.skillCount||0)+1;
      if(p.color===1){p.x=clamp(p.x+i.skill*96,55,945);p.dashDirection=i.skill;}
    }
    const m=Math.max(1,Math.hypot(i.x,i.y));
    p.x=clamp(p.x+(i.x/m*165+wind)*dt,55,945);p.y=clamp(p.y+i.y/m*165*dt,70,480);
    p.attack=i.cut&&p.energy>=12;
    if(p.attack&&p.attackCooldown<=0){p.energy-=12;p.attackCooldown=.65;p.strike=true;p.flash=.16;}
    p.energy=clamp(p.energy+(i.cut?6:18)*dt,0,100);p.input=i;
  }
  function step(s,now) {
    s._pendingCuts=[];const dt=clamp((now-s.last)/1000,0,.25);s.last=now;s.wind=Math.sin(now/9000)*12;
    s.players=s.players.filter(p=>p.bot||now-p.seen<15000);if(now>=s.end)return s;
    for(const p of s.players)seat(s,p);
    for(const p of s.players){
      if(p.respawn){if(now<p.respawn)continue;p.respawn=0;p.hp=100;p.energy=100;p.skillTime=0;p.attackCooldown=.65;p.skillCooldown=Math.max(2,p.skillCooldown||0);p.x=160+Math.random()*680;p.y=160+Math.random()*220;}
      if(p.bot){
        const target=s.players.filter(q=>q.id!==p.id&&!q.respawn).sort((a,b)=>Number(!!contact(p,b)?.valid)-Number(!!contact(p,a)?.valid)||Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y)||a.id.localeCompare(b.id))[0];
        // Seek a crossing near 60% of the target line, rather than chasing its kite.
        let x=500,y=180;
        if(target){const l=line(target),a=line(p).a,c={x:l.a.x+(l.b.x-l.a.x)*.6,y:l.a.y+(l.b.y-l.a.y)*.6};x=clamp(a.x+(c.x-a.x)/.7,55,945);y=clamp(a.y+(c.y-a.y)/.7,70,480);}
        const c=target&&contact(p,target);
        p.input={x:clamp((x-p.x)/65,-1,1),y:clamp((y-p.y)/65,-1,1),cut:!!c?.valid,skill:c?.valid?(p.x<500?1:-1):0};
      }
      move(p,p.input,dt,s.wind);
    }
    // Resolve simultaneous strikes together, independent of who created the room.
    const hits=[];
    for(const p of s.players){if(!p.strike||p.respawn)continue;
      const targets=s.players.map(q=>({q,c:contact(p,q)})).filter(t=>t.c?.valid).sort((a,b)=>Math.abs(a.c.enemy-.6)-Math.abs(b.c.enemy-.6)||a.q.id.localeCompare(b.q.id));
      const t=targets[0];p.aim=t?'hit':'miss';if(!t)continue;
      let damage=t.c.perfect?24:18;
      if(p.color===0&&p.skillTime>0){damage+=8;p.skillTime=0;}
      if(t.q.color===2&&t.q.skillTime>0)damage*=.4;
      hits.push({p,q:t.q,damage,c:t.c});
    }
    for(const h of hits){h.q.hp=Math.max(0,h.q.hp-h.damage);h.q.hitFlash=.25;h.q.lastHit={x:h.c.x,y:h.c.y,damage:Math.round(h.damage)};}
    for(const q of s.players){if(q.hp>0||q.respawn)continue;
      const winner=hits.filter(h=>h.q===q).sort((a,b)=>b.damage-a.damage||a.p.id.localeCompare(b.p.id))[0];if(!winner)continue;
      const p=winner.p;q.respawn=now+3000;q.attack=false;p.score+=100;p.cuts++;
      const cut={text:p.name+' cortou '+q.name,at:now,id:s.id+':'+(++s.cutSequence),winnerId:p.id,loserId:q.id,matchId:s.id,winnerAccountId:p.accountId,loserAccountId:q.accountId,kiteId:q.kiteId,capture:s.rules==='capture'&&!q.kitePermanent};
      s.events.unshift(cut);s._pendingCuts.push(cut);s.events=s.events.slice(0,4);
      if(s.rules==='capture'&&q.accountId&&q.basicKiteId){q.kiteId=q.basicKiteId;q.kitePermanent=true;q.color=0;q.skillTime=0;}
    }
    return s;
  }
  function practiceStep(s,id,input,now){const p=s.players.find(p=>p.id===id);if(p){p.input=sanitizeInput(input);p.seen=now;}return step(s,now);}
  return {create,player,step,move,visible,practiceStep,line,contact,types,type,sanitizeInput,seat};
}
