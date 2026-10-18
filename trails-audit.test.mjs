import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createTrails} from './src/trails.js';

// Audit: a human-like player (late view, mouse speed, aim error, reaction time, no special technique,
// never uses the skill) must be able to finish every trail by retrying, as the game's rules allow.
function human(e,rand){
 let seen=[],cursor=null,err={x:0,y:0},errT=0,validFor=0,holding=false;
 return (s,me,dt)=>{
  seen.push({t:s.last,players:s.players.map(p=>({...p}))});while(seen.length>2&&s.last-seen[1].t>=220)seen.shift();
  const view=seen[0].players,self=view.find(p=>p.id===me.id);if(!self||me.respawn){validFor=0;holding=false;return {};}
  const tg=view.filter(q=>q.id!==me.id&&!q.respawn).sort((a,b)=>Math.hypot(a.x-self.x,a.y-self.y)-Math.hypot(b.x-self.x,b.y-self.y))[0];if(!tg)return {};
  const l=e.line(tg),an=e.line(me).a,c={x:l.a.x+(l.b.x-l.a.x)*.6,y:l.a.y+(l.b.y-l.a.y)*.6};
  errT-=dt;if(errT<=0){errT=.7;err={x:(rand()*2-1)*34,y:(rand()*2-1)*34};}
  const goal={x:an.x+(c.x-an.x)/.7+err.x,y:an.y+(c.y-an.y)/.7+err.y};cursor=cursor||{x:me.x,y:me.y};
  const d=Math.hypot(goal.x-cursor.x,goal.y-cursor.y),step=520*dt;if(d>step){cursor.x+=(goal.x-cursor.x)/d*step;cursor.y+=(goal.y-cursor.y)/d*step;}else cursor={...goal};
  const dx=cursor.x-me.x,dy=cursor.y-me.y,dist=Math.hypot(dx,dy),k=dist<8?0:Math.min(1,dist/70)/dist;
  const looks=view.some(q=>q.id!==me.id&&!q.respawn&&e.contact(self,q)?.valid);validFor=looks?validFor+dt:0;
  if(validFor>=.38&&rand()>.35*dt*10)holding=true;if(!looks||me.energy<14)holding=false;
  return {x:dx*k,y:dy*k,cut:holding};
 };
}
test('a human-like player without tricks can finish every trail within a few tries per stage',()=>{
 const e=createEngine(),t=createTrails();let seed=2024;const rand=()=>{seed=(seed*16807)%2147483647;return seed/2147483647;};
 let p=t.defaults();const tries={};
 for(const st of t.stages){let n=0,won=false;
  while(!won&&n<10){n++;const s=e.create(0,{mode:'rounds',roundsToWin:st.rounds}),me=e.player('Eu',0,'you',0),level=t.aiLevel(st,p);e.admit(s,me,0);
   st.foes.forEach((f,i)=>{const b=e.player(f.name,f.color,'ai'+i,0);b.bot=true;b.ai={level,style:t.story(st.id)?.styles[i]};e.admit(s,b,0);});
   const h=human(e,rand);for(let now=16;now<s.end&&now<900000;now+=16)e.practiceStep(s,'you',h(s,me,.016),now);
   won=(me.rounds||0)>=s.roundsToWin;p=t.settle(p,st.id,{won,roundsLost:Math.max(0,(s.round||0)-(me.rounds||0))}).progress;}
  tries[st.id]=n;assert.ok(won,st.id+' was not beaten in 10 tries: '+JSON.stringify(tries));}
});
