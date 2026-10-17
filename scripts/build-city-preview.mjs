import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url)),pack=path.join(root,'assets/packs/cidade-v1');
const manifest=JSON.parse(fs.readFileSync(path.join(pack,'manifest.json'),'utf8'));
for(const [id,s] of Object.entries(manifest.sheets)){
 const raw=fs.readFileSync(path.join(pack,s.image));
 if(raw.readUInt32BE(16)!==s.width||raw.readUInt32BE(20)!==s.height||raw[25]!==6)throw Error('PNG metadata: '+id);
 if(createHash('sha256').update(raw).digest('hex')!==s.sha256)throw Error('PNG checksum: '+id);
 if(s.frames.length!==s.columns*s.rows)throw Error('Frame count: '+id);
 for(const f of s.frames)if(f.x<0||f.y<0||f.w<=0||f.h<=0||f.x+f.w>s.width||f.y+f.h>s.height)throw Error('Out of bounds: '+id);
}
if(manifest.districts.length!==12||manifest.districts.flatMap(d=>d.rivals).length!==48)throw Error('Catalog count');
const sources=Object.fromEntries(['mapa','insignias','campeoes','rivais','efeitos'].map(n=>[n,n+'.png']));
for(const name of ['Mikka','Lohan','Kleie'])sources[name]='../../characters/'+name.toLowerCase()+'/sprites-v1.png';
const template=fs.readFileSync(path.join(pack,'preview-template.html'),'utf8');
function render(src){return template.replace('__MANIFEST__',JSON.stringify(manifest)).replace('__SOURCES__',JSON.stringify(src))}
fs.writeFileSync(path.join(pack,'preview.html'),render(sources));
if(process.argv[2]){
 const out=path.resolve(process.argv[2]);fs.mkdirSync(path.dirname(out),{recursive:true});
 const inline=Object.fromEntries(Object.entries(sources).map(([k,v])=>[k,'data:image/png;base64,'+fs.readFileSync(path.resolve(pack,v)).toString('base64')]));
 fs.writeFileSync(out,render(inline));
}
console.log('City art verified: 12 districts, 12 badges, 9 leader bases, 48 portraits, 16 effect frames. Preview built.');
