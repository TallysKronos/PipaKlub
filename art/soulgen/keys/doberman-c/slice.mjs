import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {decodePNG,encodePNG} from '../../../../tools/pixelgen/png.mjs';
const folder=fileURLToPath(new URL('./sliced-rig-v2/',import.meta.url));fs.mkdirSync(folder,{recursive:true});
const image=decodePNG(fs.readFileSync(folder+'source.png'));
const definitions=[
 {id:'tailFar',name:'Vela superior da rabiola',pivot:[547,319],z:0,polygon:[[190,200],[550,200],[565,311],[558,327],[540,325],[533,311],[490,283],[445,270],[410,278],[205,350],[190,350]]},
 {id:'tailNear',name:'Vela inferior da rabiola',pivot:[540,335],z:1,polygon:[[148,375],[332,373],[490,315],[540,311],[553,332],[470,447],[170,605]]},
 {id:'head',name:'Cabeça, duas orelhas e pescoço',pivot:[1010,462],z:8,polygon:[[875,0],[1255,0],[1255,457],[1101,466],[1026,493],[929,400],[875,395]]},
 {id:'frontNear',name:'Pata dianteira próxima',pivot:[871,654],z:6,polygon:[[811,642],[859,632],[928,666],[909,701],[912,824],[977,927],[1007,1012],[838,1015],[827,920],[831,809],[799,716],[793,671]]},
 {id:'frontFar',name:'Pata dianteira distante',pivot:[1091,665],z:2,polygon:[[1048,665],[1105,633],[1148,704],[1247,842],[1314,891],[1385,931],[1382,977],[1223,979],[1173,902],[1095,797],[1047,720],[1034,662]]},
 {id:'hindNear',name:'Pata traseira próxima',pivot:[666,553],z:5,polygon:[[630,500],[740,510],[795,577],[687,681],[621,700],[470,894],[450,960],[315,965],[320,896],[345,844],[455,694],[543,649],[610,506]]},
 {id:'hindFar',name:'Pata traseira distante',pivot:[769,601],z:3,polygon:[[746,543],[823,583],[822,645],[732,757],[721,820],[791,866],[796,922],[662,931],[637,863],[623,727],[691,675],[693,615]]},
 {id:'body',name:'Tronco, peito, nós e tirantes',pivot:[869,567],z:4}
];
function contains(p,x,y){let inside=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const [ax,ay]=p[i],[bx,by]=p[j];if((ay>y)!==(by>y)&&x<(bx-ax)*(y-ay)/(by-ay)+ax)inside=!inside;}return inside;}
const labels=new Uint8Array(image.width*image.height),bounds=definitions.map(()=>[image.width,image.height,0,0]);
for(let y=0;y<image.height;y++)for(let x=0;x<image.width;x++){const i=y*image.width+x;if(!image.data[i*4+3])continue;let owner=definitions.findIndex(p=>p.polygon&&contains(p.polygon,x+.5,y+.5));if(owner<0)owner=definitions.length-1;labels[i]=owner+1;const b=bounds[owner];b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
const rebuilt=new Uint8ClampedArray(image.data.length),report={sourceSize:[image.width,image.height],method:'Disjoint polygon masks, exact source RGBA; no redraw, no hidden-surface synthesis.',parts:{}};
for(const [index,p]of definitions.entries()){const [x,y,right,bottom]=bounds[index],w=right-x+1,h=bottom-y+1,data=new Uint8ClampedArray(w*h*4);let pixels=0;for(let py=y;py<=bottom;py++)for(let px=x;px<=right;px++){const at=py*image.width+px;if(labels[at]!==index+1)continue;const pixel=image.data.subarray(at*4,at*4+4);data.set(pixel,((py-y)*w+px-x)*4);rebuilt.set(pixel,at*4);pixels++;}fs.writeFileSync(folder+p.id+'.png',encodePNG(data,w,h));report.parts[p.id]={...p,crop:[x,y,w,h],pixels};}
let changed=0,visible=0;for(let i=0;i<image.width*image.height;i++)if(image.data[i*4+3]){visible++;for(let c=0;c<4;c++)if(image.data[i*4+c]!==rebuilt[i*4+c]){changed++;break;}}
report.reconstruction={visiblePixels:visible,changedVisiblePixels:changed,missingPixels:0,overlapPixels:0};if(changed)throw Error('Reconstruction differs');fs.writeFileSync(folder+'reassembled.png',encodePNG(rebuilt,image.width,image.height));fs.writeFileSync(folder+'slices.json',JSON.stringify(report,null,2)+'\n');console.log(report.reconstruction);console.log(Object.fromEntries(Object.entries(report.parts).map(([k,v])=>[k,v.crop])));

