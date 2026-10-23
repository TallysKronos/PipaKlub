import {drawTallGrass,drawTallGrassParticles} from '/src/world-tall-grass-renderer.js';
import {createTallGrass} from '/src/world-tall-grass.js';
import {toIso,fromIso,screenToWorld,depthOrder,screenDirection} from '/src/world-isometric.js';
import {createWorldNavigation} from '/src/world-navigation.js';
import {worldTerrainContours} from '/src/world-art.js';
import {sample,render,matrices,point} from '/tools/soulgen-studio/model.mjs';
import {parkFixtures,parkFenceRuns} from '/src/park-isometric-layout.js';
import {parkActions,newParkProgress,objective,parkTransition,nearestParkAction,encodeParkSave,decodeParkSave,hitsBox,propOccludesActor} from '/src/park-exploration.js';
const $=id=>document.getElementById(id),canvas=$('park'),g=canvas.getContext('2d'),base='/art/soulgen/keys/park-wind-v2/';
const reduced=matchMedia('(prefers-reduced-motion: reduce)'),keys=new Set(),images={},rigs={};
let data,scene,nav,actor,ground,board,props,camera,fullView,overview=false,paused=reduced.matches,geometry=false,last=0,wind=0;
let progress=newParkProgress(),pending=null,destinationPoint=null,companion=null,hitAreas=[],grass=null,lastContext='',walkClock=0,stepClock=0,soundEnabled=false,audio=null,cameraLead={x:0,y:0};
const panel=$('panel'),SAVE_KEY='soulmonsters.park-preview.v1';
const viewport={width:1280,height:720};let zoom=.95;
function image(src){return new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error('Não foi possível carregar '+src));im.src=src;});}
function plane(ctx){ctx.transform(.82,.41,-.82,.41,0,0);}
function groundPaint(){
 ground=document.createElement('canvas');ground.width=2300;ground.height=1250;const c=ground.getContext('2d');
 c.translate(930,20);plane(c);c.fillStyle='#7ba45b';c.fillRect(-400,-400,2400,1900);
 c.fillStyle='#a8c66e';c.strokeStyle='#658b4e';c.lineWidth=4;c.beginPath();c.roundRect(80,192,1376,752,48);c.fill();c.stroke();
 // Soft grouped vegetation, not checkerboard tile stamps. Seeded, stable across frames.
 let seed=157;const rand=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
 for(let i=0;i<170;i++){const x=100+rand()*1336,y=210+rand()*710;c.fillStyle=i%3?'#96b65f':'#b7cf7d';c.beginPath();c.moveTo(x-5,y);c.lineTo(x-8,y-7);c.lineTo(x,y-3);c.lineTo(x+3,y-12);c.lineTo(x+5,y-2);c.lineTo(x+10,y-6);c.lineTo(x+8,y+2);c.closePath();c.fill();}
 function path(contours,radius){c.beginPath();for(const points of contours){for(let i=0;i<points.length;i++){const p=points[i],a=points[(i+points.length-1)%points.length],b=points[(i+1)%points.length],la=Math.hypot(p.x-a.x,p.y-a.y),lb=Math.hypot(p.x-b.x,p.y-b.y),r=Math.min(radius,la/2,lb/2),x=p.x+(a.x-p.x)*r/la,y=p.y+(a.y-p.y)*r/la;if(!i)c.moveTo(x,y);else c.lineTo(x,y);c.quadraticCurveTo(p.x,p.y,p.x+(b.x-p.x)*r/lb,p.y+(b.y-p.y)*r/lb);}c.closePath();}}
 const walk=scene.tiled.layers.Walkable;
 for(const [material,color,edge]of [['dirt','#e4bd77','#bd9a60'],['sidewalk','#eee0b7','#b9ad87']]){
  const rects=walk.filter(r=>r.properties.ground_frame===material);if(!rects.length)continue;
  path(worldTerrainContours(rects),38);c.fillStyle=color;c.fill();c.strokeStyle=edge;c.lineWidth=3;c.stroke();c.save();c.clip();
  if(material==='sidewalk'){c.strokeStyle='#d4c6a1';c.lineWidth=1.5;for(let x=0;x<1600;x+=48){c.beginPath();c.moveTo(x,0);c.lineTo(x,1100);c.stroke();}for(let y=0;y<1100;y+=48){c.beginPath();c.moveTo(0,y);c.lineTo(1600,y);c.stroke();}}
  else for(let i=0;i<220;i++){c.fillStyle='#d6ac68';c.fillRect(rand()*1536,rand()*1024,3,2);}
  c.restore();
 }
 // Habitat contours remain in the same place as the original game.
 const habitats=walk.filter(r=>r.properties.encounter_zone);path(worldTerrainContours(habitats),28);c.fillStyle='#6e984e';c.fill();c.save();c.clip();
 c.restore();
 grass=createTallGrass(habitats);
}
function buildProps(){
 const layout=scene.art.objects.filter(o=>o.kind==='solid'||!o.rect),seen=new Set(),out=[];
 for(const o of layout){const s=o.sprite;if(!s)continue;const b=o.rect?{x:o.rect.x+o.rect.w/2,y:o.rect.y+o.rect.h}:{x:s.x+s.w/2,y:o.y};const key=Math.round(b.x)+','+Math.round(b.y);if(seen.has(key))continue;seen.add(key);
  const frame=s.frame;if(frame==='flowerpot')continue;let type=frame.includes('tree')?'tree':frame==='park-gazebo'?'coreto':frame==='bench'?'bench':frame==='lamp'?'windsock':frame.includes('shrub')?'shrub':frame.includes('flower')?'flowers':null;
  if(!type)continue;if(type==='bench'&&Math.abs(b.x-408)<2){b.x=420;b.y=690;}
  out.push({...b,type,action:type==='sign'?'map':type==='coreto'?'assis':type==='bench'?(b.x<800?'rest':'rest-east'):null,rig:frame==='park-tree'?'treeLandmark':type,w:type==='tree'?Math.max(205,s.w):type==='coreto'?260:type==='bench'?126:type==='windsock'?215:Math.min(95,s.w),level:o.level||0});
 }
 for(const p of parkFixtures)out.push({...p,action:p.type==='sign'?'map':null,level:0});
 out.push({x:1220,y:626,type:'kite',rig:'kite',w:130,lift:325,level:0});
 // Planting beds follow the border and group around existing trees, leaving paths clear.
 for(let x=140;x<1440;x+=150)out.push({x,y:190,type:'shrub',w:94,level:0});
 for(let x=360;x<1390;x+=170)out.push({x,y:954,type:'shrub',w:90,level:0});
 for(let y=340;y<920;y+=155){out.push({x:62,y,type:'shrub',w:84,level:0},{x:1470,y,type:'shrub',w:88,level:0});}
 // Beyond the fence, overlapping groves frame the playable clearing.
 for(let x=-40;x<1600;x+=165)out.push({x,y:95,type:'tree',rig:'tree',w:255+(x%3)*8,scenery:true,level:0});
 for(let y=230;y<1090;y+=165)out.push({x:-64,y,type:'tree',rig:'tree',w:250,scenery:true,level:0},{x:1592,y:y-70,type:'tree',rig:'tree',w:265,scenery:true,level:0});
 for(let x=420;x<1560;x+=170)out.push({x,y:1080,type:'tree',rig:'tree',w:250,scenery:true,level:0});
 for(const [i,run]of parkFenceRuns.entries()){const [a,b]=run,n=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/112);for(let j=0;j<n;j++){const t=j/n,u=(j+1)/n;out.push({type:'fence',x:(a[0]+(b[0]-a[0])*(t+u)/2),y:(a[1]+(b[1]-a[1])*(t+u)/2),a:{x:a[0]+(b[0]-a[0])*t,y:a[1]+(b[1]-a[1])*t},b:{x:a[0]+(b[0]-a[0])*u,y:a[1]+(b[1]-a[1])*u},last:j===n-1,w:100,level:0});}}
 return out;
}
function drawFence(o){
 const a=toIso(o.a),b=toIso(o.b);g.lineJoin='round';
 for(const h of [14,32]){g.beginPath();g.moveTo(a.x,a.y-h);g.lineTo(b.x,b.y-h);g.lineTo(b.x,b.y-h+7);g.lineTo(a.x,a.y-h+7);g.closePath();g.fillStyle='#bd854b';g.strokeStyle='#664d33';g.lineWidth=2;g.fill();g.stroke();g.strokeStyle='#e6b568';g.lineWidth=1;g.beginPath();g.moveTo(a.x,a.y-h+1);g.lineTo(b.x,b.y-h+1);g.stroke();}
 for(const p of o.last?[a,b]:[a]){g.fillStyle='#9b663e';g.strokeStyle='#584a34';g.lineWidth=2;g.beginPath();g.roundRect(p.x-5,p.y-44,10,45,2);g.fill();g.stroke();g.fillStyle='#dba35c';g.fillRect(p.x-6,p.y-46,12,5);g.fillStyle='#24605c';g.fillRect(p.x-5,p.y-4,10,5);}
}
function shadow(p,w){g.fillStyle='#244b3c2b';g.beginPath();g.ellipse(p.x+10,p.y-1,w*.32,w*.085,-.12,0,Math.PI*2);g.fill();}
function buildBoard(){
 board=document.createElement('canvas');board.width=146;board.height=94;const c=board.getContext('2d');c.fillStyle='#97b96b';c.fillRect(0,0,146,94);c.scale(146/1536,94/1024);
 for(const r of scene.tiled.layers.Walkable.filter(r=>['dirt','sidewalk'].includes(r.properties.ground_frame))){c.fillStyle=r.properties.ground_frame==='dirt'?'#f6dca2':'#f7edcf';c.fillRect(r.x,r.y,r.w,r.h);}
 for(const o of props.filter(o=>o.type==='tree'&&!o.scenery)){c.fillStyle='#326b52';c.beginPath();c.ellipse(o.x,o.y,39,42,0,0,Math.PI*2);c.fill();}
 c.fillStyle='#df8759';c.beginPath();c.moveTo(414,423);c.lineTo(490,488);c.lineTo(414,553);c.lineTo(338,488);c.closePath();c.fill();
 c.fillStyle='#205e62';c.beginPath();c.arc(224,816,25,0,Math.PI*2);c.fill();
}
function propBox(o){const p=toIso(o),rig=rigs[o.rig||o.type],im=images[o.type];if(rig){const k=o.w/rig.width;return {x:p.x-rig.rootPivot[0]*k,y:p.y-rig.rootPivot[1]*k-(o.lift||0),w:o.w,h:rig.height*k};}return {x:p.x-o.w/2,y:p.y-o.w*im.height/im.width,w:o.w,h:o.w*im.height/im.width};}
function coretoCutaway(o){if(o.type!=='coreto')return false;const b=propBox(o);return hitsBox(toIso(actor),{x:b.x+10,y:b.y+o.w*.48,w:b.w-20,h:b.h-o.w*.48+15});}
function drawProp(o){
 if(o.type==='fence'){g.save();drawFence(o);g.restore();return;}
 const p=toIso(o),rig=rigs[o.rig||o.type];g.save();
 const player=toIso(actor),box=propBox(o);
 if(o.type!=='coreto'&&propOccludesActor(box,player,p.y))g.globalAlpha=.3;
 if(o.action)hitAreas.push({...box,id:o.action,depth:p.y});
 if(!['bunting','kite'].includes(o.type))shadow(p,o.w);
 if(rig){const k=o.w/rig.width,pose=sample(rig,'idle',wind);
  if(o.type==='tree'){const v=(Math.abs(Math.round(o.x*7+o.y))%3)-1;pose.values.canopy.scaleX*=1+v*.035;pose.values.canopy.rotation+=v*.65;}
  if(o.type==='kite'){const joint=point(matrices(rig,pose).kite,...rig.rootPivot),x=p.x+(joint.x-rig.rootPivot[0])*k,y=p.y-o.lift+(joint.y-rig.rootPivot[1])*k;g.strokeStyle='#f6edc4';g.lineWidth=1.1;g.beginPath();g.moveTo(p.x,p.y-130);g.quadraticCurveTo(x-36,y+110,x,y);g.stroke();}
  render(g,rig,images,pose,{clear:false,scale:k,offsetX:p.x-g.canvas.width/2+(rig.width/2-rig.rootPivot[0])*k,offsetY:p.y-g.canvas.height/2+(rig.height/2-rig.rootPivot[1])*k-(o.lift||0)});}
 else {const im=images[o.type],h=o.w*im.height/im.width;
  if(coretoCutaway(o)){const split=125,k=o.w/im.width;g.drawImage(im,0,split,im.width,im.height-split,p.x-o.w/2,p.y-h+split*k,o.w,(im.height-split)*k);g.save();g.globalAlpha*=.22;g.drawImage(im,0,0,im.width,split,p.x-o.w/2,p.y-h,o.w,split*k);g.restore();}
  else g.drawImage(im,p.x-o.w/2,p.y-h,o.w,h);
  if(o.type==='sign'){g.save();g.translate(p.x-o.w/2,p.y-h);g.scale(o.w/im.width,o.w/im.width);g.transform(1,.12,0,1,46,64);g.drawImage(board,0,0);g.restore();}
  if(o.type==='coreto'){const flags=rigs.bunting,k=.45;render(g,flags,images,sample(flags,'idle',wind),{clear:false,scale:k,offsetX:p.x-g.canvas.width/2,offsetY:p.y-g.canvas.height/2+(flags.height/2-flags.rootPivot[1])*k-95});}
 }
 g.restore();
}
function drawActor(t){
 const p=toIso(actor);shadow(p,42);const f=data.actor.frames[actor.direction+(actor.moving&&Math.floor(walkClock/190)%2?4:0)],b=f.bounds,k=72/b.h;
 g.imageSmoothingEnabled=true;g.imageSmoothingQuality='high';
 g.drawImage(images.kael,f.x,f.y,f.w,f.h,p.x-(b.x+b.w/2)*k,p.y-(b.y+b.h)*k,f.w*k,f.h*k);
}
function drawResident(o,t){const p=toIso(o),a=o.type==='npc'?data.npc:data.companion,dir=o.direction||0,idx=o.type==='npc'?dir:a.animations[o.moving?'move':'idle'][dir][Math.floor(walkClock/200)%a.animations[o.moving?'move':'idle'][dir].length],f=a.frames[idx],anchor=f.footAnchor||{x:f.bounds.x+f.bounds.w/2,y:f.bounds.y+f.bounds.h},k=(o.type==='npc'?74:44)/a.referenceHeight;shadow(p,o.type==='npc'?38:31);g.imageSmoothingEnabled=true;g.drawImage(images[o.type],f.x,f.y,f.w,f.h,p.x-anchor.x*k,p.y-anchor.y*k,f.w*k,f.h*k);if(o.type==='npc'){hitAreas.push({x:p.x-25,y:p.y-80,w:50,h:80,id:'assis',depth:p.y+1});label(p.x,p.y-85,progress.rewarded?'Sr. Assis':progress.accepted&&progress.collected.length===3?'Assis · recompensa':'Sr. Assis · E');}}
function label(x,y,text){g.font='600 12px system-ui';g.textAlign='center';const w=g.measureText(text).width+16;g.fillStyle='#173d39e8';g.beginPath();g.roundRect(x-w/2,y-16,w,22,5);g.fill();g.fillStyle='#fff2cf';g.fillText(text,x,y);}
function drawActions(){for(const a of parkActions){if(!['pickup','exit'].includes(a.type)||a.type==='pickup'&&(!progress.accepted||progress.collected.includes(a.id)))continue;const p=toIso(a);g.save();g.translate(p.x,p.y);if(a.type==='pickup'){const sway=paused?0:Math.sin(wind*2+a.x)*2;g.translate(0,sway);g.fillStyle='#f5d668';g.strokeStyle='#426e51';g.lineWidth=2;g.beginPath();g.ellipse(0,-14,8,18,.55,0,Math.PI*2);g.fill();g.stroke();g.strokeStyle='#fff4b5';g.beginPath();g.moveTo(-8,5);g.lineTo(6,-28);g.stroke();}else{g.fillStyle='#fff4c1';g.strokeStyle='#476e54';g.lineWidth=2;g.beginPath();g.moveTo(0,-22);g.lineTo(9,-12);g.lineTo(0,-2);g.lineTo(-9,-12);g.closePath();g.fill();g.stroke();label(0,-30,a.label);}g.restore();hitAreas.push({x:p.x-20,y:p.y-42,w:40,h:45,id:a.id,depth:p.y+3});}}
function draw(t){
 g.setTransform(1,0,0,1,0,0);g.fillStyle='#7ba45b';g.fillRect(0,0,1280,720);g.translate(640,360);g.scale(zoom,zoom);g.translate(-camera.x,-camera.y);
 g.drawImage(ground,-930,-20);
 if(actor.path.length){g.save();plane(g);g.strokeStyle='#fff5ce99';g.lineWidth=4;g.setLineDash([5,10]);g.beginPath();g.moveTo(actor.x,actor.y);for(const p of actor.path)g.lineTo(p.x,p.y);g.stroke();g.restore();}
 hitAreas=[];

 const residents=[{...actor,type:'player'},...(companion?[{...companion,type:'companion'}]:[])];
 const queue=depthOrder([...props,...grass.tufts,...residents]);const playerDepth=toIso(actor).y;queue.sort((a,b)=>(coretoCutaway(a)?playerDepth-1:a.depth)-(coretoCutaway(b)?playerDepth-1:b.depth));
 for(const o of queue)o.type==='grass'?drawTallGrass(g,o,{project:toIso,wind,paused}):o.type==='player'?drawActor(t):['npc','companion'].includes(o.type)?drawResident(o,t):drawProp(o);
 drawResident({...parkActions[0],type:'npc',direction:0},t);
 // Always retain a small, clear location marker when furniture covers the sprite.
 const player=toIso(actor);if(props.some(o=>o.type!=='fence'&&propOccludesActor(propBox(o),player,toIso(o).y))){g.strokeStyle='#fff3b1';g.lineWidth=2.5;g.beginPath();g.ellipse(player.x,player.y,13,5,0,0,Math.PI*2);g.stroke();}
 drawActions();
 const teacher=toIso(parkActions[0]);label(teacher.x,teacher.y-85,progress.rewarded?'Sr. Assis':progress.accepted&&progress.collected.length===3?'Assis · recompensa':'Sr. Assis · E');
 if(destinationPoint){const p=toIso(destinationPoint);g.strokeStyle='#fff3b1';g.lineWidth=2;g.beginPath();g.ellipse(p.x,p.y,12,6,0,0,Math.PI*2);g.stroke();}
 drawTallGrassParticles(g,grass.particles);
 if(geometry){g.save();plane(g);g.strokeStyle='#ee3e43';g.lineWidth=2;for(const r of scene.tiled.layers.Solids)g.strokeRect(r.x,r.y,r.w,r.h);g.restore();}
 // Wind streaks are sparse and share the same clock as the props; no screen shake.
 if(!paused){g.strokeStyle='#fff8d84a';g.lineWidth=1.5;for(let i=0;i<7;i++){const x=((wind*42+i*227)%1450)-700,y=160+(i*137)%650;g.beginPath();g.moveTo(x,y);g.quadraticCurveTo(x+22,y-10,x+46,y-2);g.stroke();}}
 g.setTransform(1,0,0,1,0,0);
}
function notify(text){$('hint').textContent=text;}
function focusWorld(){canvas.focus({preventScroll:true});}
function syncQuest(){ $('objective').textContent=objective(progress);$('inventory').textContent=`Fibras: ${progress.collected.length}/3 · Kit de reparo: ${progress.rewarded?1:0} · Rabbito acompanha você`; }
function tone(kind='step'){if(!soundEnabled||!audio)return;const o=audio.createOscillator(),v=audio.createGain(),at=audio.currentTime;o.type=kind==='step'?'triangle':'sine';o.frequency.setValueAtTime(kind==='step'?130:kind==='reward'?660:440,at);v.gain.setValueAtTime(.035,at);v.gain.exponentialRampToValueAtTime(.001,at+.12);o.connect(v);v.connect(audio.destination);o.start(at);o.stop(at+.13);}
function change(event,id){progress=parkTransition(progress,event,id);syncQuest();tone(event==='reward'?'reward':'collect');}
function closePanel(){panel.close();keys.clear();focusWorld();}
function openPanel(title,text,actions=[],extra=null){keys.clear();actor.moving=false;$('dialog-title').textContent=title;const body=$('dialog-body'),buttons=$('dialog-actions');body.replaceChildren();buttons.replaceChildren();const p=document.createElement('p');p.textContent=text;body.append(p);if(extra)body.append(extra);for(const [name,run]of actions){const b=document.createElement('button');b.textContent=name;b.onclick=run;buttons.append(b);}if(!panel.open)panel.showModal();(buttons.querySelector('button')||$('close-dialog')).focus();}
function showMap(){const c=document.createElement('canvas');c.width=600;c.height=400;c.setAttribute('aria-label','Mapa do parque: coreto a oeste, habitats ao norte e a leste, saída ao sul. Use os destinos abaixo para caminhar.');const ctx=c.getContext('2d');ctx.fillStyle='#9ebd72';ctx.fillRect(0,0,600,400);ctx.scale(600/1536,400/1024);for(const r of scene.tiled.layers.Walkable.filter(r=>['dirt','sidewalk'].includes(r.properties.ground_frame))){ctx.fillStyle=r.properties.ground_frame==='dirt'?'#e6bf7d':'#fff0cb';ctx.fillRect(r.x,r.y,r.w,r.h);}ctx.fillStyle='#df8052';ctx.fillRect(285,385,140,95);for(const a of parkActions.filter(a=>a.type==='pickup'&&progress.accepted&&!progress.collected.includes(a.id))){ctx.fillStyle='#fff0a5';ctx.beginPath();ctx.arc(a.x,a.y,22,0,7);ctx.fill();}ctx.fillStyle='#194f68';ctx.beginPath();ctx.arc(actor.x,actor.y,23,0,7);ctx.fill();const routes=[['Ir ao Sr. Assis',()=>{closePanel();goToAction('assis');}],['Ir ao descanso',()=>{closePanel();goToAction('rest');}]];if(progress.accepted)for(const a of parkActions.filter(a=>a.type==='pickup'&&!progress.collected.includes(a.id)))routes.push(['Ir à fibra '+(a.id==='fiber-west'?'oeste':a.id==='fiber-north'?'norte':'leste'),()=>{closePanel();goToAction(a.id);}]);openPanel('Mapa do Parque dos Ventos','Você é o ponto azul. As fibras aparecem em amarelo. Saída sul: Rua dos Ventos; saída nordeste: Clareira do Papel.',routes,c);}
function interact(id){const a=parkActions.find(a=>a.id===id);if(!a)return;
 if(Math.hypot(actor.x-a.x,actor.y-a.y)>a.range){goToAction(id);return;}
 pending=null;destinationPoint=null;actor.path=[];tone('open');
 if(id==='map'){showMap();return;}
 if(id==='assis'){
  if(!progress.accepted)openPanel('Sr. Assis · Fibras ao vento','A brisa espalhou três fibras pelo capim. Você e Rabbito podem recolhê-las? Voltem aqui e eu preparo um kit de reparo para vocês.',[['Aceitar tarefa',()=>{change('accept');closePanel();notify('Tarefa recebida. Procure as três fibras no capim ou consulte o mapa.');}]]);
  else if(progress.collected.length<3)openPanel('Sr. Assis',`Vocês encontraram ${progress.collected.length} de 3 fibras. A placa mostra onde procurar. Rabbito está pronto para acompanhar você.`,[['Ver locais no mapa',showMap]]);
  else if(!progress.rewarded)openPanel('Sr. Assis · Tarefa concluída','Vocês encontraram as três! Aqui está o kit de reparo. É uma recompensa deste passeio local.',[['Receber kit de reparo',()=>{change('reward');closePanel();notify('Tarefa concluída! Kit de reparo recebido. Salve o passeio pelo menu Esc.');}]]);
  else openPanel('Sr. Assis','Obrigado pela ajuda! Seu kit de reparo está guardado. Você pode descansar com Rabbito e continuar explorando.');
 }else if(a.type==='pickup'){
  if(!progress.accepted||progress.collected.includes(id)){notify('Converse com Sr. Assis para saber mais sobre as fibras.');return;}
  openPanel('Fibra do vento','Rabbito encontrou uma fibra presa no capim. Vamos recolhê-la com cuidado?', [['Recolher fibra',()=>{change('collect',id);closePanel();notify(progress.collected.length===3?'Três fibras recolhidas! Volte ao Sr. Assis.':`Fibra recolhida · ${progress.collected.length}/3. Consulte a placa para encontrar as outras.`);}]]);
 }else if(a.type==='bench')openPanel('Descanso no parque','Você e Rabbito fazem uma pausa à sombra. A tarefa e os itens ficam guardados durante o descanso.',[['Descansar',()=>{change('rest');closePanel();notify('Você e Rabbito descansaram. Prontos para continuar!');}]]);
 else if(a.type==='exit')openPanel(a.label,'Você chegou ao acesso para '+a.label+'. A continuação está fora deste passeio local; sua tarefa permanece aqui no parque.');
}
function goToAction(id){if(!nav)return;const a=parkActions.find(a=>a.id===id);if(!a)return;if(Math.hypot(actor.x-a.x,actor.y-a.y)<=a.range){interact(id);return;}const target=a.approach||a,path=nav.target(actor,target,reduced.matches);if(!path.length){notify(actor.navigationMessage||'Não foi possível chegar a esse ponto.');return;}pending=id;destinationPoint=target;notify('Indo até '+a.label.toLowerCase()+'…');if(reduced.matches){pending=null;interact(id);}}
function pauseMenu(){if(!actor)return;openPanel('Passeio pausado','O salvamento fica apenas neste navegador. Não altera a conta nem os saves da demo.',[
 ['Continuar',closePanel],['Consultar mapa',showMap],['Salvar passeio',()=>{try{localStorage.setItem(SAVE_KEY,encodeParkSave(progress,actor));notify('Passeio salvo neste navegador.');closePanel();}catch{openPanel('Não foi possível salvar','O navegador não permitiu gravar o progresso local. Seu passeio atual continua disponível.');}}],
 ['Carregar passeio',()=>{let saved;try{saved=decodeParkSave(localStorage.getItem(SAVE_KEY));}catch{}if(!saved){openPanel('Nenhum passeio válido salvo','Salve este passeio antes de carregar.');return;}progress=saved.progress;const at=nav.geometry.safe(saved.position)?saved.position:nav.create();Object.assign(actor,at,{path:[],history:[{x:at.x,y:at.y}],moving:false});pending=null;destinationPoint=null;companion=null;grass.reset();syncQuest();closePanel();notify('Passeio local carregado.');}],
 [soundEnabled?'Desativar sons':'Ativar sons',()=>{soundEnabled=!soundEnabled;if(soundEnabled){try{audio||=new AudioContext();audio.resume();tone('open');}catch{soundEnabled=false;}}closePanel();notify(soundEnabled?'Sons ativados.':'Sons desativados.');}]]);}
$('close-dialog').onclick=closePanel;panel.addEventListener('cancel',e=>{e.preventDefault();closePanel();});panel.addEventListener('close',()=>{keys.clear();focusWorld();});
$('action').onclick=()=>{const a=nearestParkAction(actor,progress);if(a)interact(a.id);};
function tick(t){
 const dt=last?Math.min((t-last)/1000,.06):0;last=t;
 if(!document.hidden&&!panel.open){const previous={x:actor.x,y:actor.y},hadPath=actor.path.length>0;let dx=(keys.has('ArrowRight')||keys.has('d')?1:0)-(keys.has('ArrowLeft')||keys.has('a')?1:0),dy=(keys.has('ArrowDown')||keys.has('s')?1:0)-(keys.has('ArrowUp')||keys.has('w')?1:0);
  if(dx||dy){const d=fromIso({x:dx,y:dy}),n=Math.hypot(d.x,d.y);nav.move(actor,{x:d.x/n,y:d.y/n},dt);}else nav.step(actor,dt);
  const change=toIso({x:actor.x-previous.x,y:actor.y-previous.y});if(Math.hypot(change.x,change.y)>.01)actor.direction=screenDirection(change.x,change.y);
  if(dx||dy){pending=null;destinationPoint=null;notify(actor.moving?'Explorando · E para interagir · Esc para pausar':'Caminho bloqueado. Contorne o objeto.');}
  if(hadPath&&!actor.path.length&&!dx&&!dy){destinationPoint=null;const id=pending;pending=null;if(id)interact(id);else notify(actor.navigationMessage||'Você chegou · E para interagir');}
  if(actor.moving){walkClock+=dt*1000;stepClock+=dt;if(stepClock>.32){tone('step');stepClock=0;}}
  const follow=nav.follower(actor,55);if(companion){const d=toIso({x:follow.x-companion.x,y:follow.y-companion.y});companion={...follow,direction:Math.hypot(d.x,d.y)>.01?screenDirection(d.x,d.y):companion.direction,moving:Math.hypot(d.x,d.y)>.01};}else{const choices=[{x:actor.x-40,y:actor.y},{x:actor.x+40,y:actor.y},follow];const p=choices.find(p=>nav.geometry.segment(actor,p))||follow;actor.history.unshift({...p});companion={...p,direction:actor.direction,moving:false};}
  grass.update(dt,actor,companion,{reduced:reduced.matches});
  const nearby=nearestParkAction(actor,progress),context=nearby?.id||'';if(context!==lastContext){lastContext=context;$('action').disabled=!nearby;$('action').textContent=nearby?nearby.label+' · E':'Interagir · E';}
  if(!paused)wind+=dt;
  const blend=reduced.matches?1:1-Math.exp(-dt*5),len=Math.hypot(change.x,change.y);cameraLead.x+=((len>.01?change.x/len*45:0)-cameraLead.x)*blend;cameraLead.y+=((len>.01?change.y/len*25:0)-cameraLead.y)*blend;
  const target=overview?fullView:{x:toIso(actor).x+cameraLead.x,y:toIso(actor).y-40+cameraLead.y};if(!overview&&fullView){const b=fullView.bounds,hw=640/zoom,hh=360/zoom;target.x=Math.max(b.left+hw-100,Math.min(b.right-hw+100,target.x));target.y=Math.max(b.top+hh-90,Math.min(b.bottom-hh+90,target.y));}camera.x=Math.abs(target.x-camera.x)<.01?target.x:camera.x+(target.x-camera.x)*blend;camera.y=Math.abs(target.y-camera.y)<.01?target.y:camera.y+(target.y-camera.y)*blend;
  draw(t);
 }requestAnimationFrame(tick);
}
function destination(){goToAction('assis');}
$('walk').onclick=destination;
$('menu').onclick=pauseMenu;
$('overview').onclick=()=>{if(!fullView)return;overview=!overview;zoom=overview?fullView.zoom:.95;$('overview').setAttribute('aria-pressed',String(overview));focusWorld();};
$('motion').onclick=()=>{paused=!paused;$('motion').textContent=paused?'Ativar vento':'Pausar vento';$('motion').setAttribute('aria-pressed',String(paused));focusWorld();};
$('geometry').onclick=()=>{geometry=!geometry;$('geometry').setAttribute('aria-pressed',String(geometry));focusWorld();};
function pointer(e){const b=canvas.getBoundingClientRect();return {x:((e.clientX-b.left)*1280/b.width-640)/zoom+camera.x,y:((e.clientY-b.top)*720/b.height-360)/zoom+camera.y};}
function pick(p){return hitAreas.filter(a=>hitsBox(p,a)).sort((a,b)=>b.depth-a.depth)[0];}
canvas.onclick=e=>{if(!actor||panel.open)return;const s=pointer(e),hit=pick(s);focusWorld();if(hit){goToAction(hit.id);return;}const p=fromIso(s);pending=null;const path=nav.target(actor,p,reduced.matches);destinationPoint=path.length&&!reduced.matches?p:null;notify(actor.navigationMessage||'Caminhando · E para interagir · Esc para pausar');};
canvas.onpointermove=e=>{if(!actor)return;canvas.style.cursor=pick(pointer(e))?'pointer':'crosshair';};
window.addEventListener('keydown',e=>{if(!actor)return;const key=e.key.length===1?e.key.toLowerCase():e.key;if(panel.open)return;if(key==='Escape'){e.preventDefault();pauseMenu();return;}if(key==='e'||key==='Enter'&&e.target===canvas){e.preventDefault();if(!e.repeat){const a=nearestParkAction(actor,progress);if(a)interact(a.id);else notify('Aproxime-se de um objeto ou do Sr. Assis.');}return;}if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','w','a','s','d'].includes(key)&&!['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName)){e.preventDefault();focusWorld();keys.add(key);}});
window.addEventListener('keyup',e=>keys.delete(e.key.length===1?e.key.toLowerCase():e.key));window.addEventListener('blur',()=>keys.clear());
reduced.addEventListener('change',()=>{if(reduced.matches){paused=true;$('motion').textContent='Ativar vento';$('motion').setAttribute('aria-pressed','true');}});
async function load(){
 data=await fetch('/config').then(r=>r.json());scene=data.scene;nav=createWorldNavigation(scene);actor=nav.create();camera=toIso({x:actor.x+110,y:actor.y-80});
 const slices=await fetch(base+'slices.json').then(r=>r.json());await Promise.all(Object.entries(slices).map(async([id,a])=>{images[id]=await image(a.src);}));[images.kael,images.npc,images.companion]=await Promise.all([image(data.actorImage),image('/assets/'+data.npc.image),image('/assets/'+data.companion.image)]);
 await Promise.all(['tree','treeLandmark','windsock','bunting','kite'].map(async id=>{rigs[id]=await fetch(base+id+'.json').then(r=>r.json());}));props=buildProps();groundPaint();buildBoard();
 const boxes=props.filter(o=>o.type!=='fence'&&!o.scenery).map(o=>{const p=toIso(o),rig=rigs[o.rig||o.type];if(rig){const k=o.w/rig.width;return {x:p.x-rig.rootPivot[0]*k,y:p.y-rig.rootPivot[1]*k-(o.lift||0),w:o.w,h:rig.height*k};}return {x:p.x-o.w/2,y:p.y-o.w*images[o.type].height/images[o.type].width,w:o.w,h:o.w*images[o.type].height/images[o.type].width};});
 const left=Math.min(...boxes.map(b=>b.x)),right=Math.max(...boxes.map(b=>b.x+b.w)),top=Math.min(...boxes.map(b=>b.y)),bottom=Math.max(...boxes.map(b=>b.y+b.h));fullView={x:(left+right)/2,y:(top+bottom)/2,zoom:Math.min(1180/(right-left),620/(bottom-top)),bounds:{left,right,top,bottom}};
 $('motion').textContent=paused?'Ativar vento':'Pausar vento';$('motion').setAttribute('aria-pressed',String(paused));syncQuest();notify('Rabbito está com você. Converse com Sr. Assis no coreto · E / Esc');focusWorld();requestAnimationFrame(tick);
}
load().catch(e=>{$('hint').textContent=e.message;console.error(e);});
