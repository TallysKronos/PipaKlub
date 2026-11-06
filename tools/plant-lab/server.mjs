import {campaignArea} from './integration.mjs';
import {waterfallPixels,isWaterfall} from './waterfalls.mjs';
import {WATERFALL_RGBA} from './waterfall-data.mjs';
import {WALLS} from './wall-kit.mjs';
import {WALL_COLORS} from './wall-data.mjs';
import {GROUNDS} from './ground-kit.mjs';
import {GROUND_COLORS} from './ground-data.mjs';
import {NATURE_ASSETS} from './nature-kit.mjs';
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {ASSETS,validateLayout} from './model.mjs';
import {atlas,texture,MASKS} from './autotile.mjs';
import {rasterPlan} from './terrain-raster.mjs';
import {png} from './png.mjs';
import {zip} from './zip.mjs';
const app=fileURLToPath(new URL('./',import.meta.url)),root=fileURLToPath(new URL('../../',import.meta.url));
const assets=new Map(ASSETS.map(a=>[a.id,path.join(root,a.id==='kael'?'art/characters/kael/overworld-diagonal-v1/frente-sw.png':(a.waterfall?'art/environment/kronasta-waterfalls-v1/sprites/':a.kit?'art/environment/kronasta-nature-v1/sprites/':'art/environment/topdown-plants-pixel-v1/')+a.id+'.png')]));
assets.set('waterfall-atlas',path.join(root,'art/environment/kronasta-waterfalls-v1/atlas.png'));
assets.set('kael-walk',path.join(root,'art/characters/kael/overworld-walk-v1/walk.png'));
assets.set('kael-back',path.join(root,'art/characters/kael/overworld-diagonal-v1/costas-nw.png'));
assets.set('tree-atlas',path.join(root,'art/environment/topdown-forest-v2/trees.png'));
for(const a of NATURE_ASSETS.filter(a=>a.tree))assets.set('tree-atlas-'+a.id,path.join(root,'art/environment/kronasta-nature-v1/atlases/'+a.id+'.png'));
const pages=new Map(['index.html','style.css','app.mjs','model.mjs','terrain.mjs','studio.mjs','autotile.mjs','terrain-raster.mjs','terrain-field.mjs','forest-sample.mjs','ramp-surface.mjs','water.mjs','trees.mjs','nature-kit.mjs','ground-kit.mjs','ground-data.mjs','wall-kit.mjs','wall-data.mjs','waterfalls.mjs','waterfall-assets.mjs','brush-preview.mjs','geometry-edit.mjs','geometry-preview.mjs','geometry-preview-worker.mjs','level-focus.mjs','projects.mjs','map-audit.mjs','regions.mjs','collision-shapes.mjs','map-events.mjs','biomes-scatter.mjs','ramp-rules.mjs','river-builder.mjs','water-colors.mjs','waterfall-data.mjs','custom-assets.mjs','resize-map.mjs','variation.mjs'].map(n=>['/'+n,path.join(app,n)]));pages.set('/',path.join(app,'index.html'));
const mime={'.html':'text/html; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png'};
export async function exportProject(raw){const layout=validateLayout(raw),files=[];for(const name of ['project.godot','main.tscn','lab.gd','terrain.gd','autotile.gd','trees.gd','waterfalls.gd','collision_shapes.gd','ramp_rules.gd','area_bridge.gd','README.md'])files.push([name,await fs.readFile(path.join(app,'godot-template',name))]);files.push(['integration/area.overworld.json',JSON.stringify(campaignArea(raw,{id:raw.mapId??'studio-map',name:raw.name??'Área do Studio'}),null,2)]);files.push(['integration/area.topdown.json',JSON.stringify(layout,null,2)]);files.push(['walls.json',JSON.stringify(WALLS.map(w=>({...w,...WALL_COLORS[w.id]})))]);files.push(['grounds.json',JSON.stringify(GROUNDS.map(g=>({...g,...GROUND_COLORS[g.id]})))]);files.push(['catalog.json',JSON.stringify([...ASSETS,...(layout.customAssets??[])].map(({source,...a})=>a))]);files.push(['layout.json',JSON.stringify(layout,null,2)]);files.push(['project-meta.json',JSON.stringify({id:String(raw.mapId??'studio-preview').slice(0,100)})]);files.push(['autotile/build_tileset.gd',await fs.readFile(path.join(app,'godot-template/build_tileset.gd'))]);files.push(['autotile/terrain-set.tres',await fs.readFile(path.join(app,'godot-template/terrain-set.tres'))]);const r=rasterPlan(layout,true);for(const kind of ['grass','stone','sand','water',...GROUNDS.map(g=>g.id)])files.push(['autotile/'+kind+'.png',png(atlas(kind))]);for(const kind of ['dirt','earth','rock',...WALLS.map(w=>w.id)])files.push(['autotile/'+kind+'.png',png(texture(kind))]);for(const [name,data]of [['top',r.top],['faces',r.faces],['shadow',r.shadow]])files.push(['autotile/baked-'+name+'.png',png({width:r.width,height:r.height,data})]);if(layout.objects.some(o=>isWaterfall(o.asset))){const bytes=Uint8Array.from(atob(WATERFALL_RGBA),c=>c.charCodeAt(0)),atlas=new Uint32Array(bytes.buffer);for(let phase=0;phase<4;phase++){const data=new Uint32Array(r.width*r.height);for(const o of layout.objects.filter(o=>isWaterfall(o.asset))){const image=waterfallPixels(layout,o,atlas,phase);if(image)for(let y=0;y<image.height;y++)for(let x=0;x<image.width;x++){const c=image.data[y*image.width+x],xx=image.x+x,yy=image.y+y+r.pad;if(c&&xx>=0&&xx<r.width&&yy>=0&&yy<r.height)data[yy*r.width+xx]=c;}}files.push(['autotile/waterfall-phase-'+phase+'.png',png({width:r.width,height:r.height,data})]);}}files.push(['autotile/source.json',JSON.stringify({width:layout.width,height:layout.height,surfaceModel:'shared-dual-field-v2',grounds:GROUNDS.map(g=>({...g,...GROUND_COLORS[g.id]})),walls:WALLS.map(w=>({...w,...WALL_COLORS[w.id]})),variants:layout.variants??[],levels:layout.levels,ramps:layout.ramps,stairs:layout.stairs??[],waterDepth:layout.waterDepth??[],flow:layout.flow??[],floors:layout.floors,cliffs:layout.cliffs,autotiling:layout.autotiling,masks:MASKS,pad:r.pad})]);for(const a of layout.customAssets??[])files.push(['assets/'+a.id+'.png',Buffer.from(a.source.split(',')[1],'base64')]);for(const [id,file]of assets)files.push(['assets/'+id+'.png',await fs.readFile(file)]);return zip(files);}
export async function serve(req,res){const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' blob: data:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'"};
  const end=(code,text)=>{res.writeHead(code,{...headers,'Content-Type':'text/plain; charset=utf-8'});res.end(text);};
  try{const u=new URL(req.url,'http://localhost');
    if(u.pathname==='/api/export-godot'){
      if(req.method!=='POST')return end(405,'Use POST.');
      const origin=req.headers.origin;if(origin&&origin!==`http://${req.headers.host}`)return end(403,'Origem não permitida.');
      if(!String(req.headers['content-type']||'').startsWith('application/json'))return end(415,'Envie JSON.');
      const chunks=[];let size=0;for await(const b of req){size+=b.length;if(size>12_000_000)return end(413,'Projeto muito grande.');chunks.push(b);}
      let data;try{data=JSON.parse(Buffer.concat(chunks).toString());}catch{return end(400,'JSON inválido.');}
      let file;try{file=await exportProject(data);}catch(e){return end(400,e.message);}
      res.writeHead(200,{...headers,'Content-Type':'application/zip','Content-Disposition':'attachment; filename="jardim-kronasta-godot.zip"'});res.end(file);return;
    }
    if(!['GET','HEAD'].includes(req.method))return end(405,'Somente leitura.');
    const match=/^\/assets\/([a-z0-9-]+)\.png$/.exec(u.pathname),file=match?assets.get(match[1]):pages.get(u.pathname);if(!file)return end(404,'Arquivo não encontrado.');
    const data=await fs.readFile(file);res.writeHead(200,{...headers,'Content-Type':mime[path.extname(file)]||'application/octet-stream'});res.end(req.method==='HEAD'?undefined:data);
  }catch(e){console.error(e.message);end(500,'Não foi possível atender a solicitação.');}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const port=Number(process.env.PLANT_LAB_PORT||5256);if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Porta inválida.');http.createServer(serve).listen(port,'127.0.0.1',()=>console.log('Jardim de Kronasta: http://127.0.0.1:'+port));}
