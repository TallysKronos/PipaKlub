export function createEngine() {
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  function player(name,color,id,now) { return {id,name:String(name||'Pipeiro').slice(0,18),color:clamp(Number(color)||0,0,3),x:220+Math.random()*560,y:160+Math.random()*240,hp:100,energy:100,score:0,cuts:0,input:{},seen:now,respawn:0,attack:false}; }
  function create(now=Date.now()) {return {id:crypto.randomUUID(),rules:'casual',cutSequence:0,players:[],last:now,end:now+180000,events:[],wind:0};}
  function visible(s){const {_pendingCuts,...publicState}=s;return {...publicState,players:s.players.map(({key,accountId,kiteId,basicKiteId,...p})=>p),events:s.events.map(({id,text,at,capture,winnerId,loserId})=>({id,text,at,capture,winnerId,loserId}))};}
  function move(p,input,dt,wind=0){
    if(p.respawn)return;
    let i=input||{},dx=clamp(Number(i.x)||0,-1,1),dy=clamp(Number(i.y)||0,-1,1),m=Math.max(1,Math.hypot(dx,dy));
    p.x=clamp(p.x+(dx/m*165+wind)*dt,55,945);p.y=clamp(p.y+dy/m*165*dt,70,480);
    p.attack=!!i.cut&&p.energy>6;p.energy=clamp(p.energy+(p.attack?-29:19)*dt,0,100);p.input=i;
  }
  function step(s,now) {
    s._pendingCuts=[];
    let dt=clamp((now-s.last)/1000,0,.25); s.last=now; s.wind=Math.sin(now/9000)*12;
    s.players=s.players.filter(p=>p.bot||now-p.seen<15000);
    if(now>=s.end)return s;
    for(const p of s.players){
      if(p.respawn){if(now>=p.respawn){p.respawn=0;p.hp=100;p.x=160+Math.random()*680;p.y=160+Math.random()*220;}else continue;}
      if(p.bot){let target=s.players.find(q=>q.id!==p.id&&!q.respawn);p.input={x:target?clamp((target.x-p.x)/90,-1,1):Math.sin(now/1300),y:target?clamp((target.y+60-p.y)/90,-1,1):Math.cos(now/1800),cut:Math.sin(now/1600+p.color)>.15};}
      move(p,p.input,dt,s.wind);
    }
    for(const p of s.players){if(!p.attack||p.respawn)continue;
      for(const q of s.players){if(q.id===p.id||q.respawn)continue;
        let distance=Math.hypot(p.x-q.x,p.y-q.y);
        if(distance<128){q.hp-=dt*(q.attack?21:38);if(q.hp<=0){q.hp=0;q.respawn=now+3000;p.score+=100;p.cuts++;
          const cut={text:p.name+' cortou '+q.name,at:now,id:s.id+':'+(++s.cutSequence),winnerId:p.id,loserId:q.id,matchId:s.id,winnerAccountId:p.accountId,loserAccountId:q.accountId,kiteId:q.kiteId,capture:s.rules==='capture'&&!q.kitePermanent};s.events.unshift(cut);s._pendingCuts.push(cut);s.events=s.events.slice(0,4);
          if(s.rules==='capture'&&q.accountId&&q.basicKiteId){q.kiteId=q.basicKiteId;q.kitePermanent=true;q.color=0;}
        }}
      }
    } return s;
  }
  return {create,player,step,move,visible};
}
