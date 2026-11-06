/** Godot campaign coordinates: cell vertices, 64 × 32 diamond, 64 px per level. */
export function projectIso(u,v,level=0){
  return [(u-v)*32,(u+v)*16-level*64];
}

export function surfaceLevel(cell,u,v){
  const rise={'u+':u,'u-':1-u,'v+':v,'v-':1-v}[cell.ramp];
  return cell.level+(rise===undefined?0:(cell.rampFrom??0)+rise*((cell.rampTo??1)-(cell.rampFrom??0)));
}

const corners=[[0,0],[1,0],[1,1],[0,1]];
const palette={grama:'#83a85d',bosque:'#547d55',terra:'#b48a61',piso:'#b5a492',pedra:'#89939f',agua:'#3d879d',grass:'#83a85d',dirt:'#b48a61',stone:'#89939f',sand:'#d7ba80',water:'#3d879d',vazio:'#26313a'};

export function isoTerrain(map){
  const tiles=[];
  for(let depth=0;depth<map.w+map.h-1;depth++){
    for(let u=Math.max(0,depth-map.h+1);u<=Math.min(depth,map.w-1);u++){
      const v=depth-u, index=v*map.w+u, cell=map.cells[index];
      if(!cell||cell.material==='vazio'||cell.material==='void')continue;
      const top=corners.map(([x,y])=>projectIso(u+x,v+y,surfaceLevel(cell,x,y)));
      const faces=[];
      for(const [a,b,du,dv] of [[1,2,1,0],[2,3,0,1]]){
        const x=u+du,y=v+dv, next=x<map.w&&y<map.h?map.cells[y*map.w+x]:null;
        const lower=next&&next.material!=='vazio'&&next.material!=='void'?next:null;
        const bottom=[a,b].map(i=>{
          const [cx,cy]=corners[i];
          return projectIso(u+cx,v+cy,Math.min(surfaceLevel(cell,cx,cy),lower?surfaceLevel(lower,cx-du,cy-dv):Math.min(0,cell.level)));
        });
        if(bottom.some((p,i)=>p[1]>top[[a,b][i]][1]))faces.push([top[a],top[b],bottom[1],bottom[0]]);
      }
      tiles.push({index,u,v,cell,top,faces});
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
  return {w:layout.width,h:layout.height,cells:layout.floors.map((material,i)=>({material,level:layout.levels[i],ramp:directions[layout.ramps[i]],stairs:layout.stairs?.[i]})),
    pieces:layout.objects.map(o=>({...o,u:o.x/32,v:o.y/32})),
    events:(layout.events??[]).map(e=>({...e,u:e.x/32,v:e.y/32,name:e.label})),
    spawn:{u:layout.player.x/32,v:layout.player.y/32}};
}

export function drawIso(canvas,map,tiles,{highlight=-1,sprite=()=>null,zoom=1,pan=[0,0]}={}){
  const g=canvas.getContext('2d');
  const points=tiles.flatMap(t=>[...t.top,...t.faces.flat()]);
  if(!points.length)return null;
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
    for(const [i,face] of tile.faces.entries())poly(face,i?'#594d48':'#695b50','#3c3b41');
    poly(tile.top,palette[tile.cell.material]??'#99856a',tile.index===highlight?'#fff1af':'#19273340');
    if(tile.cell.ramp)poly([tile.top[0],tile.top[1],tile.top[2]],'#ffffff23');
    for(const entity of entities.get(tile.index)??[]){
      const [x,y]=projectIso(entity.u,entity.v,surfaceLevel(tile.cell,entity.u-tile.u,entity.v-tile.v));
      const art=sprite(entity);
      if(art?.image)g.drawImage(art.image,x-art.anchor[0],y-art.anchor[1]);
      else {g.fillStyle=entity.spawn?'#fff1af':entity.type?'#7fdef0':entity.blocks?'#d78955':'#d3ceac';g.fillRect(x-3,y-6,6,6);}
    }
  }
  g.setTransform(1,0,0,1,0,0);
  return {scale,ox,oy};
}
