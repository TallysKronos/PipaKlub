// Export the runtime's canonical tokens to the art manifest; no duplicated palette.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
export function recorteTokens(){
 const source=fs.readFileSync('godot/scripts/campaign/ui_tokens.gd','utf8');
 const definitions=Object.fromEntries([...source.matchAll(/^const (\w+) := Color\("([0-9a-f]{6})"\)/gm)].map(([,id,hex])=>[id,'#'+hex.toUpperCase()]));
 const names={'nanquim':'NANQUIM','tinta':'TINTA','tinta-2':'TINTA_2','tinta-3':'TINTA_3','papel':'PAPEL','papel-2':'PAPEL_2','rabiola':'RABIOLA','ceu':'CEU','sol':'SOL','folha':'FOLHA'};
 if(Object.values(names).some(id=>!definitions[id]))throw Error('Incomplete Recorte palette');
 return {...Object.fromEntries(Object.entries(names).map(([name,id])=>[name,definitions[id]])),veu:{color:definitions.TINTA,alpha:.72}};
}
export function syncRecorteManifest(){
 const file='godot/assets/campaign/ui-recorte/manifest.json',manifest=JSON.parse(fs.readFileSync(file,'utf8'));
 manifest.source_reference='art/ui/hud-recorte-v1/ESPECIFICACAO.md';
 manifest.token_source='res://scripts/campaign/ui_tokens.gd';
 manifest.tokens=recorteTokens();
 manifest.typography={display:{family:'Lilita One',weight:400,slant_degrees:8},lettering:{family:'Bangers',weight:400},label:{family:'Barlow Condensed',weight:700,tabular_numbers:true},text:{family:'Nunito',weights:[600,800]},licenses:'godot/licenses/'};
 fs.writeFileSync(file,JSON.stringify(manifest,null,2)+'\n');
 console.log('Recorte manifest synchronized from ui_tokens.gd.');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href)syncRecorteManifest();
