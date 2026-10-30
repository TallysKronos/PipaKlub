import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createCharacterBase,characterGuide,styleReport,paintCharacterGuides} from './character-style.mjs';
import {validateProject,serialize,pixels} from './core.mjs';
import {cloneDocument,compositeAll} from './document.mjs';
import {buildSheetPack} from './sheet-pack.mjs';
import {run} from './cli.mjs';
function fixture({headBottom=23,torsoTop=24}={}){
 const p=validateProject(createCharacterBase({name:'Ari'}));
 const draw=(layer,x,y,w,h,color)=>{for(let yy=y;yy<y+h;yy++)for(let xx=x;xx<x+w;xx++)p.frames[0].cels[layer][yy*p.width+xx]=color;};
 draw(5,19,10,10,headBottom-9,6);draw(3,18,torsoTop,12,45-torsoTop,9);draw(1,19,44,4,17,12);draw(2,26,44,4,17,12);compositeAll(p);
 p.frames=[p.frames[0]];p.cols=p.rows=1;p.sequences=[{name:'idle-S',start:0,end:0,loop:true}];return p;
}
test('DS profiles keep body differences, shared support and independent review metadata through undo/save',()=>{
 const youth=validateProject(createCharacterBase()),adult=validateProject(createCharacterBase({body:'adulto'})),wide=validateProject(createCharacterBase({body:'robusto'}));
 assert.equal(youth.frames.length,8);assert.equal(youth.layers.length,7);assert.equal(characterGuide(youth).base,61);
 assert.ok(characterGuide(adult).head<characterGuide(youth).head);assert.ok(characterGuide(wide).shoulderHalf>characterGuide(youth).shoulderHalf);
 const copy=cloneDocument(youth);copy.style.baseReviewed=true;assert.equal(youth.style.baseReviewed,false);
 assert.deepEqual(validateProject(serialize(copy)).style,copy.style);assert.deepEqual(validateProject(serialize(copy)).sheet,copy.sheet);
 copy.sheet.cabecas=3.4;copy.sheet.altura=52;assert.equal(characterGuide(copy).heads,3.4);assert.equal(characterGuide(copy).height,52);
 const compact=validateProject(createCharacterBase({width:32,height:48}));assert.deepEqual(characterGuide(compact).pivot,[16,46]);
 assert.throws(()=>createCharacterBase({width:64,height:64}),/48×64 ou 32×48/);
 const bad=serialize(youth);bad.style.baseReviewed='yes';assert.throws(()=>validateProject(bad),/explicitamente/);
});
test('DS report catches a large painted head and detached head even when pose keypoints claim correct proportions',()=>{
 const good=fixture();assert.deepEqual(styleReport(good).errors,[]);
 assert.match(styleReport(fixture({headBottom:35,torsoTop:36})).errors.join(),/cabeça\/cabelo ocupam/);
 const detached=fixture({headBottom:20,torsoTop:26});assert.match(styleReport(detached).errors.join(),/separada do tronco/);
 detached.frames[0].pose.queixo[1]=characterGuide(detached).chin;assert.match(styleReport(detached).errors.join(),/separada do tronco/);
});
test('DS expansion needs explicit visual milestones, while guides cannot alter any native pixels',()=>{
 const p=fixture();p.sequences=['idle','walk','attack'].map(name=>({name:name+'-S',start:0,end:0,loop:true}));
 assert.match(styleReport(p).errors.join(),/antes de expandir/);p.style.baseReviewed=p.style.cycleReviewed=true;assert.deepEqual(styleReport(p).errors,[]);
 const before=serialize(p),ctx={save(){},restore(){},beginPath(){},moveTo(){},lineTo(){},stroke(){},setLineDash(){}};paintCharacterGuides(ctx,p,8);assert.deepEqual(serialize(p),before);
});
test('separate sheet packing preserves every native colour, exact support, direction rows and reverse playback',()=>{
 const idle=fixture(),walk=validateProject(serialize(idle));walk.frames.push({...walk.frames[0],indices:walk.frames[0].indices.slice(),cels:walk.frames[0].cels.map(c=>c.slice()),duration:110});walk.cols=2;walk.rows=1;
 walk.frames[0].name='walk-E-1';walk.frames[1].name='walk-E-2';walk.frames[1].cels[3][30*48+22]=16;compositeAll(walk);
 walk.sequences=[{name:'walk-E',start:0,end:1,direction:'reverse',loop:true}];const pack=buildSheetPack([idle,walk]);
 assert.equal(pack.sheets.length,2);assert.deepEqual(pack.atlas.pivot,{x:24,y:62});assert.deepEqual(pack.atlas.sequences[1].frames,[2,1]);
 for(const f of pack.atlas.frames){const p=[idle,walk][f.source.project],rgba=pixels(p,p.frames[f.source.frame]);for(let y=0;y<64;y++)assert.deepEqual(pack.rgba.slice(((f.frame.y+y)*pack.width+f.frame.x)*4,((f.frame.y+y)*pack.width+f.frame.x+48)*4),rgba.slice(y*48*4,(y+1)*48*4));}
 const bad=validateProject(serialize(walk));bad.palette[1][0]++;assert.throws(()=>buildSheetPack([idle,bad]),/incompatíveis/);
 bad.palette=idle.palette;bad.sequences[0].name='../escape-E';assert.throws(()=>buildSheetPack([idle,bad]),/sem caminhos/);
 assert.throws(()=>buildSheetPack([idle,idle]),/duplicada/);
});
test('agent CLI creates the same reusable DS base, refuses empty-art review and writes a compatible pack',async()=>{
 const folder=fs.mkdtempSync(path.join(os.tmpdir(),'pixelgen-ds-')),file=path.join(folder,'ari.pixelgen.json');
 try{
  await run(['new',file,'--profile','soulmon-ds-v1','--name','Ari','--body','robusto']);const p=validateProject(JSON.parse(fs.readFileSync(file)));assert.equal(p.style.body,'robusto');
  await assert.rejects(run(['profile',file,'--base-reviewed','true']),/Desenhe/);
  fs.writeFileSync(file,JSON.stringify(serialize(fixture())));await run(['pack',file,'--out',path.join(folder,'out')]);
  assert.ok(fs.existsSync(path.join(folder,'out/idle.png')));assert.deepEqual(JSON.parse(fs.readFileSync(path.join(folder,'out/completo.atlas.json'))).pivot,{x:24,y:62});
 }finally{fs.rmSync(folder,{recursive:true,force:true});}
});
