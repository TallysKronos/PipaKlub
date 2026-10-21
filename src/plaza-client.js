function currentPlazaMission(){
 if(typeof worldRuntime!=='undefined'&&worldRuntime.id?.startsWith('park-'))return {title:'Habitats do parque',body:'Procure Pipamons no capim alto. A trilha de terra é segura.',action:'wildGuide',stage:null};
 const next=trails.stages.find(stage=>trails.unlocked(trailProgress,stage.id)&&!trailProgress.stars[stage.id]),trail=next&&trails.trails[next.trailIndex];
 const context=typeof worldMissionContext==='function'?worldMissionContext(next):{};
 return plazaPolicy.mission(journeyLoading?'arrival':journey?.phase,next,trail,{...context,demo:trails.demo,complete:journey?.phase==='complete'&&!next});
}
function updatePlazaMission(){if(!$('plazaMissionTitle'))return;const m=currentPlazaMission();$('homeObjective').textContent=journeyLoading?'Preparando sua chegada ao clube…':m.body;$('plazaMissionTitle').textContent=m.title;}
// Scenic home: artwork, actors and HUD are independent layers. No simulated balances.
const plazaPolicy=createPlazaPolicy();
const plazaActor={x:735,y:655,target:{x:735,y:655},direction:3,owner:null},plazaFollower={x:805,y:660};
const plazaURL=file=>homeArt.images['plaza-'+file.replace('.png','')]?.url||'';
function plazaIcon(name){const img=document.createElement('img');img.alt='';img.src=plazaURL('icon-'+name+'.png');img.draggable=false;return img;}
function plazaAction(button,fn){button.type='button';button.onclick=()=>{if(!playerAccount||mode)return;hideJourney();fn();};return button;}
function initPlaza(){
 if(!homeArt.plaza)return;
 courtyard.classList.add('plaza');courtyard.setAttribute('aria-label','Praça do PipaKlub');
 const canvas=$('courtyardCanvas');canvas.width=1536;canvas.height=1024;canvas.setAttribute('aria-label','Kael e seu parceiro no bairro. Clique no caminho para passear.');
 const hud=courtyard.querySelector('.home-hud');hud.className='plaza-hud';
 const identity=courtyard.querySelector('.home-identity');identity.className='plaza-profile-copy';
 const profile=uiElement('button',undefined,'plaza-profile plaza-paper');profile.id='plazaProfile';profile.setAttribute('aria-label','Abrir meu perfil');
 const avatar=document.createElement('img');avatar.src=plazaURL('avatar.png');avatar.alt='';avatar.className='plaza-avatar';
 const xp=uiElement('div',undefined,'plaza-level');xp.innerHTML='<b id="plazaLevel"></b><span id="plazaXPLabel"></span><div id="plazaXP" role="progressbar" aria-label="Experiência do pipeiro" aria-valuemin="0" aria-valuemax="100"><i id="plazaXPFill"></i></div>';
 identity.append(xp);profile.append(avatar,identity);hud.prepend(profile);plazaAction(profile,()=>homeActions.profile());
 const mission=courtyard.querySelector('.home-objective');mission.className='plaza-mission plaza-paper';
 const title=mission.querySelector('small');title.textContent='Missão atual';title.id='plazaMissionTitle';
 const objective=$('homeObjective'),missionButton=uiElement('button',undefined,'plaza-mission-action');missionButton.append(objective,uiElement('span','›'));mission.append(missionButton);
 plazaAction(missionButton,()=>{const n=firstOpenStage(),m=currentPlazaMission();homeActions[m.action]()});
 const menu=$('homeMenuButton');menu.className='plaza-menu';menu.replaceChildren(plazaIcon('settings'));menu.setAttribute('aria-label','Abrir menu do clube');menu.title='Menu · Esc';
 const wallet=uiElement('div',undefined,'plaza-wallet');wallet.setAttribute('aria-label','Moedas da conta');wallet.innerHTML='<span aria-hidden="true" class="plaza-coin">✦</span><b id="plazaCoins">0</b><span class="plaza-wallet-label">moedas</span>';hud.append(wallet);
 const nav=uiElement('nav',undefined,'plaza-rail');nav.setAttribute('aria-label','Atalhos da praça');
 for(const [name,label,action]of [['backpack','Mochila',openPlazaBag],['partners','Pipamons',()=>homeActions.collection()],['map','Mapa',()=>homeActions.city()],['missions','Missões',openPlazaMissions],['settings','Config.',()=>{openHomeMenu();renderHomeMenu('optionsGroup')}]]){
  const button=uiElement('button',undefined,'plaza-nav');button.id='plazaNav-'+name;button.append(plazaIcon(name),uiElement('span',label));plazaAction(button,action);nav.append(button);
 }courtyard.append(nav);
 const destination=uiElement('section',undefined,'plaza-destination plaza-paper');destination.setAttribute('aria-label','Explorar a cidade');
 destination.innerHTML='<h2 id="plazaDistrictName">Cidade dos ventos</h2><div class="plaza-postcard"><img id="plazaDistrictImage" alt="" loading="lazy"></div><button id="plazaVisit" class="plaza-primary">Ir para a cidade <span aria-hidden="true">▶</span></button>';courtyard.append(destination);plazaAction($('plazaVisit'),()=>homeActions.city());
 const welcome=uiElement('div',undefined,'plaza-welcome');welcome.append(plazaIcon('chat'));const copy=uiElement('div');copy.append(uiElement('b','Bem-vindo ao PipaKlub!'),uiElement('span','Treine, explore e encontre novos parceiros.'));welcome.append(copy);courtyard.append(welcome);
 const footer=courtyard.querySelector('.home-footer');footer.className='plaza-footer';$('homeMotion').className='plaza-motion';
 const residents=$('homeResidents');residents.setAttribute('aria-live','polite');footer.append(uiElement('small','Clique no caminho para passear.','plaza-walk-hint'));
 const destinations=$('homeDestinations');destinations.replaceChildren();
 for(const [action,label,x,y]of [['playGroup','Clube · Jogar',49,43],['summon','Ateliê · Invocação',17,52],['shop','Banca de linhas',74,53],['professor','Sr. Assis',31,61]]){
  const b=uiElement('button',undefined,'scene-destination');b.dataset.homeAction=action;b.style.left=x+'%';b.style.top=y+'%';b.style.setProperty('--destination-x',x+'%');b.style.setProperty('--destination-y',y+'%');b.append(uiElement('span',label));b.setAttribute('aria-label',label);plazaAction(b,()=>action==='playGroup'?(openHomeMenu(),renderHomeMenu('playGroup')):homeActions[action]());destinations.append(b);
 }
 $('courtyardStage').addEventListener('click',event=>{
  if(homeArt.world)return;
  if(event.target.closest('button')||courtyard.inert||!$('journeyDialog').hidden||!$('partnerChoice').hidden||!playerAccount||mode)return;
  const r=canvas.getBoundingClientRect();plazaActor.target=plazaPolicy.point((event.clientX-r.left)*1536/r.width,(event.clientY-r.top)*1024/r.height);
  if(art.reduced&&!homeMotionPaused){Object.assign(plazaActor,plazaActor.target);Object.assign(plazaFollower,plazaPolicy.point(plazaActor.x+68,plazaActor.y+8));}
 });
 refreshPlazaHUD();
}
function refreshPlazaHUD(){
 if(!$('plazaXP')||!playerAccount)return;
 const p=plazaPolicy.profile(playerAccount.profile);$('plazaLevel').textContent='Pipeiro · Nv. '+p.level;$('plazaXPLabel').textContent=p.xp.toLocaleString('pt-BR')+' XP';$('plazaXPLabel').title=p.xp+' / '+p.next+' XP';$('plazaXPFill').style.width=p.percent+'%';$('plazaXP').setAttribute('aria-valuenow',String(Math.round(p.percent)));$('plazaXP').setAttribute('aria-valuetext',p.xp+' de '+p.next+' XP · Nível '+p.level);
 $('plazaCoins').textContent=Number(trailProgress.coins||0).toLocaleString('pt-BR');
 const next=firstOpenStage(),trail=trails.trails[next?.trailIndex];updatePlazaMission();
 const district=homeArt.districts[next?.trailIndex||0];$('plazaDistrictName').textContent=district?.name||'Cidade dos ventos';const im=homeArt.images['district-'+(trail?.id||'morro')]||homeArt.images.city;$('plazaDistrictImage').src=im.url;
 if(plazaActor.owner!==playerAccount.profile.id){Object.assign(plazaActor,{x:735,y:655,target:{x:735,y:655},direction:3,owner:playerAccount.profile.id});Object.assign(plazaFollower,{x:805,y:660});}
 refreshWorldHUD();
}
function drawPlazaScene(g,t,dt){
 if(!homeArt.plaza)return;
 const motion=!homeMotionPaused&&!art.reduced,a=plazaActor,dx=a.target.x-a.x,dy=a.target.y-a.y,d=Math.hypot(dx,dy),walking=motion&&d>3;
 if(walking){const step=Math.min(d,dt*150);Object.assign(a,plazaPolicy.point(a.x+dx/d*step,a.y+dy/d*step));a.direction=Math.abs(dx)>Math.abs(dy)?dx<0?1:2:dy<0?3:0;}
 const atlas=homeImages.get('plaza-kael'),frames=homeArt.plaza.actor.frames;
 const shadow=(x,y,r)=>{g.fillStyle='#17394235';g.beginPath();g.ellipse(x,y-2,r,6,0,0,Math.PI*2);g.fill()};
 const human=(x,y,direction,height,walk)=>{if(!atlas)return;const f=frames[direction+(walk&&Math.floor(t/180)%2?4:0)],b=f.bounds,scale=height/380;shadow(x,y,18);g.drawImage(atlas,f.x,f.y,f.w,f.h,x-(b.x+b.w/2)*scale,y-(b.y+b.h)*scale,f.w*scale,f.h*scale);};
 // The professor remains an actual actor and destination, rather than being painted into the map.
 shadow(465,625,20);art.draw(g,'sr-assis-poses','welcome',430,525,72,100,true);
 const seq=art.atlases.nozinho?.animations?.idle;if(seq)art.draw(g,'nozinho',seq[motion?Math.floor(t/180)%seq.length:0],504,586,47,47,true);
 const equipped=playerAccount?.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),showPartner=!['arrival','choose'].includes(journey?.phase);
 const target=plazaPolicy.point(a.x+68,a.y+8);if(motion){const f=1-Math.exp(-dt*5);plazaFollower.x+=(target.x-plazaFollower.x)*f;plazaFollower.y+=(target.y-plazaFollower.y)*f;}
 const partner=()=>{if(!equipped||!showPartner)return;const p=plazaFollower;shadow(p.x,p.y,20);if(typeof drawPipamonGlow==='function')drawPipamonGlow(g,eng.pipamons.progress(equipped.pipamon_xp).level,t,p.x,p.y-36,32,true,!motion);art.creature(g,equipped.model.color,t,p.x-36,p.y-72,72,{soul:equipped.model.soul,facing:a.direction===1?-1:1,animate:motion,input:{x:walking?(a.direction===1?-1:1):0}});};
 if(plazaFollower.y<a.y)partner();human(a.x,a.y,a.direction,87,walking);if(plazaFollower.y>=a.y)partner();
}
function openPlazaMissions(){
 const origin=document.activeElement;
 const next=firstOpenStage(),trail=trails.trails[next?.trailIndex],m=currentPlazaMission();
 modal('Seu próximo voo','<div id="plazaMissionBody" class="plaza-mission-list"></div>','Voltar ao passeio','Missões do clube');
 const body=$('plazaMissionBody');body.append(uiElement('h3',m.title),uiElement('p',m.body));
 for(const district of trails.trails.filter(t=>!trails.demo||t.id==='morro')){const finished=district.stages.filter(s=>trailProgress.stars[s.id]).length,row=uiElement('div',undefined,'plaza-mission-row');row.append(uiElement('b',district.name),uiElement('span',finished+' / '+district.stages.length+' lugares vencidos'));body.append(row);}
 const button=uiElement('button',m.action==='demo'?'Ver conclusão da demo':m.action==='professor'?'Falar com o Sr. Assis':'Abrir mapa da cidade','primary');button.onclick=()=>{closeModal();homeActions[m.action]()};body.append(button);
 modalReturnFocus=origin;button.focus({preventScroll:true});
}
async function openPlazaBag(){
 const origin=document.activeElement;
 modal('Sua mochila','<p id="plazaBagStatus" role="status">Buscando suas rabiolas…</p><div id="plazaBagItems" class="plaza-bag-items"></div>','Voltar ao passeio','Itens da conta');
 const container=$('plazaBagItems'),status=$('plazaBagStatus'),owner=playerAccount?.profile.id;
 modalReturnFocus=origin;$('dialogAction').focus({preventScroll:true});
 try{
  const response=await accountRequest('summon',{action:'inventory',sessionId:summonSession});
  if(owner!==playerAccount?.profile.id||$('plazaBagItems')!==container||$('modal').style.display!=='flex')return;
  const tails=(response.summon?.tails||[]).filter(t=>['ready','damaged'].includes(t.status));status.textContent=tails.length?tails.length+' rabiola'+(tails.length===1?'':'s')+' na mochila.':'Sua mochila está vazia. Encontre rabiolas nos duelos contra Pipamons selvagens.';
  const groups=new Map();for(const tail of tails){const key=tail.modelId+':'+tail.status;if(!groups.has(key))groups.set(key,{tail,count:0});groups.get(key).count++;}
  for(const {tail,count}of groups.values()){const card=uiElement('article',undefined,'plaza-bag-item');card.append(summonTailArt(tail.modelId),uiElement('b','Rabiola de '+summonDisplayName(tail)),uiElement('span','×'+count,'plaza-bag-quantity'),uiElement('small',tail.status==='ready'?'Pronta para invocação':'Danificada'));container.append(card);}
  const go=uiElement('button','Visitar o invocador','primary');go.onclick=()=>{closeModal();homeActions.summon()};container.after(go);
 }catch(e){if(owner!==playerAccount?.profile.id||$('plazaBagItems')!==container)return;status.textContent=e.message||'Não foi possível carregar a mochila.';const retry=uiElement('button','Tentar novamente','secondary');retry.onclick=openPlazaBag;container.append(retry);}
}
initPlaza();
