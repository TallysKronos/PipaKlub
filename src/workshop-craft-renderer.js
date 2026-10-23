export const CRAFT_ICON_PATHS={
 'pinça':'M19 5 8 21 5 43M25 5 35 22 38 43M5 43 13 35M38 43 30 35',
 linha:'M14 10h20v29H14zM10 7h28v6H10zM10 36h28v6H10zM16 19h16M16 24h16M16 29h16M34 26c14 0 11 18 3 17',
 tesoura:'M20 30 38 7 28 33M19 33 7 7 26 30M20 35a7 7 0 1 1-14 1 7 7 0 0 1 14-1ZM39 35a7 7 0 1 1-14 1 7 7 0 0 1 14-1Z',
 cola:'M18 14h12l6 11v18H12V25ZM20 4h8v10h-8ZM16 29h16v9H16z',
 vento:'M6 17h26c12 0 9-14 2-10M6 25h34M6 33h24c12 0 8 15 1 10',
 luz:'M24 4v5M6 12l5 4M42 12l-5 4M7 29h5M41 29h-5M17 35c0-7-6-9-6-16a13 13 0 0 1 26 0c0 7-6 9-6 16ZM18 40h12M21 45h6',
 voltar:'M26 9 11 24l15 15M12 24h28',
 confirmar:'M7 25 19 37 42 12',
 refazer:'M9 20a16 16 0 1 1 1 16M9 7v14h14'
};
export function craftIcon(id){return '<svg viewBox="0 0 48 48" aria-hidden="true" focusable="false"><path d="'+CRAFT_ICON_PATHS[id]+'"/></svg>';}
const craftBirthClocks=new WeakMap(),craftToolPaths=new Map();
export function drawCraftWorkshop(g,s,time,{bench,reduced=false,drawCreature}={}){
 const geo=craftGeometry(s.kind),cfg=CRAFT_CLASSES[s.kind],{points,center}=geo;
 g.clearRect(0,0,960,640);if(bench?.naturalWidth)g.drawImage(bench,0,0,960,640);else{g.fillStyle='#ba7941';g.fillRect(0,0,960,640);}
 function box(x,y,w,h,fill,r=12){g.beginPath();g.roundRect(x,y,w,h,r);g.fillStyle=fill;g.fill();}
 function path(ps,close=false){g.beginPath();ps.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));if(close)g.closePath();}
 function line(a,b,color,width){g.beginPath();g.moveTo(a.x,a.y);g.lineTo(b.x,b.y);g.strokeStyle=color;g.lineWidth=width;g.stroke();}
 function dot(p,r,fill,stroke){g.beginPath();g.arc(p.x,p.y,r,0,Math.PI*2);g.fillStyle=fill;g.fill();if(stroke){g.strokeStyle=stroke;g.lineWidth=2;g.stroke();}}
 function label(text,x,y,size=15,color='#fff3d8'){g.fillStyle=color;g.font='600 '+size+'px system-ui';g.textAlign='center';g.fillText(text,x,y);}
 box(211,77,538,482,'#173f43bb',16);box(219,85,522,466,'#2f6461',12);
 g.save();g.globalAlpha=.12;g.strokeStyle='#d5edce';g.lineWidth=1;for(let x=231;x<740;x+=24){g.beginPath();g.moveTo(x,94);g.lineTo(x,540);g.stroke();}for(let y=98;y<545;y+=24){g.beginPath();g.moveTo(227,y);g.lineTo(731,y);g.stroke();}g.restore();
 box(785,116,143,377,'#f8e6be',12);label('MATERIAIS',857,144,13,'#355352');
 if(s.stage>=5){
  if(!craftBirthClocks.has(s))craftBirthClocks.set(s,time);const arrival=reduced?1:Math.max(0,Math.min(1,(time-craftBirthClocks.get(s)-.4)/1.4));
  const pulse=reduced?0:Math.sin(time*2)*6;g.save();g.translate(480,300+pulse);
  const aura=g.createRadialGradient(0,0,20,0,0,230);aura.addColorStop(0,'#fff0adbb');aura.addColorStop(1,'#fff0ad00');g.fillStyle=aura;g.fillRect(-230,-230,460,460);
  if(arrival<1){g.save();g.globalAlpha=1-arrival;path(points.map(p=>({x:p.x-480,y:p.y-294})),true);g.fillStyle='#ffe1a1';g.fill();g.strokeStyle='#fff4c9';g.lineWidth=4;g.stroke();g.restore();}
  g.globalAlpha=arrival;if(drawCreature)drawCreature(g,time);else{label('Um novo elo ganhou vida',0,0,23);}g.restore();return;
 }
 // No species sprite, name, ear shape or colour is read during construction.
 g.save();if(s.stage===3){g.translate(480,294);g.rotate((s.balance-50)*.008*(s.tested?1:.2));g.translate(-480,-294);}
 const paperVisible=s.stage>=3||s.seated;
 if(paperVisible){path(points,true);g.fillStyle='#f6df9c';g.fill();points.forEach((p,i)=>{path([center,p,points[(i+1)%points.length]],true);g.fillStyle=i%2?'#e8b96a':'#ffedbb';g.fill();});path(points,true);g.strokeStyle='#584e3c';g.lineWidth=3;g.stroke();}
 if(s.stage===2&&s.cutPhase==='cut'){
  box(267,99,426,392,'#f6dfa7',4);g.save();g.globalAlpha=.14;path(points,true);g.fillStyle='#277a74';g.fill();g.restore();
 }
 if(s.stage!==2||s.cutPhase!=='cut')geo.rods.forEach((p,i)=>{
  const done=s.stage>0||s.rods.includes(i);if(done){line(p.a,p.b,'#61482d',8);line(p.a,p.b,'#e9bf7b',4);}
  else if(s.light){g.setLineDash([6,6]);line(p.a,p.b,'#eddbab88',3);g.setLineDash([]);dot(p,9,'#f9e7bf','#375957');}
 });
 if(s.stage===1)points.forEach((p,i)=>{
  if(s.knots.includes(i)){dot(p,9,'#f3e4bd','#735438');line({x:p.x-6,y:p.y-5},{x:p.x+6,y:p.y+5},'#b79158',3);return;}
  dot(p,11,'#fff3d8','#173f43');if(s.drag?.type==='knot'&&s.drag.i===i){const [a,b]=cfg.pull;g.strokeStyle='#e9c771';g.lineWidth=b-a;g.beginPath();g.arc(p.x,p.y,(a+b)/2,0,Math.PI*2);g.stroke();line(p,s.cursor,'#ffefc3',3);dot(s.cursor,7,'#fff3d8');}
 });
 if(s.stage===2){
  if(s.cutPhase==='cut'){
   if(s.light){g.setLineDash([7,5]);path(points,true);g.strokeStyle='#436e66';g.lineWidth=3;g.stroke();g.setLineDash([]);}
   geo.samples.forEach((p,i)=>{if(s.cut.includes(i))dot(p,3.3,'#238b7e');});
   if(s.damage>0){g.strokeStyle='#bd543d';g.lineWidth=2;for(let i=0;i<Math.ceil(s.damage/8);i++){const x=445+i%4*16,y=264+Math.floor(i/4)*19;line({x,y},{x:x+9,y:y+12},'#bd543d',2);}}
  }else if(s.cutPhase==='glue')points.forEach((p,i)=>{dot(p,14,s.glue.includes(i)?'#e9efc6':'#e6c36f77','#f0deab');if(!s.glue.includes(i))label('+',p.x,p.y+5,17);});
  else if(!s.seated){g.setLineDash([6,6]);path(points,true);g.strokeStyle='#ffe3a3';g.lineWidth=3;g.stroke();g.setLineDash([]);}
 }
 g.restore();
 if(s.stage===0){for(let i=0;i<4;i++)line({x:813,y:203+i*26},{x:900,y:180+i*26},'#6f5133',9);for(let i=0;i<4;i++)line({x:813,y:201+i*26},{x:900,y:178+i*26},'#e3bd7c',5);label('Varetas',857,333,15,'#355352');label('Pegar e levar',857,357,12,'#61706a');}
 else if(s.stage===2&&s.cutPhase==='seat'){box(808,193,96,128,'#d6ae6f',2);path([{x:856,y:187},{x:911,y:251},{x:856,y:326},{x:803,y:251}],true);g.fillStyle='#f8e3a6';g.fill();g.strokeStyle='#9e774a';g.lineWidth=2;g.stroke();label('Vela cortada',857,361,14,'#355352');}
 else if(s.stage===4){
  if(!s.tail){line({x:853,y:192},{x:860,y:312},'#b88155',4);for(let i=0;i<3;i++){path([{x:836,y:224+i*31},{x:873,y:224+i*31},{x:856,y:241+i*31}],true);g.fillStyle='#e8c99a';g.fill();}box(834,275,45,31,'#315c5b',6);label('?',856,299,25);label('Rabiola selada',857,353,14,'#355352');label('Alma protegida',857,378,12,'#61706a');}
  if(s.tail){line({x:480,y:478},{x:480,y:515},'#f6e6be',3);dot({x:480,y:505},12,'#f4d078','#234e50');if(s.drag?.type==='soul'){const [a,b]=cfg.pull;g.beginPath();g.arc(480,505,(a+b)/2,0,Math.PI*2);g.strokeStyle='#eac35b';g.lineWidth=b-a;g.stroke();line({x:480,y:505},s.cursor,'#ffefc3',3);}if(s.synced){dot({x:480,y:478},14,'#78c6aa');label('Elo firme',857,368,16,'#315c5b');}}
  else{g.setLineDash([5,4]);dot({x:480,y:478},18,'#e9c15e33','#f5d78d');g.setLineDash([]);}
 }else{label(s.stage===1?'Linha de seda':s.stage===3?'Teste de voo':'Kit do ateliê',857,252,15,'#355352');label('Rabiola guardada',857,406,12,'#61706a');}
 if(s.stage===3){line({x:350,y:510},{x:610,y:510},'#e4cd98',6);dot({x:350+s.balance*2.6,y:510},14,'#f4cd72','#284e4e');if(s.tested&&!reduced){g.save();g.globalAlpha=.4;for(let i=0;i<3;i++){const off=(time*75+i*57)%470;line({x:236+off,y:200+i*70},{x:267+off,y:196+i*70},'#e1f0d2',2);}g.restore();}label('Cabresto',480,545,12);}
 if(s.carrying){g.save();g.globalAlpha=.85;const p=s.cursor;if(s.carrying==='rod'){const next=geo.rods.find((_,i)=>!s.rods.includes(i));if(next)line({x:p.x+(next.a.x-next.b.x)/2,y:p.y+(next.a.y-next.b.y)/2},{x:p.x-(next.a.x-next.b.x)/2,y:p.y-(next.a.y-next.b.y)/2},'#f8d58e',7);}else if(s.carrying==='paper'){path(points.map(q=>({x:q.x+p.x-480,y:q.y+p.y-294})),true);g.fillStyle='#ffe7af';g.fill();}else{dot(p,18,'#ead5a5','#315c5b');label('?',p.x,p.y+6,23,'#315c5b');}g.restore();}
 if(s.flash>0){g.save();g.globalAlpha=s.flash*.25;path(points,true);g.fillStyle='#da644b';g.fill();g.restore();s.flash=Math.max(0,s.flash-.025);}
 if(s.cursor&&['tesoura','cola'].includes(s.tool)){dot(s.cursor,s.tool==='cola'?10:5,s.tool==='cola'?'#ecf0d480':'#fff0bc','#355c57');}
 if(s.cursor&&!s.paused&&CRAFT_ICON_PATHS[s.tool]){if(!craftToolPaths.has(s.tool))craftToolPaths.set(s.tool,new Path2D(CRAFT_ICON_PATHS[s.tool]));g.save();g.translate(s.cursor.x+7,s.cursor.y-20);g.scale(.7,.7);g.lineWidth=6;g.strokeStyle='#fff1ce';g.stroke(craftToolPaths.get(s.tool));g.lineWidth=3;g.strokeStyle='#234e50';g.stroke(craftToolPaths.get(s.tool));g.restore();}
 if(s.paused){box(280,247,400,86,'#173f43ee');label('Bancada pausada',480,298,25);}
}
