import test from 'node:test';
import assert from 'node:assert/strict';
import {mountView,mountPaintPoint} from './mount-composite.mjs';
test('montage picks the original pixel through scale, pivots and rotated distant leg',()=>{
 const f={seat:[70,80],ground:[40,100],hip:[50,60],rect:[0,0,100,100],riderRect:[0,0,100,100],farLeg:[[60,60],[100,60],[100,100],[60,100]],farLegAngle:30};
 const rig={scale:.4,riderScale:.18,directions:{se:f}},v=mountView(rig,'se',640,640);
 function screen(p,far=false){const a=far?Math.PI/6:0,dx=(p.x-f.hip[0])*rig.riderScale,dy=(p.y-f.hip[1])*rig.riderScale;return {x:v.x+(v.seat[0]+Math.cos(a)*dx-Math.sin(a)*dy)*v.zoom,y:v.y+(v.seat[1]+Math.sin(a)*dx+Math.cos(a)*dy)*v.zoom};}
 for(const [p,far]of [[{x:20,y:30},false],[{x:80,y:80},true]]){
  const s=screen(p,far),out=mountPaintPoint(rig,'se','rider',s.x,s.y,640,640,q=>Math.abs(q.x-p.x)<.01&&Math.abs(q.y-p.y)<.01);
  assert.ok(Math.abs(out.x-p.x)<1e-8&&Math.abs(out.y-p.y)<1e-8);assert.equal(out.layer,far?'far':'near');
 }
 const x=v.x+(12-f.ground[0])*rig.scale*v.zoom,y=v.y+(34-f.ground[1])*rig.scale*v.zoom;
 const m=mountPaintPoint(rig,'se','mount',x,y,640,640);assert.ok(Math.abs(m.x-12)<1e-8&&Math.abs(m.y-34)<1e-8);
});
