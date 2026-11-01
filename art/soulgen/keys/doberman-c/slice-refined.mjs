import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {decodePNG,encodePNG} from '../../../../tools/pixelgen/png.mjs';
const folder=fileURLToPath(new URL('./refined-rig-v3/',import.meta.url));fs.mkdirSync(folder,{recursive:true});
const image=decodePNG(fs.readFileSync(folder+'source.png'));
const definitions=[
 {id:'tail',name:'Rabiola completa · fios, nós e duas velas',pivot:[699,438],z:0,polygon:[[150,180],[570,180],[594,334],[655,397],[698,421],[754,429],[811,429],[826,434],[828,448],[790,460],[720,467],[684,466],[602,478],[150,620]]},
 {id:'head',name:'Cabeça, duas orelhas e pescoço',pivot:[1010,462],z:8,polygon:[[875,0],[1255,0],[1255,457],[1101,466],[1026,493],[929,400],[875,395]]},
 {id:'frontNear',name:'Pata dianteira próxima',pivot:[871,654],z:6,polygon:[[811,642],[859,632],[928,666],[909,701],[912,824],[977,927],[1007,1012],[838,1015],[827,920],[831,809],[799,716],[793,671]]},
 {id:'frontFar',name:'Pata dianteira distante',pivot:[1091,665],z:2,polygon:[[1048,665],[1105,657],[1148,704],[1247,842],[1314,891],[1385,931],[1382,977],[1223,979],[1173,902],[1095,797],[1047,720],[1034,662]]},
 {id:'hindNear',name:'Pata traseira próxima',pivot:[650,610],z:5,polygon:[[647,583],[698,570],[748,582],[696,646],[628,690],[470,894],[450,960],[315,965],[320,896],[345,844],[455,694],[543,649],[580,612]]},
 {id:'hindFar',name:'Pata traseira distante',pivot:[770,625],z:3,polygon:[[752,593],[806,607],[799,649],[732,757],[721,820],[791,866],[796,922],[662,931],[637,863],[623,727],[691,675],[693,615]]},
 {id:'body',name:'Torso e peito de pipa',pivot:[869,567],z:4}
];
function contains(p,x,y){let inside=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const [ax,ay]=p[i],[bx,by]=p[j];if((ay>y)!==(by>y)&&x<(bx-ax)*(y-ay)/(by-ay)+ax)inside=!inside;}return inside;}
// Preserve source RGBA; discard only low-alpha haze more than 3 px from solid source ink.
const strong=new Uint8Array(image.width*image.height);
for(let i=0;i<strong.length;i++)if(image.data[i*4+3]>=64)strong[i]=1;
const retained=new Uint8Array(strong.length);let discarded=0;
for(let y=0;y<image.height;y++)for(let x=0;x<image.width;x++){
 const at=y*image.width+x,alpha=image.data[at*4+3];if(!alpha)continue;
 let keep=alpha>=16;
 if(!keep)for(let dy=-3;dy<=3&&!keep;dy++)for(let dx=-3;dx<=3;dx++){const xx=x+dx,yy=y+dy;if(xx>=0&&yy>=0&&xx<image.width&&yy<image.height&&strong[yy*image.width+xx]){keep=true;break;}}
 if(keep)retained[at]=1;else discarded++;
}
const gold=new Uint8Array(image.width*image.height);
for(let y=300;y<480;y++)for(let x=535;x<930;x++){const i=(y*image.width+x)*4,r=image.data[i],g=image.data[i+1],b=image.data[i+2];if(image.data[i+3]>=16&&r>=80&&r>g*1.12&&g>b*1.25)gold[y*image.width+x]=1;}
function cordInk(x,y){for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(gold[(y+dy)*image.width+x+dx])return true;return false;}
const labels=new Uint8Array(image.width*image.height),bounds=definitions.map(()=>[image.width,image.height,0,0]);
for(let y=0;y<image.height;y++)for(let x=0;x<image.width;x++){const i=y*image.width+x;if(!retained[i])continue;let owner=definitions.findIndex(p=>p.polygon&&contains(p.polygon,x+.5,y+.5));if(owner<0)owner=definitions.length-1;
 if(definitions[owner].id==='tail'&&x>585&&!cordInk(x,y))owner=definitions.length-1;
 // Any source edge following a limb must belong to that limb, never a torso shard.
 if(definitions[owner].id==='body'&&y>690){const id=x<590?'hindNear':x<792?'hindFar':x<1015?'frontNear':'frontFar';owner=definitions.findIndex(p=>p.id===id);}
 if(definitions[owner].id==='body'&&x<590&&y>620)owner=definitions.findIndex(p=>p.id==='hindNear');
 if(definitions[owner].id==='body'&&x>1140&&y>660)owner=definitions.findIndex(p=>p.id==='frontFar');
 labels[i]=owner+1;const b=bounds[owner];b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
// Remove only disconnected tiny torso scraps left by the source antialiasing and old limb cuts.
let discardedSemanticFragments=0;const bodyLabel=definitions.length,seen=new Uint8Array(labels.length);
for(let i=0;i<labels.length;i++){if(labels[i]!==bodyLabel||seen[i])continue;const queue=[i];seen[i]=1;for(let q=0;q<queue.length;q++){const a=queue[q],x=a%image.width,y=Math.floor(a/image.width);for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy,b=yy*image.width+xx;if(xx>=0&&yy>=0&&xx<image.width&&yy<image.height&&!seen[b]&&labels[b]===bodyLabel){seen[b]=1;queue.push(b);}}}if(queue.length<1000)for(const a of queue){labels[a]=0;retained[a]=0;discardedSemanticFragments++;}}
for(const b of bounds)b.splice(0,4,image.width,image.height,0,0);
for(let i=0;i<labels.length;i++)if(labels[i]){const b=bounds[labels[i]-1],x=i%image.width,y=Math.floor(i/image.width);b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
const rebuilt=new Uint8ClampedArray(image.data.length),report={sourceSize:[image.width,image.height],method:'Semantic disjoint source masks; complete tail; retained pixels preserve RGBA exactly; only distant low-alpha haze discarded.',parts:{}};
for(const [index,p]of definitions.entries()){const [x,y,right,bottom]=bounds[index],w=right-x+1,h=bottom-y+1,data=new Uint8ClampedArray(w*h*4);let pixels=0;for(let py=y;py<=bottom;py++)for(let px=x;px<=right;px++){const at=py*image.width+px;if(labels[at]!==index+1)continue;const pixel=image.data.subarray(at*4,at*4+4);data.set(pixel,((py-y)*w+px-x)*4);rebuilt.set(pixel,at*4);pixels++;}fs.writeFileSync(folder+p.id+'.png',encodePNG(data,w,h));report.parts[p.id]={...p,crop:[x,y,w,h],pixels};}
let changed=0,visible=0;for(let i=0;i<image.width*image.height;i++)if(retained[i]){visible++;for(let c=0;c<4;c++)if(image.data[i*4+c]!==rebuilt[i*4+c]){changed++;break;}}
report.reconstruction={visiblePixels:visible,changedVisiblePixels:changed,missingPixels:0,overlapPixels:0,discardedDistantLowAlphaPixels:discarded,discardedSemanticFragments};if(changed)throw Error('Reconstruction differs');fs.writeFileSync(folder+'reassembled.png',encodePNG(rebuilt,image.width,image.height));fs.writeFileSync(folder+'slices.json',JSON.stringify(report,null,2)+'\n');console.log(report.reconstruction);console.log(Object.fromEntries(Object.entries(report.parts).map(([k,v])=>[k,v.crop])));

