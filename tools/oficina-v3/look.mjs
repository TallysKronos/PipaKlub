// Presentation only. Geometry, timing, materials and outcomes remain in model.mjs.
import {drawCraftHand} from './hand.mjs';
import {mountHudSkin} from './hud-skin.mjs';
const $=id=>document.getElementById(id);
const paths={
 kite:'M24 3 42 21 24 43 6 21ZM24 3v40M6 21h36M24 43q-8 4 0 5',
 frame:'M24 4 42 23 24 43 6 23ZM24 4v39M6 23h36',
 knot:'M14 14q10-13 18 0T14 32t18-18M6 7l35 34M7 41 41 7',
 paper:'M10 4h20l9 10v30H10ZM30 4v11h9M16 24h16M16 31h12',
 wind:'M5 15h25c13 0 8-15 1-10M5 24h35M5 33h23c14 0 9 16 1 10',
 soul:'M24 3 29 18 44 24 29 30 24 45 19 30 4 24 19 18ZM38 3v9M34 7h9',
 spool:'M13 10h22v29H13ZM9 5h30v8H9ZM9 36h30v8H9ZM15 19h18M15 25h18M15 31h18',
 restart:'M10 19a16 16 0 1 1 1 18M10 5v15h15',
 check:'M8 24 19 35 40 12',
 pause:'M16 8v32M32 8v32',
 hand:'M14 26V11a4 4 0 0 1 8 0v12-17a4 4 0 0 1 8 0v18-14a4 4 0 0 1 8 0v19q0 14-14 14-8 0-13-8L5 25q0-5 5-3Z'
};
export const icon=(id,cls='')=>`<svg class="${cls}" viewBox="0 0 48 48" aria-hidden="true" focusable="false"><path d="${paths[id]||paths.kite}"/></svg>`;
const stageIcons=['frame','knot','paper','wind','soul'];let lastStamp='';
export function renderWorkshopHud(run,stages,classes,count){
 const c=classes[run.kind],s=stages[run.stage],m=run.materials,stamp=[run.stage,run.kind,run.artesao,count,m.linha,m.folha,!!run.outcome].join('|');
 if(stamp===lastStamp)return;lastStamp=stamp;document.body.dataset.stage=s?.id||'resultado';document.body.dataset.kind=run.kind;
 const completed=Math.min(run.stage,stages.length),progress=completed/stages.length*100;
 $('steps').innerHTML=`<span class="craft-seal"><svg viewBox="0 0 48 48" aria-hidden="true"><circle class="seal-track" cx="24" cy="24" r="20"/><circle class="seal-fill" cx="24" cy="24" r="20" pathLength="100" stroke-dasharray="100" stroke-dashoffset="${100-progress}"/></svg>${icon(stageIcons[run.stage]||'check')}</span><span><small>FEITO À MÃO</small><b>${s?.name||'Um novo elo'}</b></span>`;
 $('steps').setAttribute('aria-label',(s?.name||'Montagem concluída')+' · '+completed+' de '+stages.length+' cuidados concluídos');
 $('mats').innerHTML=[['linha','spool','Linha',m.linha],['folha','paper','Papel',m.folha]].map(([id,glyph,label,n])=>`<div class="stock ${n<=1?'low':''}" role="status" aria-label="${label}: ${n}">${icon(glyph)}<span>${label}<b>${n.toString().padStart(2,'0')}</b></span>${n<=1?'<i aria-hidden="true">!</i>':''}</div>`).join('');
 $('bubble').hidden=!s;
 if(s)$('bubble').innerHTML=`<span class="gesture-icon">${icon(stageIcons[run.stage])}</span><span class="gesture-copy"><small>${c.label} · ${s.name}${run.artesao?' · artesão':''}</small><strong>${s.verb}</strong></span>${count?`<b class="gesture-count">${count}</b>`:icon('soul','gesture-spark')}`;
 $('gestureLabel').innerHTML=icon(stageIcons[run.stage]||'soul')+'<span>'+(['Pegue com a mão','Linha em mãos','Tesoura em mãos','Controle o cabresto','A alma está pronta'][run.stage]||'Um novo elo')+'</span>';
 $('legend').textContent=['Arraste para encaixar · Espaço também encaixa','Segure e solte no verde · Espaço também segura','Arraste a tesoura pelo contorno','Arraste contra a rajada · ← → também controlam','Segure e escolha quando soltar · Espaço também segura'][run.stage]||'Feito por você, desperto por um elo.';
}
export function installWorkshopLook(){
 $('brandMark').innerHTML=icon('kite');$('restartIcon').innerHTML=icon('restart');
 const main=$('main'),bench=$('bench');
 const fit=()=>{const narrow=matchMedia('(max-width:600px)').matches,inset=narrow?10:Math.min(90,main.clientWidth*.06),reserve=narrow?204:150,w=Math.max(1,Math.min(main.clientWidth-inset*2,(main.clientHeight-reserve)*1.5));bench.style.width=w+'px';bench.style.height=w/1.5+'px';bench.style.setProperty('--board-scale',w/960);};
 new ResizeObserver(fit).observe(main);fit();
 fetch('hud.json').then(r=>{if(!r.ok)throw Error();return r.json();}).then(atlas=>{
  for(const button of document.querySelectorAll('[data-painted]')){
   const layer=document.createElement('span');layer.className='hud-art';layer.setAttribute('aria-hidden','true');button.prepend(layer);
   const prefix=button.dataset.painted==='compact'?'button-compact-':'button-',skin=state=>mountHudSkin(layer,prefix+state,atlas);
   skin('normal');button.addEventListener('pointerenter',()=>skin('hover'));button.addEventListener('pointerleave',()=>skin('normal'));button.addEventListener('pointerdown',()=>skin('pressed'));button.addEventListener('pointerup',()=>skin('hover'));button.addEventListener('focus',()=>skin('hover'));button.addEventListener('blur',()=>skin('normal'));
  }
 }).catch(()=>{document.body.classList.add('skin-fallback');});
}
export function drawArtisanMat(g){
 g.save();g.fillStyle='#122f30aa';g.beginPath();g.roundRect(147,64,666,502,18);g.fill();
 g.fillStyle='#32615c';g.beginPath();g.roundRect(150,60,660,500,18);g.fill();
 g.strokeStyle='#173f3d';g.lineWidth=8;g.stroke();
 g.strokeStyle='#dfc38c66';g.lineWidth=1.5;g.setLineDash([3,7]);g.beginPath();g.roundRect(159,69,642,482,13);g.stroke();g.setLineDash([]);
 g.strokeStyle='#e1e6bd10';g.lineWidth=1;for(let x=176;x<795;x+=32){g.beginPath();g.moveTo(x,82);g.lineTo(x,539);g.stroke();}for(let y=90;y<540;y+=32){g.beginPath();g.moveTo(169,y);g.lineTo(791,y);g.stroke();}
 g.strokeStyle='#d3d9af12';g.beginPath();g.arc(480,286,206,0,Math.PI*2);g.stroke();g.beginPath();g.moveTo(480,75);g.lineTo(480,497);g.moveTo(269,286);g.lineTo(691,286);g.stroke();
 g.fillStyle='#eee0b34d';g.font='600 10px Georgia';g.textAlign='left';g.fillText('OFICINA DAS ALMAS',176,539);g.textAlign='right';g.fillText('PIPA KLUB · FEITO À MÃO',783,539);g.restore();
}
export function drawPaperDetails(g,points,center,color){
 g.save();g.beginPath();points.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));g.closePath();g.clip();
 points.forEach((p,i)=>{g.beginPath();g.moveTo(center.x,center.y);g.lineTo(p.x,p.y);g.lineTo(points[(i+1)%points.length].x,points[(i+1)%points.length].y);g.closePath();g.fillStyle=i%2?'#fff3c633':'#562f271a';g.fill();});
 g.strokeStyle='#fff3c630';g.lineWidth=1;points.forEach(p=>{g.beginPath();g.moveTo(center.x,center.y);g.lineTo(p.x,p.y);g.stroke();});g.restore();
}
export function drawCraftTool(g,id,down,t,grip=down?1:0){
 g.save();g.lineCap='round';g.lineJoin='round';g.strokeStyle='#203f3e';g.lineWidth=3;
 if(id==='linha'){
  g.fillStyle='#e9be71';g.beginPath();g.roundRect(-14,-38,28,9,3);g.fill();g.stroke();g.beginPath();g.roundRect(-11,-30,22,22,3);g.fillStyle='#52a399';g.fill();g.stroke();g.beginPath();g.roundRect(-14,-11,28,8,3);g.fillStyle='#e9be71';g.fill();g.stroke();for(let y=-27;y<-13;y+=4){g.beginPath();g.moveTo(-9,y);g.lineTo(9,y);g.strokeStyle='#2f7c76';g.lineWidth=1;g.stroke();}g.beginPath();g.moveTo(0,-3);g.quadraticCurveTo(9,1,0,0);g.strokeStyle='#fff0c7';g.lineWidth=2;g.stroke();
 }else if(id==='tesoura'){
  // Two metal blades, one visible pivot and two hollow coral handles.
  // The cutting tip stays at (0,0), matching the actual path interaction.
  g.save();const spread=down?.12+.12*Math.sin(t*24):.34;g.translate(-33*Math.sin(-.24+spread),33*Math.cos(-.24+spread));g.rotate(-.24);
  for(const side of [-1,1]){g.save();g.rotate(side*spread);
   g.beginPath();g.moveTo(-3,3);g.lineTo(-5,-9);g.lineTo(0,-33);g.quadraticCurveTo(5,-18,4,-4);g.lineTo(3,8);g.closePath();g.fillStyle=side===1?'#f7f4dc':'#adc5c4';g.fill();g.strokeStyle='#183e3d';g.lineWidth=2.2;g.stroke();
   g.beginPath();g.moveTo(0,-23);g.lineTo(0,-3);g.strokeStyle='#ffffff';g.lineWidth=1.3;g.stroke();
   g.beginPath();g.moveTo(0,5);g.lineTo(side*10,17);g.strokeStyle='#183e3d';g.lineWidth=8;g.stroke();g.strokeStyle='#adc5c4';g.lineWidth=4;g.stroke();
   g.beginPath();g.ellipse(side*12,26,9,12,side*-.3,0,Math.PI*2);g.strokeStyle='#183e3d';g.lineWidth=9;g.stroke();g.strokeStyle='#e78153';g.lineWidth=5;g.stroke();
   g.restore();
  }
  g.beginPath();g.arc(0,0,4.5,0,Math.PI*2);g.fillStyle='#f0c773';g.fill();g.strokeStyle='#183e3d';g.lineWidth=2;g.stroke();g.beginPath();g.moveTo(-2,0);g.lineTo(2,0);g.stroke();g.restore();
 }else if(id==='alma'){
  g.save();g.shadowColor='#efd189';g.shadowBlur=down?16:5;g.beginPath();g.moveTo(0,-31);g.lineTo(15,-15);g.lineTo(0,2);g.lineTo(-15,-15);g.closePath();g.fillStyle='#ecd298';g.fill();g.stroke();g.beginPath();g.moveTo(0,-27);g.lineTo(0,-2);g.moveTo(-11,-15);g.lineTo(11,-15);g.strokeStyle='#428e85';g.lineWidth=2;g.stroke();g.restore();
 }else{
  drawCraftHand(g,grip);
 }
 if(id!=='mao'){g.beginPath();g.arc(0,0,3,0,Math.PI*2);g.fillStyle='#fff2cf';g.fill();g.strokeStyle='#284b48';g.lineWidth=1;g.stroke();}g.restore();
}
