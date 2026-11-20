import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {validateLayout} from './model.mjs';
import {moveOnTerrain} from './terrain.mjs';
import {blockedByObjects} from './studio.mjs';
const root='art/environment/coletaneas-kronasta-v1';
const catalog=JSON.parse(fs.readFileSync(root+'/manifest.json'));
// North: lookout above the warehouse. South: street and fishing dock.
const width=35,height=29,n=width*height;
const floors=Array(n).fill('water'),levels=Array(n).fill(0),ramps=Array(n).fill(null);
const cliffs=Array(n).fill('face-arenito'),rampProfiles=Array(n).fill(null);
const set=(x,y,f,z)=>{const i=y*width+x;floors[i]=f;if(z!==undefined)levels[i]=z};
const rect=(x0,y0,x1,y1,f,z)=>{for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)set(x,y,f,z)};
const lawn='chao-grama-baixa', shore='chao-areia-umida', street='chao-calcamento', cargo='chao-ardosia';
const stone='chao-ruinas', concrete='face-concreto';
rect(4,4,24,24,shore,0);rect(6,2,22,26,shore,0);
rect(3,7,25,21,shore,0);rect(5,16,28,23,shore,0);
rect(24,20,31,24,'chao-tijolos',0);
rect(6,19,18,24,street,0);rect(9,23,14,26,street,0);
rect(16,20,28,22,'chao-tijolos',0);
rect(6,4,22,14,lawn,2);rect(5,7,24,15,lawn,2);
rect(6,13,18,14,street,2);
rect(17,8,25,15,cargo,2);rect(20,6,24,8,cargo,2);
rect(9,11,17,13,street,2);
rect(7,4,15,8,stone,4);rect(8,3,14,4,stone,4);rect(6,5,8,7,lawn,4);
rect(7,5,9,7,'chao-pedra-musgosa',4);

function northRamp(x0,x1,bottom,base,material){
 for(let x=x0;x<=x1;x++){
  for(let i=0;i<4;i++){
   const y=bottom-i,index=y*width+x;
   set(x,y,material,base+Math.floor(i/2));
   ramps[index]='n';
   rampProfiles[index]=i%2?[.5,1]:[0,.5];
   cliffs[index]=concrete;
  }
 }
}
for(let y=6;y<=15;y++)for(let x=16;x<=25;x++){
 if(levels[y*width+x]===2)cliffs[y*width+x]=concrete;
}
rect(9,15,12,18,street,0);
rect(20,16,22,19,cargo,0);
rect(12,9,14,12,stone,2);
northRamp(9,12,18,0,street);
northRamp(20,22,19,0,cargo);
northRamp(12,14,12,2,stone);
// The shallows follow the shoreline. The boat sits off the lower berth.
const waterDepth=floors.map((floor,index)=>{
 if(floor!=='water')return 0;
 const x=index%width,y=Math.floor(index/width);
 let distance=4;
 for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){
  const xx=x+dx,yy=y+dy;
  if(xx>=0&&yy>=0&&xx<width&&yy<height&&floors[yy*width+xx]!=='water'){
   distance=Math.min(distance,Math.abs(dx)+Math.abs(dy));
  }
 }
 return Math.min(3,distance-1);
});
const center=(x,y)=>({x:(x+.5)*32,y:(y+.5)*32});
const point=(id,type,x,y,label,text)=>({id,type,...center(x,y),label,text,once:type==='item'});
const events=[
  point('entrada','spawn',11,24,'Entrada do cais','Suba pela rua da feira. A doca fica à direita.'),
  point('placa','trigger',11,21,'Placa do cais','À frente, subida da feira. À direita, doca e acesso de serviço.'),
  point('carga','trigger',20,12,'Pátio de carga','As bobinas sobem da doca pela rampa de serviço. O caminho claro leva ao mirante.'),
  point('reparo','item',27,22,'Linha encerada','Um carretel de linha encerada entre as redes do atracadouro.'),
  point('mirante','trigger',11,6,'Mirante dos Carretéis','Do mirante, a feira e a doca aparecem em níveis diferentes.'),
];
const base={version:1,width,height,floors,levels,ramps,rampProfiles,waterDepth,cliffs,objects:[],customAssets:[],autotiling:true,events,player:center(11,24)};
function verify(raw){
 const a=validateLayout(raw),seen=new Set(),queue=[[11,24]];
 for(const [x,y] of queue){
  const key=y*width+x;if(seen.has(key))continue;seen.add(key);
  for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){
   const xx=x+dx,yy=y+dy;if(xx<0||yy<0||xx>=width||yy>=height||seen.has(yy*width+xx))continue;
   let at=center(x,y);const target=center(xx,yy);
   for(let step=0;step<8;step++){
    const next=moveOnTerrain(a,at,{x:dx*4,y:dy*4});
    if(blockedByObjects(a,at,next))break;
    at=next;
   }
   if(Math.hypot(at.x-target.x,at.y-target.y)<1)queue.push([xx,yy]);
  }
 }
 for(const {x,y,label} of a.events)assert.ok(seen.has(Math.floor(y/32)*width+Math.floor(x/32)),'Evento inalcançável: '+label);
 for(const [x,y] of [[10,17],[11,14],[18,12],[21,18],[21,14],[13,10]])assert.ok(seen.has(y*width+x),'Percurso interrompido em '+x+','+y);
 for(const [x,bottom] of [[10,18],[21,19],[13,12]]){
  for(const direction of [-1,1]){
   const start=center(x,direction===-1?bottom+1:bottom-4);
   let at=start;
   for(let step=0;step<40;step++){
    const next=moveOnTerrain(a,at,{x:0,y:direction*4});
    assert.ok(!blockedByObjects(a,at,next),'Objeto obstrui a rampa em '+x+','+bottom);
    at=next;
   }
   assert.equal(at.y,start.y+direction*160,'Rampa interrompida em '+x+','+bottom);
  }
 }
 return seen.size;
}
console.log('Blocagem:',verify(base),'células alcançáveis');
const byId=new Map(catalog.flatMap(page=>page.sprites.map(asset=>[asset.id,asset])));
function put(id,x,y,collision){
 const art=byId.get(id),asset='custom-cais-'+id;
 if(!base.customAssets.some(a=>a.id===asset)){
  base.customAssets.push({id:asset,name:art.name,source:'data:image/png;base64,'+fs.readFileSync(path.join(root,art.file)).toString('base64'),frameWidth:art.width,frameHeight:art.height,anchor:art.anchor,frames:1});
 }
 base.objects.push({id:base.objects.length+1,asset,...center(x,y),layer:'objects',collidable:!!collision,...(collision?{collision:{shape:'rect',width:collision[0],height:collision[1],y:-collision[1]/2}}:{})});
}
// The two market stalls share a service edge; the street stays empty in front.
put('placa-de-trilha',13.1,21.3);put('poste-de-rua',8.2,20);put('poste-de-rua',13.1,18.8);
put('barraca-de-feira',7.1,21,[55,22]);put('caixotes-de-laranja',6.3,22.3,[35,19]);
put('bancada-de-pipas',15.1,20,[50,20]);put('expositor-de-carreteis',16.2,19.8,[32,19]);
put('bromelia-no-banco',15.2,21.15);put('arbusto-coral',5.7,23.3);

// Cargo bay uses one loading line. Containers are against the back, machinery faces the yard.
put('conteiner-ocre',21.2,9.25,[62,34]);put('conteiner-ocre',24.7,9.25,[62,34]);
put('portico-de-icamento',23.8,11.8,[72,22]);put('bobina-em-palete',24.7,12.5,[39,22]);
put('tambores',24.6,14.1,[36,20]);put('grelha-de-drenagem',19.3,12.7);
put('poste-de-rua',18.5,14.6);put('balizadores-com-corrente',23.7,15.1,[70,10]);

// The lower berth is a destination with a clear edge, moorings and one pocket of activity.
put('rede-e-covo',28.8,21.6,[35,20]);put('cabeco-com-corda',26,24);
put('cabeco-com-corda',30,24);put('barco-a-remo',28,25.1);put('taboa',30.6,22.9);
put('capim-rabiola',24.2,23.5);put('poste-de-rua',25.3,20.6);

// Garden beds frame the two mouths of the high path. The center of the lookout stays free.
put('ipe-florido',7.8,7.1,[40,24]);put('arvore-costeira',15.5,10.5,[32,24]);
put('rocha-musgosa',7.2,10.6,[36,23]);put('arbusto-coral',8.5,10.5);put('samambaia-enrolada',6.2,11.1);
put('fonte-de-terracota',11.3,4.9,[46,23]);put('mureta-de-pedra',8.5,8.5,[66,12]);
put('mureta-de-pedra',10.4,8.5,[66,12]);put('bromelia-no-banco',14.6,5.4);put('arbusto-coral',14.5,6.6);
console.log('Mapa com arte:',verify(base),'células alcançáveis,',base.objects.length,'peças,',base.customAssets.length,'assets');
const target=root+'/mapas';fs.mkdirSync(target,{recursive:true});
fs.writeFileSync(target+'/cais-dos-carreteis-v2.json',JSON.stringify({...validateLayout(base),name:'Cais dos Carretéis · Refeito'},null,2)+'\n');
