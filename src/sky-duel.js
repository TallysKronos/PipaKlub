// Isolated, local 2.5D experiment. Never awards account progress or inventory.
export function createSkyDuel(){
 const skills=[
  {id:'puxao',name:'Puxão',cost:28,cooldown:4,duration:1.05,description:'Puxe e solte: mergulho e retomada. A subida pode causar crítico com contato.'},
  {id:'chicote',name:'Chicote lateral',cost:26,cooldown:4.5,duration:.8,description:'Varredura para o lado escolhido. Errou o corte? A recuperação deixa você exposto.'},
  {id:'estilingue',name:'Estilingue',cost:32,cooldown:5,duration:1,description:'Carrega, recua e dispara em profundidade. O rival vê a preparação.'},
  {id:'laco',name:'Laço',cost:30,cooldown:5,duration:1.2,description:'Volta curta para mudar o ângulo. Um acerto do rival interrompe a manobra.'},
  {id:'folha',name:'Folha solta',cost:20,cooldown:3.5,duration:1.1,description:'Cede linha, desce e recupera ao lado. Evita golpes pela posição, sem invulnerabilidade.'},
  {id:'duplo',name:'Duplo toque',cost:30,cooldown:4.5,duration:1.1,description:'Dois pulsos. O segundo ignora a guarda se a linha alcançar o rival.'}
 ];
 const clamp=(n,a,b)=>Math.max(a,Math.min(b,n)),add=(a,b)=>({x:a.x+b.x,y:a.y+b.y,z:a.z+b.z}),sub=(a,b)=>({x:a.x-b.x,y:a.y-b.y,z:a.z-b.z}),mul=(a,n)=>({x:a.x*n,y:a.y*n,z:a.z*n}),dot=(a,b)=>a.x*b.x+a.y*b.y+a.z*b.z;
 function contact(a,b){
  const u=sub(a,a.anchor),v=sub(b,b.anchor),w=sub(a.anchor,b.anchor),aa=dot(u,u),bb=dot(u,v),cc=dot(v,v),dd=dot(u,w),ee=dot(v,w),den=aa*cc-bb*bb;
  let s=den>1e-6?clamp((bb*ee-cc*dd)/den,.22,.98):.5,t=0;
  for(let i=0;i<4;i++){t=clamp((bb*s+ee)/cc,.22,.98);s=clamp((bb*t-dd)/aa,.22,.98);}
  const p=add(a.anchor,mul(u,s)),q=add(b.anchor,mul(v,t)),d=sub(p,q),distance=Math.sqrt(dot(d,d));
  const angle=Math.sqrt(Math.max(0,1-bb*bb/(aa*cc)));
  return {point:mul(add(p,q),.5),distance,valid:distance<24&&angle>.12,s,t};
 }
 const pilot=(id,x,z,anchor)=>({id,x,y:200,z,anchor,hp:100,energy:100,cooldown:0,dodge:0,dodgeCooldown:0,flash:0,pull:0,lineCooldown:0,lineSkill:null,trail:[],impact:null});
 function create(){return {time:0,left:90,player:pilot('you',100,480,{x:-240,y:-280,z:40}),bot:pilot('bot',-100,730,{x:240,y:-280,z:40}),charge:0,rest:2,ended:false,winner:null,message:'Cruze as linhas no mesmo plano. Verde = pode cortar.'};}
 function attack(s,who){
  if(s.ended||who.cooldown>0||who.energy<16||who.dodge>0||who.lineSkill)return false;
  const enemy=who===s.player?s.bot:s.player,c=contact(who,enemy);who.energy-=16;who.cooldown=.7;who.pull=.28;
  if(c.valid&&enemy.dodge<=0){const damage=enemy===s.bot&&s.charge>0?12:20;enemy.hp=Math.max(0,enemy.hp-damage);enemy.flash=.3;s.message=who===s.player?'Acerto! −'+damage+' de linha do rival.':'Sua linha sofreu um corte. Esquive quando o rival preparar a puxada.';if(enemy.lineSkill?.id==='laco'){enemy.lineSkill=null;s.message='Laço interrompido pelo rival!';}}
  else s.message=enemy.dodge>0?'Esquiva! A puxada passou.':'Sem contato em profundidade. Avance, recue ou reposicione.';
  if(enemy.hp===0){s.ended=true;s.winner=who.id;}return true;
 }
 function startSkill(s,id,direction=1){
  const p=s.player,def=skills.find(k=>k.id===id);
  if(!def||s.ended||p.lineSkill||p.lineCooldown>0||p.energy<def.cost||p.dodge>0)return false;
  p.energy-=def.cost;p.lineCooldown=def.cooldown;p.trail=[];p.impact=null;
  p.lineSkill={id,phase:'charge',held:0,elapsed:0,origin:{x:p.x,y:p.y,z:p.z},direction:direction<0?-1:1,hits:[],lastPoint:null};
  s.message=def.name+': preparando · solte E para executar.';return true;
 }
 function releaseSkill(s){const k=s.player.lineSkill;if(!k||k.phase!=='charge'||s.ended)return false;k.phase='move';k.elapsed=0;k.origin={x:s.player.x,y:s.player.y,z:s.player.z};s.message=skills.find(d=>d.id===k.id).name+' · manobra em curso';return true;}
 function cancelCharge(s){if(s?.player.lineSkill?.phase==='charge'){s.player.lineSkill=null;s.message='Preparação cancelada. Energia e recarga mantidas.';}}
 function skillPose(k,progress){
  const t=clamp(progress,0,1),d=k.direction;
  if(k.id==='puxao')return {x:0,y:t<.42?-120*Math.sin(t/.42*Math.PI/2):-120*Math.cos((t-.42)/.58*Math.PI/2),z:0};
  if(k.id==='chicote')return {x:d*155*Math.sin(t*Math.PI),y:35*Math.sin(t*Math.PI*2),z:0};
  if(k.id==='estilingue')return {x:0,y:12*Math.sin(t*Math.PI),z:t<.3?-55*t/.3:-55+205*Math.sin((t-.3)/.7*Math.PI/2)};
  if(k.id==='laco')return {x:d*90*Math.sin(t*Math.PI*2),y:65*(1-Math.cos(t*Math.PI*2)),z:25*Math.sin(t*Math.PI*2)};
  if(k.id==='folha')return {x:d*100*Math.sin(t*Math.PI/2),y:-95*Math.sin(t*Math.PI),z:-45*Math.sin(t*Math.PI)};
  return {x:d*25*Math.sin(t*Math.PI*2),y:55*Math.sin(t*Math.PI*4),z:0};
 }
 function skillWindow(id,t){if(id==='puxao')return t>=.45&&t<.9?{slot:0,damage:32,critical:true}:null;if(id==='chicote')return t>.18&&t<.65?{slot:0,damage:24}:null;if(id==='estilingue')return t>.4&&t<.86?{slot:0,damage:28}:null;if(id==='laco')return t>.2&&t<.88?{slot:0,damage:20}:null;if(id==='duplo')return t>.15&&t<.4?{slot:0,damage:8}:t>.63&&t<.9?{slot:1,damage:18,breakGuard:true}:null;return null;}
 function tickSkill(s,dt){
  const p=s.player,k=p.lineSkill;if(!k)return;
  if(k.phase==='charge'){k.held+=dt;if(k.held>=1.2)releaseSkill(s);return;}
  const def=skills.find(d=>d.id===k.id);k.elapsed+=dt;const t=clamp(k.elapsed/def.duration,0,1),offset=skillPose(k,t);
  p.x=clamp(k.origin.x+offset.x,-270,270);p.y=clamp(k.origin.y+offset.y,65,355);p.z=clamp(k.origin.z+offset.z,330,1050);
  const point={x:p.x,y:p.y,z:p.z};if(!k.lastPoint||Math.hypot(point.x-k.lastPoint.x,point.y-k.lastPoint.y,point.z-k.lastPoint.z)>5){p.trail.push({...point,at:s.time});k.lastPoint=point;}
  const window=skillWindow(k.id,t),c=contact(p,s.bot);
  if(window&&!k.hits.includes(window.slot)&&c.valid&&s.bot.dodge<=0){
   k.hits.push(window.slot);const wasGuarded=s.charge>0,guarded=wasGuarded&&!window.breakGuard,damage=guarded?Math.ceil(window.damage*.6):window.damage;
   s.bot.hp=Math.max(0,s.bot.hp-damage);s.bot.flash=.3;p.pull=.2;p.impact={...c.point,at:s.time,critical:!!window.critical,guardBreak:!!window.breakGuard&&wasGuarded};
   if(window.breakGuard&&wasGuarded){s.charge=0;s.rest=2.5;}
   s.message=(window.critical?'CRÍTICO! ':window.breakGuard&&wasGuarded?'GUARDA QUEBRADA! ':'Contato! ')+def.name+' · −'+damage+' de linha'+(guarded?' (guarda)':'');
   if(s.bot.hp===0){s.ended=true;s.winner='you';}
  }
  if(t===1){if(!k.hits.length)s.message=k.id==='folha'?'Folha solta: posição recuperada.':def.name+': sem contato · recuperação.';p.lineSkill=null;p.cooldown=Math.max(p.cooldown,k.id==='chicote'&&!k.hits.length?.85:.25);}
 }
 function step(s,input,seconds){
  if(s.ended)return;const dt=clamp(seconds,0,.05);s.time+=dt;s.left=Math.max(0,90-s.time);
  for(const p of [s.player,s.bot]){for(const k of ['cooldown','dodge','dodgeCooldown','flash','pull','lineCooldown'])p[k]=Math.max(0,p[k]-dt);p.energy=Math.min(100,p.energy+dt*12);p.trail=p.trail.filter(q=>s.time-q.at<1);}
  const p=s.player,b=s.bot;
  if(input.dodge&&!p.lineSkill&&p.dodgeCooldown===0&&p.energy>=22){p.energy-=22;p.dodge=.55;p.dodgeCooldown=3;p.x=clamp(p.x+(input.x<0?-1:1)*75,-270,270);}
  const speed=p.dodge>0?320:175;
  if(!p.lineSkill){p.x=clamp(p.x+clamp(Number(input.x)||0,-1,1)*speed*dt,-270,270);p.y=clamp(p.y+clamp(Number(input.y)||0,-1,1)*speed*dt,80,330);p.z=clamp(p.z+clamp(Number(input.z)||0,-1,1)*230*dt,330,1050);}
  tickSkill(s,dt);
  // The rival periodically seeks the player's plane, then advertises its attack.
  const approach=s.rest<.9,tx=-p.x+Math.sin(s.time*.8)*65,ty=approach?p.y:210+Math.sin(s.time*.7)*70,tz=approach?p.z:p.z+170+Math.sin(s.time*.5)*90;
  const ease=Math.min(1,dt*1.8);b.x=clamp(b.x+(tx-b.x)*ease,-260,260);b.y=clamp(b.y+(ty-b.y)*ease,80,330);b.z=clamp(b.z+(tz-b.z)*ease,330,1050);
  s.rest=Math.max(0,s.rest-dt);
  if(s.charge>0){s.charge-=dt;if(s.charge<=0){attack(s,b);s.rest=2.5;}}
  else if(s.rest===0&&contact(b,p).valid&&s.time>4)s.charge=.9;
  if(input.attack)attack(s,p);
  if(!s.ended&&s.left===0){s.ended=true;s.winner=p.hp===b.hp?'draw':p.hp>b.hp?'you':'bot';}
 }
 return {create,step,contact,attack,skills,startSkill,releaseSkill,cancelCharge,skillPose,skillWindow};
}
