import test from 'node:test';
import assert from 'node:assert/strict';
import {SLOTS,SPEC,VARIANTS,blank,hexToInt,keyIndex,quantize,suggestMapping,applyMapping,appearanceRamps,recolor,metrics,autoHead,registerToPivot,mirror,composeFrame,auditFrames,auditHeadLayer,auditFrameLayer,manifest,downscale,translate} from './model.mjs';
const tone=(slot,i)=>SLOTS.find(s=>s.id===slot).tones[i];
function paint(img,x0,y0,x1,y1,hex,shape='rect'){const c=hexToInt(hex),cx=(x0+x1)/2,cy=(y0+y1)/2,rx=(x1-x0)/2,ry=(y1-y0)/2;for(let y=y0;y<y1;y++)for(let x=x0;x<x1;x++){if(shape==='oval'&&((x+.5-cx)/rx)**2+((y+.5-cy)/ry)**2>1)continue;const i=(y*img.width+x)*4;img.data[i]=c>>16;img.data[i+1]=c>>8&255;img.data[i+2]=c&255;img.data[i+3]=255;}return img;}
// Boneco simples na paleta-chave, com balanço de cabeça "bob" e pés no pivô (y=224).
function figure(bob=0,{hair=true}={}){const f=blank(256,256);
 paint(f,104,180,124,224,tone('calca',1));paint(f,132,180,152,224,tone('calca',1));paint(f,100,214,126,224,tone('tenis',0));paint(f,130,214,156,224,tone('tenis',0));
 paint(f,96,110+bob,160,184,tone('jaqueta',1));paint(f,112,116+bob,144,170,tone('camiseta',1));
 paint(f,98,52+bob,158,112+bob,tone('pele',2),'oval');paint(f,112,78+bob,120,86+bob,tone('olhos',1));paint(f,136,78+bob,144,86+bob,tone('olhos',1));
 if(hair)paint(f,96,40+bob,160,72+bob,tone('cabelo',1),'oval');return f;}
const noisy=img=>{const o=blank(img.width,img.height);o.data.set(img.data);for(let i=0;i<o.data.length;i+=4)if(o.data[i+3]){const n=(i/4%7)-3;o.data[i]=Math.max(0,Math.min(255,o.data[i]+n*2));o.data[i+2]=Math.max(0,Math.min(255,o.data[i+2]-n));}return o;};
test('paleta-chave tem rampas únicas e variações com o mesmo número de tons',()=>{
 const total=SLOTS.reduce((s,x)=>s+x.tones.length,0);assert.equal(keyIndex().size,total);
 for(const [slot,list] of Object.entries(VARIANTS))for(const [,ramp] of list)if(ramp)assert.equal(ramp.length,SLOTS.find(s=>s.id===slot).tones.length,slot);
});
test('arte com ruído volta para as cores-chave e troca de rampa recolore só o grupo',()=>{
 const src=noisy(figure()),clusters=quantize([src],16),assign=suggestMapping(clusters),keyed=applyMapping(src,clusters,assign);
 const m=metrics(keyed);assert.equal(m.off,0);assert.ok(m.bySlot.pele>1500&&m.bySlot.jaqueta>2000,JSON.stringify(m.bySlot));
 const dark=recolor(keyed,SLOTS,appearanceRamps(SLOTS,{pele:3})),i=(80*256+128)*4;
 assert.deepEqual([...dark.data.slice(i,i+3)],[0x6b,0x3c,0x22]);assert.equal(metrics(dark).bySlot.pele,undefined);
 // Grupo sem atribuição conta como fora da paleta.
 const none=applyMapping(src,clusters,assign.map(()=>null));assert.equal(metrics(none).off,metrics(none).area);
});
test('âncora da cabeça automática cai no rosto e acompanha o balanço',()=>{
 const [x,y]=autoHead(figure(0)),[,y2]=autoHead(figure(4));assert.ok(Math.abs(x-128)<=2&&y>60&&y<100,`${x},${y}`);assert.equal(y2-y,4);
});
test('conferência de quadros: pivô, altura, cabeça e deriva',()=>{
 const good=[0,2,4,2].map(b=>({image:figure(b),head:autoHead(figure(b))}));
 const ok=auditFrames(good);assert.deepEqual(ok.items.map(i=>i.level),['ok'],JSON.stringify(ok.items));
 const lifted={image:translate(figure(0),0,-8),head:[128,70]},noHead={image:figure(2),head:null};
 const bad=auditFrames([good[0],lifted,noHead,good[3]]).items;
 assert.ok(bad.some(i=>i.rule==='Pivô'&&i.level==='fail'));assert.ok(bad.some(i=>i.rule==='Cabeça'&&/sem âncora/.test(i.text)));
 const drift=auditFrames([good[0],{image:figure(2,{hair:false}),head:[128,80]}]).items;assert.ok(drift.some(i=>i.rule==='Deriva'),JSON.stringify(drift));
 assert.equal(registerToPivot(lifted.image).dy,8);
});
test('cabelo preso pela âncora e roupa dentro da silhueta',()=>{
 const base=figure(0,{hair:false}),head=autoHead(base),hair=paint(blank(80,50),8,6,72,40,tone('cabelo',2),'oval');
 const layer={image:hair,anchor:[40,40]};assert.equal(auditHeadLayer(base,head,layer).level,'ok');
 assert.equal(auditHeadLayer(base,head,{image:hair,anchor:[40,140]}).level,'fail');
 const coat=paint(blank(256,256),94,110,162,186,tone('jaqueta',2));assert.equal(auditFrameLayer(base,coat).level,'ok');
 assert.equal(auditFrameLayer(base,paint(blank(256,256),0,0,60,60,tone('jaqueta',2))).level,'fail');
 const out=composeFrame({base,head,dir:'se',layers:[{kind:'head',slot:'cabelo',image:hair,anchor:[40,40]}]}),i=(head[1]-20)*256*4+head[0]*4;
 assert.equal(out.data[i+3],255);assert.equal(out.data[i]<<16|out.data[i+1]<<8|out.data[i+2],hexToInt(tone('cabelo',2)));
});
test('espelho, redução 2× e manifesto em 1×',()=>{
 const f=paint(blank(4,2),0,0,1,1,'#ff0000');assert.equal(mirror(f).data[3*4],255);
 const half=downscale(figure(0));assert.deepEqual([half.width,half.height,metrics(half).baseline],[128,128,112]);
 const m=manifest({name:'Kael',actions:{andar:{ms:100,dirs:{se:{frames:[{head:[140,90]}]},sw:{mirror:'se'},ne:{frames:[]}}}},layers:[{id:'espetado',kind:'head',slot:'cabelo',images:{se:1,ne:1},anchors:{se:[40,40]}}]});
 assert.deepEqual(m.actions.andar.directions,{se:[{image:'base/andar-se-0.png',head:[70,45]}],sw:{mirror:'se'}});
 assert.deepEqual(m.cell,[128,128]);assert.deepEqual(m.pivot,[64,112]);assert.deepEqual(m.layers.espetado.anchor,{se:[20,20]});
});
test('posição na figura separa cores parecidas (tênis escuro × cabelo escuro)',async()=>{
 const {clusterStats}=await import('./model.mjs');
 // Tênis pintado com um azul-marinho mais perto do cabelo que do tênis padrão.
 const f=figure(0),shoe=hexToInt('#141a3a');for(let y=214;y<224;y++)for(let x=100;x<156;x++){const i=(y*256+x)*4;if(f.data[i+3]){f.data[i]=shoe>>16;f.data[i+1]=shoe>>8&255;f.data[i+2]=shoe&255;}}
 const clusters=quantize([f],12),k=clusters.findIndex(c=>c.color===shoe);assert.ok(k>=0);
 assert.equal(suggestMapping(clusters)[k].slot,'cabelo');assert.equal(suggestMapping(clusters,SLOTS,clusterStats([f],clusters))[k].slot,'tenis');
});
test('quatro diagonais seguem os eixos da grade 2:1, com espelhos à esquerda',async()=>{
 const {facingIso,DIRS,DRAWN,MIRROR,ORDER}=await import('./model.mjs');
 // Andar ao longo dos eixos da grade: (±32,±16) na tela.
 assert.equal(facingIso(32,16),'se');assert.equal(facingIso(-32,16),'sw');assert.equal(facingIso(32,-16),'ne');assert.equal(facingIso(-32,-16),'nw');
 // Andar reto na tela empata entre duas diagonais: mantém a anterior quando ela é uma delas.
 assert.equal(facingIso(1,0,'ne'),'ne');assert.equal(facingIso(1,0,'se'),'se');assert.equal(facingIso(1,0,'sw'),'se');assert.equal(facingIso(0,1,'sw'),'sw');assert.equal(facingIso(0,-1,'ne'),'ne');
 assert.equal(facingIso(0,0,'nw'),'nw');assert.deepEqual(DIRS,['se','ne','nw','sw']);assert.deepEqual(DRAWN,['se','ne']);
 for(const [d,m] of Object.entries(MIRROR))assert.deepEqual(ORDER[d],ORDER[m]);
});
