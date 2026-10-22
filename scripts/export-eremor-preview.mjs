import fs from 'node:fs';
const pack='assets/creatures/eremor-v1/',out='output/eremor-sprites-v1';
const data=file=>'data:image/png;base64,'+fs.readFileSync(pack+file).toString('base64');
const battle=data('battle/eremor.png'),world=data('overworld/eremor.png');
let html=fs.readFileSync('art/eremor-sprites-v1/index.html','utf8');
const renderer=fs.readFileSync('src/world-actors.js','utf8').split('export function createWorldCompanions')[1];
html=html.replace("import {createWorldCompanions} from '/src/world-actors.js';",'function createWorldCompanions'+renderer)
 .replace("fetch(pack+'battle/eremor.json').then(r=>r.json())",'Promise.resolve('+fs.readFileSync(pack+'battle/eremor.json','utf8')+')')
 .replace("fetch(pack+'overworld/manifest.json').then(r=>r.json())",'Promise.resolve('+fs.readFileSync(pack+'overworld/manifest.json','utf8')+')')
 .replace("image(pack+'battle/eremor.png')",'image('+JSON.stringify(battle)+')')
 .replace("image(pack+'overworld/eremor.png')",'image('+JSON.stringify(world)+')')
 .replace('href="/assets/creatures/eremor-v1/battle/eremor.png" target="_blank"','href="'+battle+'" download="eremor-batalha.png"')
 .replace('href="/assets/creatures/eremor-v1/overworld/eremor.png" target="_blank"','href="'+world+'" download="eremor-overworld.png"');
if(html.includes('fetch(pack')||html.includes('from \'/src/'))throw Error('Export still depends on server');
fs.mkdirSync(out,{recursive:true});fs.cpSync(pack,out,{recursive:true});fs.writeFileSync(out+'/preview.html',html);
console.log('Exported Eremor offline review and PNG/JSON pack.');
