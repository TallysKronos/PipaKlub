import fs from 'node:fs';
import {CRAFT_ICON_PATHS} from '../src/workshop-craft-renderer.js';
const manifest=JSON.parse(fs.readFileSync('assets/workshop/v1/manifest.json'));
const runtime=['workshop-craft','workshop-craft-renderer','workshop-craft-controls'].map(n=>fs.readFileSync('src/'+n+'.js','utf8').replace(/^export /gm,'')).join('\n');
const html=fs.readFileSync('src/workshop-craft-preview.html','utf8').replace('/* CRAFT_STYLE */',()=>fs.readFileSync('src/workshop.css','utf8')+'\n'+fs.readFileSync('src/workshop-craft.css','utf8')).replace('/* CRAFT_RUNTIME */',()=>runtime).replace('/* CRAFT_RECTS */',()=>JSON.stringify(manifest.rects));
fs.mkdirSync('art/workshop-v2',{recursive:true});fs.writeFileSync('art/workshop-v2/index.html',html);
for(const [id,d]of Object.entries(CRAFT_ICON_PATHS)){const file=({pinça:'pinca',linha:'linha',tesoura:'tesoura',cola:'cola',vento:'vento',luz:'gabarito'})[id]||id;fs.writeFileSync('assets/workshop/v2/'+file+'.svg','<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path d="'+d+'" fill="none" stroke="#244f50" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/></svg>\n');}
console.log('Built neutral kite workshop and reusable vector assets.');
