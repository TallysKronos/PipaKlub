import {drawIso,isoTerrain,pickIso,studioIso} from './isometric.mjs';

async function getJson(url){
  const response=await fetch(url);
  if(!response.ok)throw new Error(await response.text());
  return response.json();
}

export function installIsoPanel({current,edit,walk,sprite}){
  const byId=id=>document.getElementById(id);
  const dialog=byId('isoDialog'),canvas=byId('isoCanvas'),select=byId('isoMap');
  const info=byId('isoInfo'),source=byId('isoSource');
  let map,tiles,transform,highlight=-1,zoom=1,pan=[0,0],drag,request=0,catalogLoaded=false;

  function render(){
    if(!map||!dialog.open)return;
    const rect=canvas.getBoundingClientRect();
    canvas.width=Math.max(1,Math.round(rect.width));
    canvas.height=Math.max(1,Math.round(rect.height));
    transform=drawIso(canvas,map,tiles,{highlight,zoom,pan,sprite});
  }

  async function loadMap(){
    const generation=++request,id=select.value;
    highlight=-1;zoom=1;pan=[0,0];map=null;transform=null;source.hidden=true;
    canvas.getContext('2d').clearRect(0,0,canvas.width,canvas.height);
    info.textContent='Carregando mapa…';
    try{
      const next=id?await getJson('/api/campaign-maps/'+id):studioIso(current());
      if(generation!==request||!dialog.open)return;
      map=next;tiles=isoTerrain(map);
      source.hidden=!id;
      if(id){source.href='/api/campaign-maps/'+id;source.download=id+'.json';}
      info.textContent=id
        ? `${map.w} × ${map.h} · ${map.pieces.length} objetos · ${map.events.length} eventos · mapa de campanha em leitura`
        : 'Projeto atual · clique para aplicar o pincel de piso ou relevo · setas testam Kael · roda aproxima · arraste com o botão central para mover.';
      render();
    }catch(error){if(generation===request)info.textContent='Erro ao abrir mapa: '+error.message;}
  }

  byId('isoOpen').onclick=async()=>{
    dialog.showModal();
    loadMap();
    if(catalogLoaded)return;
    try{
      const catalog=await getJson('/api/campaign-maps');
      for(const item of catalog)select.add(new Option(`${item.name??item.id} · ${item.id}`,item.id));
      catalogLoaded=true;
    }catch(error){info.textContent='Catálogo da campanha indisponível: '+error.message;}
  };
  byId('isoClose').onclick=()=>dialog.close();
  byId('isoFit').onclick=()=>{zoom=1;pan=[0,0];render();};
  select.onchange=loadMap;
  new ResizeObserver(render).observe(canvas);
  canvas.addEventListener('wheel',event=>{
    event.preventDefault();
    zoom=Math.min(5,Math.max(.6,zoom*(event.deltaY<0?1.15:1/1.15)));
    render();
  },{passive:false});
  canvas.addEventListener('pointerdown',event=>{
    if(event.button===1){
      event.preventDefault();
      canvas.setPointerCapture(event.pointerId);
      drag=[event.clientX-pan[0],event.clientY-pan[1]];
      return;
    }
    if(event.button!==0||!transform)return;
    const rect=canvas.getBoundingClientRect();
    const hit=pickIso(tiles,(event.clientX-rect.left-transform.ox)/transform.scale,(event.clientY-rect.top-transform.oy)/transform.scale);
    if(!hit)return;
    canvas.focus();
    highlight=hit.index;
    const entries=[...(map.pieces??[]),...(map.events??[])].filter(e=>Math.floor(e.u)===hit.u&&Math.floor(e.v)===hit.v);
    const edited=!select.value&&edit(hit,event);
    if(edited){map=studioIso(current());tiles=isoTerrain(map);}
    info.textContent=`Célula ${hit.u}, ${hit.v} · cota ${map.cells[hit.index].level} · ${map.cells[hit.index].material}`
      +(entries.length?' · '+entries.map(e=>e.name??e.label??e.asset).join(', '):'');
    render();
  });
  canvas.addEventListener('keydown',event=>{
    const direction={ArrowUp:[0,-1],ArrowDown:[0,1],ArrowLeft:[-1,0],ArrowRight:[1,0]}[event.key];
    if(!direction||select.value||!map)return;
    event.preventDefault();
    map.spawn=walk(map.spawn,direction);
    render();
  });
  canvas.addEventListener('pointermove',event=>{if(drag){pan=[event.clientX-drag[0],event.clientY-drag[1]];render();}});
  for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,()=>{drag=null;});
}
