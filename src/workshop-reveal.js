// Oficina das Almas · etapa do papel: a marca da alma está sob retalhos colados e precisa ser revelada sem rasgar.
// Estilete = arranca uma camada num raio largo e rasga onde a marca já aparece; tesourinha = raspa devagar.
// Coordenadas locais da bancada (centro da criatura em 0,0), como em workshop-renderer.js.
export const REVEAL_CELL=6,REVEAL_AREA={x:-132,y:-192,w:264,h:342},REVEAL_SECONDS=90,REVEAL_COUNTDOWN=3,REVEAL_FAIL=.5,REVEAL_DONE=.9,REVEAL_LIGHTS=2;
export const REVEAL_TOOLS={estilete:{radius:24,shock:34,tear:.45,shockTear:.12},tesourinha:{radius:9,layer:.3,tear:.008}};
// Papel do kit do ateliê: manteiga (equilibrado). Outros papéis entram com a economia de materiais.
const REVEAL_PAPER={fragility:1,cover:[1.2,2.4],lightDepth:3};
function revealRandom(seed){let s=seed>>>0||1;return ()=>(s=(s*1664525+1013904223)>>>0)/4294967296;}
// mask(x,y) diz se o ponto local pertence à marca (silhueta real da espécie).
export function createReveal(mask,seed=1){
 const r=revealRandom(seed),cols=Math.floor(REVEAL_AREA.w/REVEAL_CELL),rows=Math.floor(REVEAL_AREA.h/REVEAL_CELL),cells=[];
 const blobs=Array.from({length:8},()=>({x:REVEAL_AREA.x+r()*REVEAL_AREA.w,y:REVEAL_AREA.y+r()*REVEAL_AREA.h,s:30+r()*60,a:r()*.9}));
 for(let j=0;j<rows;j++)for(let i=0;i<cols;i++){
  const x=REVEAL_AREA.x+i*REVEAL_CELL+REVEAL_CELL/2,y=REVEAL_AREA.y+j*REVEAL_CELL+REVEAL_CELL/2,piece=!!mask(x,y);
  let cover=REVEAL_PAPER.cover[0]+(REVEAL_PAPER.cover[1]-REVEAL_PAPER.cover[0])*r()*.5;
  for(const b of blobs){const d=Math.hypot(x-b.x,y-b.y);if(d<b.s)cover+=b.a*(1-d/b.s);}
  if(!piece)cover+=.6;
  cells.push({x,y,piece,cover:Math.min(3,cover),damage:0});
 }
 return {seed,cols,rows,cells,lights:REVEAL_LIGHTS,lightUntil:0,flashes:[],strikes:0};
}
function revealAround(state,x,y,radius,fn){
 const i0=Math.max(0,Math.floor((x-radius-REVEAL_AREA.x)/REVEAL_CELL)),i1=Math.min(state.cols-1,Math.floor((x+radius-REVEAL_AREA.x)/REVEAL_CELL));
 const j0=Math.max(0,Math.floor((y-radius-REVEAL_AREA.y)/REVEAL_CELL)),j1=Math.min(state.rows-1,Math.floor((y+radius-REVEAL_AREA.y)/REVEAL_CELL));
 for(let j=j0;j<=j1;j++)for(let i=i0;i<=i1;i++){const c=state.cells[j*state.cols+i],d=Math.hypot(c.x-x,c.y-y);if(d<=radius)fn(c,d);}
}
export function revealStrike(state,tool,x,y){
 const t=REVEAL_TOOLS[tool],f=REVEAL_PAPER.fragility;if(!t)return revealScore(state);state.strikes++;
 if(tool==='estilete')revealAround(state,x,y,t.shock,(c,d)=>{
  if(d<=t.radius){const left=c.cover-(1-.4*d/t.radius);if(left<0&&c.piece)c.damage=Math.min(1,c.damage-left*t.tear*f);c.cover=Math.max(0,left);}
  else if(c.piece&&c.cover<.3)c.damage=Math.min(1,c.damage+t.shockTear*f*(1-d/t.shock));
 });
 else revealAround(state,x,y,t.radius,c=>{const left=c.cover-t.layer;if(left<0&&c.piece)c.damage=Math.min(1,c.damage+t.tear*f);c.cover=Math.max(0,left);});
 return revealScore(state);
}
// Nota = quanto da marca apareceu × (1 − rasgo médio). Rasgo médio de 50% faz a folha ceder.
export function revealScore(state){
 let n=0,shown=0,dmg=0;for(const c of state.cells)if(c.piece){n++;if(c.cover<=.05)shown++;dmg+=c.damage;}
 const revealed=n?shown/n:0,damage=n?dmg/n:0;
 return {revealed,damage,score:Math.round(100*revealed*(1-damage)),failed:damage>=REVEAL_FAIL,done:revealed>=REVEAL_DONE};
}
export const revealLightVisible=c=>c.piece&&c.cover<=REVEAL_PAPER.lightDepth;
// Máscara pela silhueta real: as mesmas peças e posições que o renderer usa para o Rabbito; demais espécies usam o losango do gabarito.
export function revealMask(parts,rects,rabbit){
 if(!rabbit||!parts?.complete||!rects||typeof document==='undefined'){const pts=[[0,-100],[105,0],[0,100],[-105,0]];return (x,y)=>{let inside=false;for(let i=0,j=3;i<4;j=i++){const [xi,yi]=pts[i],[xj,yj]=pts[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)inside=!inside;}return inside;};}
 const c=document.createElement('canvas');c.width=REVEAL_AREA.w;c.height=REVEAL_AREA.h;const g=c.getContext('2d',{willReadFrequently:true});g.translate(-REVEAL_AREA.x,-REVEAL_AREA.y);
 for(const [id,x,y,w,h,px,py] of [['body',0,30,148,178,.5,.5],['earFar',28,-47,42,113,.5,.94],['earNear',-25,-47,66,119,.5,.94]]){const r=rects[id];if(r)g.drawImage(parts,...r,x-w*px,y-h*py,w,h);}
 const data=g.getImageData(0,0,c.width,c.height).data;
 return (x,y)=>{const i=Math.floor(x-REVEAL_AREA.x),j=Math.floor(y-REVEAL_AREA.y);return i>=0&&j>=0&&i<c.width&&j<c.height&&data[(j*c.width+i)*4+3]>60;};
}
const REVEAL_COVER=['#efe2c4','#e2cfa6','#cdb487','#b39a6c'];
// Desenha sobre a marca (já pintada pelo renderer) os retalhos, rasgos, a Luz e o cursor da ferramenta.
export function drawWorkshopReveal(g,state,time,{tool,cursor,lit,reduced}){
 for(const c of state.cells){
  if(c.piece&&c.damage>.02){g.fillStyle='rgba(168,50,42,'+Math.min(.85,c.damage*1.2)+')';g.fillRect(c.x-3,c.y-3,REVEAL_CELL,REVEAL_CELL);}
  if(c.cover>.05){g.fillStyle=REVEAL_COVER[Math.min(3,Math.floor(c.cover))];g.fillRect(c.x-3,c.y-3,REVEAL_CELL,REVEAL_CELL);if(((c.x*7+c.y*13)|0)%5===0){g.fillStyle='#0000000d';g.fillRect(c.x-3,c.y-1,REVEAL_CELL,1);}}
 }
 if(lit){g.fillStyle='rgba(64,224,208,.45)';for(const c of state.cells)if(c.cover>.05&&revealLightVisible(c))g.fillRect(c.x-3,c.y-3,REVEAL_CELL,REVEAL_CELL);}
 if(!reduced)for(const f of state.flashes){const a=1-(time-f.at)/.26;if(a<=0)continue;g.strokeStyle='rgba(255,255,255,'+a+')';g.lineWidth=2;g.beginPath();g.arc(f.x,f.y,REVEAL_TOOLS.estilete.radius*(1.2-a*.2),0,7);g.stroke();}
 state.flashes=state.flashes.filter(f=>time-f.at<.26);
 if(cursor){g.strokeStyle='#c14e22';g.lineWidth=2;g.beginPath();g.arc(cursor.x,cursor.y,REVEAL_TOOLS[tool]?.radius||10,0,7);g.stroke();}
}
