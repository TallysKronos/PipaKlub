// Isolated, local 2.5D experiment. Never awards account progress or inventory.
export function createSkyDuel(){
 const clamp=(n,a,b)=>Math.max(a,Math.min(b,n)),add=(a,b)=>({x:a.x+b.x,y:a.y+b.y,z:a.z+b.z}),sub=(a,b)=>({x:a.x-b.x,y:a.y-b.y,z:a.z-b.z}),mul=(a,n)=>({x:a.x*n,y:a.y*n,z:a.z*n}),dot=(a,b)=>a.x*b.x+a.y*b.y+a.z*b.z;
 function contact(a,b){
  const u=sub(a,a.anchor),v=sub(b,b.anchor),w=sub(a.anchor,b.anchor),aa=dot(u,u),bb=dot(u,v),cc=dot(v,v),dd=dot(u,w),ee=dot(v,w),den=aa*cc-bb*bb;
  let s=den>1e-6?clamp((bb*ee-cc*dd)/den,.22,.98):.5,t=0;
  for(let i=0;i<4;i++){t=clamp((bb*s+ee)/cc,.22,.98);s=clamp((bb*t-dd)/aa,.22,.98);}
  const p=add(a.anchor,mul(u,s)),q=add(b.anchor,mul(v,t)),d=sub(p,q),distance=Math.sqrt(dot(d,d));
  const angle=Math.sqrt(Math.max(0,1-bb*bb/(aa*cc)));
  return {point:mul(add(p,q),.5),distance,valid:distance<24&&angle>.12,s,t};
 }
 const pilot=(id,x,z,anchor)=>({id,x,y:200,z,anchor,hp:100,energy:100,cooldown:0,dodge:0,dodgeCooldown:0,flash:0,pull:0});
 function create(){return {time:0,left:90,player:pilot('you',100,480,{x:-240,y:-280,z:40}),bot:pilot('bot',-100,730,{x:240,y:-280,z:40}),charge:0,rest:2,ended:false,winner:null,message:'Cruze as linhas no mesmo plano. Verde = pode cortar.'};}
 function attack(s,who){
  if(s.ended||who.cooldown>0||who.energy<16||who.dodge>0)return false;
  const enemy=who===s.player?s.bot:s.player,c=contact(who,enemy);who.energy-=16;who.cooldown=.7;who.pull=.28;
  if(c.valid&&enemy.dodge<=0){enemy.hp=Math.max(0,enemy.hp-20);enemy.flash=.3;s.message=who===s.player?'Acerto! −20 de linha do rival.':'Sua linha sofreu um corte. Esquive quando o rival preparar a puxada.';}
  else s.message=enemy.dodge>0?'Esquiva! A puxada passou.':'Sem contato em profundidade. Avance, recue ou reposicione.';
  if(enemy.hp===0){s.ended=true;s.winner=who.id;}return true;
 }
 function step(s,input,seconds){
  if(s.ended)return;const dt=clamp(seconds,0,.05);s.time+=dt;s.left=Math.max(0,90-s.time);
  for(const p of [s.player,s.bot]){for(const k of ['cooldown','dodge','dodgeCooldown','flash','pull'])p[k]=Math.max(0,p[k]-dt);p.energy=Math.min(100,p.energy+dt*12);}
  const p=s.player,b=s.bot;
  if(input.dodge&&p.dodgeCooldown===0&&p.energy>=22){p.energy-=22;p.dodge=.55;p.dodgeCooldown=3;p.x=clamp(p.x+(input.x<0?-1:1)*75,-270,270);}
  const speed=p.dodge>0?320:175;
  p.x=clamp(p.x+clamp(Number(input.x)||0,-1,1)*speed*dt,-270,270);p.y=clamp(p.y+clamp(Number(input.y)||0,-1,1)*speed*dt,80,330);p.z=clamp(p.z+clamp(Number(input.z)||0,-1,1)*230*dt,330,1050);
  // The rival periodically seeks the player's plane, then advertises its attack.
  const approach=s.rest<.9,tx=-p.x+Math.sin(s.time*.8)*65,ty=approach?p.y:210+Math.sin(s.time*.7)*70,tz=approach?p.z:p.z+170+Math.sin(s.time*.5)*90;
  const ease=Math.min(1,dt*1.8);b.x=clamp(b.x+(tx-b.x)*ease,-260,260);b.y=clamp(b.y+(ty-b.y)*ease,80,330);b.z=clamp(b.z+(tz-b.z)*ease,330,1050);
  s.rest=Math.max(0,s.rest-dt);
  if(s.charge>0){s.charge-=dt;if(s.charge<=0){attack(s,b);s.rest=2.5;}}
  else if(s.rest===0&&contact(b,p).valid&&s.time>4)s.charge=.9;
  if(input.attack)attack(s,p);
  if(!s.ended&&s.left===0){s.ended=true;s.winner=p.hp===b.hp?'draw':p.hp>b.hp?'you':'bot';}
 }
 return {create,step,contact,attack};
}
