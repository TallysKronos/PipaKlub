import {parseWorldMap} from '/src/world-map.js';
import {buildWorldArtPlan} from '/src/world-art.js';
export const clone=value=>JSON.parse(JSON.stringify(value));
export function pngBytes(data){if(!/^data:image\/png;base64,[a-zA-Z0-9+/=]+$/.test(data))throw Error('PNG embutido inválido.');return Uint8Array.from(atob(data.split(',')[1]),c=>c.charCodeAt(0));}
export const props=o=>Object.fromEntries((o.properties||[]).map(p=>[p.name,p.value]));
export function prop(o,name,value){o.properties=(o.properties||[]).filter(p=>p.name!==name);if(value!==undefined&&value!=='')o.properties.push({name,type:Number.isInteger(value)?'int':typeof value==='number'?'float':'string',value});}
export function layer(project,name){return project.map.layers.find(l=>l.name===name);}
export function validateProject(p){
 if(p?.schema!=='pipaklub-atelier'||p.version!==1||!p.map||!p.kit?.frames||!p.layout?.bindings||!Array.isArray(p.layout.decorations))throw Error('Escolha um projeto .json do Ateliê, versão 1.');
 if(JSON.stringify(p).length>40000000)throw Error('Projeto excede 40 MB.');
 const m=p.map,required=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'];
 if(![m.width,m.height].every(n=>Number.isInteger(n)&&n>=8&&n<=64)||m.tilewidth!==32||m.tileheight!==32||m.orientation!=='orthogonal'||m.infinite)throw Error('Use mapa ortogonal de 8–64 células, grade de 32 px.');
 if(!Array.isArray(m.layers)||m.layers.length!==6||!required.every(n=>m.layers.filter(l=>l.name===n&&l.type==='objectgroup'&&Array.isArray(l.objects)).length===1)||m.layers.some(l=>l.objects.length>1500))throw Error('Mapa deve ter as seis camadas de objetos do PipaKlub.');
 for(const l of m.layers)for(const o of l.objects)if(![o.x,o.y,o.width,o.height].every(Number.isFinite)||o.width<=0||o.height<=0)throw Error('Objeto com dimensões inválidas.');
 if(typeof p.name!=='string'||p.name.length>80)throw Error('Nome do projeto inválido.');
 if(!p.kit.sheets||Object.keys(p.kit.frames).length>1000)throw Error('Biblioteca inválida.');
 for(const [id,s]of Object.entries(p.kit.sheets)){
  if(!/^[a-z0-9-]{1,100}$/.test(id)||!Number.isInteger(s.width)||!Number.isInteger(s.height)||s.width<1||s.height<1||s.width>8192||s.height>8192)throw Error('Dimensões de folha inválidas: '+id);
  if(p.images?.[id]){if(!/^data:image\/png;base64,[a-zA-Z0-9+/=]+$/.test(p.images[id]))throw Error('Imagem importada inválida.');}
  else if(!/^world\/(morro-kit-v1|quintal-kit-v1)\/[a-z0-9-]+\.png$/.test(s.image))throw Error('Folha sem imagem local: '+id);
 }
 for(const [id,f]of Object.entries(p.kit.frames)){
  const s=p.kit.sheets[f.sheet];if(!s||![f.x,f.y,f.w,f.h].every(Number.isInteger)||f.x<0||f.y<0||f.w<1||f.h<1||f.x+f.w>s.width||f.y+f.h>s.height||![f.anchor?.x,f.anchor?.y].every(n=>Number.isFinite(n)&&n>=-2&&n<=3))throw Error('Recorte fora da imagem: '+id);
 }
 for(const b of [...Object.values(p.layout.bindings),...p.layout.decorations]){
  if(b.hidden)continue;if(!p.kit.frames[b.frame])throw Error('Peça ausente no mapa: '+b.frame);
  for(const key of ['sourceWidth','sourceHeight'])if(b[key]!==undefined&&(!Number.isInteger(b[key])||b[key]<1||b[key]>p.kit.frames[b.frame][key==='sourceWidth'?'w':'h']))throw Error('Recorte de término inválido: '+b.frame);
  for(const key of ['width','height','step'])if(b[key]!==undefined&&(!Number.isFinite(b[key])||b[key]<=0||b[key]>16384))throw Error('Tamanho ou repetição inválida: '+b.frame);
  for(const key of ['footX','footY','sortY','anchorX','anchorY'])if(b[key]!==undefined&&!Number.isFinite(b[key]))throw Error('Apoio inválido: '+b.frame);
  if(b.repeat&&!['x','y'].includes(b.repeat)||b.repeat&&(!Number.isFinite(b.step)||b.step<1))throw Error('Passo de repetição inválido: '+b.frame);
 }
 return p;
}
export function compile(p){validateProject(p);const scene=parseWorldMap(p.map);for(const r of scene.tiled.layers.Walkable)if(r.properties.ground_frame&&!p.kit.frames[r.properties.ground_frame])throw Error('Piso usa peça ausente: '+r.properties.ground_frame);scene.art=buildWorldArtPlan(scene,p.kit,p.layout);return scene;}
export function validate(p){try{const scene=compile(p);return {ok:true,scene,message:scene.nodes.length+' pontos de caminhada · '+scene.art.objects.length+' peças de cenário'};}catch(e){return {ok:false,message:e.message};}}
export function bounds(p){return {w:p.map.width*p.map.tilewidth,h:p.map.height*p.map.tileheight};}
export function rect(p,name,r,extra={}){
 const id=Math.max(0,...p.map.layers.flatMap(l=>l.objects.map(o=>o.id)))+1;
 const o={id,name:extra.name||name+' '+id,x:r.x,y:r.y,width:r.w,height:r.h,rotation:0,visible:true,properties:[]};
 for(const [k,v]of Object.entries(extra))if(k!=='name')prop(o,k,v);
 layer(p,name).objects.push(o);p.map.nextobjectid=id+1;return o;
}
export function resolve(p,selection){if(!selection)return null;if(selection.layer==='decorations')return p.layout.decorations[selection.id];return layer(p,selection.layer)?.objects.find(o=>o.id===selection.id);}
export function remove(p,s){if(s.layer==='decorations')p.layout.decorations.splice(s.id,1);else{const l=layer(p,s.layer);l.objects=l.objects.filter(o=>o.id!==s.id);delete p.layout.bindings[s.id];}}
export function move(p,s,dx,dy){const o=resolve(p,s);if(!o)return;if(s.layer==='decorations'){o.footX+=dx;o.footY+=dy;o.sortY+=dy;return;}o.x+=dx;o.y+=dy;const b=p.layout.bindings[o.id];if(b){if(b.footX!==undefined)b.footX+=dx;if(b.footY!==undefined)b.footY+=dy;}if(props(o).sort_y!==undefined)prop(o,'sort_y',props(o).sort_y+dy);}
export function place(p,frame,x,y,kind='object',level=0){
 const f=p.kit.frames[frame];if(!f)throw Error('Selecione uma peça.');
 const width=f.recommendedWidth||Math.round((f.recommendedHeight||96)*f.w/f.h),height=width*f.h/f.w;
 const r={x:x-width/4,y:y-16,w:width/2,h:16};const b=bounds(p);
 r.x=Math.max(0,Math.min(b.w-r.w,r.x));r.y=Math.max(0,Math.min(b.h-r.h,r.y));
 const name=kind==='foreground'?'Foreground':'Solids',o=rect(p,name,r,{name:frame,level,sort_y:y});
 p.layout.bindings[o.id]={frame,width,footX:x,footY:y};return {layer:name,id:o.id};
}
export function blankProject(kit){
 const map={type:'map',version:'1.10',orientation:'orthogonal',renderorder:'right-down',infinite:false,width:32,height:24,tilewidth:32,tileheight:32,tilesets:[],properties:[{name:'ground_corner_radius',type:'int',value:24},{name:'actor_height',type:'int',value:64},{name:'foot_radius',type:'int',value:12}],layers:['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,i)=>({id:i+1,name,type:'objectgroup',objects:[],x:0,y:0,visible:true,opacity:1})),nextlayerid:7,nextobjectid:1};
 const p={schema:'pipaklub-atelier',version:1,name:'Meu quintal',map,kit:clone(kit),layout:{bindings:{},decorations:[],audit:{enforce:true}},images:{}};
 rect(p,'Walkable',{x:32,y:32,w:960,h:704},{name:'Chão inicial',level:0,ground_frame:'dirt'});rect(p,'Spawns',{x:64,y:608,w:32,h:32},{name:'Entrada',level:0});return p;
}
export class History{
 constructor(){this.undoStack=[];this.redoStack=[];}
 push(p){this.undoStack.push(clone(p));if(this.undoStack.length>35)this.undoStack.shift();this.redoStack=[];}
 undo(p){if(!this.undoStack.length)return p;this.redoStack.push(clone(p));return this.undoStack.pop();}
 redo(p){if(!this.redoStack.length)return p;this.undoStack.push(clone(p));return this.redoStack.pop();}
}
