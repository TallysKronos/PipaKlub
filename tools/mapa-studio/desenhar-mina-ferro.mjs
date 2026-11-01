import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {compile} from '../import-overworld.mjs';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=40,H=40,source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const id=p=>'mina-ferro-'+p.toLowerCase(),names=['Pátio de carga','Entroncamento','Frente de extração','Grande veio'];
const heights={...source,name:'mina-alturas',image:'../tiles/rascunho.png',firstgid:101,tiles:[]};
for(let n=0;n<=6;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});
heights.tiles.push({id:7,type:'altura',properties:props({nivel:-1})});
for(let n=0;n<4;n++)heights.tiles.push({id:8+n,type:'altura',properties:props({nivel:n,rampa:'v-'})});
export function minePart(part){
 const n=part.charCodeAt(0)-65,base=n,ix=(u,v)=>v*W+u,mat=Array(W*H).fill('rocha'),levels=[],ramps=new Set(),events=[],pieces=[];let next=1;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)levels.push(base+(v<20?3:2));
 const paint=(u,v,w,h,m='terra')=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){mat[ix(x,y)]=m;levels[ix(x,y)]=base+(y<20?1:0);}};
 const oval=(cx,cy,rx,ry)=>{for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2)if(((u+1-cx)/rx)**2+((v+1-cy)/ry)**2<=1)paint(u,v,2,2,'grama');};
 const path=(points,width=5)=>{for(let k=1;k<points.length;k++){const a=points[k-1],b=points[k],steps=Math.ceil(Math.hypot(a[0]-b[0],a[1]-b[1])*4);for(let j=0;j<=steps;j++)paint(Math.round(a[0]+(b[0]-a[0])*j/steps)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*j/steps)-Math.floor(width/2),width,width);}};
 const object=(type,name,u,v,p={})=>({id:next++,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const access=u=>{paint(u-1,18,5,6);for(let x=u-1;x<u+4;x++)ramps.add(ix(x,20));};
 const lowRails=[],highRails=[],frames=[],propsList=[];
 if(part==='A'){oval(20,29,14,7);oval(25,11,10,7);lowRails.push([[25,39],[25,29],[25,22]]);highRails.push([[25,19],[25,11],[25,0]]);path([[25,29],[8,29]],5);access(24);}
 if(part==='B'){oval(20,29,14,7);oval(14,10,9,7);lowRails.push([[25,39],[25,29],[11,29],[11,22]],[[25,29],[32,29]]);highRails.push([[11,19],[11,9],[25,9],[25,0]]);path([[25,29],[33,25]],4);path([[11,10],[7,10]],4);access(10);}
 if(part==='C'){oval(24,29,10,7);oval(26,11,10,7);oval(10,11,6,5);lowRails.push([[25,39],[25,29],[29,29],[29,22]],[[25,29],[8,29]]);highRails.push([[29,19],[29,11],[25,11],[25,0]],[[25,11],[9,11]]);access(28);}
 if(part==='D'){oval(20,29,14,7);oval(20,10,13,7);lowRails.push([[25,39],[25,29],[10,29],[10,22]],[[25,29],[29,29],[29,22]]);highRails.push([[10,19],[10,10],[29,10],[29,19]]);access(9);access(28);path([[20,10],[20,6]],5);}
 if(part==='A')lowRails.push([[25,29],[8,29]],[[12.5,29],[12.5,25.5]],[[25,29],[29.5,29],[29.5,26.5]]);
 if(part==='B')lowRails.push([[30.5,29],[30.5,27.5]]);
 if(part==='C')lowRails.push([[19.5,29],[19.5,26.5]]);
 if(part==='D')lowRails.push([[29,29],[29.5,29],[29.5,26.5]]);
 for(const r of [...lowRails,...highRails])path(r,5);
 // Entrance landing and sidings remain two cells wide or more.
 const rewards=part==='A'?[[8,29],[31,11],[18,33]]:part==='B'?[[33,25],[7,10],[29,33]]:part==='C'?[[8,29],[9,11],[31,31]]:[[7,29],[31,12],[20,14]];
 for(const [u,v]of rewards){path([[u,v<20?11:29],[u,v]],3);paint(u-1,v-1,3,3);}
 if(part==='A')path([[25,11],[31,11]],3);
 if(part==='D')path([[29,11],[31,12]],3);
 // Optional encounter rubble, adjacent to a side pocket, not on the rail axis.
 const encounter=part==='A'?[15,32]:part==='B'?[27,32]:part==='C'?[29,32]:[7,31];paint(encounter[0],encounter[1],3,2,'mato');
 // Keep solid wall tips at least two cells thick; clear pointed floor tips only.
 const sloped=new Set([...ramps].flatMap(i=>[i,i+W]));
 for(let pass=0;pass<20;pass++){let changed=false;for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v);if(sloped.has(i))continue;const ns=[i-1,i+1,i-W,i+W].filter(j=>!sloped.has(j));if(ns.filter(j=>levels[j]===levels[i]).length>=2)continue;const count=new Map();for(const j of ns)count.set(levels[j],(count.get(levels[j])||0)+1);const target=[...count].find(([h,c])=>c>=2);if(target&&mat[i]==='rocha'){levels[i]=target[0];changed=true;}}if(!changed)break;}
 events.push(object('entrada','Entrada da mina',25,37));
 if(n>0)events.push(object('saida','Voltar à galeria anterior',25,39,{destino:id(String.fromCharCode(64+n)),chegada_u:25,chegada_v:2}));
 if(n<3)events.push(object('saida','Próxima galeria',25,0,{destino:id(String.fromCharCode(66+n)),chegada_u:25,chegada_v:37}));
 else events.push(object('interacao','Grande veio de ferro',20,10,{texto:'As marcas de picareta acompanham o veio vermelho no fundo da galeria.'}));
 rewards.forEach(([u,v],i)=>events.push(object('item',['Suprimentos','Reserva no ramal','Achado entre ferramentas'][i],u,v,{item:['cola-reparo','vareta-bambu','papel-seda'][i],quantidade:1,visibilidade:i===1?'escondido':'brilho',trajetoria:'ambas'})));
 // Scenery deliberately sits off the central rails; blocking footprints are explicit.
 const layouts={A:[['veio',19,23,3,2],['cheio',12,25,2,2],['vazio',29,26,2,2],['estoque',13,31,2,2],['ferramentas',29,13,2,1]],B:[['veio',16,23,3,2],['vazio',30,27,2,2],['guincho',16,31,2,2],['ferramentas',6,12,2,1],['estoque',17,6,2,2]],C:[['cheio',19,26,2,2],['veio',6,8,3,2],['veio',30,6,3,2],['ferramentas',28,32,2,1]],D:[['veio',18,6,4,2],['guincho',14,26,2,2],['cheio',29,26,2,2],['estoque',24,7,2,2]]};
 for(const [kind,u,v,w,h]of layouts[part]){pieces.push(object('peca',kind,u,v,{asset:'mina-prop',variante:kind,pegada:w+'x'+h}));propsList.push({kind,u,v,w,h});}
 const frameDefs={A:[[25,34,'v'],[25,14,'v']],B:[[25,34,'v'],[18,29,'u'],[11,14,'v'],[25,4,'v']],C:[[25,34,'v'],[29,14,'v'],[15,11,'u']],D:[[25,34,'v'],[10,14,'v'],[29,14,'v'],[20,10,'u']]};
 for(const [u,v,axis]of frameDefs[part]){frames.push({u,v,axis});for(const sign of [-1,1])pieces.push(object('peca','Apoio do pórtico',u+(axis==='v'?sign*2:0),v+(axis==='u'?sign*2:0),{asset:'mina-suporte',pegada:'1x1'}));}
 const occupied=(u,v)=>pieces.some(p=>{const q=Object.fromEntries(p.properties.map(a=>[a.name,a.value])),[w,h]=q.pegada.split('x').map(Number),x=Math.floor(p.x/32),y=Math.floor(p.y/32);return u>=x-2&&u<x+w+2&&v>=y-2&&v<y+h+2;});
 const candidates=[];for(let v=5;v<H-4;v++)for(let u=5;u<W-4;u++)if(mat[ix(u,v)]==='grama'&&!occupied(u,v)&&events.every(e=>Math.hypot(e.x/32-u,e.y/32-v)>3)&&[...ramps].every(i=>Math.hypot(i%W-u,Math.floor(i/W)-v)>5))candidates.push([u,v]);
 candidates.sort((a,b)=>Math.sin(a[0]*12.98+a[1]*78.23+n)*43758%1-Math.sin(b[0]*12.98+b[1]*78.23+n)*43758%1);
 let count=0;for(const [u,v]of candidates){if(occupied(u,v))continue;const kind=['estalagmite-alta','rocha-solta','estalagmite-baixa','coluna-calcario','cogumelos-gruta','cristal-ambar'][count%6];pieces.push(object('peca','Formação da gruta',u,v,{asset:'mina-cave',variante:kind,pegada:'1x1'}));if(++count===8)break;}
 const feature={nativeProps:true,mine:true,baseLevel:base,part,followTrail:false,guards:[],clearViews:[],shots:[],rails:[...lowRails,...highRails],frames,props:propsList};
 for(const i of ramps){const u=i%W,v=Math.floor(i/W);feature.clearViews.push([u+.5,v+.5],[u+.5,v+2.5]);}
 feature.shots.push({name:'carga',u:25,v:29,zoom:1,kind:'jogo'},{name:'galeria-alta',u:part==='B'?13:25,v:11,zoom:1,kind:'jogo'},{name:'desvio',u:rewards[0][0],v:rewards[0][1],zoom:1,kind:'jogo'},{name:'marco',u:part==='D'?20:25,v:part==='D'?6:25,zoom:1,kind:'jogo'});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Mina de ferro · '+names[n],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'mina-ferro-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:levels.map((l,i)=>ramps.has(i)?109+l:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};return{id:id(part),part,raw,feature};
}
export function generateMine(){const parts=['A','B','C','D'].map(minePart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})})),links=[['A','B'],['B','C'],['C','D']].map(([a,b])=>({from:{area:id(a),u:25,v:0,direction:'v-'},to:{area:id(b),u:25,v:39,direction:'v+'}}));fs.mkdirSync(root+'documentation/overworld/mina-ferro/relatorios',{recursive:true});for(const p of parts){const m=region.find(r=>r.id===p.id).map,result=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Grande veio de ferro')]});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));const shots=writeCapturePlan(out,p.feature,'documentation/overworld/mina-ferro');shots[0].zoom=.46;shots[0].offsetY=100;fs.writeFileSync(root+'documentation/overworld/mina-ferro/planos/'+p.id+'.json',JSON.stringify({area:p.id,shots},null,2)+'\n');fs.writeFileSync(root+'documentation/overworld/mina-ferro/relatorios/'+p.id+'.json',JSON.stringify(result,null,2)+'\n');}const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));for(const[p,n]of parts.map((p,n)=>[p,n])){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Mina de ferro · '+names[n],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;}
if(process.argv[1]===fileURLToPath(import.meta.url))generateMine();
