// Avatar Studio: boneco de papel em camadas (art/avatar/especificacao.html). Sem DOM: imagens são {width,height,data RGBA}.
export const RULES='avatar-1';
// Oito direções: as diagonais seguem os eixos da grade 2:1 (26,57° na tela), não 45°. W, SW e NW são espelhos de E, SE e NE.
export const DIRS=['s','se','e','ne','n','nw','w','sw'],DRAWN=['s','se','e','ne','n'],MIRROR={w:'e',sw:'se',nw:'ne'};
export const DIR_NAMES={s:'Frente',se:'Frente-direita',e:'Direita',ne:'Costas-direita',n:'Costas',nw:'Costas-esquerda',w:'Esquerda',sw:'Frente-esquerda'};
const ISO=Math.atan2(1,2)*180/Math.PI,ANGLES={e:0,se:ISO,s:90,sw:180-ISO,w:180,nw:-180+ISO,n:-90,ne:-ISO};
// Direção do sprite a partir do deslocamento na tela (y para baixo): a mais próxima em ângulo.
export function facing8(dx,dy,previous='s'){if(Math.hypot(dx,dy)<1e-6)return previous;const a=Math.atan2(dy,dx)*180/Math.PI;let best='s',gap=Infinity;for(const [d,v] of Object.entries(ANGLES)){const g=Math.abs(((a-v+540)%360)-180);if(g<gap){gap=g;best=d;}}return best;}
export const SPEC={cell:256,pivot:[128,224],scale:2,height:192,eyeLine:92};
export const ACTIONS={parado:{name:'Parado',frames:4,ms:180},andar:{name:'Andar',frames:8,ms:100},correr:{name:'Correr',frames:6,ms:80}};
export const SLOTS=[
 {id:'contorno',name:'Contorno',tones:['#0b1020'],fixed:true},
 {id:'pele',name:'Pele',tones:['#9a5634','#cf8350','#f0a868','#f9c995']},
 {id:'cabelo',name:'Cabelo',tones:['#121838','#1e2a5e','#2f4590','#4d6cbc']},
 {id:'jaqueta',name:'Jaqueta',tones:['#0e346e','#13499a','#2a6cc0','#5d95da']},
 {id:'camiseta',name:'Camiseta',tones:['#141a24','#252d3b','#3c4757']},
 {id:'calca',name:'Calça',tones:['#3e5677','#5f7fa5','#8ba7c6']},
 {id:'tenis',name:'Tênis',tones:['#1b2030','#2d354a','#47516b']},
 {id:'detalhe',name:'Detalhe',tones:['#b67a1f','#e8b24c']},
 {id:'mochila',name:'Mochila',tones:['#272c42','#3b435e','#57617e']},
 {id:'olhos',name:'Olhos',tones:['#ffffff','#2a1a10'],fixed:true}];
export const VARIANTS={
 pele:[['Mel',null],['Claro',['#b8705a','#e3a184','#f6c6a8','#fde3cf']],['Castanho',['#5e321c','#8a4d2c','#b06d3f','#cf9161']],['Escuro',['#2e1810','#4a2818','#6b3c22','#8c5532']]],
 cabelo:[['Azul-noite',null],['Preto',['#0a0a10','#17171f','#26262f','#3a3a46']],['Castanho',['#2a160c','#4a2a16','#6e4322','#94622f']],['Cobre',['#4a1a0a','#8a3612','#c45a1c','#e8843a']]],
 jaqueta:[['Azul',null],['Terracota',['#6e2a16','#a8442a','#d0683f','#ec9a6c']],['Verde-mata',['#163a24','#245a36','#3a7d4c','#62a670']],['Mostarda',['#6e4c0c','#a87a16','#d4a22c','#ecc864']]],
 camiseta:[['Preta',null],['Creme',['#a89a7c','#d6c8a4','#f2e8cc']],['Branca',['#9aa4b0','#d4dbe2','#f6f8fa']]],
 calca:[['Jeans',null],['Caqui',['#6a5a3a','#958058','#bfa97c']],['Preta',['#14161c','#252830','#3a3e4a']]],
 tenis:[['Marinho',null],['Branco',['#8c96a4','#ccd4de','#f4f6f8']],['Vermelho',['#5a1416','#9a2226','#d0403a']]],
 detalhe:[['Latão',null],['Prata',['#7c8696','#c4ccd6']]],
 mochila:[['Marinho',null],['Terracota',['#5a2416','#8a3c24','#b65c38']],['Verde',['#1c3a26','#2c5a3a','#467d52']]]};
export const hexToInt=h=>parseInt(h.slice(1),16),intToHex=n=>'#'+n.toString(16).padStart(6,'0');
const rgbOf=n=>[n>>16&255,n>>8&255,n&255];
// Distância perceptual simples ("redmean").
export function colorDistance(a,b){const [r1,g1,b1]=rgbOf(a),[r2,g2,b2]=rgbOf(b),rm=(r1+r2)/2,dr=r1-r2,dg=g1-g2,db=b1-b2;return Math.sqrt((2+rm/256)*dr*dr+4*dg*dg+(2+(255-rm)/256)*db*db);}
export const blank=(w,h)=>({width:w,height:h,data:new Uint8ClampedArray(w*h*4)});
// ---------- paleta ----------
export function keyIndex(slots=SLOTS){const map=new Map();slots.forEach(s=>s.tones.forEach((t,tone)=>map.set(hexToInt(t),{slot:s.id,tone})));return map;}
// Agrupa as cores opacas de várias imagens em k cores (corte pela mediana, ponderado pela contagem).
export function quantize(images,k=24,threshold=128){
 const counts=new Map();for(const img of images){const d=img.data;for(let i=0;i<d.length;i+=4)if(d[i+3]>=threshold){const c=d[i]<<16|d[i+1]<<8|d[i+2];counts.set(c,(counts.get(c)||0)+1);}}
 let boxes=[[...counts.entries()]];
 const range=box=>{let lo=[255,255,255],hi=[0,0,0];for(const [c] of box){const v=rgbOf(c);for(let j=0;j<3;j++){if(v[j]<lo[j])lo[j]=v[j];if(v[j]>hi[j])hi[j]=v[j];}}return hi.map((h,j)=>h-lo[j]);};
 while(boxes.length<k){let best=-1,bestScore=0;boxes.forEach((b,i)=>{if(b.length<2)return;const r=Math.max(...range(b)),w=b.reduce((s,[,n])=>s+n,0),score=r*Math.sqrt(w);if(score>bestScore){bestScore=score;best=i;}});if(best<0)break;
  const box=boxes[best],r=range(box),ch=r.indexOf(Math.max(...r));box.sort((a,b)=>rgbOf(a[0])[ch]-rgbOf(b[0])[ch]);const total=box.reduce((s,[,n])=>s+n,0);let acc=0,cut=1;for(let i=0;i<box.length-1;i++){acc+=box[i][1];if(acc>=total/2){cut=i+1;break;}}
  boxes.splice(best,1,box.slice(0,cut),box.slice(cut));}
 return boxes.filter(b=>b.length).map(b=>{const w=b.reduce((s,[,n])=>s+n,0),avg=[0,1,2].map(j=>Math.round(b.reduce((s,[c,n])=>s+rgbOf(c)[j]*n,0)/w));return {color:avg[0]<<16|avg[1]<<8|avg[2],count:w};}).sort((a,b)=>b.count-a.count);
}
// Faixa vertical típica de cada grupo (0 = topo da figura, 1 = pé). Cores iguais em lugares diferentes (cabelo, tênis e
// mochila azul-marinho) só se separam pela posição.
export const BANDS={cabelo:[0,.38],olhos:[.12,.4],pele:[.08,.95],jaqueta:[.28,.75],camiseta:[.3,.7],mochila:[.25,.72],calca:[.55,.93],tenis:[.82,1]};
// Para cada cor agrupada: altura mediana dos seus pixels na figura e fração na borda (vizinho transparente).
export function clusterStats(images,clusters,threshold=128){
 const ys=clusters.map(()=>[]),edge=clusters.map(()=>0),count=clusters.map(()=>0),cache=new Map();
 for(const img of images){const {width:w,height:h,data:d}=img;let y0=h,y1=-1;for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(d[(y*w+x)*4+3]>=threshold){if(y<y0)y0=y;y1=y;}if(y1<0)continue;const span=Math.max(1,y1-y0);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4;if(d[i+3]<threshold)continue;const c=d[i]<<16|d[i+1]<<8|d[i+2];let k=cache.get(c);if(k===undefined){let best=0,dist=Infinity;clusters.forEach((cl,j)=>{const dd=colorDistance(c,cl.color);if(dd<dist){dist=dd;best=j;}});k=best;cache.set(c,k);}
   count[k]++;if((x*7+y*13)%5===0)ys[k].push((y-y0)/span);const open=(xx,yy)=>xx<0||yy<0||xx>=w||yy>=h||d[(yy*w+xx)*4+3]<threshold;if(open(x-1,y)||open(x+1,y)||open(x,y-1)||open(x,y+1))edge[k]++;}}
 return clusters.map((_,k)=>{const v=ys[k].sort((a,b)=>a-b);return {y:v.length?v[v.length>>1]:.5,edge:count[k]?edge[k]/count[k]:0};});
}
// Sugere grupo e tom: cor-chave mais próxima, penalizada quando a cor aparece fora da faixa típica do grupo.
export function suggestMapping(clusters,slots=SLOTS,stats=null){const keys=[...keyIndex(slots)];return clusters.map((c,i)=>{const st=stats?.[i];let best=null,cost=Infinity;
 for(const [k,v] of keys){let d=colorDistance(c.color,k);if(st){const band=BANDS[v.slot];if(band){const out=st.y<band[0]?band[0]-st.y:st.y>band[1]?st.y-band[1]:0;d+=out*900;}if(v.slot==='contorno')d-=st.edge>.5?60:0;}
  if(d<cost){cost=d;best=v;}}return {...best};});}
// Converte uma imagem para as cores-chave: cada pixel vai para o grupo mais próximo e herda o grupo/tom atribuído. Alpha vira 0 ou 255.
export function applyMapping(img,clusters,assign,slots=SLOTS,threshold=128){
 const out=blank(img.width,img.height),cache=new Map(),tone=(slot,t)=>{const s=slots.find(x=>x.id===slot);return s?hexToInt(s.tones[Math.min(t,s.tones.length-1)]):null;};
 const d=img.data,o=out.data;
 for(let i=0;i<d.length;i+=4){if(d[i+3]<threshold)continue;const c=d[i]<<16|d[i+1]<<8|d[i+2];let key=cache.get(c);
  if(key===undefined){let best=0,dist=Infinity;clusters.forEach((cl,j)=>{const dd=colorDistance(c,cl.color);if(dd<dist){dist=dd;best=j;}});const a=assign[best];key=a?.slot?tone(a.slot,a.tone):c|0x1000000;cache.set(c,key);}
  // Cor sem grupo fica com bit extra: mantém a cor original e conta como fora da paleta.
  const v=key&0xffffff;o[i]=v>>16;o[i+1]=v>>8&255;o[i+2]=v&255;o[i+3]=key>0xffffff?254:255;}
 return out;
}
export function appearanceRamps(slots,appearance={},variants=VARIANTS){const out={};for(const s of slots){const pick=appearance[s.id],v=variants[s.id]?.[pick||0];out[s.id]=v?.[1]||s.tones;}return out;}
export function recolor(img,slots,ramps){
 const swap=new Map();for(const s of slots){const to=ramps[s.id]||s.tones;s.tones.forEach((t,i)=>swap.set(hexToInt(t),hexToInt(to[Math.min(i,to.length-1)])));}
 const out=blank(img.width,img.height),d=img.data,o=out.data;o.set(d);
 for(let i=0;i<d.length;i+=4){if(!d[i+3])continue;const n=swap.get(d[i]<<16|d[i+1]<<8|d[i+2]);if(n!==undefined){o[i]=n>>16;o[i+1]=n>>8&255;o[i+2]=n&255;}}
 return out;
}
// ---------- medidas e montagem ----------
export function metrics(img,slots=SLOTS){
 const {width:w,height:h,data:d}=img,keys=keyIndex(slots),bySlot={};let x0=w,y0=h,x1=-1,y1=-1,area=0,off=0,semi=0;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4,a=d[i+3];if(!a)continue;if(a<255&&a!==254)semi++;if(a<128)continue;area++;if(x<x0)x0=x;if(x>x1)x1=x;if(y<y0)y0=y;if(y>y1)y1=y;
  const k=keys.get(d[i]<<16|d[i+1]<<8|d[i+2]);if(k&&a===255)bySlot[k.slot]=(bySlot[k.slot]||0)+1;else off++;}
 return {bounds:x1<0?null:{x:x0,y:y0,w:x1-x0+1,h:y1-y0+1},baseline:y1+1,area,off,semi,bySlot};
}
// Âncora da cabeça automática: centro dos pixels de pele (ou de cabelo, nas costas) na metade de cima da figura.
export function autoHead(img,slots=SLOTS){
 const m=metrics(img,slots);if(!m.bounds)return null;const {width:w,data:d}=img,keys=keyIndex(slots),limit=m.bounds.y+m.bounds.h*.42;
 for(const want of [['pele'],['cabelo','pele']]){let sx=0,sy=0,n=0;for(let y=m.bounds.y;y<limit;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4;if(d[i+3]<255)continue;const k=keys.get(d[i]<<16|d[i+1]<<8|d[i+2]);if(k&&want.includes(k.slot)){sx+=x;sy+=y;n++;}}
  if(n>40)return [Math.round(sx/n),Math.round(sy/n)];}
 return [Math.round(m.bounds.x+m.bounds.w/2),Math.round(m.bounds.y+m.bounds.h*.22)];
}
export function mirror(img){const out=blank(img.width,img.height),{width:w,height:h,data:d}=img;for(let y=0;y<h;y++)for(let x=0;x<w;x++){const a=(y*w+x)*4,b=(y*w+(w-1-x))*4;for(let j=0;j<4;j++)out.data[b+j]=d[a+j];}return out;}
export function translate(img,dx,dy){const out=blank(img.width,img.height),{width:w,height:h,data:d}=img;for(let y=0;y<h;y++){const sy=y-dy;if(sy<0||sy>=h)continue;for(let x=0;x<w;x++){const sx=x-dx;if(sx<0||sx>=w)continue;const a=(sy*w+sx)*4,b=(y*w+x)*4;for(let j=0;j<4;j++)out.data[b+j]=d[a+j];}}return out;}
// Registro: desloca para o apoio cair no pivô, sem escalar.
export function registerToPivot(img,pivot=SPEC.pivot){const m=metrics(img);if(!m.bounds)return {img,dy:0};const dy=pivot[1]-m.baseline;return {img:dy?translate(img,0,dy):img,dy};}
export function over(dst,src,dx=0,dy=0){const {width:w,height:h}=dst;for(let y=0;y<src.height;y++){const ty=y+dy;if(ty<0||ty>=h)continue;for(let x=0;x<src.width;x++){const tx=x+dx;if(tx<0||tx>=w)continue;const s=(y*src.width+x)*4;if(src.data[s+3]<128)continue;const t=(ty*w+tx)*4;for(let j=0;j<3;j++)dst.data[t+j]=src.data[s+j];dst.data[t+3]=255;}}return dst;}
const FRONT=['cabelo-tras','mochila','corpo','roupa','cabelo','acessorio'],BACK=['corpo','roupa','cabelo','cabelo-tras','mochila','acessorio'];
export const ORDER={s:FRONT,se:FRONT,sw:FRONT,e:FRONT,w:FRONT,ne:BACK,nw:BACK,n:BACK};
// Compõe um quadro: corpo + camadas de quadro (roupa) + camadas de cabeça presas à âncora.
export function composeFrame({base,head,dir,layers=[],ramps,slots=SLOTS}){
 const out=blank(base.width,base.height),parts={corpo:[base]};
 for(const l of layers){if(!l.image)continue;const place=l.kind==='head'?[head[0]-l.anchor[0],head[1]-l.anchor[1]]:[0,0];(parts[l.slot]??=[]).push([l.image,...place]);}
 for(const slot of ORDER[dir]||ORDER.s)for(const p of parts[slot]||[]){const [img,dx,dy]=Array.isArray(p)?p:[p,0,0];over(out,img,dx,dy);}
 return ramps?recolor(out,slots,ramps):out;
}
// ---------- conferência ----------
export function auditFrames(frames,{pivot=SPEC.pivot,scale=SPEC.scale,cell=SPEC.cell,slots=SLOTS}={}){
 const items=[],per=frames.map(f=>({...metrics(f.image,slots),head:f.head})),bad=(level,rule,text)=>items.push({level,rule,text});
 frames.forEach((f,i)=>{const m=per[i],n=`Quadro ${i}`;
  if(f.image.width!==cell||f.image.height!==cell)bad('fail','Grade',`${n}: ${f.image.width}×${f.image.height}; a célula é ${cell}×${cell}.`);
  if(!m.bounds){bad('fail','Grade',`${n}: vazio.`);return;}
  if(Math.abs(m.baseline-pivot[1])>scale)bad('fail','Pivô',`${n}: apoio em y=${m.baseline}; o pivô pede ${pivot[1]}.`);
  const offPct=m.off/m.area*100;if(offPct>.5)bad('fail','Paleta',`${n}: ${offPct.toFixed(1).replace('.',',')}% dos pixels fora da paleta-chave.`);
  if(m.semi)bad('warn','Alpha',`${n}: ${m.semi} pixels semitransparentes.`);
  if(!f.head)bad('fail','Cabeça',`${n}: sem âncora da cabeça.`);
 });
 const heights=per.filter(m=>m.bounds).map(m=>m.bounds.h).sort((a,b)=>a-b),med=heights[heights.length>>1];
 per.forEach((m,i)=>{if(!m.bounds)return;const v=Math.abs(m.bounds.h-med)/med*100;if(v>5)bad('fail','Altura',`Quadro ${i}: altura ${m.bounds.h} px, ${v.toFixed(0)}% diferente da mediana (${med}).`);else if(v>2)bad('warn','Altura',`Quadro ${i}: altura varia ${v.toFixed(1).replace('.',',')}% da mediana.`);});
 for(let i=0;i<frames.length;i++){const a=per[i],b=per[(i+1)%frames.length];if(frames.length<2)break;
  if(a.head&&b.head){const jump=Math.hypot(a.head[0]-b.head[0],a.head[1]-b.head[1]);if(jump>3*scale)bad('fail','Cabeça',`Âncora salta ${jump.toFixed(0)} px do quadro ${i} para o ${(i+1)%frames.length}.`);}
  for(const slot of ['cabelo','mochila']){const x=a.bySlot[slot]||0,y=b.bySlot[slot]||0;if(Math.max(x,y)>80&&Math.abs(x-y)/Math.max(x,y)>.12)bad('warn','Deriva',`${slot==='cabelo'?'Cabelo':'Mochila'} muda ${Math.round(Math.abs(x-y)/Math.max(x,y)*100)}% entre os quadros ${i} e ${(i+1)%frames.length}: redesenho da IA, não movimento.`);}}
 if(!items.some(i=>i.level!=='ok'))items.push({level:'ok',rule:'Quadros',text:`${frames.length} quadros conferidos: pivô, paleta, altura e cabeça.`});
 return {items,metrics:per};
}
// Cabelo preso: a borda de baixo do cabelo precisa cair sobre a cabeça do corpo.
export function auditHeadLayer(base,head,layer){
 const dx=head[0]-layer.anchor[0],dy=head[1]-layer.anchor[1],{width:w,height:h,data:d}=layer.image;let edge=0,hit=0;
 const opaqueBase=(x,y)=>x>=0&&y>=0&&x<base.width&&y<base.height&&base.data[(y*base.width+x)*4+3]>=128;
 for(let x=0;x<w;x++){let low=-1;for(let y=h-1;y>=0;y--)if(d[(y*w+x)*4+3]>=128){low=y;break;}if(low<0)continue;edge++;const bx=x+dx,by=low+dy;if(opaqueBase(bx,by)||opaqueBase(bx,by+1)||opaqueBase(bx,by+2))hit++;}
 const share=edge?hit/edge:0;
 return share<.6?{level:'fail',rule:'Cabelo',text:`Só ${Math.round(share*100)}% da borda do cabelo encosta na cabeça: camada descolada.`,share}:{level:'ok',rule:'Cabelo',text:`Cabelo preso à cabeça (${Math.round(share*100)}% da borda).`,share};
}
export function auditFrameLayer(base,layer,scale=SPEC.scale){
 const r=3*scale,{width:w,height:h,data:d}=layer,inBase=(x,y)=>{for(let yy=Math.max(0,y-r);yy<=Math.min(h-1,y+r);yy++)for(let xx=Math.max(0,x-r);xx<=Math.min(w-1,x+r);xx++)if(base.data[(yy*w+xx)*4+3]>=128)return true;return false;};
 let out=0,total=0;for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(d[(y*w+x)*4+3]>=128){total++;if(!inBase(x,y))out++;}
 return total&&out/total>.005?{level:'fail',rule:'Roupa',text:`${out} pixels da roupa fora da silhueta do corpo (+${r} px).`}:{level:'ok',rule:'Roupa',text:'Roupa dentro da silhueta.'};
}
// ---------- manifesto ----------
export function manifest(project){
 const half=v=>v.map(n=>Math.round(n/SPEC.scale)),actions={};
 for(const [id,a] of Object.entries(project.actions)){const dirs={};for(const [dir,entry] of Object.entries(a.dirs)){if(entry.mirror){dirs[dir]={mirror:entry.mirror};continue;}if(!entry.frames?.length)continue;dirs[dir]=entry.frames.map((f,i)=>({image:`base/${id}-${dir}-${i}.png`,head:f.head?half(f.head):null}));}
  if(Object.keys(dirs).length)actions[id]={ms:a.ms,loop:a.loop!==false,directions:dirs};}
 const layers={};for(const l of project.layers||[])layers[l.id]={kind:l.kind,slot:l.slot,images:Object.fromEntries(Object.keys(l.images||{}).map(dir=>[dir,`camadas/${l.id}-${dir}.png`])),...(l.kind==='head'?{anchor:Object.fromEntries(Object.entries(l.anchors||{}).map(([k,v])=>[k,half(v)]))}:{})};
 return {name:project.name,cell:[SPEC.cell/SPEC.scale,SPEC.cell/SPEC.scale],pivot:half(SPEC.pivot),scale:1,actions,layers,palette:'paleta.json',rulesVersion:RULES};
}
export function paletteJson(project){return {slots:project.slots.map(s=>({id:s.id,name:s.name,tones:s.tones,fixed:!!s.fixed})),variants:VARIANTS,rulesVersion:RULES};}
// Reduz 2× → 1× por fator inteiro: pega o pixel de cima à esquerda de cada bloco opaco (sem média, preserva a paleta).
export function downscale(img,f=SPEC.scale){const out=blank(img.width/f,img.height/f);for(let y=0;y<out.height;y++)for(let x=0;x<out.width;x++){let pick=-1;for(let yy=0;yy<f&&pick<0;yy++)for(let xx=0;xx<f;xx++){const i=((y*f+yy)*img.width+x*f+xx)*4;if(img.data[i+3]>=128){pick=i;break;}}if(pick<0)continue;const o=(y*out.width+x)*4;for(let j=0;j<4;j++)out.data[o+j]=img.data[pick+j];}return out;}
