// The portable Avatar Studio contract is the source of truth for the game.
export function avatarFrameIndex(action,time=0){const n=action?.length||0;if(!n)return -1;const i=Math.floor(Math.max(0,time)/(action.ms||100));return action.loop===false?Math.min(n-1,i):i%n;}
export function validAvatarAppearance(value,palette){const out={};for(const [id,variants] of Object.entries(palette.variants)){const n=value?.[id];if(Number.isInteger(n)&&n>=0&&n<variants.length)out[id]=n;}return out;}
export function createAvatarPlayer(config,model,env={}){
 const images=new Map(),cache=new Map(),manifest=config.manifest,palette=config.palette;
 const makeCanvas=env.canvas||((w,h)=>{const c=document.createElement('canvas');c.width=w;c.height=h;return c;});
 const loadImage=env.loadImage||((url)=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error('Avatar indisponível'));im.src=url;}));
 let pending=null,ready=false,owner='',appearance={},storage=env.storage;
 if(storage===undefined)try{storage=localStorage;}catch{storage=null;}
 const key=id=>'soulmonsters.avatar.v1.'+encodeURIComponent(id||'local');
 function setOwner(id){id=String(id||'local');if(id===owner)return;owner=id;let saved;try{saved=JSON.parse(storage?.getItem(key(id))||'{}');}catch{saved={};}appearance=validAvatarAppearance(saved,palette);cache.clear();}
 function setAppearance(value){appearance=validAvatarAppearance(value,palette);cache.clear();try{storage?.setItem(key(owner),JSON.stringify(appearance));}catch{}return {...appearance};}
 function load(retry=false){if(ready)return Promise.resolve(true);if(pending&&!retry)return pending;pending=Promise.all(Object.entries(config.images).map(async([file,url])=>{if(images.has(file))return;const im=await loadImage(url),c=makeCanvas(im.width,im.height),g=c.getContext('2d',{willReadFrequently:true});g.drawImage(im,0,0);const d=g.getImageData(0,0,c.width,c.height);images.set(file,{width:c.width,height:c.height,data:d.data});})).then(()=>ready=true).catch(()=>false);return pending;}
 function sequence(action,dir){let a=manifest.actions[action];if(!a)return null;const d=a.directions[dir],source=d?.mirror||dir,list=a.directions[source];return Array.isArray(list)?{a,list,source,flip:source!==dir}:null;}
 function frame(action,dir,i){const seq=sequence(action,dir);if(!ready||!seq)return null;const {list,source,flip}=seq,f=list[i];if(!f)return null;const ck=action+'|'+dir+'|'+i;if(cache.has(ck))return cache.get(ck);
  const point=p=>p&&(flip?[manifest.cell[0]-1-p[0],p[1]]:p),base=images.get(f.image),layers=[];
  for(const l of Object.values(manifest.layers)){const image=images.get(l.images?.[source]);if(!image)continue;const anchor=l.anchor?.[source];if(!anchor)continue;const points=list.map(v=>v[l.kind]),mount=model.laggedMount(points,i,l.lag||0,seq.a.loop!==false);if(!mount)continue;layers.push({kind:l.kind,slot:l.slot,image:flip?model.mirror(image):image,anchor:flip?[image.width-1-anchor[0],anchor[1]]:anchor,mount:point(mount)});}
  const raw=model.composeFrame({base:flip?model.mirror(base):base,head:point(f.head),torso:point(f.torso),hand:point(f.hand),dir,layers,slots:palette.slots,ramps:model.appearanceRamps(palette.slots,appearance,palette.variants)}),c=makeCanvas(raw.width,raw.height),g=c.getContext('2d'),data=g.createImageData(raw.width,raw.height);data.data.set(raw.data);g.putImageData(data,0,0);cache.set(ck,c);return c;
 }
 function draw(g,{x,y,height=96,action='parado',dir='se',time=0}){if(!ready){load();return false;}const seq=sequence(action,dir);if(!seq)return false;const i=avatarFrameIndex({length:seq.list.length,ms:seq.a.ms,loop:seq.a.loop},time),im=frame(action,dir,i);if(!im)return false;const k=height/96;g.save();g.imageSmoothingEnabled=false;g.drawImage(im,x-manifest.pivot[0]*k,y-manifest.pivot[1]*k,im.width*k,im.height*k);g.restore();return true;}
 return {load,draw,frame,sequence,setOwner,setAppearance,get appearance(){return {...appearance};},get ready(){return ready;},palette};
}

export function mountAvatarAppearance(parent,avatar,owner){
 const section=document.createElement('section');section.className='avatar-appearance';
 const title=document.createElement('h3');title.textContent='Seu avatar';section.append(title);
 const previews=document.createElement('div');previews.className='avatar-previews';section.append(previews);
 const canvases=['se','sw','ne','nw'].map((dir,i)=>{const figure=document.createElement('figure'),c=document.createElement('canvas'),caption=document.createElement('figcaption');c.width=128;c.height=144;c.setAttribute('role','img');c.setAttribute('aria-label',['Frente-direita','Frente-esquerda','Costas-direita','Costas-esquerda'][i]);caption.textContent=['Frente ↘','Frente ↙','Costas ↗','Costas ↖'][i];figure.append(c,caption);previews.append(figure);return {c,dir};});
 const controls=document.createElement('div');controls.className='avatar-colors';section.append(controls);const selects=new Map();
 const note=document.createElement('p');note.textContent='Visual salvo neste navegador para esta conta.';section.append(note);
 const status=document.createElement('p');status.setAttribute('role','status');section.append(status);
 for(const slot of avatar.palette.slots.filter(s=>!s.fixed)){const options=avatar.palette.variants[slot.id];if(!options)continue;const label=document.createElement('label'),text=document.createElement('span'),select=document.createElement('select');text.textContent=slot.id==='cabelo'?'Cor do cabelo':slot.name;options.forEach(([name],i)=>{const o=document.createElement('option');o.value=i;o.textContent=name;select.append(o);});select.onchange=()=>{avatar.setAppearance({...avatar.appearance,[slot.id]:Number(select.value)});status.textContent='Aparência salva.';};label.append(text,select);controls.append(label);selects.set(slot.id,select);}
 let running=false,start=0;
 function paint(t){if(!section.isConnected||parent.hidden||parent.closest('[hidden]')){running=false;return;}if(!start)start=t;for(const {c,dir}of canvases){const g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);avatar.draw(g,{x:64,y:130,height:96,dir,action:'andar',time:matchMedia('(prefers-reduced-motion:reduce)').matches?0:t-start});}requestAnimationFrame(paint);}
 parent.append(section);
 return {refresh(){avatar.setOwner(owner());for(const [id,s]of selects)s.value=avatar.appearance[id]||0;status.textContent='';avatar.load(true).then(ok=>{if(!ok)status.textContent='Não foi possível carregar o avatar. Abra o perfil novamente para tentar.';});if(!running){running=true;requestAnimationFrame(paint);}}};
}
