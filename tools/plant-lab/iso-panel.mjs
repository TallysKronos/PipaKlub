import {campaignFloorOptions,drawIso,isoTerrain,pickIso,studioIso,paintCampaignFloor,isMovableDecoration,moveCampaignDecoration} from './isometric.mjs';

async function getJson(url){
  const response=await fetch(url);
  if(!response.ok)throw new Error(await response.text());
  return response.json();
}

export function installIsoPanel({current,openProject,edit,walk,sprite,artwork=()=>false}){
  const byId=id=>document.getElementById(id);
  const workspace=byId('isoWorkspace'),canvas=byId('isoCanvas'),select=byId('isoMap');
  const title=byId('isoTitle');
  const info=byId('isoInfo'),source=byId('isoSource');
  const search=byId('isoSearch');
  const brushes=byId('isoBrushes'),exportButton=byId('isoExport');
  const decor=byId('isoDecor'),decorLabel=byId('isoDecorLabel');
  const undoButton=byId('isoUndo');
  const saveButton=byId('isoSave');
  const openProjectButton=byId('isoOpenProject');
  const copies=new Map(),histories=new Map(),revisions=new Map();
  const geometry=byId('isoGeometry');
  let saving=false;
  geometry.onclick=()=>{geometry.setAttribute('aria-pressed',String(geometry.getAttribute('aria-pressed')!=='true'));render();};
  let brush='',paintPointer=null,stroke=null;
  let map,tiles,transform,highlight=-1,zoom=1,pan=[0,0],drag,request=0,catalog;
  const projectControls=document.querySelectorAll('.toolrail,.inspector,.asset-browser,.tool-options,.history-actions,.run-actions,.menubar button:not(#openCampaign)');

  function updateMode(campaign){
    document.body.classList.toggle('campaign-map-open',campaign);
    for(const control of projectControls)control.inert=campaign;
  }

  const searchKey=value=>value.normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase();
  function showCatalog(){
    const active=select.value,query=searchKey(search.value.trim());
    select.options.length=1;
    for(const item of catalog??[]){
      const label=`${item.name??item.id} · ${item.id}`;
      if(item.id===active||searchKey(label).includes(query))select.add(new Option(label,item.id));
    }
    select.value=active;
  }
  search.oninput=showCatalog;

  function chooseBrush(material){
    brush=material;
    if(material)decor.value='';
    for(const button of brushes.querySelectorAll('button')){
      button.setAttribute('aria-pressed',String(button.dataset.brush===material&&!decor.value));
    }
    canvas.dataset.mode=material==='pan'?'pan':material?'paint':'inspect';
  }

  function showBrushes(){
    const labels={piso:'Piso',grama:'Grama',terra:'Terra',calcada:'Calçada',asfalto:'Asfalto'};
    for(const [material,label] of [['','Inspecionar'],['pan','Mover vista'],...campaignFloorOptions(map).map(key=>[key,labels[key]])]){
      const button=document.createElement('button');
      button.type='button';
      button.dataset.brush=material;
      button.textContent=label;
      button.onclick=()=>{decor.value='';chooseBrush(material);};
      brushes.append(button);
    }
    chooseBrush('');
  }

  function updateSaveState(){
    const pending=histories.get(select.value)?.length??0;
    undoButton.disabled=saving||!pending;
    saveButton.disabled=saving||!pending;
    saveButton.textContent=saving?'Salvando…':pending?`Salvar no jogo (${pending})`:'Salvar no jogo';
  }

  function render(){
    if(!map||workspace.hidden)return;
    const rect=canvas.getBoundingClientRect();
    canvas.width=Math.max(1,Math.round(rect.width));
    canvas.height=Math.max(1,Math.round(rect.height));
    transform=drawIso(canvas,map,tiles,{highlight,zoom,pan,sprite,artwork:!select.value&&artwork(),geometry:geometry.getAttribute('aria-pressed')==='true'});
  }

  async function loadMap(){
    const generation=++request,id=select.value;
    updateMode(Boolean(id));
    geometry.hidden=Boolean(id)||!artwork();
    geometry.setAttribute('aria-pressed','false');
    title.textContent=id?(select.selectedOptions[0]?.textContent??id):'Mapas da campanha';
    highlight=-1;zoom=1;pan=[0,0];map=null;transform=null;source.hidden=true;
    brushes.hidden=decorLabel.hidden=undoButton.hidden=exportButton.hidden=saveButton.hidden=openProjectButton.hidden=true;
    brushes.replaceChildren();
    brush='';paintPointer=null;stroke=null;drag=null;
    decor.options.length=1;
    canvas.getContext('2d').clearRect(0,0,canvas.width,canvas.height);
    info.textContent='Carregando mapa…';
    try{
      let next=id?copies.get(id):studioIso(current());
      if(id&&!next){
        const response=await fetch('/api/campaign-maps/'+id,{cache:'no-store'});
        if(!response.ok)throw new Error(await response.text());
        next=await response.json();
        revisions.set(id,response.headers.get('X-Map-Revision'));
      }
      if(generation!==request||workspace.hidden)return;
      if(id&&!copies.has(id)){
        copies.set(id,next);
        histories.set(id,[]);
      }
      map=next;tiles=isoTerrain(map);
      source.hidden=!id;
      if(id){source.href='/api/campaign-maps/'+id;source.download=id+'.json';}
      info.textContent=id
        ? 'Escolha um piso e pinte no mapa. Use a roda para aproximar e salve quando terminar.'
        : 'Projeto atual · clique para aplicar o pincel de piso ou relevo · setas testam Kael · roda aproxima · arraste com o botão central para mover.';
      if(id){
        openProjectButton.hidden=false;
        brushes.hidden=undoButton.hidden=exportButton.hidden=saveButton.hidden=false;
        for(const piece of map.pieces.filter(isMovableDecoration)){
          decor.add(new Option(`${piece.name??piece.asset} · ${piece.u}, ${piece.v}`,String(piece.id)));
        }
        decorLabel.hidden=decor.options.length===1;
        showBrushes();
        updateSaveState();
      }
      render();
    }catch(error){if(generation===request)info.textContent='Erro ao abrir mapa: '+error.message;}
  }

  async function openWorkspace(event,initialMap=''){
    const menu=event?.currentTarget.closest('details');
    if(menu)menu.open=false;
    workspace.hidden=false;
    search.focus();
    loadMap();
    if(catalog)return;
    try{
      catalog=await getJson('/api/campaign-maps');
      showCatalog();
      if(initialMap&&catalog.some(entry=>entry.id===initialMap)){
        select.value=initialMap;
        await loadMap();
      }
    }catch(error){info.textContent='Catálogo da campanha indisponível: '+error.message;}
  }
  byId('isoOpen').onclick=byId('openCampaign').onclick=openWorkspace;
  function closeWorkspace(){
    workspace.hidden=true;
    updateMode(false);
    byId('isoOpen').focus();
  }
  byId('isoClose').onclick=closeWorkspace;
  openProjectButton.onclick=async()=>{
    if(!map||!select.value||saving)return;
    openProjectButton.disabled=select.disabled=true;
    try{
      await openProject(map);
      closeWorkspace();
    }catch(error){info.textContent='Não foi possível abrir o projeto · '+error.message;}
    finally{openProjectButton.disabled=select.disabled=false;}
  };
  byId('isoFit').onclick=()=>{zoom=1;pan=[0,0];render();};
  select.onchange=loadMap;
  decor.onchange=()=>{
    chooseBrush('');
    if(decor.value)info.textContent='Clique no destino da decoração. Escolha uma célula livre na mesma altura.';
  };
  function undoCopy(){
    const history=histories.get(select.value);
    if(saving||!map||map!==copies.get(select.value)||!history?.length)return;
    const group=history.at(-1).stroke;
    do{history.pop().undo();}while(group&&history.at(-1)?.stroke===group);
    tiles=isoTerrain(map);
    updateSaveState();
    info.textContent='Última ação desfeita.';
    render();
  }
  undoButton.onclick=undoCopy;
  async function saveCopy(){
    const id=select.value,history=histories.get(id);
    if(saving||map!==copies.get(id)||!history?.length)return;
    saving=true;select.disabled=true;updateSaveState();
    try{
      const response=await fetch('/api/campaign-maps/'+id,{
        method:'PUT',
        headers:{'Content-Type':'application/json'},
        body:JSON.stringify({revision:revisions.get(id),edits:history.map(entry=>entry.edit)})
      });
      if(!response.ok)throw new Error(await response.text());
      revisions.set(id,(await response.json()).revision);
      history.length=0;
      info.textContent='Salvo no jogo · '+id+'.json';
    }catch(error){info.textContent='Falha ao salvar · '+error.message;}
    finally{saving=false;select.disabled=false;updateSaveState();}
  }
  saveButton.onclick=saveCopy;
  window.addEventListener('beforeunload',event=>{
    if(![...histories.values()].some(history=>history.length))return;
    event.preventDefault();
    event.returnValue='';
  });
  workspace.addEventListener('keydown',event=>{
    if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='s'&&select.value){
      event.preventDefault();
      saveCopy();
    }
    if((event.ctrlKey||event.metaKey)&&!event.shiftKey&&event.key.toLowerCase()==='z'&&map===copies.get(select.value)){
      event.preventDefault();
      event.stopPropagation();
      undoCopy();
    }
  });
  exportButton.onclick=()=>{
    if(!copies.has(select.value)||map!==copies.get(select.value))return;
    const url=URL.createObjectURL(new Blob([JSON.stringify(map,null,2)+'\n'],{type:'application/json'}));
    const link=document.createElement('a');
    link.href=url;
    link.download=select.value+'.copia.json';
    link.click();
    setTimeout(()=>URL.revokeObjectURL(url),1000);
  };
  new ResizeObserver(render).observe(canvas);
  canvas.addEventListener('wheel',event=>{
    event.preventDefault();
    zoom=Math.min(5,Math.max(.6,zoom*(event.deltaY<0?1.15:1/1.15)));
    render();
  },{passive:false});
  canvas.addEventListener('pointerdown',event=>{
    if(saving||!transform)return;
    if(event.button===1||(event.button===0&&brush==='pan')){
      event.preventDefault();
      canvas.setPointerCapture(event.pointerId);
      drag=[event.clientX-pan[0],event.clientY-pan[1]];
      return;
    }
    if(event.button!==0)return;
    canvas.focus();
    if(brush&&select.value){
      paintPointer=event.pointerId;
      stroke=Symbol();
      canvas.setPointerCapture(paintPointer);
    }
    applyAt(event);
  });
  function applyAt(event,dragging=false){
    if(!transform||saving)return;
    const rect=canvas.getBoundingClientRect();
    const hit=pickIso(tiles,(event.clientX-rect.left-transform.ox)/transform.scale,(event.clientY-rect.top-transform.oy)/transform.scale);
    if(!hit||(dragging&&highlight===hit.index))return;
    highlight=hit.index;
    const entries=[...(map.pieces??[]),...(map.events??[])].filter(e=>Math.floor(e.u)===hit.u&&Math.floor(e.v)===hit.v);
    const edited=!select.value&&edit(hit,event);
    if(edited){map=studioIso(current());tiles=isoTerrain(map);}
    const paintingCopy=copies.has(select.value)&&brush!==''&&brush!=='pan';
    const oldCell=paintingCopy?structuredClone(map.cells[hit.index]):null;
    const changedCopy=paintingCopy&&paintCampaignFloor(map,hit.index,brush);
    if(changedCopy)tiles=isoTerrain(map);
    const movingCopy=copies.has(select.value)&&decor.value!=='';
    const decoration=movingCopy?map.pieces.find(item=>String(item.id)===decor.value):null;
    const previousPosition=decoration?{u:decoration.u,v:decoration.v}:null;
    const moved=movingCopy&&moveCampaignDecoration(map,decor.value,hit.u,hit.v);
    if(changedCopy||moved){
      const history=histories.get(select.value);
      const edit=changedCopy?{type:'floor',index:hit.index,material:brush}:{type:'decoration',id:decoration.id,u:hit.u,v:hit.v};
      history.push({edit,stroke,undo:()=>{
        if(changedCopy){
          map.cells[hit.index]=oldCell;
        }else{
          Object.assign(decoration,previousPosition);
          const option=[...decor.options].find(entry=>entry.value===String(decoration.id));
          if(option)option.textContent=`${decoration.name??decoration.asset} · ${decoration.u}, ${decoration.v}`;
        }
      }});
      updateSaveState();
    }
    if(moved){
      const piece=map.pieces.find(item=>String(item.id)===decor.value);
      decor.selectedOptions[0].textContent=`${piece.name??piece.asset} · ${piece.u}, ${piece.v}`;
    }
    info.textContent=`Célula ${hit.u}, ${hit.v} · cota ${map.cells[hit.index].level} · ${map.cells[hit.index].material}`
      +(entries.length?' · '+entries.map(e=>e.name??e.label??e.asset).join(', '):'')+(paintingCopy?(changedCopy?' · piso atualizado na cópia':' · piso igual ou superfície protegida'):'')+(movingCopy?(moved?' · decoração movida':' · destino ocupado ou protegido'):'');
    render();
  }
  canvas.addEventListener('keydown',event=>{
    const direction={ArrowUp:[0,-1],ArrowDown:[0,1],ArrowLeft:[-1,0],ArrowRight:[1,0]}[event.key];
    if(!direction||select.value||!map)return;
    event.preventDefault();
    map.spawn=walk(map.spawn,direction);
    render();
  });
  canvas.addEventListener('pointermove',event=>{
    if(drag){pan=[event.clientX-drag[0],event.clientY-drag[1]];render();}
    else if(event.pointerId===paintPointer)applyAt(event,true);
  });
  for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,event=>{
    drag=null;
    if(event.pointerId===paintPointer){paintPointer=null;stroke=null;}
  });
  const requestedMap=new URLSearchParams(location.search).get('mapa');
  if(requestedMap)void openWorkspace(null,requestedMap);
}
