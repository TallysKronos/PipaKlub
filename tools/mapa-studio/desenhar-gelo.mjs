import fs from'node:fs';import{fileURLToPath}from'node:url';import{compile}from'../import-overworld.mjs';import{parseTiled}from'./model.mjs';import{auditZeroBreak}from'./conferencia-bosque.mjs';import{writeCapturePlan}from'./capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=44,H=40,source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const id=p=>'gelo-'+p.toLowerCase(),names=['Clareira nevada','Lago congelado','Desfiladeiro de cristal','Coroa da geleira'];
const heights={...source,name:'gelo-alturas',image:'../tiles/rascunho.png',firstgid:101,tiles:[]};for(let n=0;n<=6;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});heights.tiles.push({id:7,type:'altura',properties:props({nivel:-2})});for(let n=0;n<=5;n++)heights.tiles.push({id:8+n,type:'altura',properties:props({nivel:n,rampa:'v-'})});
export function icePart(part){
 const n=part.charCodeAt(0)-65,base=n+1,ix=(u,v)=>v*W+u,mat=Array(W*H).fill('rocha'),levels=Array(W*H).fill(-2),ramps=new Set(),events=[],pieces=[],trails=[];let next=1;
 const split=u=>part==='A'?(u<16?16:u>=34?24:20):part==='B'?(u<8?16:u>=20?18:20):part==='C'?(u<20?22:u>=34?18:20):(u>=18&&u<26?16:20);
 const paint=(u,v,w,h,m='terra')=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){mat[ix(x,y)]=m;levels[ix(x,y)]=base+(y<split(x)?1:0);}};
 const path=(points,width=3)=>{trails.push(points);for(let k=1;k<points.length;k++){const a=points[k-1],b=points[k],steps=Math.ceil(Math.hypot(a[0]-b[0],a[1]-b[1])*4);for(let j=0;j<=steps;j++)paint(Math.round(a[0]+(b[0]-a[0])*j/steps)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*j/steps)-Math.floor(width/2),width,width);}};
 const oval=(cx,cy,rx,ry,m)=>{for(let v=4;v<H-4;v+=2)for(let u=4;u<W-4;u+=2)if(((u+1-cx)/rx)**2+((v+1-cy)/ry)**2<=1)paint(u,v,2,2,m);};
 for(let v=4;v<H-4;v+=2)for(let u=4;u<W-4;u+=2){const cx=part==='C'?22+(v-20)*.18:22,ry=part==='B'?16:part==='D'?16:17,cy=part==='D'?19:20;if(((u+1-cx)/18)**2+((v+1-cy)/ry)**2<=1)paint(u,v,2,2,'grama');}
 const object=(type,name,u,v,p={})=>({id:next++,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const access=u=>{paint(u-1,18,5,6);for(let x=u-1;x<u+4;x++)ramps.add(ix(x,20));};
 if(part==='A'){path([[22,39],[22,30],[26,28],[26,22]]);path([[26,19],[26,10],[22,10],[22,0]]);access(24);}
 if(part==='B'){path([[22,39],[22,29],[12,29],[12,22]]);path([[12,19],[12,10],[22,10],[22,0]]);access(10);oval(22,29,9,5,'piso');}
 if(part==='C'){path([[22,39],[28,33],[30,28],[30,22]]);path([[22,39],[14,31],[14,26],[18,23],[30,23]]);path([[30,19],[30,10],[22,10],[22,0]]);access(28);for(let v=25;v<33;v++)for(let u=20;u<24;u++){mat[ix(u,v)]='rocha';levels[ix(u,v)]=-2;}}
 if(part==='D'){path([[22,39],[22,29],[12,29],[12,22]]);path([[22,29],[30,29],[30,22]]);path([[12,19],[12,10],[30,10],[30,19]]);access(10);access(28);}
 const rewards=part==='A'?[[7,28],[32,12],[15,31]]:part==='B'?[[8,31],[32,29],[33,14]]:part==='C'?[[13,30],[33,27],[9,11]]:[[8,29],[33,12],[22,14]];
 for(const[u,v]of rewards){const nearest=v<20?[22,10]:part==='C'?[u,29]:[22,29];path([nearest,[u,v]],3);paint(u-1,v-1,3,3);}
 // Encounters are frost patches, never mandatory to reach an exit.
 const frost=part==='A'?[16,27]:part==='B'?[32,26]:part==='C'?[12,27]:[32,26];paint(frost[0],frost[1],3,2,'mato');
 // Repaint lake only outside ramp feet, keeping an unambiguous opaque frozen surface.
 if(part==='B')oval(22,29,9,5,'piso');
 const sloped=new Set([...ramps].flatMap(i=>[i,i+W]));
 // Trim isolated rocky/snow tips after the paths cut the outline.
 for(let pass=0;pass<24;pass++){let changed=false;for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v);if(levels[i]<0||sloped.has(i))continue;const ns=[i-1,i+1,i-W,i+W].filter(j=>!sloped.has(j));if(ns.filter(j=>levels[j]===levels[i]).length>=2)continue;if(mat[i]==='grama'){mat[i]='rocha';levels[i]=-2;changed=true;}}if(!changed)break;}
 // Close single-cell pinholes left by the outline trim; preserve the authored ravine.
 for(let v=1;v<H-1;v++)for(let u=1;u<W-1;u++){const i=ix(u,v),ns=[i-1,i+1,i-W,i+W];if(levels[i]<0&&ns.every(j=>levels[j]>=0&&levels[j]===levels[ns[0]])){levels[i]=levels[ns[0]];mat[i]='grama';}}
 events.push(object('entrada','Entrada da região gelada',22,37));
 if(n>0)events.push(object('saida','Voltar ao trecho anterior',22,39,{destino:id(String.fromCharCode(64+n)),chegada_u:22,chegada_v:2}));
 if(n<3)events.push(object('saida','Continuar pela neve',22,0,{destino:id(String.fromCharCode(66+n)),chegada_u:22,chegada_v:37}));
 else events.push(object('interacao','Formação glacial',22,12,{texto:'O vento desenhou camadas na face azul da geleira.'}));
 rewards.forEach(([u,v],i)=>events.push(object('item',['Material na neve','Achado escondido','Suprimentos'][i],u,v,{item:['cola-reparo','vareta-bambu','papel-seda'][i],quantidade:1,visibilidade:i===1?'escondido':'brilho',trajetoria:'ambas'})));
 const layouts={A:[['pinheiro',8,25,1,1],['pinheiro',9,25,1,1],['pinheiro',30,28,1,1],['pinheiro',31,28,1,1],['abrigo',10,29,3,3],['rocha',28,9,3,2],['cristal',29,13,2,2],['rocha',10,10,3,2],['rocha',35,26,3,2]],B:[['pinheiro',6,26,1,1],['pinheiro',7,26,1,1],['rocha',29,27,3,2],['cristal',30,10,2,2],['rocha',9,8,3,2],['cristal',17,7,2,2]],C:[['cristal',12,26,2,2],['cristal',28,26,2,2],['rocha',14,11,3,2],['formacao',26,7,3,3],['cristal',16,30,2,2],['cristal',31,30,2,2]],D:[['formacao',20,7,4,3],['abrigo',8,25,3,3],['cristal',32,27,2,2],['rocha',29,12,3,2],['rocha',13,7,3,2]]};
 for(const[kind,u,v,w,h]of layouts[part])pieces.push(object('peca',kind,u,v,{asset:'gelo-prop',variante:kind,pegada:w+'x'+h}));
 const marks=part==='A'?[[29,23],[24,16]]:part==='B'?[[15,23],[14,16],[31,31]]:part==='C'?[[32,23],[24,34]]:[[15,23],[27,23]];
 for(const[u,v]of marks)pieces.push(object('peca','Estaca de orientação',u,v,{asset:'gelo-marker',pegada:'1x1'}));
 const feature={nativeProps:true,ice:true,baseLevel:base,part,followTrail:false,guards:[],clearViews:[],shots:[],trails};
 for(const i of ramps){const u=i%W,v=Math.floor(i/W);feature.clearViews.push([u+.5,v+.5],[u+.5,v+2.5]);}
 for(const[name,u,v]of[['chegada',22,30],['patamar',22,12],['desvio',rewards[0][0],rewards[0][1]],['marco',part==='D'?22:part==='B'?22:part==='C'?22:11,part==='D'?11:part==='B'?29:part==='C'?29:29]])feature.shots.push({name,u,v,zoom:1,kind:'jogo'});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,properties:props({nome:'Gelo · '+names[n],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'gelo-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:levels.map((l,i)=>ramps.has(i)?109+l:l<0?108:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};return{id:id(part),part,raw,feature};
}
export function generateIce(){
 const parts=['A','B','C','D'].map(icePart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})})),links=[['A','B'],['B','C'],['C','D']].map(([a,b])=>({from:{area:id(a),u:22,v:0,direction:'v-'},to:{area:id(b),u:22,v:39,direction:'v+'}}));
 fs.mkdirSync(root+'documentation/overworld/gelo/relatorios',{recursive:true});
 for(const p of parts){const m=region.find(r=>r.id===p.id).map,result=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Formação glacial')]});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));const shots=writeCapturePlan(out,p.feature,'documentation/overworld/gelo');shots[0].zoom=.40;shots[0].offsetY=60;fs.writeFileSync(root+'documentation/overworld/gelo/planos/'+p.id+'.json',JSON.stringify({area:p.id,shots},null,2)+'\n');fs.writeFileSync(root+'documentation/overworld/gelo/relatorios/'+p.id+'.json',JSON.stringify(result,null,2)+'\n');}
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));for(const[p,n]of parts.map((p,n)=>[p,n])){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Gelo · '+names[n],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateIce();

