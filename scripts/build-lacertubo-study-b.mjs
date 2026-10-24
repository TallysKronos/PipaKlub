// Separate authoring study. Never writes the game atlas or replaces Lacertubo A.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {validate,render,sample,exportPlan} from '../tools/soulgen-studio/model.mjs';
const {createCanvas,loadImage}=await import(pathToFileURL(process.env.SOULGEN_CANVAS_MODULE||'C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/index.js'));
const base='art/soulgen/keys/lacertubo/user-adjustment/user-saved.soulgen.json',root='art/soulgen/keys/lacertubo-v2',out=root+'/color-rig-v2';fs.mkdirSync(out,{recursive:true});
const original=JSON.parse(fs.readFileSync(base,'utf8')),p=structuredClone(original);
p.name='Lacertubo · Estudo B · encaixes internos';p.creatureId='lacertubo-v2';p.artRevision=3;p.rigRevision=1;
p.assets.parts.src='/'+root+'/source/parts-v2.png';p.assets.parts.name='Peças B · encaixes fechados';
p.brief={...p.brief,notes:'Alternativa B baseada na montagem salva pelo usuário. PVC interno nos ombros e quadris, papel sobre as juntas; cotovelos e joelhos aparentes. Vela dorsal 18% menor. Não substitui o boss do jogo.'};
// Upper leg caps tuck beneath the chest. Lower legs remain exposed below its edge.
const by=id=>p.parts.find(q=>q.id===id);
by('frontFar').z=0;by('rearFar').z=1;by('tail').z=2;by('sail').z=3;
by('frontNear').z=4;by('rearNear').z=5;by('body').z=6;by('head').z=7;
// Preserve the user's positioning as the starting point, then shrink around the
// sail's own insertion so the reduction cannot leave its base floating.
const sail=by('sail'),[sx,sy,sw,sh]=sail.rect,[px,py]=sail.pivot;
sail.rect=[px+(sx-px)*.82,py+(sy-py)*.82,sw*.82,sh*.82];
const images={};for(const [id,a]of Object.entries(p.assets)){images[id]=await loadImage(a.src.startsWith('/')?'.'+a.src:a.src);if(images[id].width!==a.width||images[id].height!==a.height)throw Error('Dimensões divergentes: '+id);}
const report=validate(p);if(!report.ok)throw Error(report.errors.join('\n'));
fs.writeFileSync(out+'/lacertubo-v2.soulgen.json',JSON.stringify(p,null,2)+'\n');
const portrait=createCanvas(640,480);render(portrait.getContext('2d'),p,images,sample(p,'idle',.6),{scale:3.1});fs.writeFileSync(out+'/portrait.png',portrait.toBuffer('image/png'));
const review=createCanvas(1280,480),g=review.getContext('2d');g.fillStyle='#e8ecd6';g.fillRect(0,0,1280,480);
for(const [i,project]of [original,p].entries()){const ims={};for(const [key,a]of Object.entries(project.assets))ims[key]=await loadImage(a.src.startsWith('/')?'.'+a.src:a.src);render(g,project,ims,sample(project,'idle',.6),{clear:false,scale:2.9,offsetX:i?320:-320,offsetY:10});g.fillStyle='#24474a';g.font='bold 20px sans-serif';g.fillText(i?'B · encaixes internos':'A · seu ajuste salvo',35+i*640,35);}
fs.writeFileSync(out+'/comparison.png',review.toBuffer('image/png'));
// Offline sheet for inspecting the study in a DCC, without touching runtime assets.
const plan=exportPlan(p,{fps:12,cell:256,columns:8}),sheet=createCanvas(plan.width,plan.height),sg=sheet.getContext('2d');
for(const f of plan.frames){const tile=createCanvas(256,256);render(tile.getContext('2d'),p,images,sample(p,f.clip,f.time),{scale:plan.renderScale});sg.drawImage(tile,f.x,f.y);}
fs.writeFileSync(out+'/study-atlas.png',sheet.toBuffer('image/png'));
fs.writeFileSync(out+'/export.json',JSON.stringify({report,plan,scope:'authoring comparison only'},null,2)+'\n');
console.log('Estudo B exportado sem alterar o boss do jogo.');
