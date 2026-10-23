import test from 'node:test';
import assert from 'node:assert/strict';
import {createCraft,craftClass,craftGeometry,craftDown,craftMove,craftUp,craftReady,craftPayload,craftRestore,craftCancel,craftSelect,CRAFT_CLASSES} from './src/workshop-craft.js';
import {validWorkshopPayload} from './src/workshop-model.js';
const at={x:850,y:220};
function drag(s,a,b){craftDown(s,a);craftMove(s,b);craftUp(s,b);}
function completeCut(s,density=1){const pts=craftGeometry(s.kind).points;craftSelect(s,'tesoura');craftDown(s,pts[0]);for(let i=0;i<pts.length;i++){const a=pts[i],b=pts[(i+1)%pts.length];for(let j=1;j<=density;j++)craftMove(s,{x:a.x+(b.x-a.x)*j/density,y:a.y+(b.y-a.y)*j/density});}craftUp(s,pts[0]);}
for(const kind of Object.keys(CRAFT_CLASSES))test(kind+': neutral construction can be completed with valid existing account payloads',()=>{
 let s=createCraft(kind,0);const g=craftGeometry(kind);
 for(const p of g.rods)drag(s,at,p);assert.ok(craftReady(s));assert.ok(validWorkshopPayload(0,craftPayload(s)));
 s=createCraft(kind,1);for(const p of g.points)drag(s,p,{x:p.x+43,y:p.y});assert.ok(craftReady(s));assert.ok(validWorkshopPayload(1,craftPayload(s)));
 s=createCraft(kind,2);completeCut(s,200);assert.equal(s.cutPhase,'glue');craftSelect(s,'cola');for(const p of g.points)drag(s,p,p);assert.equal(s.cutPhase,'seat');craftSelect(s,'pinça');drag(s,at,g.center);assert.ok(craftReady(s));assert.ok(validWorkshopPayload(2,craftPayload(s)));
 s=createCraft(kind,3);craftSelect(s,'vento');craftDown(s,{x:690,y:300});drag(s,{x:350+32*2.6,y:510},{x:480,y:510});assert.ok(craftReady(s));assert.ok(validWorkshopPayload(3,craftPayload(s)));
 s=createCraft(kind,4);drag(s,at,{x:480,y:478});drag(s,{x:480,y:505},{x:523,y:505});assert.ok(craftReady(s));assert.ok(validWorkshopPayload(4,craftPayload(s)));
});
test('cut result is independent of dense pointer events, including corners',()=>{const a=createCraft('rare',2),b=createCraft('rare',2);completeCut(a,1);completeCut(b,400);assert.deepEqual([...a.cut].sort((a,b)=>a-b),[...b.cut].sort((a,b)=>a-b));assert.equal(a.damage,b.damage);assert.equal(a.cutPhase,b.cutPhase);});
test('wrong placements, loose or overpulled knots cannot complete a stage',()=>{
 const s=createCraft();drag(s,at,{x:730,y:545});assert.equal(s.rods.length,0);assert.equal(craftReady(s),false);assert.throws(()=>craftPayload(s));
 const k=createCraft('rare',1),p=craftGeometry('rare').points[0];drag(k,p,{x:p.x+7,y:p.y});assert.equal(k.knots.length,0);drag(k,p,{x:p.x+90,y:p.y});assert.equal(k.knots.length,0);
});
test('damage is spatial, blocks completion and reset protects the sealed soul',()=>{const s=createCraft('common',2);craftDown(s,{x:480,y:294});for(let i=0;i<40;i++)craftMove(s,{x:i%2?450:510,y:294});assert.equal(s.damage,100);assert.equal(craftReady(s),false);assert.equal(s.tail,false);assert.equal(createCraft('common',2).damage,0);});
test('pause, cancel and two-click placement work without holding a pointer',()=>{const s=createCraft();s.paused=true;drag(s,at,craftGeometry().rods[0]);assert.equal(s.rods.length,0);s.paused=false;craftDown(s,at);craftUp(s,at);assert.equal(s.carrying,'rod');const p=craftGeometry().rods[0];craftDown(s,p);craftUp(s,p);assert.equal(s.rods.length,1);craftDown(s,at);craftCancel(s);assert.equal(s.carrying,null);});
test('local restore rejects another class, stage, out-of-bounds geometry and corrupt values',()=>{const s=createCraft();s.rods=[0,1];assert.deepEqual(craftRestore(s,'common',0).rods,[0,1]);assert.deepEqual(craftRestore(s,'rare',0).rods,[]);assert.deepEqual(craftRestore(s,'common',1).rods,[]);assert.deepEqual(craftRestore({...s,rods:[200]},'common',0).rods,[]);assert.deepEqual(craftRestore({...s,balance:NaN},'common',0).rods,[]);});
test('difficulty has visible complexity and bounded margins, without species-specific geometry',()=>{assert.equal(craftClass('rara'),'rare');assert.equal(craftClass('especial'),'common');assert.ok(craftGeometry('rare').points.length>craftGeometry('common').points.length);assert.ok(CRAFT_CLASSES.rare.cutTolerance>=14);assert.equal(JSON.stringify(createCraft()).includes('rabbito'),false);assert.equal(JSON.stringify(craftGeometry()).includes('species'),false);});
