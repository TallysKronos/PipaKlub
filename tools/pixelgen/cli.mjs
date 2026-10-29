#!/usr/bin/env node
// Pixelgen for agents: every edit is a command or a JSON list of operations, every result can
// be looked at as PNG/GIF/text, and `check` says whether the sprite is ready. See AGENTS.md.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {convert,serialize,validateProject,pixels} from './core.mjs';
import {compositeAll} from './document.mjs';
import {sequencesFor,playbackOrder,duration,atlas} from './animation.mjs';
import {aseprite} from './aseprite.mjs';
import {godotResource} from './godot.mjs';
import {qualityReport} from './quality.mjs';
import {legibilityReport,GROUNDS} from './legibility.mjs';
import {apply,frameList,layerIndex,toHex,setRamp} from './draw.mjs';
import {renderFrame,renderSheet,renderGrounds,gifFrames,asciiFrame,Canvas,frameRGBA,renderBoard,sceneGif,sceneFor} from './render.mjs';
import {encodePNG,decodePNG} from './png.mjs';
import {encodeGIF} from './gif.mjs';
import {rigReport,recipe,validateSheet,validatePose,measure,POINTS,RECIPES} from './rig.mjs';

const HELP=`Pixelgen CLI — uso: npm run pixel -- <comando> <projeto.pixelgen.json> [opções]

  new <arq> --size 48x64 [--name Nome] [--palette outro.pixelgen.json|cores.gpl|"#hex,#hex"]
  info <arq>                         resumo JSON: camadas, quadros, sequências, paleta, rampas
  ramp <arq> <nome> <#escuro> ... <#claro>   rampa nomeada (use "nome:0" nas operações)
  draw <arq> <ops.json | ->          aplica uma lista JSON de operações (ver AGENTS.md)
  ascii <arq> [--frame i] [--layer nome]     grade de caracteres + legenda de cores
  render <arq> --out pasta [--frame i|nome|all] [--zoom 8] [--ground grama|terra|calcada|noite|xadrez]
         [--silhouette] [--onion] [--pose] [--sheet] [--grounds] [--gif sequência] [--no-grid]
         [--board seq,seq|all]  prancha: uma linha por sequência, no cenário da ação
         (climb → barranco com escada, swim → água, o resto na grama); --gif também usa o cenário
  pose <arq> --frame i [topo=24,8 queixo=24,29 ...] [--clear]   marca/mostra os pontos da pose
         pontos: topo queixo ombroTras ombroFrente maoTras maoFrente quadril peTras peFrente
  recipe <arq> <idle|walk|run> <S|SO|O|NO|N|NE|E|SE> --base quadro [--replace] [--stride 1]
         gera o ciclo a partir da pose parada, movendo as camadas de cada parte
  sheet <arq> [ficha.json] [--set cabecas=2.5 --set altura=58 ...]   ficha do personagem
  check <arq> [--sequence nome] [--json]     legibilidade + geometria; sai com código 1 se reprovar
  import <imagem.png> <arq> [--cols 4 --rows 1 --width 48 --height 64 --colors 32 ...]
  export <arq> [--png folha.png] [--frame-png quadro.png --frame i] [--aseprite a.aseprite]
         [--atlas a.json] [--godot res://caminho/folha.png --tres a.tres] [--gpl paleta.gpl]`;

function args(list){const out={_:[],set:[]};for(let i=0;i<list.length;i++){const a=list[i];if(a.startsWith('--')){const k=a.slice(2),v=list[i+1];if(v===undefined||v.startsWith('--'))out[k]=true;else if(k==='set'){out.set.push(v);i++;}else{out[k]=v;i++;}}else out._.push(a);}return out;}
const load=file=>{if(!fs.existsSync(file))throw Error(`Projeto não encontrado: ${file}`);return validateProject(JSON.parse(fs.readFileSync(file,'utf8')));};
const save=(file,p)=>{fs.mkdirSync(path.dirname(path.resolve(file)),{recursive:true});fs.writeFileSync(file,JSON.stringify(serialize(p)));};
const writePNG=(file,cv)=>{fs.mkdirSync(path.dirname(path.resolve(file)),{recursive:true});fs.writeFileSync(file,encodePNG(cv.data,cv.w,cv.h));return file;};
const print=v=>console.log(typeof v==='string'?v:JSON.stringify(v,null,2));
const target=v=>v===undefined?undefined:v==='all'?'all':/^\d+$/.test(v)?Number(v):v;

function summary(p){compositeAll(p);return {name:p.name,size:`${p.width}x${p.height}`,layers:p.layers.map((l,i)=>({index:i,name:l.name,visible:l.visible!==false,locked:!!l.locked})),
 frames:p.frames.map((f,i)=>({index:i,name:f.name,duration:duration(f),opaque:f.indices.reduce((n,v)=>n+(v?1:0),0)})),sequences:sequencesFor(p).map(s=>({...s})),
 palette:p.palette.map((c,i)=>i?toHex(c):'transparente'),ramps:p.ramps||{}};}
function paletteFrom(spec){
 if(!spec)return [[0,0,0,0],[20,24,30,255],[233,228,216,255]];
 if(spec.endsWith('.json'))return load(spec).palette.map(c=>[...c]);
 if(spec.endsWith('.gpl'))return [[0,0,0,0],...fs.readFileSync(spec,'utf8').split('\n').map(l=>l.trim().split(/\s+/).slice(0,3).map(Number)).filter(c=>c.length===3&&c.every(Number.isInteger)).map(c=>[...c,255])];
 return [[0,0,0,0],...spec.split(',').map(h=>{const n=parseInt(h.replace('#',''),16);return [n>>16,(n>>8)&255,n&255,255];})];
}
// Verdict for agents. Errors block delivery; warnings ask for a look.
export function check(p,{sequence}={}){
 const frames=sequence?frameList(p,sequence):null,leg=legibilityReport(p,{frames}),q=qualityReport(p),errors=[],warnings=[];
 if(leg.darkEdge<.7)errors.push(`Contorno escuro em ${Math.round(leg.darkEdge*100)}% da borda (mínimo 70%).`);
 for(const [k,v] of Object.entries(leg.grounds))if(k!=='noite'&&v>.25)errors.push(`Pouco contraste com ${k}: ${Math.round(v*100)}% da borda (máximo 25%).`);
 if(leg.grounds.noite>.25)warnings.push(`No chão escuro (noite) ${Math.round(leg.grounds.noite*100)}% da borda some; considere um realce de luz na borda.`);
 if(leg.confusingNeighbours>.18)warnings.push(`${Math.round(leg.confusingNeighbours*100)}% das cores vizinhas têm quase o mesmo brilho.`);
 const list=frames||p.frames.map((_,i)=>i);for(const i of list){const f=q.frames[i];if(!f.opaquePixels)errors.push(`Quadro ${i} (${f.name}) vazio.`);else{if(f.bounds.h<p.height*.45)warnings.push(`Quadro ${i}: figura ocupa só ${f.bounds.h}px de altura.`);if(f.isolatedPixels>2)warnings.push(`Quadro ${i}: ${f.isolatedPixels} pixels isolados.`);}}
 for(const s of q.sequences){if(sequence&&s.name!==sequence)continue;const still=/^(idle|parado)/.test(s.name);if(s.groundVariation>(still?1:2))(still?errors:warnings).push(`${s.name}: o apoio dos pés varia ${s.groundVariation}px.`);}
 for(const w of q.warnings)if(/toca|borda/.test(w))warnings.push(w);
 const rig=rigReport(p,{frames});errors.push(...rig.errors);warnings.push(...rig.warnings);
 return {pass:!errors.length,errors,warnings,metrics:{darkEdge:leg.darkEdge,grounds:leg.grounds,confusingNeighbours:leg.confusingNeighbours,colorsUsed:q.colorsUsed}};
}
export async function run(argv){
 const a=args(argv),[cmd,file,...rest]=a._;
 if(!cmd||cmd==='help'||a.help)return print(HELP);
 if(cmd==='new'){const [w,h]=String(a.size||'48x64').split('x').map(Number),palette=paletteFrom(a.palette);
  const p=validateProject({kind:'pixelgen',version:2,name:a.name||path.basename(file).replace(/\.pixelgen\.json$|\.json$/,''),width:w,height:h,cols:1,rows:1,palette,layers:[{name:'Corpo',visible:true,locked:false}],frames:[{name:'idle-S-1',indices:Array(w*h).fill(0),cels:[Array(w*h).fill(0)]}],sequences:[{name:'idle-S',start:0,end:0,loop:true}]});
  if(a.palette?.endsWith('.json'))p.ramps=load(a.palette).ramps;save(file,p);return print(summary(p));}
 if(cmd==='import'){const [out]=rest,src=decodePNG(fs.readFileSync(file)),opts=Object.fromEntries(Object.entries(a).filter(([k])=>k!=='_'));const p=validateProject({...convert(src,opts),name:a.name||path.basename(out).replace(/\.pixelgen\.json$/,'')});save(out,p);return print(summary(p));}
 const p=load(file);
 switch(cmd){
  case 'info':return print(summary(p));
  case 'ramp':{const [name,...colors]=rest;const list=setRamp(p,name,colors);save(file,p);return print({ramp:name,indices:list,colors:list.map(i=>toHex(p.palette[i]))});}
  case 'draw':{const src=rest[0];if(!src)throw Error('Informe o arquivo de operações ou - para ler da entrada.');const ops=JSON.parse(src==='-'?fs.readFileSync(0,'utf8'):fs.readFileSync(src,'utf8'));const log=apply(p,Array.isArray(ops)?ops:ops.ops);save(file,p);return print({ok:true,log});}
  case 'ascii':{const f=frameList(p,target(a.frame)??0)[0];return print(asciiFrame(p,f,a.layer===undefined?null:layerIndex(p,target(a.layer))));}
  case 'render':{
   const out=a.out||'pixelgen-render',zoom=Number(a.zoom)||8,ground=a.ground||'xadrez',written=[],base=path.join(out,path.basename(file).replace(/\.pixelgen\.json$|\.json$/,''));
   const list=frameList(p,target(a.frame)??0);
   if(a.board){const names=a.board===true||a.board==='all'?sequencesFor(p).map(s=>s.name):String(a.board).split(',');written.push(writePNG(`${base}-prancha.png`,renderBoard(p,names,{zoom:Number(a.zoom)||3})));}
   else if(a.sheet)written.push(writePNG(`${base}-folha${a.silhouette?'-silhueta':''}.png`,renderSheet(p,a.frame?list:p.frames.map((_,i)=>i),{zoom:Number(a.zoom)||3,ground:a.ground||'grama',silhouette:!!a.silhouette})));
   else if(a.grounds)for(const f of list)written.push(writePNG(`${base}-${f}-chaos-do-jogo.png`,renderGrounds(p,f)));
   else if(!a.gif&&!a.board)for(const f of list){const s=sequencesFor(p).find(s=>f>=s.start&&f<=s.end),prev=s?(f>s.start?f-1:s.loop!==false&&s.end>s.start?s.end:null):null,next=s?(f<s.end?f+1:s.loop!==false&&s.end>s.start?s.start:null):null;
    written.push(writePNG(`${base}-${f}${a.silhouette?'-silhueta':''}.png`,renderFrame(p,f,{zoom,grid:!a['no-grid'],ground,silhouette:!!a.silhouette,onion:!!a.onion,pose:!!a.pose,neighbours:[prev,next]})));}
   if(a.gif){const s=sequencesFor(p).find(s=>s.name===a.gif);if(!s)throw Error(`Sequência inexistente: ${a.gif}. Sequências: ${sequencesFor(p).map(s=>s.name).join(', ')}`);const g=a.ground||sceneFor(s.name)==='grama'?gifFrames(p,playbackOrder(s),{zoom:Number(a.zoom)||3,ground:a.ground||'grama'}):sceneGif(p,s,{zoom:Number(a.zoom)||4});const f=`${base}-${s.name}.gif`;fs.mkdirSync(out,{recursive:true});fs.writeFileSync(f,encodeGIF(g.frames,g.width,g.height,g.palette));written.push(f);}
   return print({written});}
  case 'pose':{const list=frameList(p,target(a.frame)??0),points=Object.fromEntries(rest.map(s=>{const m=/^([a-zA-Z]+)=(-?\d+),(-?\d+)$/.exec(s);if(!m)throw Error(`Ponto inválido: ${s}. Use nome=x,y.`);return [m[1],[Number(m[2]),Number(m[3])]];}));
   if(rest.length||a.clear){for(const i of list){const f=p.frames[i];f.pose=validatePose(a.clear?points:{...(f.pose||{}),...points},p.width,p.height);}save(file,p);}
   return print(list.map(i=>({frame:i,name:p.frames[i].name,pose:p.frames[i].pose||{},medidas:measure(p,i)})));}
  case 'recipe':{const [motion,dir]=rest;if(!a.base)throw Error('Informe --base com o quadro parado da direção.');const r=recipe(p,{motion,dir,base:target(a.base),replace:!!a.replace,stride:a.stride?Number(a.stride):1});save(file,p);return print(r);}
  case 'sheet':{let next={...(p.sheet||{})};if(rest[0])next={...next,...JSON.parse(fs.readFileSync(rest[0],'utf8'))};
   for(const s of a.set){const m=/^([a-zA-Z]+)=(.*)$/.exec(s);if(!m)throw Error(`Use --set chave=valor: ${s}`);next[m[1]]=m[2]===''?undefined:/^-?\d+(\.\d+)?$/.test(m[2])?Number(m[2]):m[1]==='rampas'?m[2].split(','):m[2];}
   if(rest[0]||a.set.length){p.sheet=validateSheet(next,p);save(file,p);}return print(p.sheet||{});}
  case 'check':{const r=check(p,{sequence:a.sequence});if(a.json)print(r);else{print(`${r.pass?'APROVADO':'REPROVADO'} · contorno ${Math.round(r.metrics.darkEdge*100)}% · cores ${r.metrics.colorsUsed}`);for(const e of r.errors)print('ERRO  '+e);for(const w of r.warnings)print('AVISO '+w);}if(!r.pass)process.exitCode=1;return;}
  case 'export':{const written=[],name=path.basename(file).replace(/\.pixelgen\.json$|\.json$/,'');
   if(a.png){const cv=new Canvas(p.width*p.cols,p.height*p.rows,[0,0,0,0]);p.frames.forEach((f,i)=>cv.blit(pixels(p,f),p.width,p.height,i%p.cols*p.width,Math.floor(i/p.cols)*p.height));written.push(writePNG(a.png,cv));}
   if(a['frame-png']){const i=frameList(p,target(a.frame)??0)[0],cv=new Canvas(p.width,p.height,[0,0,0,0]);cv.blit(frameRGBA(p,i),p.width,p.height,0,0);written.push(writePNG(a['frame-png'],cv));}
   if(a.aseprite){fs.writeFileSync(a.aseprite,Buffer.from(aseprite(p)));written.push(a.aseprite);}
   if(a.atlas){fs.writeFileSync(a.atlas,JSON.stringify(atlas(p,path.basename(a.png||name+'-sheet.png')),null,2));written.push(a.atlas);}
   if(a.godot){const f=a.tres||name+'.tres';fs.writeFileSync(f,godotResource(p,a.godot));written.push(f);}
   if(a.gpl){fs.writeFileSync(a.gpl,'GIMP Palette\nName: '+name+'\nColumns:8\n#\n'+p.palette.slice(1).map((c,i)=>c.slice(0,3).join(' ')+' Cor-'+(i+1)).join('\n')+'\n');written.push(a.gpl);}
   if(!written.length)throw Error('Escolha ao menos um formato: --png, --frame-png, --aseprite, --atlas, --godot, --gpl.');return print({written});}
  default:throw Error(`Comando desconhecido: ${cmd}\n\n${HELP}`);
 }
}
if(process.argv[1]===fileURLToPath(import.meta.url))run(process.argv.slice(2)).catch(e=>{console.error('Erro: '+e.message);process.exitCode=2;});
