import {tile as floorTile,texture as wallTexture} from './autotile.mjs';
import {isGround} from './ground-kit.mjs';

/** Godot campaign coordinates: cell vertices, 64 × 32 diamond, 64 px per level. */
export function projectIso(u,v,level=0){
  return [(u-v)*32,(u+v)*16-level*64];
}

export function surfaceLevel(cell,u,v){
  const rise={'u+':u,'u-':1-u,'v+':v,'v-':1-v}[cell.ramp];
  return cell.level+(rise===undefined?0:(cell.rampFrom??0)+rise*((cell.rampTo??1)-(cell.rampFrom??0)));
}

const corners=[[0,0],[1,0],[1,1],[0,1]];
const palette={grama:'#83a85d',bosque:'#547d55',terra:'#b48a61',piso:'#b5a492',calcada:'#c5b9a4',asfalto:'#656b72',pedra:'#89939f',agua:'#3d879d',grass:'#83a85d',dirt:'#b48a61',stone:'#89939f',sand:'#d7ba80',water:'#3d879d',vazio:'#26313a'};
const geometryColors=['#8aab6c','#a4b487','#cebf91','#d9ab7c','#dce2b4'];
const textures=new Map();

function bitmap(key,width,height,pixels){
  if(!textures.has(key)){
    const surface=document.createElement('canvas');
    surface.width=width;
    surface.height=height;
    surface.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(pixels.buffer),width,height),0,0);
    textures.set(key,surface);
  }
  return textures.get(key);
}

function paintStudioFloor(g,{cell,top,u,v}){
  const kind=cell.material;
  if(!isGround(kind)&&!['grass','dirt','stone','sand','water'].includes(kind))return;
  const variant=(u*13+v*7+u*v)%3;
  const key=kind+'/'+variant;
  const [[x,y],[ax,ay],,[bx,by]]=top;
  g.save();
  g.transform((ax-x)/32,(ay-y)/32,(bx-x)/32,(by-y)/32,x,y);
  g.drawImage(bitmap(key,32,32,floorTile(kind,255,variant)),0,0);
  g.restore();
}

function paintStudioFace(g,face,tile){
  const kind=tile.cell.cliff??'earth';
  const key='wall/'+kind;
  if(!textures.has(key)){
    const {width,height,data}=wallTexture(kind);
    bitmap(key,width,height,data);
  }
  const [[x,y],[ax,ay]]=face;
  const length=Math.max(face[3][1]-y,face[2][1]-ay);
  g.save();
  g.clip();
  g.transform((ax-x)/32,(ay-y)/32,0,2,x,y);
  const offset=((ax>x?tile.u:tile.v)%2)*32;
  for(let row=0;row<length/2;row+=64){
    g.drawImage(textures.get(key),offset,0,32,64,0,row,32,64);
  }
  g.fillStyle=ax>x?'#181e3428':'#181e3448';
  g.fillRect(0,0,32,length/2);
  g.restore();
}

function paintDockEdge(g,face,tile){
  const [[x,y],[ax,ay],[bx,by],[cx,cy]]=face;
  g.save();
  g.clip();
  g.transform((ax-x)/32,(ay-y)/32,0,1,x,y);
  const length=Math.max(cy-y,by-ay);
  g.fillStyle='#55382b';
  g.fillRect(0,0,32,8);
  const post=(ax>x?tile.u:tile.v)%2===0;
  if(post)g.fillRect(10,6,8,length);
  g.fillStyle='#b18152';
  g.fillRect(0,1,32,3);
  if(post)g.fillRect(11,8,2,length);
  g.restore();
}

export function isoTerrain(map){
  const tiles=[];
  for(let depth=0;depth<map.w+map.h-1;depth++){
    for(let u=Math.max(0,depth-map.h+1);u<=Math.min(depth,map.w-1);u++){
      const v=depth-u, index=v*map.w+u, cell=map.cells[index];
      if(!cell||cell.material==='vazio'||cell.material==='void')continue;
      const top=corners.map(([x,y])=>projectIso(u+x,v+y,surfaceLevel(cell,x,y)));
      const faces=[],waterFaces=[];
      for(const [a,b,du,dv] of [[1,2,1,0],[2,3,0,1]]){
        const x=u+du,y=v+dv, next=x<map.w&&y<map.h?map.cells[y*map.w+x]:null;
        const lower=next&&next.material!=='vazio'&&next.material!=='void'?next:null;
        const bottom=[a,b].map(i=>{
          const [cx,cy]=corners[i];
          return projectIso(u+cx,v+cy,Math.min(surfaceLevel(cell,cx,cy),lower?surfaceLevel(lower,cx-du,cy-dv):Math.min(0,cell.level)));
        });
        if(bottom.some((p,i)=>p[1]>top[[a,b][i]][1])){
          faces.push([top[a],top[b],bottom[1],bottom[0]]);
          waterFaces.push(lower?.material==='water');
        }
      }
      tiles.push({index,u,v,cell,top,faces,waterFaces});
    }
  }
  return tiles;
}

function contains(poly,x,y){
  let inside=false;
  for(let i=0,j=poly.length-1;i<poly.length;j=i++){
    const [a,b]=poly[i],[c,d]=poly[j];
    if((b>y)!==(d>y)&&x<(c-a)*(y-b)/(d-b)+a)inside=!inside;
  }
  return inside;
}

export function pickIso(tiles,x,y){
  for(let i=tiles.length-1;i>=0;i--){
    const tile=tiles[i];
    if(contains(tile.top,x,y))return tile;
    if(tile.faces.some(face=>contains(face,x,y)))return null;
  }
  return null;
}

export function studioIso(layout){
  const directions={n:'v-',s:'v+',e:'u+',w:'u-'};
  return {w:layout.width,h:layout.height,cells:layout.floors.map((material,i)=>({material,level:layout.levels[i],cliff:layout.cliffs?.[i],waterDepth:layout.waterDepth?.[i],ramp:directions[layout.ramps[i]],rampFrom:layout.rampProfiles?.[i]?.[0],rampTo:layout.rampProfiles?.[i]?.[1],stairs:layout.stairs?.[i]})),
    pieces:layout.objects.map(o=>({...o,u:o.x/32,v:o.y/32})),
    events:(layout.events??[]).map(e=>({...e,u:e.x/32,v:e.y/32,name:e.label})),
    spawn:{u:layout.player.x/32,v:layout.player.y/32}};
}

export function drawIso(canvas,map,tiles,{highlight=-1,sprite=()=>null,zoom=1,pan=[0,0],artwork=false,geometry=false}={}){
  const g=canvas.getContext('2d');
  const points=tiles.flatMap(t=>[...t.top,...t.faces.flat()]);
  if(!points.length)return null;
  if(artwork){
    for(const piece of map.pieces??[]){
      const art=sprite(piece);
      const u=Math.floor(piece.u),v=Math.floor(piece.v);
      const cell=map.cells[v*map.w+u];
      if(!art?.image||!cell)continue;
      const [x,y]=projectIso(piece.u,piece.v,surfaceLevel(cell,piece.u-u,piece.v-v));
      const left=x-art.anchor[0],top=y-art.anchor[1];
      points.push([left,top],[left+art.image.width,top+art.image.height]);
    }
  }
  const xs=points.map(p=>p[0]),ys=points.map(p=>p[1]);
  const left=Math.min(...xs),right=Math.max(...xs),top=Math.min(...ys),bottom=Math.max(...ys);
  const scale=Math.max(.05,Math.min((canvas.width-24)/(right-left||1),(canvas.height-36)/(bottom-top||1)))*zoom;
  const ox=(canvas.width-(left+right)*scale)/2+pan[0],oy=(canvas.height-(top+bottom)*scale)/2+pan[1];
  const poly=(p,fill,stroke)=>{
    g.beginPath();p.forEach(([x,y],i)=>i?g.lineTo(x,y):g.moveTo(x,y));g.closePath();g.fillStyle=fill;g.fill();
    if(stroke){g.strokeStyle=stroke;g.stroke();}
  };
  g.setTransform(1,0,0,1,0,0);g.fillStyle='#17202a';g.fillRect(0,0,canvas.width,canvas.height);
  g.setTransform(scale,0,0,scale,ox,oy);g.imageSmoothingEnabled=false;g.lineWidth=1/scale;
  const entities=new Map();
  for(const entry of [...(map.pieces??[]),...(map.events??[]),{...map.spawn,asset:'kael',spawn:true}]){
    const u=Number(entry.u),v=Number(entry.v), x=Math.floor(u),y=Math.floor(v);
    if(!Number.isFinite(u+v)||x<0||x>=map.w||y<0||y>=map.h)continue;
    const i=y*map.w+x;
    if(!entities.has(i))entities.set(i,[]);
    entities.get(i).push(entry);
  }
  for(const tile of tiles){
    for(const [i,face] of tile.faces.entries()){
      const dock=artwork&&!geometry&&tile.cell.cliff==='face-madeira'&&tile.waterFaces[i];
      poly(face,dock?'#173e4433':i?'#594d48':'#695b50',artwork&&!geometry?null:'#3c3b41');
      if(dock)paintDockEdge(g,face,tile);
      else if(artwork&&!geometry)paintStudioFace(g,face,tile);
    }
    const color=geometry&&tile.cell.material!=='water'
      ? tile.cell.ramp?'#da8b50':geometryColors[tile.cell.level%geometryColors.length]
      : palette[tile.cell.material]??'#99856a';
    poly(tile.top,color,artwork&&!geometry?null:'#19273340');
    if(artwork&&!geometry){
      paintStudioFloor(g,tile);
      if(tile.cell.material==='water'&&tile.cell.waterDepth!==undefined){
        poly(tile.top,['#61bea25c','#43a3a83c','#204b7828','#11284c48'][tile.cell.waterDepth]);
      }
    }
    if(tile.index===highlight)poly(tile.top,'#ffffff25','#fff1af');
    if(tile.cell.ramp&&!artwork)poly([tile.top[0],tile.top[1],tile.top[2]],'#ffffff23');
    for(const entity of entities.get(tile.index)??[]){
      if(geometry&&!entity.spawn)continue;
      const [x,y]=projectIso(entity.u,entity.v,surfaceLevel(tile.cell,entity.u-tile.u,entity.v-tile.v));
      const art=sprite(entity);
      if(art?.image)g.drawImage(art.image,x-art.anchor[0],y-art.anchor[1]);
      else if(artwork&&!geometry)continue;
      else {g.fillStyle=entity.spawn?'#fff1af':entity.type?'#7fdef0':entity.blocks?'#d78955':'#d3ceac';g.fillRect(x-3,y-6,6,6);}
    }
  }
  g.setTransform(1,0,0,1,0,0);
  return {scale,ox,oy};
}

const floorGroups = [['piso','grama','terra'],['calcada','asfalto']];

export function campaignFloorOptions(map){
  const materials=new Set(map.cells.filter(cell=>!cell.ramp).map(cell=>cell.material));
  return floorGroups.filter(group=>group.some(material=>materials.has(material))).flat();
}

/** Preserve elevation, topology, pieces, events and any explicit corner transitions. */
export function paintCampaignFloor(map,index,material){
  const cell=map.cells[index];
  if(!cell||cell.ramp||cell.material===material||
    !floorGroups.some(group=>group.includes(cell.material)&&group.includes(material)))return false;
  const previous=cell.material;
  cell.material=material;
  if(Array.isArray(cell.corners))cell.corners=cell.corners.map(corner=>corner===previous?material:corner);
  return true;
}

export function isMovableDecoration(piece){
  return piece.blocks===false&&piece.interact==null&&['arvore','arbusto','flores','pedra'].includes(piece.asset);
}

export function moveCampaignDecoration(map,id,u,v){
  const piece=map.pieces.find(candidate=>String(candidate.id)===String(id));
  if(!piece||!isMovableDecoration(piece)||!Number.isInteger(u)||!Number.isInteger(v))return false;
  const w=piece.fu??1,h=piece.fv??1;
  if(!Number.isInteger(w)||!Number.isInteger(h)||w<1||h<1||u<0||v<0||u+w>map.w||v+h>map.h)return false;
  const origin=map.cells[piece.v*map.w+piece.u];
  if(!origin)return false;
  const within=point=>point.u>=u&&point.u<u+w&&point.v>=v&&point.v<v+h;
  if((map.events??[]).some(within)||(map.spawn&&within(map.spawn)))return false;
  if(map.pieces.some(other=>other!==piece&&u<other.u+(other.fu??1)&&other.u<u+w&&v<other.v+(other.fv??1)&&other.v<v+h))return false;
  for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){
    const cell=map.cells[y*map.w+x];
    if(!cell||cell.ramp||cell.level!==origin.level||!['grama','bosque','terra','piso','calcada','asfalto'].includes(cell.material))return false;
  }
  if(piece.u===u&&piece.v===v)return false;
  Object.assign(piece,{u,v});
  return true;
}
