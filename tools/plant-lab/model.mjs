import {validateCustomAssets} from './custom-assets.mjs';
import {rampValid} from './ramp-rules.mjs';
import {validateEvents} from './map-events.mjs';
import {validateCollision} from './collision-shapes.mjs';
import {WATERFALLS} from './waterfall-assets.mjs';
import {WALL_IDS} from './wall-kit.mjs';
import {GROUNDS} from './ground-kit.mjs';
import {NATURE_ASSETS} from './nature-kit.mjs';
export const MAX_LEVEL=12;
export const TILE = 32;
export const PLANTS = [
  {id:'capim-rabiola-a',name:'Capim baixo',family:'Capim',anchor:[32,52]},
  {id:'capim-rabiola-b',name:'Capim com espiga',family:'Capim',anchor:[32,52]},
  {id:'arbusto-folha-pipa-a',name:'Arbusto de folhas',family:'Arbustos',anchor:[32,52]},
  {id:'arbusto-folha-pipa-b',name:'Arbusto florido',family:'Arbustos',anchor:[32,52]},
  {id:'bromelia-do-vento-a',name:'Bromélia coral',family:'Bromélias',anchor:[32,52]},
  {id:'bromelia-do-vento-b',name:'Bromélia dupla',family:'Bromélias',anchor:[32,52]},
  {id:'pedra-da-margem',name:'Pedra de margem',family:'Margens',anchor:[32,52]},
  {id:'junco-da-margem',name:'Junco',family:'Margens',anchor:[32,52]},
  {id:'vitoria-regia',name:'Vitória-régia',family:'Aquáticas',anchor:[32,52]},
  {id:'arvore-kronasta',name:'Árvores de Kronasta',family:'Floresta conectada',anchor:[32,80]}
];
PLANTS.push(...NATURE_ASSETS,...WATERFALLS);
export const ASSETS = [...PLANTS,{id:'kael',name:'Kael',anchor:[40,65]}];
export const FLOORS = ['grass','dirt','stone','sand','water',...GROUNDS.map(g=>g.id)];
export const clone = value => JSON.parse(JSON.stringify(value));
const campaignFloors={
  bosque:'chao-bosque-sombrio',grama:'grass',terra:'dirt',mato:'chao-grama-seca',
  piso:'stone',construcao:'chao-tijolos',calcada:'chao-calcamento',canteiro:'chao-musgo',
  asfalto:'chao-ardosia',agua:'water',ponte:'chao-trilha',rocha:'chao-basalto',
};
const campaignPassable=new Set(['grama','terra','mato','piso','calcada','asfalto','ponte']);
const campaignDirections={'v-':'n','v+':'s','u-':'w','u+':'e'};
const campaignEvents={entrada:'spawn',saida:'exit',npc:'npc',item:'item',encontro:'encounter',gatilho:'trigger'};

export function projectFromCampaign(map,{legacyRamps=false}={}){
  if(map.schema!=='overworld-godot-1')throw Error('Formato de campanha inválido.');
  const {w:width,h:height,cells}=map;
  const minLevel=Math.min(...cells.filter(cell=>campaignPassable.has(cell.material)).map(cell=>cell.level),0);
  const raw={version:1,width,height,autotiling:false,objects:[],events:[],
    floors:cells.map(cell=>campaignFloors[cell.material]??'stone'),
    levels:cells.map(cell=>Math.max(0,Math.min(MAX_LEVEL,cell.level-minLevel))),
    ramps:cells.map(()=>null),
    campaignBlocked:cells.map(cell=>!campaignPassable.has(cell.material)),
  };
  if(!legacyRamps)raw.rampProfiles=cells.map(()=>null);
  for(let index=0;index<cells.length;index++){
    const cell=cells[index],direction=campaignDirections[cell.ramp];
    if(!direction)continue;
    if(legacyRamps&&(cell.rampFrom??0)>=.5)raw.levels[index]=Math.min(MAX_LEVEL,raw.levels[index]+1);
    else{
      raw.ramps[index]=direction;
      if(!legacyRamps)raw.rampProfiles[index]=[cell.rampFrom??0,cell.rampTo??1];
    }
  }
  for(let index=0;index<cells.length;index++){
    if(legacyRamps&&raw.ramps[index]&&!rampValid(raw,index))raw.ramps[index]=null;
  }
  for(const piece of map.pieces??[]){
    const u=Math.floor(piece.u),v=Math.floor(piece.v),w=piece.fu??1,h=piece.fv??1;
    if(piece.blocks){
      for(let y=Math.max(0,v);y<Math.min(height,v+h);y++){
        for(let x=Math.max(0,u);x<Math.min(width,u+w);x++)raw.campaignBlocked[y*width+x]=true;
      }
    }
    const asset=PLANTS.some(candidate=>candidate.id===piece.asset)?piece.asset:
      ({arvore:'arvore-kronasta',arbusto:'arbusto-folha-pipa-a',flores:'flores-amarelas',pedra:'pedra-da-margem'})[piece.asset];
    if(!asset||u<0||v<0||u>=width||v>=height)continue;
    raw.objects.push({id:raw.objects.length+1,asset,x:(u+.5)*TILE,y:(v+.5)*TILE});
  }
  for(const event of map.events??[]){
    const type=campaignEvents[event.type];
    if(!type||event.u<0||event.v<0||event.u>=width||event.v>=height)continue;
    raw.events.push({id:'native-'+raw.events.length,type,x:Math.min(width*TILE-1,(event.u+.5)*TILE),
      y:Math.min(height*TILE-1,(event.v+.5)*TILE),label:event.name,text:event.props?.texto,
      targetMap:event.props?.destino?'campaign-'+event.props.destino:''});
  }
  const spawn=Math.floor(map.spawn.v)*width+Math.floor(map.spawn.u);
  const index=!raw.campaignBlocked[spawn]&&spawn>=0&&spawn<cells.length?spawn:raw.campaignBlocked.indexOf(false);
  if(index<0)throw Error('O mapa não tem uma célula livre para Kael.');
  raw.player={x:(index%width+.5)*TILE,y:(Math.floor(index/width)+.5)*TILE};
  return validateLayout(raw);
}
export function repairImportedRamps(layout,map){
  if(!layout.campaignBlocked||layout.rampProfiles)return layout;
  if(layout.width!==map.w||layout.height!==map.h)throw Error('A cópia foi redimensionada. Abra uma cópia nova para importar as rampas.');
  const legacy=projectFromCampaign(map,{legacyRamps:true});
  const native=projectFromCampaign(map);
  const fixed=clone(layout);
  fixed.rampProfiles=native.rampProfiles;
  for(let index=0;index<map.cells.length;index++){
    if(!native.ramps[index])continue;
    if(layout.levels[index]!==legacy.levels[index]||layout.ramps[index]!==legacy.ramps[index]){
      throw Error('Há edições no relevo sobre uma rampa original. Abra uma cópia nova para preservar esta versão.');
    }
    fixed.levels[index]=native.levels[index];
    fixed.ramps[index]=native.ramps[index];
  }
  for(let index=0;index<map.cells.length;index++){
    if(native.ramps[index]&&rampValid(native,index)&&!rampValid(fixed,index)){
      throw Error('Um patamar foi editado junto à rampa original. Abra uma cópia nova para preservar esta versão.');
    }
  }
  return validateLayout(fixed);
}
export function validateLayout(raw) {
  if(!raw || raw.version!==1 || !Number.isInteger(raw.width) || !Number.isInteger(raw.height) || raw.width<8 || raw.width>64 || raw.height<8 || raw.height>64) throw Error('Projeto inválido: dimensões entre 8×8 e 64×64.');
  const {width,height}=raw;
  if(!Array.isArray(raw.floors)||raw.floors.length!==width*height||raw.floors.some(t=>!FLOORS.includes(t)))throw Error('O piso contém células inválidas.');
  const count=width*height;
  const campaignBlocked=raw.campaignBlocked;
  if(campaignBlocked!==undefined&&(!Array.isArray(campaignBlocked)||campaignBlocked.length!==count||campaignBlocked.some(value=>typeof value!=='boolean')))throw Error('Colisões da campanha inválidas.');
  const levels=raw.levels===undefined?Array(count).fill(0):raw.levels;
  const ramps=raw.ramps===undefined?Array(count).fill(null):raw.ramps;
  const cliffs=raw.cliffs===undefined?Array(count).fill('earth'):raw.cliffs;
  if(!Array.isArray(levels)||levels.length!==count||levels.some(h=>!Number.isInteger(h)||h<0||h>MAX_LEVEL))throw Error('Cotas inválidas: use níveis de 0 a 12.');
  if(!Array.isArray(ramps)||ramps.length!==count||ramps.some(r=>r!==null&&!['n','s','e','w'].includes(r)))throw Error('Rampas inválidas.');
  if(raw.rampProfiles!==undefined&&(!Array.isArray(raw.rampProfiles)||raw.rampProfiles.length!==count||raw.rampProfiles.some(p=>p!==null&&(!Array.isArray(p)||p.length!==2||!p.every(Number.isFinite)||p[0]<0||p[1]>1||p[0]>=p[1]))))throw Error('Perfis de rampa inválidos.');
  const rampProfiles=raw.rampProfiles?.map((profile,i)=>ramps[i]&&profile?[...profile]:null);
  if(!Array.isArray(cliffs)||cliffs.length!==count||cliffs.some(m=>!WALL_IDS.includes(m)))throw Error('Material de barranco inválido.');
  for(let i=0;i<count;i++)if(ramps[i]&&!rampProfiles?.[i]&&!rampValid({width,height,levels,ramps,rampProfiles},i))throw Error('Uma rampa precisa ligar dois patamares planos com uma cota de diferença.');
  if(raw.waterDepth&&(!Array.isArray(raw.waterDepth)||raw.waterDepth.length!==count||raw.waterDepth.some(v=>!Number.isInteger(v)||v<0||v>3)))throw Error('Profundidade da água inválida.');
  if(raw.flow&&(!Array.isArray(raw.flow)||raw.flow.length!==count||raw.flow.some(v=>v!==null&&!['n','s','e','w'].includes(v))))throw Error('Correnteza inválida.');
  if(raw.variants&&(!Array.isArray(raw.variants)||raw.variants.length!==count||raw.variants.some(v=>v!==null&&![0,1,2].includes(v))))throw Error('Variantes de piso inválidas.');
  if(raw.stairs&&(!Array.isArray(raw.stairs)||raw.stairs.length!==count||raw.stairs.some(v=>typeof v!=='boolean')))throw Error('Escadas inválidas.');
  if(!Array.isArray(raw.objects)||raw.objects.length>1500)throw Error('Máximo de 1.500 peças.');
  const point=p=>p&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=0&&p.y>=0&&p.x<=width*TILE&&p.y<=height*TILE;
  const customAssets=raw.customAssets?validateCustomAssets(raw.customAssets):[];
  const seen=new Set();
  const objects=raw.objects.map(o=>{
    if(!o||!PLANTS.some(p=>p.id===o.asset)&&!customAssets.some(p=>p.id===o.asset)||!Number.isSafeInteger(o.id)||o.id<1||seen.has(o.id)||!point(o))throw Error('Há uma peça inválida ou ID repetido.');
    seen.add(o.id);return {id:o.id,asset:o.asset,x:Math.round(o.x),y:Math.round(o.y),flip:!!o.flip,layer:o.layer==='objects'?'objects':'vegetation',collidable:!!o.collidable,...(o.decorative?{decorative:true}:{}),...(o.collision?{collision:validateCollision(o.collision)}:{})};
  });
  if(!point(raw.player))throw Error('Posição de Kael inválida.');
  return {...(rampProfiles?{rampProfiles}:{}),...(campaignBlocked?{campaignBlocked:[...campaignBlocked]}:{}),...(raw.variants?{variants:[...raw.variants]}:{}),...(raw.customAssets?{customAssets}:{}),...(raw.waterDepth?{waterDepth:[...raw.waterDepth]}:{}),...(raw.flow?{flow:[...raw.flow]}:{}),...(raw.stairs?{stairs:raw.stairs.map((v,i)=>!!v&&!!ramps[i])}:{}),...(raw.events?{events:validateEvents(raw.events,width,height)}:{}),version:1,width,height,tileSize:TILE,autotiling:raw.autotiling!==false,floors:[...raw.floors],levels:[...levels],ramps:[...ramps],cliffs:[...cliffs],objects,player:{x:Math.round(raw.player.x),y:Math.round(raw.player.y)},nextId:Math.max(0,...objects.map(o=>o.id))+1};
}
export function initialLayout() {
  const width=24,height=16,floors=Array(width*height).fill('grass');
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const bend=8+Math.round(Math.sin(x*.25)*1.3);
    if(Math.abs(y-bend)<=1 || ((x-13)**2/13+(y-8)**2/6<1) || (x>=17&&x<=18&&y>=9))floors[y*width+x]='dirt';
  }
  const specs=[
    [2,68,64],[3,106,75],[2,147,61],[0,184,83],[1,222,76],[4,284,66],
    [3,348,68],[2,387,78],[0,428,90],[5,511,79],[2,553,68],[3,591,79],[1,649,69],[0,703,92],
    [0,60,150],[4,104,173],[1,164,162],[2,208,144],[3,255,156],[0,318,180],
    [2,606,165],[5,670,181],[1,718,162],
    [3,61,386],[2,107,405],[0,159,389],[4,202,417],[1,267,405],
    [0,315,449],[5,370,446],[2,421,429],[3,460,443],[0,510,451],
    [3,643,401],[2,684,418],[4,724,390],[0,651,461],
    [0,90,321],[1,158,337],[4,701,304]
  ];
  return demoRelief(validateLayout({version:1,width,height,floors,objects:specs.map(([a,x,y],i)=>({id:i+1,asset:PLANTS[a].id,x,y,flip:i%4===0})),player:{x:348,y:285}}));
}
export function demoRelief(source){
  const a=clone(source),w=a.width,n=w*a.height;a.levels=Array(n).fill(0);a.ramps=Array(n).fill(null);a.cliffs=Array(n).fill('earth');
  const set=(x,y,h,m='earth')=>{if(x>=0&&y>=0&&x<w&&y<a.height){a.levels[y*w+x]=h;a.cliffs[y*w+x]=m;}};
  const ramp=(x,y,h)=>{set(x,y,h);a.ramps[y*w+x]='n';a.floors[y*w+x]='dirt';};
  // Two terraces with two-cell-wide, continuous northbound approaches.
  if(w>=22&&a.height>=12){
    for(let y=3;y<=6;y++)for(let x=2;x<=9;x++)if(!((y===3||y===6)&&(x===2||x===9)))set(x,y,1);
    for(let y=3;y<=4;y++)for(let x=4;x<=7;x++)set(x,y,2);
    for(const x of [5,6]){ramp(x,5,1);ramp(x,7,0);a.floors[6*w+x]='dirt';a.floors[4*w+x]='dirt';}
    for(let y=3;y<=6;y++)for(let x=16;x<=21;x++)if(!((y===3||y===6)&&(x===16||x===21)))set(x,y,2,'rock');
    for(const x of [18,19]){set(x,8,1,'rock');a.floors[8*w+x]='dirt';ramp(x,7,1);ramp(x,9,0);a.floors[6*w+x]='dirt';}
  }
  return validateLayout(a);
}
export function snapPoint(point, enabled=true) {
  return enabled?{x:Math.round(point.x/8)*8,y:Math.round(point.y/8)*8}:{x:Math.round(point.x),y:Math.round(point.y)};
}
export function floorCell(layout,x,y) {const c=Math.floor(x/TILE),r=Math.floor(y/TILE);return c>=0&&r>=0&&c<layout.width&&r<layout.height?r*layout.width+c:-1;}
export function sortedObjects(layout,includePlayer=true) {
  return [...layout.objects,...(includePlayer?[{id:-1,asset:'kael',...layout.player}]:[])].sort((a,b)=>a.y-b.y||a.id-b.id);
}
