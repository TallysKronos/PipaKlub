'use strict';
const chart = JSON.parse(document.getElementById('chart-data').textContent);
const nodes = new Map(chart.nodes.map(node => [node.id, node]));
const stages = chart.terminology.stages;
const routes = {base:'BASE DA FAMÍLIA',attack:'A / ATAQUE',speed:'B / VELOCIDADE',intelligence:'C / INTELIGÊNCIA',special:'REMONTA ESPECIAL',story:'CARRETEL NEGRO'};
const accents = {base:'#3378bc',attack:'#b47a31',speed:'#227f8b',intelligence:'#6c67a0'};
let selected = 'azulao';
let current = 'azulao';
let configuration = null;
let history = ['azulao'];
let checks = [];
const $ = id => document.getElementById(id);
function el(tag, text, cls){const item=document.createElement(tag);if(text!==undefined)item.textContent=text;if(cls)item.className=cls;return item;}
function stageLabel(node){return `Estágio ${['I','II','III','IV'][node.stage-1]} · ${stages[node.stage-1]}`;}
function imageFor(node){
  if(!node.art){const holder=el('div',undefined,'thumb');holder.append(el('span',chart.modelSheets?.[node.id]?'Concept disponível na ficha':chart.conceptSheets?.[node.id]?'Folha A/B/C disponível na ficha':'Brief visual · arte a criar','unmade'));return holder;}
  const holder=el('div',undefined,'thumb');
  if(node.art.startsWith('branch-')){
    const window=el('div',undefined,'art-window');window.style.setProperty('--shift',node.art==='branch-b'?'-50%':'-83.333%');
    const img=el('img');img.src=chart.sources.branches;img.alt=`Recorte de apresentação do concept ${node.art==='branch-b'?'B':'C'} aprovado`;window.append(img);holder.append(window);
  }else{const img=el('img');img.src=chart.sources[node.art];img.alt=node.name+' · arte existente';holder.append(img);}
  return holder;
}
function choose(id){selected=id;checks=nodes.get(id).requirements.map(()=>false);renderSelection();}
function drawCards(){
  for(const node of chart.nodes){
    const button=el('button',undefined,node.kind==='stage'?'node':'extra-card'+(node.kind==='state'?' story':''));button.type='button';button.dataset.node=node.id;button.setAttribute('aria-pressed','false');button.addEventListener('click',()=>choose(node.id));
    if(node.kind==='stage'){
      button.style.gridColumn=String(node.column);button.style.gridRow=String(node.row);button.style.setProperty('--accent',accents[node.route]);
      button.append(el('span',routes[node.route],'route'),imageFor(node),el('h3',node.name));
      button.append(el('p',node.nameStatus==='proposto'?'Nome e/ou arte propostos':node.status==='concept-aprovado'?'Arquitetura aprovada':'Arte e identidade existentes','note'));
      button.append(el('p',node.tagline,'description'));$('nodes').append(button);
    }else{
      button.append(el('span',node.kind==='state'?'Estado · história':'Proposta · mesmo estágio','tag '+(node.kind==='state'?'':'proposed')),el('h3',node.name),el('p',node.tagline));
      $(node.kind==='state'?'story':'configurations').append(button);
    }
  }
}
function renderDetails(){
  const node=nodes.get(selected), root=$('details');root.replaceChildren();
  root.append(el('p',routes[node.route]+' / '+stageLabel(node),'eyebrow'),el('h2',node.name),el('p',node.tagline,'detail-intro'));
  root.append(el('span',node.mechanicStatus,'tag '+(node.status==='proposta'?'proposed':'existing')));
  if(node.art&&!chart.modelSheets?.[node.id]){
    const ref=el('div',undefined,'reference');const picture=imageFor(node);picture.classList.remove('thumb');ref.append(picture);
    const link=el('a','Abrir referência original ↗');link.href=node.art.startsWith('branch-')?chart.sources.branches:chart.sources[node.art];link.target='_blank';link.rel='noopener';const caption=el('p');caption.append(link);ref.append(caption);root.append(ref);
  }
  const modelSheet=chart.modelSheets?.[node.id];
  const explorationSheet=chart.conceptSheets?.[node.id];
  if(modelSheet||explorationSheet){
    const ref=el('figure',undefined,'reference');const img=el('img');img.src=modelSheet||explorationSheet;img.alt=modelSheet?`${node.name}: concept atual em pipa viva / 2D mangá`:`${node.name}: três alternativas A/B/C em revisão`;img.style.maxHeight='none';ref.append(img);const caption=el('figcaption',modelSheet?'Concept atual em avaliação. Arte criada não significa aprovação, rig ou integração. ':'Exploração de silhuetas e cores preliminares. ');const link=el('a','Ampliar folha ↗');link.href=img.getAttribute('src');link.target='_blank';link.rel='noopener';caption.append(link);ref.append(caption);root.append(ref);
  }
  const swatches=el('div',undefined,'swatches');swatches.setAttribute('aria-label','Paleta de referência ou proposta');for(const color of node.palette){const s=el('span');s.style.backgroundColor=color;s.title=color;swatches.append(s);}root.append(swatches);
  const body=el('div',undefined,'detail-body');for(const [title,key] of [['Identidade','identity'],['O que muda','change'],['Função proposta','role'],['Limite da forma','tradeoff'],['Gesto característico','action'],['Direção para a prancha','brief']])body.append(el('h3',title),el('p',node[key]));root.append(body);
}
function canReach(node){return chart.edges.some(edge=>edge.from===current&&edge.to===node.id&&edge.kind!=='possession');}
function renderSimulator(){
  const now=nodes.get(current), node=nodes.get(selected), reachable=canReach(node);
  $('current-name').textContent=now.name;$('current-stage').textContent=stageLabel(now);
  $('current-config').textContent=configuration?'Configuração: '+nodes.get(configuration).name:'Sem configuração especial';
  $('path-history').textContent='Percurso: '+history.map(id=>nodes.get(id).name).join(' → ');
  $('remove-config').hidden=!configuration;
  $('return').hidden=history.length<=1;
  $('eligibility').textContent=node.kind==='state'?'Estado narrativo. Não disponível por Remonta.':current===selected?'Este é o corpo atual. Selecione uma forma ligada a ele.':reachable?'Ligação disponível na simulação. Confira os critérios propostos abaixo.':'Esta forma não está ligada diretamente ao corpo atual. Siga o chart ou retorne pela oficina.';
  const options=$('requirement-options');options.replaceChildren();
  node.requirements.forEach((text,i)=>{const label=el('label'),input=el('input');input.type='checkbox';input.checked=Boolean(checks[i]);input.disabled=!reachable;input.addEventListener('change',()=>{checks[i]=input.checked;updateButton();});label.append(input,el('span',text));options.append(label);});
  $('requirements').hidden=!node.requirements.length||node.kind==='state';
  $('simulate').textContent=node.kind==='configuration'?'Testar Remonta Especial':'Testar Remonta';updateButton();
}
function updateButton(){const node=nodes.get(selected);$('simulate').disabled=!canReach(node)||!node.requirements.length||!node.requirements.every((_,i)=>checks[i])||selected===configuration;}
function renderSelection(){
  document.querySelectorAll('[data-node]').forEach(button=>{button.setAttribute('aria-pressed',String(button.dataset.node===selected));button.classList.toggle('current-node',button.dataset.node===current);});
  renderDetails();renderSimulator();drawEdges();
}
function drawEdges(){
  const svg=$('connections'), rect=$('nodes').getBoundingClientRect();svg.replaceChildren();svg.setAttribute('viewBox',`0 0 ${rect.width} ${rect.height}`);
  const ancestors=new Set();let cursor=selected;while(cursor){ancestors.add(cursor);const incoming=chart.edges.find(edge=>edge.to===cursor&&edge.kind==='reweaving');cursor=incoming?.from;}
  for(const edge of chart.edges.filter(e=>e.kind==='reweaving')){
    const a=document.querySelector(`[data-node="${edge.from}"]`).getBoundingClientRect(),b=document.querySelector(`[data-node="${edge.to}"]`).getBoundingClientRect();
    const x1=a.right-rect.left,y1=a.top+a.height/2-rect.top,x2=b.left-rect.left,y2=b.top+b.height/2-rect.top,mid=(x1+x2)/2;
    const path=document.createElementNS('http://www.w3.org/2000/svg','path');path.setAttribute('d',`M ${x1} ${y1} H ${mid} V ${y2} H ${x2}`);path.setAttribute('class','edge'+(edge.proposal?' proposal':'')+(ancestors.has(edge.from)&&ancestors.has(edge.to)?' active':''));svg.append(path);
  }
}
function start(id){current=id;configuration=null;history=[id];$('feedback').textContent='Novo percurso de teste. Nenhum save do jogo foi alterado.';choose(id);}
$('start-base').addEventListener('click',()=>start('azulao'));
$('start-small').addEventListener('click',()=>start('azulim'));
$('simulate').addEventListener('click',()=>{
  if($('simulate').disabled)return;const node=nodes.get(selected);
  if(node.kind==='configuration'){configuration=node.id;$('feedback').textContent='Remonta Especial simulada. O corpo continua Pipa · II; a alma e a rota não foram trocadas.';}
  else{current=node.id;configuration=null;history.push(current);$('feedback').textContent=`Remonta simulada: ${node.name}. A mesma alma permanece na rabiola.`;}
  checks=[];renderSelection();
});
$('remove-config').addEventListener('click',()=>{configuration=null;$('feedback').textContent='Configuração retirada no teste; Azulão continua no mesmo estágio.';renderSelection();});
$('return').addEventListener('click',()=>{if(history.length<=1)return;history.pop();current=history[history.length-1];configuration=null;$('feedback').textContent='Retorno pela oficina simulado. Nome, memória e vínculo preservados; XP e custos não são definidos nesta prova.';choose(current);});
drawCards();renderSelection();window.addEventListener('resize',drawEdges);document.fonts?.ready.then(drawEdges);
