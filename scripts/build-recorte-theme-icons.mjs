// Geometric control markers, not illustrated icons (the latter belong to PIP-65).
import fs from 'node:fs/promises';
import {recorteTokens} from './sync-recorte-tokens.mjs';
const t=recorteTokens(),out=new URL('../godot/assets/ui/recorte-v1/theme/markers/',import.meta.url);
await fs.mkdir(out,{recursive:true});
const save=(id,w,h,body)=>fs.writeFile(new URL(id+'.svg',out),`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>\n`);
for(const [state,color] of [['normal',t.papel],['focus',t.rabiola],['disabled',t['tinta-3']]]){
  await save('diamond-'+state,32,32,`<path d="M16 2L29 16 16 30 3 16Z" fill="${color}" stroke="${t.nanquim}" stroke-width="2"/>`);
  for(const on of [false,true])await save('toggle-'+(on?'on':'off')+'-'+state,64,40,`<path d="M9 6H61L54 34H2Z" fill="${t['tinta-2']}" stroke="${t['papel-2']}" stroke-width="2"/><path d="M${on?45:18} 6l14 14-14 14-14-14Z" fill="${color}" stroke="${t.nanquim}" stroke-width="2"/>`);
  for(const on of [false,true])await save('check-'+(on?'on':'off')+'-'+state,32,32,`<path d="M16 2L30 16 16 30 2 16Z" fill="${on?color:t['tinta-2']}" stroke="${color}" stroke-width="2"/>${on?`<path d="M9 16l5 5 10-12" fill="none" stroke="${t.nanquim}" stroke-width="3"/>`:''}`);
}
await save('empty',1,1,'');
console.log('Recorte: geometric control markers exported.');
