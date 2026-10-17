export function createNetworkView(engine){
  let history=[],own=null,authority=null,ownId=null,receivedAt=0,halfLag=0;
  const clone=p=>({...p,lineMove:p.lineMove?{...p.lineMove,origin:{...p.lineMove.origin},forward:{...p.lineMove.forward},hits:[...p.lineMove.hits]}:null});
  const same=(a={},b={})=>a.x===b.x&&a.y===b.y&&!!a.cut===!!b.cut&&(a.skill||0)===(b.skill||0)&&!!a.dodge===!!b.dodge&&(a.lineNonce||0)===(b.lineNonce||0)&&!!a.lineHeld===!!b.lineHeld&&a.lineId===b.lineId&&a.lineSide===b.lineSide;
  function reset(){history=[];own=null;authority=null;ownId=null;receivedAt=0;}
  function receive(state,id,now,rtt=0){
    const p=state.players.find(p=>p.id===id);ownId=id;
    if(p){
      const snap=!own||!!p.respawn!==!!own.respawn||p.color!==own.color||(p.skillCount||0)>(own.skillCount||0)||Math.hypot(p.x-own.x,p.y-own.y)>220;
      const pending=own&&!snap&&(own.lineSeen||0)>(p.lineSeen||0);
      const previous=own;own=snap?clone(p):{...p,x:own.x,y:own.y,skillCount:Math.max(p.skillCount||0,own.skillCount||0),skillCooldown:Math.max(p.skillCooldown||0,own.skillCooldown||0)};own=clone(own);if(pending){for(const k of ['lineMove','lineSeen','lineCount','lineCooldown','energy'])own[k]=clone(previous)[k];}else if(p.lineMove){own.x=p.x;own.y=p.y;}authority=clone(p);
    }
    receivedAt=now;halfLag=Math.max(0,Math.min(rtt/2,180));
    history.push({state,at:now});history=history.slice(-24);
  }
  function render(now,input,dt){
    if(!history.length)return [];
    const latest=history.at(-1).state,active=latest.end>latest.last&&(!latest.phase||latest.phase==='live');
    if(own&&active&&!own.respawn&&now-receivedAt<1000){
      engine.move(own,input,Math.min(dt,.1),latest.wind,latest.daily?.weather);
      if(authority&&!own.lineMove&&same(input,authority.input)&&now-receivedAt<500){
        const target=clone(authority);engine.move(target,authority.input,Math.min((now-receivedAt+halfLag)/1000,.25),latest.wind,latest.daily?.weather);
        const blend=1-Math.exp(-3*Math.min(dt,.1));
        own.x+=(target.x-own.x)*blend;own.y+=(target.y-own.y)*blend;
      }
    }
    const gap=history.length>1?history.at(-1).at-history.at(-2).at:50;
    const targetTime=now-Math.max(80,Math.min(180,gap*1.4));
    let before=history[0],after=history.at(-1);
    for(const h of history){if(h.at<=targetTime)before=h;if(h.at>=targetTime){after=h;break;}}
    const factor=Math.max(0,Math.min(1,(targetTime-before.at)/Math.max(1,after.at-before.at)));
    return latest.players.map(p=>{
      if(p.id===ownId)return own?clone(own):clone(p);
      const a=before.state.players.find(q=>q.id===p.id),b=after.state.players.find(q=>q.id===p.id);
      if(!a||!b||a.respawn||b.respawn||Math.hypot(a.x-b.x,a.y-b.y)>180)return clone(p);
      const q={...clone(p),x:a.x+(b.x-a.x)*factor,y:a.y+(b.y-a.y)*factor};
      if(targetTime>after.at&&active)engine.move(q,p.input,Math.min((targetTime-after.at)/1000,.08),latest.wind,latest.daily?.weather);
      return q;
    });
  }
  return {receive,render,reset};
}
