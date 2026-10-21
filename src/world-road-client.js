// This extension is installed only in the explicit Morro preview. Battle and rewards
// continue to use the existing account/server flow.
const worldRoadChapters=homeArt.world?.morroRoad||[],worldRoad=createNeighborhoodRoad(worldRoadChapters.length?worldRoadChapters:[{id:'morro',stage:'morro-1'}]);
const worldRoadEnabled=new URLSearchParams(location.search).get('overworld')==='pilot'&&worldRoadChapters.length===5;
if(worldRoadEnabled)for(const c of worldRoadChapters)worldScenes[c.id]=c.scene;
function worldRoadChapter(id=worldRuntime.id){return worldRoadEnabled?worldRoadChapters.find(c=>c.id===id):null;}
function worldRoadProgress(){return typeof trailSync!=='undefined'&&trailSync.user===playerAccount?.profile?.id?trailSync.confirmed():null;}
function worldIsMorro(){return worldRuntime.id==='morro'||!!worldRoadChapter();}
function worldRoadGateState(){const c=worldRoadChapter();return c?worldRoad.gate(c.id,worldRoadProgress()):null;}
function worldRoadGateLabel(c,status){return status.state==='pending'?'Conferindo a vitória na sua conta…':['open','complete'].includes(status.state)?'Passagem liberada':'Vença '+trails.stage(c.stage).foes.map(f=>f.name).join(' e ')+' para seguir';}
function worldSyncRoadGate(){
 const c=worldRoadChapter();if(!c)return;const scene=worldScene(),gate=scene.tiled.layers.Foreground.find(r=>r.properties.road_gate),solids=scene.tiled.layers.Solids,status=worldRoadGateState(),closed=!['open','complete'].includes(status.state);
 if(!gate)return;const existing=solids.findIndex(r=>r.properties.dynamic_road_gate);
 if(closed&&existing<0)solids.push({...gate,id:-100,properties:{...gate.properties,hidden:true,dynamic_road_gate:true}});
 if(!closed&&existing>=0)solids.splice(existing,1);
 const state=worldState();state.roadGateClosed=closed;state.roadGate=gate;if(state.roadGateSignature!==status.state){state.roadGateSignature=status.state;worldRuntime.missionKey=null;if($('worldDestination'))renderWorldDestinations();}
}
function drawWorldRoadGate(g){
 const state=worldState(),r=state.roadGate;if(!state.roadGateClosed||!r)return;
 const f=homeArt.world.kit.frames.fence,image=homeImages.get('world-kit-'+f.sheet),w=r.w+12,h=w*f.h/f.w;
 if(image)g.drawImage(image,f.x,f.y,f.w,f.h,r.x-6,r.y+r.h-h,w,h);
 const label=worldRoadGateLabel(worldRoadChapter(),worldRoadGateState());g.font='bold 12px Nunito,sans-serif';g.textAlign='center';g.lineWidth=4;g.strokeStyle='#fff3d6';g.strokeText(label,r.x+r.w/2,r.y+r.h-h-8);g.fillStyle='#574332';g.fillText(label,r.x+r.w/2,r.y+r.h-h-8);
}
function worldRoadInteract(place){
 const c=worldRoadChapter();if(!c||!['road_gate','road_next','road_back'].includes(place.action))return false;
 if(place.action==='road_back'){openWorld(place.target,{arrival:'north'});return true;}
 const status=worldRoadGateState();if(!['open','complete'].includes(status.state)){toast(worldRoadGateLabel(c,status));trailSync.retry();return true;}
 if(place.action==='road_gate'){const exit=worldScene().places.find(p=>p.action==='road_next');worldGo(exit);return true;}
 if(status.next)openWorld(status.next.id,{arrival:'south'});else if(trails.demo)openDemoFinale();else homeActions.city();return true;
}
