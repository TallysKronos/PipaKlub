// Deterministic, local-preview progression. No account writes, XP or campaign rewards.
export const parkActions=[
 {id:'assis',label:'Conversar com Sr. Assis',type:'npc',x:310,y:420,approach:{x:336,y:479},range:90},
 {id:'map',label:'Consultar mapa',type:'sign',x:320,y:738,approach:{x:348,y:780},range:80},
 {id:'rest',label:'Descansar com Rabbito',type:'bench',x:420,y:690,approach:{x:444,y:738},range:80},
 {id:'rest-east',label:'Descansar com Rabbito',type:'bench',x:1118,y:622,approach:{x:1140,y:672},range:80},
 {id:'fiber-west',label:'Recolher fibra do vento',type:'pickup',x:220,y:465,range:55},
 {id:'fiber-north',label:'Recolher fibra do vento',type:'pickup',x:900,y:375,range:55},
 {id:'fiber-east',label:'Recolher fibra do vento',type:'pickup',x:1180,y:780,range:55},
 {id:'exit-street',label:'Rua dos Ventos',type:'exit',x:224,y:896,range:60},
 {id:'exit-clearing',label:'Clareira do Papel',type:'exit',x:1288,y:400,range:60},
];
export const fiberIds=parkActions.filter(a=>a.type==='pickup').map(a=>a.id);
export function newParkProgress(){return {version:1,accepted:false,collected:[],rewarded:false,rests:0};}
export function objective(p){return !p.accepted?'Converse com Sr. Assis no coreto':p.collected.length<3?`Recolha fibras do vento · ${p.collected.length}/3`:!p.rewarded?'Volte ao Sr. Assis para receber o kit':'Kit de reparo recebido · explore com Rabbito';}
export function parkTransition(p,event,id){
 const next={...p,collected:[...p.collected]};
 if(event==='accept')next.accepted=true;
 if(event==='collect'&&p.accepted&&fiberIds.includes(id)&&!p.collected.includes(id))next.collected.push(id);
 if(event==='reward'&&p.accepted&&p.collected.length===3)next.rewarded=true;
 if(event==='rest')next.rests=Math.min(999,p.rests+1);
 return next;
}
export function nearestParkAction(position,p){return parkActions.filter(a=>(a.type!=='pickup'||p.accepted&&!p.collected.includes(a.id))&&Math.hypot(a.x-position.x,a.y-position.y)<=a.range).sort((a,b)=>Math.hypot(a.x-position.x,a.y-position.y)-Math.hypot(b.x-position.x,b.y-position.y))[0]||null;}
export function encodeParkSave(progress,position){return JSON.stringify({schema:'park-preview-save',version:1,progress,position:{x:position.x,y:position.y,direction:position.direction}});}
export function decodeParkSave(raw){
 try{
  const s=JSON.parse(raw),p=s.progress,a=s.position;
  if(s.schema!=='park-preview-save'||s.version!==1||p?.version!==1||typeof p.accepted!=='boolean'||typeof p.rewarded!=='boolean'||!Number.isInteger(p.rests)||p.rests<0||p.rests>999||!Array.isArray(p.collected)||p.collected.length>3||new Set(p.collected).size!==p.collected.length||p.collected.some(id=>!fiberIds.includes(id))||!p.accepted&&(p.collected.length||p.rewarded)||p.rewarded&&p.collected.length!==3||!Number.isFinite(a?.x)||!Number.isFinite(a?.y)||a.x<0||a.x>1536||a.y<0||a.y>1024||!Number.isInteger(a.direction)||a.direction<0||a.direction>3)return null;
  return {progress:{version:1,accepted:p.accepted,collected:[...p.collected],rewarded:p.rewarded,rests:p.rests},position:{x:a.x,y:a.y,direction:a.direction}};
 }catch{return null;}
}
export function hitsBox(point,box){return point.x>=box.x&&point.x<=box.x+box.w&&point.y>=box.y&&point.y<=box.y+box.h;}
export function propOccludesActor(box,player,depth){return depth>player.y&&hitsBox({x:player.x,y:player.y-30},{x:box.x-8,y:box.y,w:box.w+16,h:box.h+20});}
