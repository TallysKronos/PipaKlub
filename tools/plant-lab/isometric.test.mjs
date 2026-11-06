import assert from 'node:assert/strict';
import test from 'node:test';
import http from 'node:http';
import {once} from 'node:events';
import {projectIso,surfaceLevel,isoTerrain,pickIso,studioIso} from './isometric.mjs';
import {initialLayout} from './model.mjs';
import {serve} from './server.mjs';

test('projection and picking preserve elevated cell and ramp coordinates',()=>{
  const map={w:2,h:2,cells:[{material:'piso',level:1},{material:'piso',level:0},{material:'vazio',level:0},{material:'piso',level:0,ramp:'u-'}]};
  const tiles=isoTerrain(map);
  assert.equal(tiles.length,3);
  assert.deepEqual(projectIso(.5,.5,1),[0,-48]);
  assert.equal(pickIso(tiles,0,-48).index,0);
  const ramp=map.cells[3];
  assert.equal(surfaceLevel(ramp,0,0),1);
  assert.equal(surfaceLevel(ramp,1,0),0);
  assert.equal(pickIso(tiles,...projectIso(1.5,1.5,.5)).index,3);
});

test('Studio projects keep their source layout and use native coordinates in preview',()=>{
  const layout=initialLayout();
  const before=structuredClone(layout);
  const map=studioIso(layout);
  assert.deepEqual(map.spawn,{u:layout.player.x/32,v:layout.player.y/32});
  assert.equal(map.cells.length,layout.width*layout.height);
  assert.deepEqual(layout,before);
});

test('campaign catalog serves original native maps, including objects and events',async()=>{
  const server=http.createServer(serve).listen(0,'127.0.0.1');
  await once(server,'listening');
  try{
    const base='http://127.0.0.1:'+server.address().port;
    const catalog=await (await fetch(base+'/api/campaign-maps')).json();
    assert.ok(catalog.length>30);
    for(const id of ['kronasta-feira-c','kronasta-bambuzal-c','kronasta-mirante-c']){
      assert.ok(catalog.some(item=>item.id===id));
      const map=await (await fetch(base+'/api/campaign-maps/'+id)).json();
      assert.equal(map.schema,'overworld-godot-1');
      assert.equal(map.cells.length,map.w*map.h);
      assert.ok(map.pieces.length&&map.events.length);
      assert.ok(isoTerrain(map).length);
    }
    assert.equal((await fetch(base+'/api/campaign-maps/nonexistent')).status,404);
    assert.equal((await fetch(base+'/api/campaign-maps/kronasta-feira-c',{method:'POST'})).status,405);
  }finally{
    server.close();
  }
});
