import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {sharp} from '../../scripts/kael-raster.mjs';
import {metrics,auditTorsoLayer,auditHeadLayer} from './model.mjs';
const root=new URL('../../art/avatar/kael-v1/',import.meta.url);
const read=async src=>{const {data,info}=await sharp(Buffer.from(src.split(',')[1],'base64')).raw().toBuffer({resolveWithObject:true});return {width:info.width,height:info.height,data};};
test('Kael: pele sem branco de olho na testa, camadas separadas e mochila acima da cintura nos 24 quadros',async()=>{
 const p=JSON.parse(await fs.readFile(new URL('kael.avatarstudio.json',root),'utf8')),bag=p.layers.find(l=>l.slot==='mochila'),hair=p.layers.find(l=>l.slot==='cabelo');assert.equal(bag.kind,'torso');let count=0;
 for(const action of ['parado','andar'])for(const dir of ['se','ne']){
  const layer={image:await read(bag.images[dir]),anchor:bag.anchors[dir]},hairLayer={image:await read(hair.images[dir]),anchor:hair.anchors[dir]};
  for(const f of p.actions[action].dirs[dir].frames){const image=await read(f.src),m=metrics(image);assert.equal(m.baseline,224);assert.equal(m.off,0);assert.equal(m.semi,0);assert.equal(m.bySlot.cabelo||0,0);assert.equal(m.bySlot.mochila||0,0);
   assert.equal(auditTorsoLayer(image,f.torso,layer).level,'ok',`${action} ${dir} ${count}`);assert.equal(auditHeadLayer(image,f.head,hairLayer).level,'ok');
   for(let y=0;y<f.head[1]-4;y++)for(let x=0;x<image.width;x++){const i=(y*image.width+x)*4;if(image.data[i+3])assert.notDeepEqual([...image.data.subarray(i,i+3)],[255,255,255],`eye white in forehead: ${action} ${dir} ${x},${y}`);}count++;
  }
 }assert.equal(count,24);
});
