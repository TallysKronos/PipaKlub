import test from 'node:test';
import assert from 'node:assert/strict';
import {pieceBox,placement,defaultRoom,auditPiece,auditSource,auditScene,autoFit,alphaBounds,drawOrder,footprintRect,manifest,presetKaelRoom,crc32,zip,verdict,pixelBlock} from './model.mjs';
const inPoly=(poly,x,y)=>{let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)hit=!hit;}return hit;};
function raster(w,h,poly,bg=0){const data=new Uint8ClampedArray(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4,on=inPoly(poly,x+.5,y+.5);data[i]=on?120:255;data[i+1]=on?80:255;data[i+2]=40;data[i+3]=on?255:bg;}return {width:w,height:h,data};}
const wardrobe={id:'guarda-roupa',kind:'floor',footprint:[2,1],height:4,cell:[7,1]};
test('caixa da peça segue a fórmula da especificação (R9)',()=>{
 assert.deepEqual(pieceBox(wardrobe),{w:96,h:176,anchor:[64,176],poly:[[0,144],[64,176],[96,160],[96,32],[32,0],[0,16]]});
 assert.deepEqual(pieceBox({kind:'floor',footprint:[2,4],height:2}).anchor,[64,160]);
 assert.deepEqual([pieceBox({kind:'flat',footprint:[5,3]}).w,pieceBox({kind:'flat',footprint:[5,3]}).h],[256,128]);
 const win=pieceBox({kind:'wallLeft',footprint:[2],height:1.5});assert.deepEqual([win.w,win.h,win.anchor],[64,80,[0,80]]);
});
test('posição na tela usa a âncora no canto frontal da pegada',()=>{
 const room=defaultRoom(),at=placement(room,wardrobe);
 // origem (256,160); canto frontal (7,1) → x=256+6·32=448, y=160+8·16=288; menos a âncora (64,176).
 assert.deepEqual([at.x,at.y],[384,112]);
 assert.deepEqual(footprintRect(wardrobe),{u0:5,v0:0,u1:7,v1:1});
});
test('peça desenhada na caixa passa; ângulo de 30° e deslocamento reprovam',()=>{
 const box=pieceBox(wardrobe),good=auditPiece(wardrobe,raster(box.w,box.h,box.poly));
 assert.equal(verdict(good.items),'ok',JSON.stringify(good.items));
 // 30°: inclinação tan(30°)=0,577 nas arestas de baixo, mesma largura.
 const t=Math.tan(Math.PI/6),h=box.h,bad=[[0,h-64*t],[64,h],[96,h-32*t],[96,32],[32,0],[0,16]];
 const thirty=auditPiece(wardrobe,raster(96,176,bad));assert.equal(verdict(thirty.items),'fail');assert.ok(thirty.items.some(i=>/inclinação 0,58/.test(i.text)),JSON.stringify(thirty.items));
 const shifted=raster(96,176,box.poly.map(([x,y])=>[x+6,y-4]));assert.equal(verdict(auditPiece(wardrobe,shifted).items),'fail');
});
test('fonte com fundo opaco e halo é apontada',()=>{
 const box=pieceBox(wardrobe),opaque=raster(box.w,box.h,box.poly,255);assert.equal(verdict(auditSource(opaque)),'fail');
 const halo=raster(box.w,box.h,box.poly);for(let i=3;i<halo.data.length;i+=4)if(halo.data[i]===255&&i%3===0)halo.data[i]=140;assert.equal(verdict(auditSource(halo)),'warn');
});
test('ajuste automático escolhe redução inteira e alinha base e lado esquerdo',()=>{
 const fit=autoFit(pieceBox(wardrobe),{x:10,y:20,w:384,h:704});assert.deepEqual(fit,{scale:1/4,freeScale:null,offset:[-2,-5],exact:true});
 const odd=autoFit(pieceBox(wardrobe),{x:0,y:0,w:150,h:270});assert.equal(odd.exact,false);assert.ok(Math.abs(odd.freeScale-96/150)<1e-9);
 assert.deepEqual(alphaBounds(raster(10,10,[[2,3],[8,3],[8,9],[2,9]])),{x:2,y:3,w:6,h:6});
});
test('bloco de pixel é estimado em arte ampliada',()=>{
 const w=96,h=96,data=new Uint8ClampedArray(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4,c=((x>>2)*37+(y>>2)*91)%256;data[i]=c;data[i+1]=255-c;data[i+2]=(c*7)%256;data[i+3]=255;}
 assert.equal(pixelBlock({width:w,height:h,data}),4);
});
test('ordem de desenho, conferência da cena e manifesto do quarto do Kael',()=>{
 const project=presetKaelRoom(),issues=auditScene(project.room,project.pieces);assert.deepEqual(issues.filter(i=>i.level==='fail'),[]);
 const kael={id:'kael',layer:'actor',rect:{u0:8,v0:4,u1:9,v1:5}},desk={id:'mesa',rect:{u0:7,v0:0,u1:10,v1:2}},bed={id:'cama',rect:{u0:0,v0:1,u1:2,v1:5}};
 assert.deepEqual(drawOrder([kael,desk,bed,{id:'tapete',layer:'flat',rect:null}]).map(i=>i.id),['tapete','cama','mesa','kael']);
 const clash=auditScene(project.room,[...project.pieces,{id:'bau',kind:'floor',footprint:[1,1],height:1,cell:[6,1]}]);assert.ok(clash.some(i=>/mesmas células/.test(i.text)));
 project.pieces.find(p=>p.id==='guarda-roupa').image='data:image/png;base64,';const m=manifest(project);assert.equal(m.pieces.cama.image,null);assert.deepEqual(m.pieces['guarda-roupa'],{image:'guarda-roupa.png',size:[96,176],kind:'floor',footprint:[2,1],height:4,anchor:[64,176],cell:[7,1],rulesVersion:'grade-iso-1'});
 assert.equal(m.pieces.janela.wall,'esquerda');assert.deepEqual(m.grid,{cell:[64,32],height:32,scale:1});
});
test('zip sem compressão com CRC correto',()=>{
 assert.equal(crc32(new TextEncoder().encode('hello')),0x3610a686);
 const out=zip([{name:'a.txt',data:'hello'},{name:'pasta/b.json',data:'{}'}]),view=new DataView(out.buffer);
 assert.equal(view.getUint32(0,true),0x04034b50);assert.equal(view.getUint32(out.length-22,true),0x06054b50);assert.equal(view.getUint16(out.length-12,true),2);
});
