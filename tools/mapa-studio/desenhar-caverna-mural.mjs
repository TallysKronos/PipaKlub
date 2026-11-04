import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=40,H=40,source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const id=p=>'caverna-mural-'+p.toLowerCase(),names=['Vestíbulo do Nó','Galeria do Vento','Salão do Primeiro Laço'];
const heights={...source,name:'mural-alturas',image:'../tiles/rascunho.png',firstgid:101,tiles:[]};
for(let n=0;n<=6;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});
heights.tiles.push({id:7,type:'altura',properties:props({nivel:-1})});
for(let n=0;n<4;n++)heights.tiles.push({id:8+n,type:'altura',properties:props({nivel:n,rampa:'v-'})});
export function muralPart(part){
 const n=part.charCodeAt(0)-65,base=n,ix=(u,v)=>v*W+u,mat=Array(W*H).fill('rocha'),levels=[],ramps=new Set(),events=[],pieces=[];let next=1;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)levels.push(base+3);
 const paint=(u,v,w,h,m='terra')=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){mat[ix(x,y)]=m;levels[ix(x,y)]=base+(y<20?1:0);}};
 const oval=(cx,cy,rx,ry)=>{for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2)if(((u+1-cx)/rx)**2+((v+1-cy)/ry)**2<=1)paint(u,v,2,2,'grama');};
 const path=(points,width=5)=>{for(let k=1;k<points.length;k++){const a=points[k-1],b=points[k],steps=Math.ceil(Math.hypot(a[0]-b[0],a[1]-b[1])*4);for(let j=0;j<=steps;j++)paint(Math.round(a[0]+(b[0]-a[0])*j/steps)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*j/steps)-Math.floor(width/2),width,width);}};
 const object=(type,name,u,v,p={})=>({id:next++,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const access=u=>{paint(u-1,18,5,6);for(let x=u-1;x<u+4;x++)ramps.add(ix(x,20));};
 const stairs=[];
 const accessAt=u=>{access(u);stairs.push({u:u-1,v:20,width:5,length:2});};
 if(part==='A'){
  oval(22,29,13,7);oval(20,10,12,7);
  path([[25,39],[25,29],[14,29],[14,22]],5);path([[14,19],[14,10],[25,10],[25,0]],5);accessAt(13);
  path([[22,29],[32,29]],4);path([[14,10],[7,10]],3);
 }
 if(part==='B'){
  oval(15,29,10,7);oval(27,10,10,7);
  path([[25,39],[25,29],[15,29],[29,29],[29,22]],5);path([[29,19],[29,10],[25,10],[25,0]],5);accessAt(28);
  path([[15,29],[7,29]],3);path([[29,10],[33,10]],3);
 }
 if(part==='C'){
  oval(21,29,12,7);oval(20,11,14,8);
  path([[25,39],[25,29],[20,29],[20,22]],5);path([[20,19],[20,10]],5);accessAt(19);
  paint(8,5,25,9,'piso');for(let v=0;v<5;v++)for(let u=0;u<W;u++){mat[ix(u,v)]='rocha';levels[ix(u,v)]=base+3;}path([[20,29],[8,29]],3);path([[20,11],[33,11]],3);
 }
 const rewards=part==='A'?[[32,29],[7,10],[29,13]]:part==='B'?[[7,29],[33,10],[21,12]]:[[8,29],[33,11],[10,9]];
 for(const [u,v]of rewards){path([[u,v<20?11:29],[u,v]],3);paint(u-1,v-1,3,3);}
 // Keep solid wall tips at least two cells thick; clear pointed floor tips only.
 const sloped=new Set([...ramps].flatMap(i=>[i,i+W]));
 for(let pass=0;pass<20;pass++){let changed=false;for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v);if(sloped.has(i))continue;const ns=[i-1,i+1,i-W,i+W].filter(j=>!sloped.has(j));if(ns.filter(j=>levels[j]===levels[i]).length>=2)continue;const count=new Map();for(const j of ns)count.set(levels[j],(count.get(levels[j])||0)+1);const target=[...count].find(([h,c])=>c>=2);if(target&&mat[i]==='rocha'){levels[i]=target[0];changed=true;}}if(!changed)break;}
 events.push(object('entrada','Chegada à Caverna do Mural',25,37));
 events.push(object('saida',n===0?'Kronasta':'Voltar',25,39,{destino:n===0?'kronasta':id(String.fromCharCode(64+n)),chegada_u:25,chegada_v:2}));
 if(n<2)events.push(object('saida','Próxima câmara',25,0,{destino:id(String.fromCharCode(66+n)),chegada_u:25,chegada_v:37}));
 if(part==='C'){
  events.push(object('npc','Tyler',20,10,{acao:'muralStory',storySpritePath:'res://assets/campaign/tyler-clareira-v1/tyler.png'}));
  events.push(object('saida','Retorno pelo vestíbulo',26,37,{destino:'kronasta',requer:'muralPrimeiroLaco',atalho:true}));
 }
 if(part==='B')events.push(object('interacao','Descansar na galeria',15,29,{acao:'muralRest'}));
 rewards.forEach(([u,v],i)=>events.push(object('item',['Suprimentos no nicho','Material escondido','Reserva de papel'][i],u,v,{item:['cola-reparo','vareta-bambu','papel-seda'][i],quantidade:1,visibilidade:i===1?'escondido':'brilho',trajetoria:'ambas'})));
 const occupied=(u,v)=>events.some(e=>Math.hypot(e.x/32-u,e.y/32-v)<4)||[...ramps].some(i=>Math.hypot(i%W-u,Math.floor(i/W)-v)<5);
 let count=0;
 for(let v=6;v<35;v+=4)for(let u=6;u<35;u+=5)if(mat[ix(u,v)]==='grama'&&!occupied(u,v)&&((u*3+v+n)%4===0)){
  pieces.push(object('peca','Formação de calcário',u,v,{asset:'mina-cave',variante:['coluna-calcario','estalagmite-baixa','rocha-solta'][count++%3],pegada:'1x1'}));
 }
 const feature={nativeProps:true,mine:true,mural:true,baseLevel:base,part,followTrail:false,guards:[],clearViews:[],shots:[],rails:[],frames:[],props:[]};
 for(const i of ramps){const u=i%W,v=Math.floor(i/W);feature.clearViews.push([u+.5,v+.5],[u+.5,v+2.5]);}
 feature.shots.push({name:'camara-baixa',u:21,v:29,zoom:1,kind:'jogo'},{name:'camara-alta',u:20,v:11,zoom:1,kind:'jogo'},{name:'nicho',u:rewards[1][0],v:rewards[1][1],zoom:1,kind:'jogo'});
 if(part==='C'){feature.muralPanel={u:14,v:5,width:12,heightPx:112};feature.shots.push({name:'mural',u:20,v:7,zoom:1,kind:'jogo'});}
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Caverna do Mural · '+names[n],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'caverna',parte:part,trajetoria:'2',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:levels.map((l,i)=>ramps.has(i)?109+l:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};return{id:id(part),part,raw,feature};
}
export function generateMural(){
 const parts=['A','B','C'].map(muralPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:25,v:0,direction:'v-'},to:{area:id(b),u:25,v:39,direction:'v+'}}));
 fs.mkdirSync(root+'documentation/overworld/caverna-mural/relatorios',{recursive:true});
 for(const p of parts){const m=region.find(r=>r.id===p.id).map,r=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events]});console.log(p.id+'\n'+r.lines.join('\n'));if(!r.ok)throw Error(p.id+' rejected');
 fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
 const shots=writeCapturePlan(out,p.feature,'documentation/overworld/caverna-mural');shots[0].zoom=.46;shots[0].offsetY=100;
 fs.writeFileSync(root+'documentation/overworld/caverna-mural/planos/'+p.id+'.json',JSON.stringify({area:p.id,shots},null,2)+'\n');fs.writeFileSync(root+'documentation/overworld/caverna-mural/relatorios/'+p.id+'.json',JSON.stringify(r,null,2)+'\n');}
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));
 for(const[p,n]of parts.map((p,n)=>[p,n])){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Caverna do Mural · '+names[n],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}
 fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateMural();
