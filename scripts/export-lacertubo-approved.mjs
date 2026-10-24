// Import the user's saved Soulgen project and bake it without reconstructing poses.
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {validate,exportPlan,render,sample} from '../tools/soulgen-studio/model.mjs';
const input=process.argv[2];if(!input)throw Error('Informe o projeto Soulgen salvo e aprovado.');
const {createCanvas,loadImage}=await import(pathToFileURL(process.env.SOULGEN_CANVAS_MODULE||'C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/index.js'));
const bytes=fs.readFileSync(input),project=JSON.parse(bytes),check=validate(project);if(!check.ok)throw Error(check.errors.join('\n'));
const root='art/soulgen/keys/lacertubo-v2',images={},sources={};fs.mkdirSync(root+'/source',{recursive:true});
for(const [id,a]of Object.entries(project.assets)){
 const buffer=a.src.startsWith('data:')?Buffer.from(a.src.split(',')[1],'base64'):fs.readFileSync(a.src.replace(/^\//,''));
 const target=root+'/source/approved-'+id+'.png';fs.writeFileSync(target,buffer);
 const png=await loadImage(target);if(png.width!==a.width||png.height!==a.height)throw Error('Dimensões divergentes: '+id);
 a.src='/'+target;images[id]=png;sources[id]=createHash('sha256').update(buffer).digest('hex');
}
project.creatureId='lacertubo-v2';project.artRevision=3;project.rigRevision=2;
const output=root+'/color-rig-v2/lacertubo-v2.soulgen.json';fs.writeFileSync(output,JSON.stringify(project,null,2)+'\n');
const plan=exportPlan(project,{fps:12,cell:256,columns:8}),sheet=createCanvas(plan.width,plan.height),g=sheet.getContext('2d'),frames={},animations={},playback={};
for(const f of plan.frames){const tile=createCanvas(256,256);render(tile.getContext('2d'),project,images,sample(project,f.clip,f.time),{scale:plan.renderScale,facing:-1});g.drawImage(tile,f.x,f.y);frames[f.name]={frame:{x:f.x,y:f.y,w:256,h:256},duration:f.duration};}
for(const [id,a]of Object.entries(plan.animations)){animations[id]=a.frames;playback[id]={loop:a.loop,durations:a.frames.map(()=>1000/12)};}
const dir='assets/creatures/lacertubo-v2';fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(dir+'/lacertubo.png',sheet.toBuffer('image/png'));
const portrait=createCanvas(640,480);render(portrait.getContext('2d'),project,images,sample(project,'idle',.6),{scale:3.1});fs.writeFileSync(dir+'/portrait.png',portrait.toBuffer('image/png'));
const manifest=JSON.parse(fs.readFileSync('assets/atlas.json'));manifest.atlases.lacertubo={frames,animations,playback,meta:{image:'creatures/lacertubo-v2/lacertubo.png',size:{w:plan.width,h:plan.height},viewport:{x:0,y:0,w:256,h:256},source:output,artRevision:3,rigRevision:2,format:'RGBA8888'}};fs.writeFileSync('assets/atlas.json',JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(root+'/approved-export.json',JSON.stringify({approvedFile:input.split(/[\\/]/).at(-1),approvedSha256:createHash('sha256').update(bytes).digest('hex'),sources,project:output,gameAtlas:dir+'/lacertubo.png',frames:plan.frames.length,fps:12,check},null,2)+'\n');
console.log('Montagem salva incorporada: '+plan.frames.length+' quadros; posições, pivôs, hierarquia e animações preservados.');
