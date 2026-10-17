// A separate canvas and input lifetime keep this experiment outside live matches.
const skyDuel=createSkyDuel();let skyMatch=null,skyActive=false,skyPaused=false,skyRAF=0,skyLast=0,skyClock=0,skyPaint=0,skyKeys=new Set(),skyPointer=null,skyHeld={attack:false,z:0},skyFocus=null;
const skyExperiment=document.createElement('div');skyExperiment.id='skyExperiment';skyExperiment.hidden=true;
skyExperiment.innerHTML=`<section class="sky-lab" role="dialog" aria-modal="true" aria-labelledby="skyTitle"><header class="sky-top"><div><small>LABORATÓRIO · TREINO LOCAL 2.5D</small><h2 id="skyTitle">Duelo nas Alturas</h2></div><div><button id="skyPause" class="secondary">Pausar</button><button id="skyExit" class="secondary">Sair</button></div></header><div class="sky-stage"><canvas id="skyDuelCanvas" aria-label="Duelo com profundidade: mova com WASD ou setas, R e F para avançar e recuar, espaço para atacar e Shift para esquivar."></canvas><div class="sky-score"><span id="skyYourHP"></span><b id="skyTime"></b><span id="skyBotHP"></span></div><div class="sky-contact" id="skyContact" role="status"></div><div class="sky-result" id="skyResult" hidden><h3 id="skyResultTitle"></h3><p>Experimento local: sem XP, moedas ou perda de pipas.</p><button class="primary" id="skyRestart">Voar de novo</button></div></div><div class="sky-bottom"><div class="sky-readout"><b id="skyFeedback" role="status"></b><small id="skyEnergy"></small></div><div class="sky-controls"><button class="secondary" id="skyNear" aria-label="Avançar em profundidade">Avançar · R</button><button class="secondary" id="skyFar" aria-label="Recuar em profundidade">Recuar · F</button><button class="primary" id="skyAttack">Puxar · espaço</button><button class="secondary" id="skyDodge">Esquiva · Shift</button></div><p class="sky-help">Arraste para guiar ou use WASD / setas. R avança até o rival, F recua; a roda do mouse também muda a profundidade. Cruze as linhas e puxe quando a mira ficar verde. O aviso vermelho antecipa o ataque do rival.</p></div></section>`;
document.body.append(skyExperiment);
const skyButton=uiElement('button','✦ Duelo nas Alturas · teste','secondary');skyButton.id='skyDuelButton';skyButton.type='button';document.querySelector('.menu-actions').append(skyButton);
const skyCanvas=$('skyDuelCanvas'),skyCtx=skyCanvas.getContext('2d');
function skyProject(p,w,h){const scale=650/(p.z+300);return {x:w/2+(p.x-skyMatch.player.x*.24)*scale,y:h*.25+(370-p.y)*scale,scale};}
function skyResetInput(){skyKeys.clear();skyPointer=null;skyHeld={attack:false,z:0};}
function skyStart(){skyMatch=skyDuel.create();skyPaused=false;skyClock=0;skyLast=0;skyResetInput();$('skyResult').hidden=true;$('skyPause').textContent='Pausar';}
function skyOpen(){if(mode){toast('Saia da partida para abrir o laboratório.');return;}skyFocus=document.activeElement;skyActive=true;skyExperiment.hidden=false;document.body.classList.add('sky-testing');skyStart();$('skyExit').focus();skyRAF=requestAnimationFrame(skyTick);}
function skyClose(){skyActive=false;cancelAnimationFrame(skyRAF);skyRAF=0;skyResetInput();skyExperiment.hidden=true;document.body.classList.remove('sky-testing');skyFocus?.focus();}
function skyTogglePause(){skyPaused=!skyPaused;skyResetInput();skyLast=0;$('skyPause').textContent=skyPaused?'Continuar':'Pausar';}
skyButton.onclick=skyOpen;$('skyExit').onclick=skyClose;$('skyRestart').onclick=skyStart;$('skyPause').onclick=skyTogglePause;
const skyHandled=new Set(['w','a','s','d','arrowup','arrowdown','arrowleft','arrowright','r','f',' ','shift','escape','p']);
document.addEventListener('keydown',e=>{if(!skyActive)return;const key=e.key.toLowerCase();if(!skyHandled.has(key))return;e.preventDefault();e.stopImmediatePropagation();if(key==='escape'){skyClose();return;}if(key==='p'){if(!e.repeat)skyTogglePause();return;}skyKeys.add(key);},true);
document.addEventListener('keyup',e=>{if(!skyActive)return;const key=e.key.toLowerCase();if(skyHandled.has(key)){e.preventDefault();e.stopImmediatePropagation();skyKeys.delete(key);}},true);
addEventListener('blur',()=>{if(skyActive&&!skyPaused)skyTogglePause();});document.addEventListener('visibilitychange',()=>{if(document.hidden&&skyActive&&!skyPaused)skyTogglePause();});
skyCanvas.addEventListener('pointerdown',e=>{if(skyPaused||skyMatch.ended||skyPointer)return;e.preventDefault();skyCanvas.setPointerCapture(e.pointerId);skyPointer={id:e.pointerId,x:e.clientX,y:e.clientY};});
skyCanvas.addEventListener('pointermove',e=>{if(skyPointer?.id===e.pointerId){skyPointer.x=e.clientX;skyPointer.y=e.clientY;}});
for(const event of ['pointerup','pointercancel','lostpointercapture'])skyCanvas.addEventListener(event,e=>{if(skyPointer?.id===e.pointerId)skyPointer=null;});
skyCanvas.addEventListener('wheel',e=>{e.preventDefault();if(!skyPaused&&!skyMatch.ended)skyMatch.player.z=Math.max(330,Math.min(1050,skyMatch.player.z+Math.sign(e.deltaY)*50));},{passive:false});
skyCanvas.addEventListener('contextmenu',e=>e.preventDefault());
function skyHold(id,down,up){const button=$(id);button.addEventListener('pointerdown',e=>{e.preventDefault();button.setPointerCapture(e.pointerId);down();});for(const event of ['pointerup','pointercancel','lostpointercapture'])button.addEventListener(event,up);}
skyHold('skyNear',()=>skyHeld.z=1,()=>skyHeld.z=0);skyHold('skyFar',()=>skyHeld.z=-1,()=>skyHeld.z=0);skyHold('skyAttack',()=>skyHeld.attack=true,()=>skyHeld.attack=false);
$('skyDodge').onclick=()=>{if(!skyPaused&&!skyMatch.ended)skyDuel.step(skyMatch,{dodge:true},0);};
// Keyboard activation works for the same controls without requiring pointer events.
for(const [id,action]of [['skyNear',()=>skyMatch.player.z=Math.min(1050,skyMatch.player.z+70)],['skyFar',()=>skyMatch.player.z=Math.max(330,skyMatch.player.z-70)],['skyAttack',()=>skyDuel.attack(skyMatch,skyMatch.player)]])$(id).addEventListener('click',e=>{if(e.detail===0&&!skyPaused&&!skyMatch.ended)action();});
function skyTick(t){if(!skyActive)return;const dt=skyLast?Math.min(.05,(t-skyLast)/1000):0;skyLast=t;
 if(!skyPaused){const has=k=>skyKeys.has(k),input={x:Number(has('d')||has('arrowright'))-Number(has('a')||has('arrowleft')),y:Number(has('w')||has('arrowup'))-Number(has('s')||has('arrowdown')),z:Number(has('r'))-Number(has('f'))||skyHeld.z,attack:has(' ')||skyHeld.attack,dodge:has('shift')};
  if(skyPointer&&!input.x&&!input.y){const r=skyCanvas.getBoundingClientRect(),p=skyProject(skyMatch.player,r.width,r.height),dx=skyPointer.x-r.left-p.x,dy=skyPointer.y-r.top-p.y;input.x=Math.max(-1,Math.min(1,dx/70));input.y=Math.max(-1,Math.min(1,-dy/70));}
  skyDuel.step(skyMatch,input,dt);skyClock+=dt;
 }
 if(t-skyPaint>=(lightMode?33:16)||skyMatch.ended){skyDraw(t);skyPaint=t;}skyRAF=requestAnimationFrame(skyTick);
}
function skyDraw(t){
 const r=skyCanvas.getBoundingClientRect(),w=Math.max(1,r.width),h=Math.max(1,r.height),d=Math.min(devicePixelRatio||1,lightMode?1:1.5);if(skyCanvas.width!==Math.round(w*d)||skyCanvas.height!==Math.round(h*d)){skyCanvas.width=Math.round(w*d);skyCanvas.height=Math.round(h*d);}skyCtx.setTransform(d,0,0,d,0,0);
 const c=skyCtx,s=skyMatch,contact=skyDuel.contact(s.player,s.bot),time=art.reduced?0:skyClock*1000;
 const g=c.createLinearGradient(0,0,0,h);g.addColorStop(0,'#387cb0');g.addColorStop(.65,'#a7d8df');g.addColorStop(1,'#e5efdd');c.fillStyle=g;c.fillRect(0,0,w,h);
 // Cloud layers move at different speeds and remain behind combat silhouettes.
 for(let layer=0;layer<3;layer++)for(let i=0;i<4;i++){const cw=100+layer*65,x=((i*w/3+time*(.004+layer*.004))%(w+cw))-cw/2,y=h*(.12+layer*.24)+Math.sin(i*2+layer)*20;c.fillStyle=['#e4f3ef77','#f1f8edaa','#fff8e4cc'][layer];c.beginPath();c.ellipse(x,y,cw,13+layer*9,0,0,Math.PI*2);c.ellipse(x+cw*.3,y-12,cw*.55,22+layer*5,0,0,Math.PI*2);c.fill();}
 c.fillStyle='#6e9b9f35';c.beginPath();c.moveTo(0,h);for(let x=0;x<=w;x+=w/12)c.lineTo(x,h*.86-Math.sin(x/w*17)*h*.035);c.lineTo(w,h);c.fill();
 const project=p=>skyProject(p,w,h),line=(a,b,color,width=2)=>{c.strokeStyle=color;c.lineWidth=width;c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke();};
 for(const p of [s.player,s.bot]){const a=project(p.anchor),b=project(p);line(a,b,p===s.player?'#f8f1cc':'#294e76',p.pull>0?4:2);if(p.dodge>0){c.setLineDash([5,5]);c.strokeStyle='#fff';c.lineWidth=2;c.beginPath();c.ellipse(b.x,b.y,57*b.scale,30*b.scale,0,0,Math.PI*2);c.stroke();c.setLineDash([]);}}
 // Far-to-near sorting provides real occlusion as the pilots change depth.
 for(const p of [s.player,s.bot].sort((a,b)=>b.z-a.z)){const b=project(p),size=175*b.scale,own=p===s.player,alt=own?playerAccount?.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id):null,color=own?selected:2;c.save();c.globalAlpha=p.flash>0?.5:1;
  art.creature(c,color,time,b.x-size/2,b.y-size*.62,size,{soul:alt?.model?.soul||null,facing:own?1:-1,animate:!skyPaused&&!art.reduced,input:{x:own?1:-1,y:0},hitFlash:p.flash,skillCooldown:p.pull>0?6.9:0});c.restore();
  c.fillStyle=own?'#16434b':'#263a61';c.font='bold 12px system-ui';c.textAlign='center';c.fillText(own?'VOCÊ':'RIVAL',b.x,b.y+size*.45);c.fillStyle='#173a4940';c.fillRect(b.x-28,b.y+size*.5,56,4);c.fillStyle=own?'#35a28e':'#e47c59';c.fillRect(b.x-28,b.y+size*.5,56*p.hp/100,4);
 }
 if(contact.valid){const p=project(contact.point);c.strokeStyle='#246c4e';c.fillStyle='#e3ffbe';c.lineWidth=3;c.beginPath();c.arc(p.x,p.y,12,0,Math.PI*2);c.fill();c.stroke();line({x:p.x-18,y:p.y},{x:p.x+18,y:p.y},'#246c4e');line({x:p.x,y:p.y-18},{x:p.x,y:p.y+18},'#246c4e');}
 // Depth ruler is a tactical instrument rather than a claim of 3D sprite rotation.
 const rx=w-28,top=65,len=Math.max(70,h-160);c.strokeStyle='#25556966';c.lineWidth=4;c.beginPath();c.moveTo(rx,top);c.lineTo(rx,top+len);c.stroke();for(const p of [s.bot,s.player]){const y=top+(p.z-330)/720*len;c.fillStyle=p===s.player?'#e9ffd4':'#df715c';c.beginPath();c.arc(rx,y,6,0,Math.PI*2);c.fill();}c.font='10px system-ui';c.fillStyle='#214653';c.textAlign='right';c.fillText('PERTO',rx-10,top);c.fillText('LONGE',rx-10,top+len);
 if(skyPaused){c.fillStyle='#12324677';c.fillRect(0,0,w,h);c.fillStyle='#fff6dc';c.font='bold 25px system-ui';c.textAlign='center';c.fillText('Pausado',w/2,h/2);}
 $('skyYourHP').textContent='Sua linha · '+s.player.hp+'%';$('skyBotHP').textContent='Rival · '+s.bot.hp+'%';$('skyTime').textContent=Math.ceil(s.left)+'s';
 const status=$('skyContact');status.className='sky-contact'+(s.charge>0?' danger':contact.valid?' ready':'');status.textContent=s.charge>0?'Rival preparando puxada · esquive!':contact.valid?'CRUZAMENTO REAL · PUXE!':'Aproxime as linhas no mesmo plano · distância '+Math.round(contact.distance);
 $('skyFeedback').textContent=s.message;$('skyEnergy').textContent='Energia '+Math.round(s.player.energy)+'% · Esquiva '+(s.player.dodgeCooldown>0?s.player.dodgeCooldown.toFixed(1)+'s':'pronta')+' · Profundidade '+Math.round(s.player.z);
 if(s.ended){$('skyResult').hidden=false;$('skyResultTitle').textContent=s.winner==='you'?'Você conquistou o céu!':s.winner==='draw'?'Duelo empatado':'O rival venceu esta vez';}
}
