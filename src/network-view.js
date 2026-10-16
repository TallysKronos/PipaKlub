export function createNetworkView(engine){
  let history=[],own=null,authority=null,ownId=null,receivedAt=0,halfLag=0;
  const same=(a={},b={})=>a.x===b.x&&a.y===b.y&&!!a.cut===!!b.cut;
  function reset(){history=[];own=null;authority=null;ownId=null;receivedAt=0;}
  function receive(state,id,now,rtt=0){
    const p=state.players.find(p=>p.id===id);ownId=id;
    if(p){
      const snap=!own||!!p.respawn!==!!own.respawn||Math.hypot(p.x-own.x,p.y-own.y)>220;
      own=snap?{...p}:{...p,x:own.x,y:own.y};authority={...p};
    }
    receivedAt=now;halfLag=Math.max(0,Math.min(rtt/2,180));
    history.push({state,at:now});history=history.slice(-24);
  }
  function render(now,input,dt){
    if(!history.length)return [];
    const latest=history.at(-1).state,active=latest.end>latest.last;
    if(own&&active&&!own.respawn&&now-receivedAt<1000){
      engine.move(own,input,Math.min(dt,.1),latest.wind);
      if(authority&&same(input,authority.input)&&now-receivedAt<500){
        const target={...authority};engine.move(target,authority.input,Math.min((now-receivedAt+halfLag)/1000,.25),latest.wind);
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
      if(p.id===ownId)return own?{...own}:p;
      const a=before.state.players.find(q=>q.id===p.id),b=after.state.players.find(q=>q.id===p.id);
      if(!a||!b||a.respawn||b.respawn||Math.hypot(a.x-b.x,a.y-b.y)>180)return {...p};
      const q={...p,x:a.x+(b.x-a.x)*factor,y:a.y+(b.y-a.y)*factor};
      if(targetTime>after.at&&active)engine.move(q,p.input,Math.min((targetTime-after.at)/1000,.08),latest.wind);
      return q;
    });
  }
  return {receive,render,reset};
}
