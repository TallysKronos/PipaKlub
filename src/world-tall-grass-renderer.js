export function drawTallGrass(g,b,{project,wind=0,paused=false}){
 const p=project(b),sway=paused?0:Math.sin(wind*1.7+b.phase)*2.2;
 const colors=['#689b45','#83b351','#a5c86a'];
 g.save();g.translate(p.x,p.y);g.lineJoin='round';
 g.fillStyle='#355b3a26';g.beginPath();g.ellipse(0,0,13,4,0,0,7);g.fill();
 for(const [i,spread]of [-1,-.5,0,.5,1].entries()){
  const h=b.h*(i===2?1:.65+Math.abs(spread)*.14),root=spread*7;
  const tip=spread*12+sway+b.bend*24,top=-h*(1-Math.abs(b.bend)*.54);
  g.fillStyle=colors[(b.tint+i)%3];g.strokeStyle='#547e3d';g.lineWidth=.65;
  g.beginPath();g.moveTo(root-4,1);g.quadraticCurveTo(root-11+tip*.22,-h*.45,tip,top);
  g.quadraticCurveTo(root+11+tip*.35,-h*.4,root+3,1);g.closePath();g.fill();g.stroke();
  g.strokeStyle='#c3dd8525';g.lineWidth=1;g.beginPath();g.moveTo(root,0);g.quadraticCurveTo(root+tip*.3,-h*.4,tip,top+5);g.stroke();
 }
 g.restore();
}
export function drawTallGrassParticles(g,particles){for(const p of particles){
 g.save();g.translate(p.x,p.y);g.rotate(p.rotation);g.globalAlpha=Math.min(1,(p.life-p.age)/.25);
 g.fillStyle=['#c8df89','#a4cb67','#e0e7a0'][p.tint];g.strokeStyle='#638c49';g.lineWidth=.8;
 g.beginPath();g.moveTo(-p.size,0);g.quadraticCurveTo(0,-p.size,p.size,0);g.quadraticCurveTo(0,p.size,-p.size,0);g.fill();g.stroke();g.restore();
}}
