// Canvas composition: art retains its original colour; guides are functional geometry.
export function createWorkshopRenderer({bench,parts,rects,drawCreature,reduced=()=>false}){
 let lastStage=-1,stageAt=0,lastCount=-1,countAt=0;
 function piece(g,id,x,y,w,h,angle=0,px=.5,py=.5){
  const r=rects?.[id];if(!parts?.complete||!r)return;
  g.save();g.translate(x,y);g.rotate(angle);g.drawImage(parts,...r,-w*px,-h*py,w,h);g.restore();
 }
 return function draw(g,job,input,time){
  const W=960,H=640,stage=job?.stage??0,p=workshopPose(stage,input,time,reduced());
  if(lastStage!==stage){lastStage=stage;stageAt=time;lastCount=-1;}
  const ease=t=>{t=Math.max(0,Math.min(1,t));return t*t*(3-2*t);},arrival=reduced()?1:ease((time-stageAt)/.9);
  g.clearRect(0,0,W,H);if(bench?.complete&&bench.naturalWidth)g.drawImage(bench,0,0,W,H);
  else {g.fillStyle='#ead0a0';g.fillRect(0,0,W,H);}
  const x=480,y=400;
  // Ground contact is independent of the animated root.
  g.beginPath();g.ellipse(x,y+119,80,7,0,0,Math.PI*2);g.fillStyle='#50412b30';g.fill();
  g.save();g.translate(x,y);g.rotate(p.tilt*Math.PI/180);g.translate(0,stage>=5?(-12+p.rise)*arrival:p.rise);
  if(stage>=5&&!reduced()){
   const elapsed=time-stageAt,burst=Math.max(0,1-elapsed/2.8),bloom=1+.045*Math.sin(Math.min(elapsed/1.5,1)*Math.PI);g.scale(bloom,bloom);
   g.save();g.globalAlpha=burst*.55;const aura=g.createRadialGradient(0,-15,15,0,-15,190);aura.addColorStop(0,'#fff6cd');aura.addColorStop(.6,'#79d8ca88');aura.addColorStop(1,'#79d8ca00');g.fillStyle=aura;g.fillRect(-200,-210,400,400);g.restore();
  }
  const rabbit=job.modelId==='rabbito'||job.targetModelId==='rabbito';
  const pts=rabbit?[[-65,-155],[28,-155],[50,8],[-48,70]]:[[0,-100],[105,0],[0,100],[-105,0]],count=stage>0?4:input.joints.length;
  const ends=rabbit?[[-25,-47],[28,-47],[-48,70],[50,8]]:pts.map((_,i)=>pts[(i+1)%4]);
  if(lastCount!==count){lastCount=count;countAt=time;}
  if(stage===2&&input.reveal&&typeof drawWorkshopReveal==='function'){
   // A marca da alma brilha sob os retalhos; a escavação cobre o desenho real da espécie.
   g.save();g.shadowColor='#5fe0cf';g.shadowBlur=reduced()?0:18;
   if(rabbit&&parts?.complete){piece(g,'body',0,30,148,178);piece(g,'earFar',28,-47,42,113,0,.5,.94);piece(g,'earNear',-25,-47,66,119,0,.5,.94);}
   else{g.beginPath();pts.forEach(([a,b],i)=>i?g.lineTo(a,b):g.moveTo(a,b));g.closePath();g.fillStyle='#c9f4ec';g.fill();g.lineWidth=3;g.strokeStyle='#1b8a7a';g.stroke();}
   g.restore();drawWorkshopReveal(g,input.reveal,time,{...input.revealView,reduced:reduced()});
  }else if(stage<3){
   if(rabbit&&parts?.complete){g.globalAlpha=.10;piece(g,'body',0,30,148,178);piece(g,'earFar',28,-47,42,113,0,.5,.94);piece(g,'earNear',-25,-47,66,119,0,.5,.94);g.globalAlpha=1;}
   g.strokeStyle='#75685466';g.lineWidth=2;g.setLineDash([6,6]);for(let i=0;i<4;i++){g.beginPath();g.moveTo(...pts[i]);g.lineTo(...ends[i]);g.stroke();}g.setLineDash([]);
   for(let i=0;i<count;i++){const a=pts[i],b=ends[i],f=stage===0&&i===count-1&&!reduced()?ease((time-countAt)/.4):1;g.beginPath();g.moveTo(...a);g.lineTo(a[0]+(b[0]-a[0])*f,a[1]+(b[1]-a[1])*f);g.strokeStyle='#6d472b';g.lineWidth=9;g.stroke();g.strokeStyle='#e8bc75';g.lineWidth=5;g.stroke();}
   if(stage>=1)for(const [a,b] of pts){g.save();g.translate(a,b);g.rotate(.7);g.strokeStyle='#fbefcf';g.lineWidth=4;g.strokeRect(-6,-6,12,12);g.restore();}
   if(stage===2&&input.cuts.length){if(rabbit){if(input.cuts.length>=1)piece(g,'earNear',-25,-47,66,119,0,.5,.94);if(input.cuts.length>=2)piece(g,'earFar',28,-47,42,113,0,.5,.94);if(input.cuts.length>=3){g.save();if(input.cuts.length===3){g.beginPath();g.rect(-90,-70,180,100);g.clip();}piece(g,'body',0,30,148,178);g.restore();}}else{g.globalAlpha=.22;g.fillStyle='#38a6a0';g.beginPath();pts.slice(0,input.cuts.length+1).forEach(([a,b],i)=>i?g.lineTo(a,b):g.moveTo(a,b));g.lineTo(0,0);g.closePath();g.fill();g.globalAlpha=1;}}
   if(stage===1){g.fillStyle='#e1d6b6';g.fillRect(-100,130,200,10);g.fillStyle='#398e86';g.fillRect(20,130,20,10);g.fillStyle='#254c5a';const needle=reduced()?input.tension:50+Math.sin(time*2.2)*45;g.fillRect(-100+needle*2,124,3,22);}
   if(stage===0||stage===2)pts.forEach(([a,b],i)=>{const done=(stage===0?input.joints:input.cuts).length>i;g.beginPath();g.arc(a,b,13,0,Math.PI*2);g.fillStyle=done?'#337f79':'#fff4d5';g.fill();g.strokeStyle='#425959';g.lineWidth=2;g.stroke();g.fillStyle=done?'#fff4d5':'#314c54';g.font='bold 14px sans-serif';g.textAlign='center';g.textBaseline='middle';g.fillText(String(i+1),a,b);});
  }
  if(stage>=3){
   if(rabbit&&parts?.complete&&rects){
    // One anatomical coordinate space. Ears overlap their fixed roots on the body.
    if(stage>=4)piece(g,'tail',-52,43,128,85,p.tail,.9,.5);
    // Keep the canonical body. The unregistered happy body is an unused source study.
    g.globalAlpha=stage===3?arrival:1;piece(g,'body',0,30,148,178,0,.5,.5);
    piece(g,'earFar',28,-47,42,113,p.ear,.5,.94);
    piece(g,'earNear',-25,-47,66,119,-p.ear,.5,.94);g.globalAlpha=1;
   }else if(drawCreature)drawCreature(g,job,time,-115,-120,230,stage>=5?'victory':'idle');
   if(stage===3){g.beginPath();g.moveTo(0,10);g.bezierCurveTo(40,80,-50,115,(input.balance-50)*2,155);g.strokeStyle='#254c5a';g.lineWidth=2;g.stroke();g.beginPath();g.arc((input.balance-50)*2,155,7,0,7);g.fillStyle='#b66f42';g.fill();}
  }
  if(stage===4||stage>=5){
   g.save();g.globalAlpha=stage>=5?.35:.12+p.glow*.25;g.strokeStyle='#309d96';g.lineWidth=3;g.beginPath();g.ellipse(0,115,155,30,0,0,7);g.stroke();g.restore();
   if(!reduced())for(let i=0;i<12;i++){const a=i*2.399+time*.3,r=105+Math.sin(time+i)*16;g.fillStyle=i%2?'#e7b54c':'#53a69e';g.globalAlpha=.65;g.beginPath();g.arc(Math.cos(a)*r,Math.sin(a)*r*.6-25,2+i%3,0,7);g.fill();}g.globalAlpha=1;
   g.strokeStyle='#2c716e';g.lineWidth=2;g.beginPath();g.moveTo(0,65);g.bezierCurveTo(65,135,-60,120,-12,177);g.stroke();
  }
  g.restore();
  // Functional preview caption; not painted into the source image.
  g.fillStyle='#fff8e9e8';g.fillRect(340,554,280,38);g.fillStyle='#294b53';g.font='bold 15px sans-serif';g.textAlign='center';g.fillText(stage>=5?'Um novo elo ganhou vida':stage===2&&input.reveal?'Revele a marca sem rasgar':stage<3?'Gabarito de montagem · quatro apoios':job.name||'Seu parceiro',480,578);
 };
}
