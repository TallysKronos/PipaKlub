import {completeSkeleton} from './skeleton.mjs';
// Reusable production contract. This supplies guides and checks, never finished character art.
export const CHARACTER_STYLE='soulmon-ds-v1';
export const BODY_TYPES={
 jovem:{label:'Jovem · esguio',heads:3.2,width:.44},
 adulto:{label:'Adulto · alongado',heads:3.5,width:.48},
 robusto:{label:'Robusto · ombros largos',heads:3.1,width:.62}
};
export const CHARACTER_LAYERS=['Braço de trás','Perna de trás','Perna da frente','Tronco','Braço da frente','Cabeça','Cabelo'];
const HEX=['#172237','#283e62','#5275a4','#8c534b','#d18c68','#f5c69b','#ffe4bc','#203a64','#3d69a3','#6c94bb','#242d42','#536177','#8a96a6','#e9e6d6','#238796','#70ced0','#6c634f','#c6b475','#803c55','#c27683'];
export const STYLE_PALETTE=[[0,0,0,0],...HEX.map(c=>[1,3,5].map(i=>parseInt(c.slice(i,i+2),16)).concat(255))];
export const STYLE_RAMPS={tinta:[1],cabelo:[1,2,3],pele:[4,5,6,7],roupa:[8,9,10],calca:[11,12,13],tenis:[1,14],acento:[15,16],metal:[17,18],extra:[19,20]};
export const STYLE_DIRECTIONS=['S','SO','O','NO','N','NE','E','SE'];
export function validateCharacterStyle(value,p){
 if(value==null)return undefined;
 if(typeof value!=='object'||Array.isArray(value)||value.id!==CHARACTER_STYLE||!BODY_TYPES[value.body])throw Error('Perfil de personagem inválido.');
 if(![[48,64],[32,48]].some(([w,h])=>p.width===w&&p.height===h))throw Error('Soulmon DS aceita células 48×64 ou 32×48; não redimensione arte automaticamente.');
 for(const key of ['baseReviewed','cycleReviewed'])if(value[key]!==undefined&&typeof value[key]!=='boolean')throw Error('Revisão visual deve ser marcada explicitamente.');
 return {id:CHARACTER_STYLE,body:value.body,baseReviewed:value.baseReviewed===true,cycleReviewed:value.cycleReviewed===true};
}
export function characterGuide(p){
 if(!p.style)return null;
 const body=BODY_TYPES[p.style.body],height=p.sheet?.altura??(p.height===64?54:42),base=p.sheet?.base??p.height-3,heads=p.sheet?.cabecas??body.heads,top=base-height+1,head=Math.round(height/heads),cx=Math.floor(p.width/2);
 const chin=top+head-1,shoulder=chin+3,hip=shoulder+Math.round((base-shoulder)*.46);
 const shoulderHalf=Math.round(height*body.width/2);
 return {top,chin,shoulder,hip,knee:Math.round((hip+base)/2),base,pivot:[cx,p.height-(p.settings?.margin??2)],cx,height,head,heads,shoulderHalf,colors:p.sheet?.cores??20};
}
export function createCharacterBase({name='Novo personagem',body='jovem',width=48,height=64}={}){
 const p={kind:'pixelgen',version:2,name,width,height,cols:4,rows:2,palette:STYLE_PALETTE.map(c=>[...c]),ramps:structuredClone(STYLE_RAMPS),layers:CHARACTER_LAYERS.map(name=>({name,visible:true,locked:false})),frames:[],sequences:[],style:{id:CHARACTER_STYLE,body,baseReviewed:false,cycleReviewed:false},settings:{width,height,cols:4,rows:2,margin:2,colors:20}};
 p.style=validateCharacterStyle(p.style,p);const g=characterGuide(p);
 p.sheet={nome:name,cabecas:g.heads,altura:g.height,base:g.base,cores:20,rampas:['tinta','pele','roupa'],referencia:'idle-S-1',preenchimentoMax:.78,notas:'Perfil DS: cabeça compacta, membros legíveis, contorno seletivo; revisar 1×. A paleta inicial é editável e não define identidade.'};
 for(const dir of STYLE_DIRECTIONS){
  const side=['E','O'].includes(dir),quarter=dir.length===2,spread=side?2:quarter?Math.max(3,g.shoulderHalf-2):g.shoulderHalf;
  const pose={topo:[g.cx,g.top],queixo:[g.cx,g.chin],ombroTras:[g.cx-spread,g.shoulder],ombroFrente:[g.cx+spread,g.shoulder],quadril:[g.cx,g.hip],maoTras:[g.cx-spread-1,g.hip-1],maoFrente:[g.cx+spread+1,g.hip-1],peTras:[g.cx-3,g.base],peFrente:[g.cx+3,g.base]};
  const i=p.frames.length;p.frames.push({name:`idle-${dir}-1`,duration:700,indices:Array(width*height).fill(0),cels:CHARACTER_LAYERS.map(()=>Array(width*height).fill(0)),pose:completeSkeleton(pose),support:['peTras','peFrente']});
  p.sequences.push({name:`idle-${dir}`,start:i,end:i,loop:true,direction:'forward'});
 }
 return p;
}
export function styleReport(p,{frames}={}){
 const g=characterGuide(p),errors=[],warnings=[],measures=[];
 if(!g)return {errors,warnings,measures,profile:null};
 const list=frames||p.frames.map((_,i)=>i),headLayers=p.layers.map((l,i)=>['Cabeça','Cabelo'].includes(l.name)?i:-1).filter(i=>i>=0),torso=p.layers.findIndex(l=>l.name==='Tronco');
 if(!headLayers.length||torso<0)warnings.push('Perfil DS: preserve Cabeça/Cabelo e Tronco em camadas separadas para medir proporção e ligação do pescoço.');
 for(const i of list){
  const f=p.frames[i],occupied=[];for(let j=0;j<f.indices.length;j++)if(f.indices[j])occupied.push(j);
  if(!occupied.length)continue;
  const top=Math.min(...occupied.map(j=>Math.floor(j/p.width))),bottom=Math.max(...occupied.map(j=>Math.floor(j/p.width))),heads=new Set();
  for(const layer of headLayers)f.cels[layer].forEach((v,j)=>{if(v)heads.add(j);});
  let headHeight=0,neckGap=null;
  if(heads.size){
   const ys=[...heads].map(j=>Math.floor(j/p.width));headHeight=Math.max(...ys)-Math.min(...ys)+1;
   const free=/^(run|fall|hurt|attack|victory|defeat|swim|climb)/.test(f.name);
   if(!free&&headHeight/(bottom-top+1)>.40)errors.push(`${f.name}: cabeça/cabelo ocupam ${Math.round(headHeight/(bottom-top+1)*100)}% da altura; alvo DS ≈${Math.round(100/g.heads)}%.`);
   if(torso>=0){
    const body=[];f.cels[torso].forEach((v,j)=>{if(v)body.push(j);});
    if(body.length){let closest=Infinity;
     for(const a of heads)for(const b of body){const d=Math.max(Math.abs(a%p.width-b%p.width),Math.abs(Math.floor(a/p.width)-Math.floor(b/p.width)));if(d<closest)closest=d;if(closest<=1)break;}
     neckGap=Math.max(0,closest-1);if(neckGap>1)errors.push(`${f.name}: cabeça separada do tronco por ${neckGap}px; confira o pescoço.`);
    }
   }
  }
  if(!f.pose)warnings.push(`${f.name}: faltam referências anatômicas para comparar direções.`);
  measures.push({frame:i,name:f.name,height:bottom-top+1,headHeight,neckGap});
 }
 const motions=new Set((p.sequences||[]).map(s=>s.name.replace(/-(S|SO|O|NO|N|NE|E|SE)$/,'')));
 if(!p.style.baseReviewed)warnings.push('Perfil DS: pose base ainda sem revisão visual registrada em 1×.');
 if(motions.size>2&&(!p.style.baseReviewed||!p.style.cycleReviewed))errors.push('Perfil DS: antes de expandir a biblioteca, registre a revisão visual da pose base e de um ciclo curto.');
 return {profile:p.style.id,body:p.style.body,guide:g,errors,warnings,measures,review:{base:p.style.baseReviewed,cycle:p.style.cycleReviewed},note:'Guias e medidas não certificam identidade, anatomia nem animação bonita.'};
}
// Editor-only helper. Never touches cels, palette or exported pixel buffers.
export function paintCharacterGuides(ctx,p,scale,offsetX=0){
 const g=characterGuide(p);if(!g)return;
 ctx.save();ctx.lineWidth=1;ctx.setLineDash?.([3,3]);
 for(const [key,color]of [['top','#91bad0'],['chin','#91bad0'],['shoulder','#d6b47b'],['hip','#d6b47b'],['knee','#86bba7'],['base','#86bba7']]){
  ctx.strokeStyle=color;ctx.beginPath();ctx.moveTo(offsetX,(g[key]+.5)*scale);ctx.lineTo(offsetX+p.width*scale,(g[key]+.5)*scale);ctx.stroke();
 }
 ctx.setLineDash?.([]);ctx.strokeStyle='#91bad055';ctx.beginPath();ctx.moveTo(offsetX+(g.cx+.5)*scale,0);ctx.lineTo(offsetX+(g.cx+.5)*scale,p.height*scale);ctx.stroke();ctx.restore();
}
