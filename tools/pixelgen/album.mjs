// Local project autosave: snapshots, serialized writes and explicit conflict handling.
export function connectedSave({send,onState=()=>{},delay=500}){
 let binding=null,dirty=null,timer=null,running=null,error=null;
 async function flush(){clearTimeout(timer);if(running)await running;if(error)throw error;if(!binding||!dirty)return;
  running=(async()=>{while(dirty){const value=dirty;dirty=null;onState('saving');try{const result=await send(binding.id,{revision:binding.revision,project:value});binding.revision=result.revision;onState(dirty?'saving':'saved',binding.inGame);}catch(e){dirty=dirty||value;error=e;onState('error',e.message);throw e;}}})();
  try{await running;}finally{running=null;}
 }
 return {bind(value){binding=value;dirty=null;error=null;onState('saved',value.inGame);},get active(){return binding;},get pending(){return !!dirty||!!running;},
  change(value){if(!binding)return;dirty=value;onState(error?'error':'pending',error?.message);clearTimeout(timer);if(!error)timer=setTimeout(()=>flush().catch(()=>{}),delay);},
  flush,async retry(){error=null;return flush();},async detach(){await flush();binding=null;},
 };
}
export async function initAlbum({document:doc,open,close=()=>{},refresh=()=>{},request=globalThis.fetch}){
 if(!request)return null;
 const $=id=>doc.getElementById(id);let catalog;
 try{const r=await request('/api/characters');if(!r.ok)return null;catalog=await r.json();}catch{return null;}
 let current=null,opening=false;
 const root=$('albumHome'),grid=$('albumGrid'),state=$('connectionState');
 const saver=connectedSave({send:async(id,value)=>{const r=await request('/api/characters/'+id,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(value)});const data=await r.json();if(!r.ok)throw Error(data.error||'Não foi possível salvar.');return data;},
  onState(kind,detail){state.dataset.state=kind;state.textContent=({pending:'Alterações pendentes…',saving:'Salvando no projeto…',saved:detail?'Salvo · pixels aplicados no jogo':'Salvo no asset · ainda fora dos mapas',error:'Falha ao salvar · '+detail})[kind];$('retryConnected').hidden=kind!=='error';}
 });
 function lockContract(connected){for(const id of ['frameName','frameDuration','duplicateFrame','blankFrame','deleteFrame','frameBefore','frameAfter','durationAll','saveSequence']){const el=$(id);if(el){el.disabled=connected;el.title=connected?'A grade e a ordem usadas pelo jogo são preservadas. Exporte uma cópia para criar novas ações.':'';}}$('convert').disabled=connected;}
 function showEditor(){doc.body.classList.remove('album-visible');root.hidden=true;$('albumBack').hidden=false;$('connectedBar').hidden=false;lockContract(true);refresh();}
 async function openAsset(character,asset){if(opening)return;opening=true;try{await saver.detach();const data=await getAsset(asset.id);
    await open(data.project);current=character;saver.bind({id:asset.id,revision:data.revision,inGame:data.inGame});
    $('connectedName').textContent=character.name;const choices=$('albumAsset');choices.replaceChildren();for(const a of character.assets){const o=doc.createElement('option');o.value=a.id;o.textContent=a.label;o.disabled=!a.available;choices.append(o);}choices.value=asset.id;showEditor();
   }catch(e){$('albumMessage').textContent=e.message;state.textContent=e.message;}finally{opening=false;}}
 async function getAsset(id){const r=await request('/api/characters/'+id);const value=await r.json();if(!r.ok)throw Error(value.error);return value;}
 function render(){const query=$('albumSearch').value.trim().toLocaleLowerCase('pt-BR'),group=$('albumGroup').value;grid.replaceChildren();let count=0;
  for(const c of catalog.filter(c=>(group==='all'||c.group===group)&&c.name.toLocaleLowerCase('pt-BR').includes(query))){count++;const card=doc.createElement('button');card.className='sticker-card';card.dataset.character=c.id;const a=c.assets.find(a=>a.available);card.disabled=!a;
   const image=doc.createElement('img');image.src='/api/characters/'+(a?.id||c.id)+'/preview';image.alt='Sprite de '+c.name;image.loading='lazy';
   const stage=doc.createElement('span');stage.className='sticker-art';stage.append(image);const name=doc.createElement('strong');name.textContent=c.name;const role=doc.createElement('span');role.className='sticker-role';role.textContent=c.role;const badge=doc.createElement('span');badge.className='sticker-badge';badge.textContent=!a?'Arquivo indisponível':c.inGame?'No jogo':'Pronto para o mapa';
   const foot=doc.createElement('span');foot.className='sticker-foot';foot.textContent=a?`${c.assets.length>1?c.assets.length+' ações':a.frames+' direções'} · Editar ↗`:'Confira o arquivo local';card.append(stage,role,name,badge,foot);card.onclick=()=>openAsset(c,a);grid.append(card);}
  $('albumCount').textContent=`${count} ${count===1?'personagem':'personagens'}`;$('albumEmpty').hidden=count>0;
 }
 $('albumSearch').oninput=render;$('albumGroup').onchange=render;
 $('albumAsset').onchange=()=>{const a=current.assets.find(a=>a.id===$('albumAsset').value);openAsset(current,a);};
 $('retryConnected').onclick=()=>saver.retry().catch(()=>{});
 async function home(){try{close();await saver.flush();doc.body.classList.add('album-visible');root.hidden=false;$('albumBack').hidden=true;$('connectedBar').hidden=true;lockContract(false);render();}catch{state.focus();}}
 $('albumBack').onclick=home;$('albumWorkbench').onclick=async()=>{try{await saver.detach();doc.body.classList.remove('album-visible');root.hidden=true;$('albumBack').hidden=false;$('connectedBar').hidden=true;lockContract(false);}catch{}};
 globalThis.addEventListener?.('beforeunload',event=>{if(saver.pending){event.preventDefault();event.returnValue='';}});
 render();await home();
 return {change:value=>saver.change(value),async detach(){await saver.detach();$('connectedBar').hidden=true;lockContract(false);},get active(){return saver.active;},flush:()=>saver.flush()};
}
