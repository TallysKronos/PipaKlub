const school=createSchool(eng),SCHOOL_KEY='pipaSchoolV1',TOUR_KEY='pipaMenuTourV1';
let schoolRun=null,schoolDone=[],schoolTourStep=-1,schoolLastNotice='';
try{const saved=JSON.parse(localStorage.getItem(SCHOOL_KEY)||'[]');if(Array.isArray(saved))schoolDone=saved.filter(id=>school.lessons.some(l=>l.id===id));}catch{}
const schoolHub=document.createElement('div');schoolHub.id='schoolHub';schoolHub.className='overlay';schoolHub.hidden=true;
schoolHub.innerHTML='<section class="panel school-card" role="dialog" aria-modal="true" aria-labelledby="schoolTitle"><button class="close" id="schoolClose" aria-label="Fechar escola">×</button><div class="school-heading"><canvas id="schoolAssis" width="90" height="100" aria-label="Sr. Assis"></canvas><div><div class="eyebrow">Um passo de cada vez</div><h2 id="schoolTitle">Escola do Sr. Assis</h2><p>Treine à vontade. Aqui você não perde pipas e não gasta itens.</p></div></div><p id="schoolProgress" role="status"></p><div id="schoolLessons" class="school-lessons"></div><div class="school-links"><button class="secondary" id="schoolTour">Conhecer os menus</button><button class="secondary" id="schoolTalk">Conversar com o Sr. Assis</button><button class="primary" id="schoolMorro">Ir para o Morro ▶</button></div><p class="collection-info">Seu avanço nas lições fica salvo neste aparelho.</p></section>';
document.body.append(schoolHub);
const schoolCoach=document.createElement('section');schoolCoach.id='schoolCoach';schoolCoach.className='school-coach';schoolCoach.hidden=true;schoolCoach.setAttribute('aria-label','Orientação do Sr. Assis');
schoolCoach.innerHTML='<div class="eyebrow" id="schoolNumber"></div><b id="schoolLessonName"></b><p id="schoolHint"></p><p id="schoolNotice" role="status" aria-live="polite"></p><div class="school-controls"><button class="secondary" id="schoolRetry">Recomeçar</button><button class="secondary" id="schoolExit">Voltar à escola</button><button class="primary" id="schoolNext" disabled>Próxima lição ▶</button></div>';
document.body.append(schoolCoach);
const schoolTour=document.createElement('div');schoolTour.id='schoolTourOverlay';schoolTour.hidden=true;schoolTour.className='school-tour';
schoolTour.innerHTML='<div id="schoolSpot" class="school-spot" aria-hidden="true"></div><section class="panel school-tour-card" role="dialog" aria-modal="true" aria-labelledby="schoolTourTitle"><div class="eyebrow" id="schoolTourCount"></div><h2 id="schoolTourTitle"></h2><p id="schoolTourText"></p><div class="school-controls"><button class="secondary" id="schoolTourSkip">Pular tour</button><button class="secondary" id="schoolTourBack">Voltar</button><button class="primary" id="schoolTourNext">Continuar ▶</button></div></section>';
document.body.append(schoolTour);
const schoolTourStops=[
 ['accountButton','Seu lugar no clube','Entre na conta para guardar suas pipas. Em Minha conta você encontra coleção, trocas, invocação e seu perfil.'],
 ['trailsButton','Comece pelo Morro','As Trilhas são desafios em sequência. Comece na etapa 1 do Morro; as vitórias abrem novos caminhos.'],
 ['quickButton','Um encontro no céu','Partida rápida procura jogadores e completa a sala com bots quando necessário.'],
 ['practice','Treine sem pressa','O treino livre deixa você experimentar movimentos e habilidades contra bots.'],
 ['dexButton','Conheça os Pipamon','A Pipa Dex reúne criaturas, histórias e rabiolas. Consultar a Dex não entrega pipas à sua conta.'],
 ['meetAssis','Eu fico por aqui','Volte à Escola do Sr. Assis quando quiser repetir uma lição. Agora vamos praticar!']
];
function closeSchool(){schoolHub.hidden=true;schoolHub.style.display='none';$('meetAssis').focus?.();}
function renderSchool(){
 $('schoolProgress').textContent=schoolDone.length+' de '+school.lessons.length+' lições concluídas';
 $('schoolLessons').replaceChildren(...school.lessons.map((lesson,i)=>{const b=document.createElement('button');b.type='button';b.className='school-lesson secondary';b.textContent=(schoolDone.includes(lesson.id)?'✓ ':'')+(i+1)+'. '+lesson.name;b.onclick=()=>startSchoolLesson(i);return b;}));
}
function openSchool(){
 if(!requireClubAccount('Escola do Sr. Assis'))return;
 if(mode){toast('Saia da partida para visitar a escola.');return;}
 if(introductionOpen)closeIntroduction();if(accountModal.style.display==='flex')closeAccount();
 closeTrails();keys={};resetPointer();renderSchool();schoolHub.hidden=false;schoolHub.style.display='flex';$('schoolClose').focus?.();
 art.load('sr-assis-expressions').then(()=>{const c=$('schoolAssis'),context=c.getContext('2d');if(!context)return;context.clearRect(0,0,c.width,c.height);art.draw(context,'sr-assis-expressions','speaking',0,0,c.width,c.height,true);});
}
function startSchoolLesson(index){
 if(!requireClubAccount('Escola do Sr. Assis'))return;
 if(mode&& !schoolRun)return;
 if(schoolRun){schoolRun=null;leave();}
 closeSchool();closeSchoolTour(false);trailStage=null;
 schoolRun=school.create(index,Date.now());enter(schoolRun.state,'you','practice');
 schoolCoach.hidden=false;document.body.classList.add('in-school');schoolLastNotice='';
 const lesson=school.lessons[index];$('schoolNumber').textContent='Escola · lição '+(index+1)+' de '+school.lessons.length;
 $('schoolLessonName').textContent=lesson.name;$('schoolHint').textContent=lesson.hint;$('schoolNotice').textContent='';$('schoolNext').disabled=true;
 $('schoolNext').textContent=index===school.lessons.length-1?'Ir para o Morro ▶':'Próxima lição ▶';
 setText('liveLabel','Escola do Sr. Assis');setText('arenaMode','Exercício livre · sem perdas');setText('modeLabel','ESCOLA');
 $('sky').focus?.();
}
function stepSchool(now){
 if(!schoolRun)return;school.tick(schoolRun,input(),now);
 const lesson=school.lessons[schoolRun.index],notice=schoolRun.complete?lesson.success:schoolRun.warning||(schoolRun.index===5?'Solte o ataque e acompanhe sua energia subir até 90%.':'Busque o círculo verde para preparar o cruzamento.');
 if(notice!==schoolLastNotice){schoolLastNotice=notice;$('schoolNotice').textContent=notice;}
 if(schoolRun.complete&&!schoolRun.saved){
  schoolRun.saved=true;if(!schoolDone.includes(lesson.id)){schoolDone.push(lesson.id);try{localStorage.setItem(SCHOOL_KEY,JSON.stringify(schoolDone));}catch{}}
  keys={};resetPointer();$('schoolNext').disabled=false;$('schoolNext').focus?.();
 }
}
function drawSchoolGuide(){
 if(!schoolRun||schoolRun.complete||schoolRun.index>=4)return;
 const {x,y}=schoolRun.target;ctx.save();ctx.strokeStyle='#26704b';ctx.fillStyle='#ffffffb0';ctx.lineWidth=3;ctx.setLineDash([5,5]);ctx.beginPath();ctx.arc(x,y,30,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.setLineDash([]);ctx.fillStyle='#183e38';ctx.font='800 17px Nunito,sans-serif';ctx.textAlign='center';ctx.fillText('Mire aqui',x,y-42);ctx.restore();
}
function exitSchoolLesson(){schoolRun=null;schoolCoach.hidden=true;document.body.classList.remove('in-school');}
const schoolOriginalLeave=leave;
leave=function(){exitSchoolLesson();schoolOriginalLeave();};
function goSchoolMorro(){if(schoolRun)leave();closeSchool();closeSchoolTour(false);trailPick=trails.stages[0].id;openTrails();}
$('schoolRetry').onclick=()=>{if(schoolRun)startSchoolLesson(schoolRun.index);};
$('schoolExit').onclick=()=>{leave();openSchool();};
$('schoolNext').onclick=()=>{if(!schoolRun?.complete)return;const next=schoolRun.index+1;if(next<school.lessons.length)startSchoolLesson(next);else goSchoolMorro();};
$('schoolClose').onclick=closeSchool;$('schoolMorro').onclick=goSchoolMorro;
$('schoolTalk').onclick=()=>{closeSchool();openIntroduction();};
schoolHub.onclick=e=>{if(e.target===schoolHub)closeSchool();};
function positionSchoolSpot(){
 if(schoolTourStep<0)return;const target=$(schoolTourStops[schoolTourStep][0]);target.scrollIntoView?.({block:'nearest'});const r=target.getBoundingClientRect();
 const card=schoolTour.querySelector('.school-tour-card'),above=r.top>(document.documentElement.clientHeight||600)/2;card.style.top=above?'24px':'auto';card.style.bottom=above?'auto':'24px';
 Object.assign($('schoolSpot').style,{left:r.left-6+'px',top:r.top-6+'px',width:r.width+12+'px',height:r.height+12+'px'});
}
function renderSchoolTour(){
 const [,title,text]=schoolTourStops[schoolTourStep];$('schoolTourCount').textContent='Conheça o clube · '+(schoolTourStep+1)+' de '+schoolTourStops.length;
 $('schoolTourTitle').textContent=title;$('schoolTourText').textContent=text;$('schoolTourBack').disabled=schoolTourStep===0;
 $('schoolTourNext').textContent=schoolTourStep===schoolTourStops.length-1?'Começar as lições ▶':'Continuar ▶';positionSchoolSpot();$('schoolTourNext').focus?.();
}
function openSchoolTour(){if(mode||!requireClubAccount('Escola do Sr. Assis'))return;if(introductionOpen)closeIntroduction();closeSchool();schoolTourStep=0;schoolTour.hidden=false;keys={};renderSchoolTour();}
function closeSchoolTour(remember=true){if(schoolTourStep<0)return;schoolTourStep=-1;schoolTour.hidden=true;if(remember)try{localStorage.setItem(TOUR_KEY,'done');}catch{}}
function firstSchoolVisit(){if(!requireClubAccount('Escola do Sr. Assis'))return;openSchool();let seen=false;try{seen=localStorage.getItem(TOUR_KEY)==='done';}catch{}if(!seen)openSchoolTour();}
$('schoolTour').onclick=openSchoolTour;
$('schoolTourBack').onclick=()=>{schoolTourStep=Math.max(0,schoolTourStep-1);renderSchoolTour();};
$('schoolTourNext').onclick=()=>{if(schoolTourStep===schoolTourStops.length-1){closeSchoolTour();openSchool();}else{schoolTourStep++;renderSchoolTour();}};
$('schoolTourSkip').onclick=()=>{closeSchoolTour();openSchool();};
addEventListener('resize',positionSchoolSpot);
addEventListener('keydown',e=>{
 const panel=schoolTourStep>=0?schoolTour:!schoolHub.hidden?schoolHub:null;
 if(!panel)return;
 if(e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();if(schoolTourStep>=0){closeSchoolTour();openSchool();}else closeSchool();}
 if(e.key==='Tab'){const buttons=[...panel.querySelectorAll('button')].filter(b=>!b.disabled),first=buttons[0],last=buttons.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus?.();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus?.();}}
},true);
$('meetAssis').textContent='Escola do Sr. Assis';$('meetAssis').onclick=firstSchoolVisit;
const schoolIntroNext=$('assisNext').onclick;
$('assisNext').onclick=()=>{if(introductionStep===ART_CONFIG.intro.steps.length-1){closeIntroduction();firstSchoolVisit();}else schoolIntroNext();};
