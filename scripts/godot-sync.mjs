import fs from 'node:fs';
import path from 'node:path';
import {createParkBossScene} from '../src/park-boss-layout.js';
import {veredasTerrainPlan} from '../src/veredas-region-renderer.js';
const root='godot/assets';fs.mkdirSync(root,{recursive:true});
for(const [source,target] of [['assets/avatar/kael-v1','kael'],['assets/characters/nina-v1/overworld.png','nina.png'],['assets/characters/nina-v1/portrait.png','nina-portrait.png'],['assets/world/park-isometric-v1/veredas-terrain-v1.png','terrain.png'],['assets/world/village-isometric-v1/chest.png','chest.png'],['assets/world/park-isometric-v1/canopy.png','canopy.png'],['assets/world/park-isometric-v1/trunk.png','trunk.png'],['assets/creatures/starters-soulgen-v2/rabbito.png','rabbito.png']])fs.cpSync(source,path.join(root,target),{recursive:true});
const atlas=JSON.parse(fs.readFileSync('assets/atlas.json','utf8'));fs.writeFileSync(path.join(root,'rabbito.json'),JSON.stringify(atlas.atlases.rabbito));
const s=createParkBossScene();fs.writeFileSync(path.join(root,'veredas.json'),JSON.stringify({width:s.width,height:s.height,walk:s.tiled.layers.Walkable,solids:s.tiled.layers.Solids,chests:s.veredas.chests,water:s.veredas.water,terrain:veredasTerrainPlan(s)}));
console.log('Godot: artes originais e planta das Veredas sincronizadas.');
