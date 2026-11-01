// PIP-128: editable, deterministic composition study. No game/runtime imports.
// Run from repository root: node art/ui/soulmonsters-v2/pip-128/render.mjs
import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
let canvasModule;
try { canvasModule = require(process.env.HUD_CANVAS_MODULE || '@napi-rs/canvas'); }
catch(error) {
 if(process.env.HUD_CANVAS_MODULE)throw error;
 canvasModule = require('../../../../tmp/soulgen-qa/node_modules/@napi-rs/canvas');
}
const {createCanvas, loadImage, GlobalFonts} = canvasModule;
const here=path.dirname(fileURLToPath(import.meta.url));
const repo=path.resolve(here,'../../../..');
const fonts=path.join(repo,'godot/assets/campaign/ui-modern/fonts');
GlobalFonts.registerFromPath(path.join(fonts,'Nunito.ttf'),'Nunito');
GlobalFonts.registerFromPath(path.join(fonts,'BarlowCondensed-Bold.ttf'),'Barlow');
const assets={world:'contexto/exploracao.png',arena:'../../../../godot/assets/campaign/veredas-arena-wide-v2.png',kael:'../../../../godot/assets/campaign/portrait-kael-manga-v4.png',rabbit:'../../../../godot/assets/campaign/combat-rabbito.png',rival:'../../../../godot/assets/campaign/combat-lacertubo.png'};
const images={};for(const [key,file] of Object.entries(assets))images[key]=await loadImage(path.resolve(here,file));
const directions={
 A:{name:'Seda & vareta',label:'Papel leve. Estrutura aparente.',ink:'#163d40',paper:'#fff5dc',muted:'#536b65',accent:'#087b7e',line:'#087b7e',select:'#c05528',edge:'#a77f43',surface:'#f2dfb3'},
 B:{name:'Muro do bairro',label:'O bairro escreve a interface.',ink:'#233d42',paper:'#fff0ca',muted:'#b7ceca',accent:'#f3ae48',line:'#8dd5ba',select:'#ed7c40',edge:'#e9ba71',surface:'#34565a'},
 C:{name:'Carretel & Elo',label:'Um fio entre você e seu parceiro.',ink:'#152e43',paper:'#f7edcf',muted:'#b8cbd0',accent:'#f4b95d',line:'#8ed7ca',select:'#f4b95d',edge:'#b49665',surface:'#25465a'}
};
const fixture={area:'Bosque dos Ventos',part:'TRILHA DAS COPAS · A',objective:'Siga a trilha até o marco de pedra.',longObjective:'Investigue o marco de pedra na bifurcação e descubra de onde vem o fio preso entre as raízes.',partner:'Rabbito',level:8,line:84,hull:96,energy:70,rival:'Lacertubo',rivalLevel:8,rivalLine:62,rivalHull:78,seconds:42,money:'1.240',emblems:'0 / 12',selected:'Soulmonsters'};
let ctx,D,records=[],current=[],checks=[];
const fill=(color)=>ctx.fillStyle=color;
function rect(x,y,w,h,color){fill(color);ctx.fillRect(x,y,w,h);}
function line(points,color,width=2){ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.strokeStyle=color;ctx.lineWidth=width;ctx.lineCap='round';ctx.lineJoin='round';ctx.stroke();}
function poly(points,color,stroke=null,width=1){ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();fill(color);ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=width;ctx.stroke();}}
function circle(x,y,r,color,stroke=null,width=1){ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);fill(color);ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=width;ctx.stroke();}}
function text(value,x,y,size=20,color=D.paper,font='Nunito',max=Infinity,align='left'){
 ctx.font=`${font==='Nunito'?'700 ':''}${size}px ${font}`;ctx.textAlign=align;ctx.textBaseline='alphabetic';fill(color);
 const width=ctx.measureText(value).width;
 current.push({type:'text',text:value,x,y,width,size,max,overflow:width>max+.5});ctx.fillText(value,x,y);
}
function wrap(value,x,y,max,size=19,color=D.paper,leading=27){let row='',n=0;for(const word of value.split(' ')){ctx.font=`700 ${size}px Nunito`;if(row&&ctx.measureText(row+' '+word).width>max){text(row,x,y+n*leading,size,color,'Nunito',max);row=word;n++;}else row+=(row?' ':'')+word;}text(row,x,y+n*leading,size,color,'Nunito',max);return(n+1)*leading;}
function region(id,x,y,w,h){current.push({type:'region',id,x,y,w,h});}
function knot(x,y,color=D.select){circle(x,y,6,D.paper,D.ink,2);line([[x-6,y-4],[x+6,y+4]],color,3);line([[x-6,y+4],[x+6,y-4]],color,3);}
function spool(x,y,r=25){circle(x,y,r,D.paper,D.ink,3);circle(x,y,r-5,D.ink);for(let n=0;n<3;n++){ctx.beginPath();ctx.ellipse(x,y,(r-9),r-12+n*5,-.35,0,Math.PI*2);ctx.strokeStyle=D.accent;ctx.lineWidth=2;ctx.stroke();}circle(x,y,3,D.paper);}
function tail(x,y,color=D.select){line([[x,y],[x+17,y+6],[x+6,y+21],[x+18,y+30]],color,2);poly([[x+6,y+9],[x+17,y+7],[x+12,y+18]],color);poly([[x+5,y+23],[x+17,y+25],[x+9,y+33]],color);}
function panel(x,y,w,h,{selected=false,dark=false,plain=false}={}){
 const key=D.key;
 if(key==='A'){
  poly([[x+6,y+6],[x+w-2,y+9],[x+w+4,y+h+4],[x+1,y+h+6]],'#102e3238');
  poly([[x+1,y+5],[x+w-15,y],[x+w,y+h-7],[x+12,y+h]],dark?D.ink:D.paper,D.ink,1.5);
  line([[x+10,y+4],[x+w-18,y+2]],D.edge,3);line([[x+11,y+8],[x+13,y+h-8]],D.edge,2);
  if(!plain){knot(x+12,y+5);poly([[x+w-29,y+2],[x+w-14,y+1],[x+w-20,y+16]],D.accent);}
  if(selected){line([[x+4,y+h-5],[x+w-8,y+h-9]],D.select,5);tail(x+w-8,y+h-13);}
 }else if(key==='B'){
  poly([[x+5,y+5],[x+w+4,y+2],[x+w+1,y+h+6],[x-3,y+h+2]],selected?D.select:'#b6b19d');
  poly([[x,y],[x+w-8,y+1],[x+w,y+h-10],[x+w-13,y+h],[x+1,y+h-3]],selected?D.accent:dark?D.paper:D.ink,D.ink,1);
  if(!plain){rect(x+13,y-3,44,7,D.accent);line([[x+w-26,y+h-2],[x+w-8,y+h-4]],D.select,4);}
  // Two purposeful paint registers, kept outside the text's quiet surface.
  if(h>110){rect(x+2,y+12,5,27,D.accent);rect(x+2,y+44,5,7,D.select);}
  if(selected){rect(x+3,y+7,5,h-16,D.select);knot(x+w-8,y+h-5);}
 }else{
  // Rolled leading edge and a loose paper tail, rather than a generic capsule.
  ctx.beginPath();ctx.moveTo(x+18,y);ctx.lineTo(x+w-16,y);ctx.quadraticCurveTo(x+w,y,x+w,y+16);ctx.lineTo(x+w,y+h-12);ctx.lineTo(x+w-15,y+h);ctx.lineTo(x+18,y+h);ctx.quadraticCurveTo(x,y+h,x,y+h-18);ctx.lineTo(x,y+18);ctx.quadraticCurveTo(x,y,x+18,y);ctx.closePath();fill(dark?D.paper:D.ink);ctx.fill();ctx.strokeStyle=D.edge;ctx.lineWidth=1.5;ctx.stroke();
  line([[x+18,y+5],[x+w-21,y+5]],D.edge,1);
  if(!plain){knot(x+17,y+5,D.accent);line([[x+w-19,y+h-2],[x+w-4,y+h+7]],D.accent,2);}
  if(selected){line([[x+10,y+h-8],[x+w-23,y+h-8]],D.select,4);circle(x+w-14,y+h-9,4,D.select);}
 }
}
function primary(){return D.key==='A'?D.ink:D.paper;}
function secondary(){return D.key==='A'?D.muted:D.muted;}
function selectedInk(selected){return selected&&D.key==='B'?D.ink:primary();}
function selectedMuted(selected){return selected&&D.key==='B'?D.ink:secondary();}
function icon(kind,x,y,size=28,color=primary()){
 ctx.save();ctx.translate(x,y);ctx.scale(size/32,size/32);const p=(pts)=>line(pts,color,2.3);
 if(kind==='kite'){poly([[15,1],[29,13],[17,29],[2,15]],'transparent',color,2);p([[15,1],[17,29]]);p([[2,15],[29,13]]);p([[17,29],[22,33],[18,37]]);}
 else if(kind==='bag'){p([[6,10],[26,10],[28,29],[4,29],[6,10]]);p([[10,10],[10,4],[22,4],[22,10]]);p([[9,19],[23,19],[23,25],[9,25],[9,19]]);}
 else if(kind==='book'){p([[16,5],[16,29]]);p([[16,7],[4,3],[3,26],[16,29],[29,26],[28,3],[16,7]]);}
 else if(kind==='badge'){poly([[16,1],[28,9],[28,23],[16,31],[4,23],[4,9]],'transparent',color,2);p([[9,15],[14,21],[24,10]]);}
 else if(kind==='pin'){circle(16,10,8,'transparent',color,2);p([[9,15],[16,29],[23,15]]);circle(16,10,2,color);}
 else if(kind==='profile'){circle(16,8,6,'transparent',color,2);p([[5,29],[7,20],[16,17],[25,20],[27,29]]);}
 else if(kind==='save'){p([[4,2],[25,2],[29,7],[29,29],[3,29],[3,2]]);p([[9,2],[9,12],[23,12],[23,2]]);p([[9,28],[9,19],[23,19],[23,28]]);}
 else if(kind==='gear'){circle(16,16,10,'transparent',color,2);circle(16,16,4,'transparent',color,2);for(let n=0;n<8;n++){let a=n*Math.PI/4;p([[16+Math.cos(a)*11,16+Math.sin(a)*11],[16+Math.cos(a)*15,16+Math.sin(a)*15]]);}}
 else if(kind==='cut'){p([[3,3],[27,27]]);p([[27,3],[3,27]]);circle(6,26,4,'transparent',color,2);circle(26,26,4,'transparent',color,2);}
 else if(kind==='guard'){p([[16,2],[29,7],[26,23],[16,30],[6,23],[3,7],[16,2]]);p([[16,8],[16,23]]);}
 else {spool(16,16,13);}
 ctx.restore();
}
function keycap(key,x,y,color=primary()){ctx.font='700 15px Nunito';const w=Math.max(27,ctx.measureText(key).width+14);ctx.beginPath();ctx.roundRect(x,y-19,w,26,5);fill(color);ctx.fill();text(key,x+w/2,y,15,color===D.ink?D.paper:D.ink,'Nunito',w-6,'center');return w;}
function hint(key,label,x,y,color=primary()){const w=keycap(key,x,y,color);text(label,x+w+9,y+1,17,color);}
function fit(image,x,y,w,h,{frame=false,flip=false}={}){const sw=frame?image.width/8:image.width,sh=frame?image.height/16:image.height;const scale=Math.min(w/sw,h/sh);ctx.save();if(flip){ctx.translate(x+w,y);ctx.scale(-1,1);x=0;y=0;}ctx.drawImage(image,0,0,sw,sh,x+(w-sw*scale)/2,y+(h-sh*scale)/2,sw*scale,sh*scale);ctx.restore();}
function bar(x,y,w,pct,color=D.line,kind='line'){
 const track=D.key==='A'?'#d6cdb4':'#476375';
 if(kind==='hull'){for(let i=0;i<10;i++){const a=x+i*w/10;poly([[a,y+8],[a+6,y],[a+w/10-3,y],[a+w/10-9,y+8]],i<Math.round(pct/10)?color:track);}}
 else if(kind==='energy'){for(let i=0;i<10;i++)rect(x+i*w/10,y,w/10-3,7,i<Math.round(pct/10)?color:track);}
 else{line([[x,y+4],[x+w,y+4]],track,7);line([[x,y+4],[x+w*pct/100,y+4]],color,4);circle(x+w*pct/100,y+4,4,color);}
}
function resources(x,y,w,values,compact=false){const names=['Ligne','Armação','Energia'];names[0]='Linha';for(let i=0;i<(compact?2:3);i++){let yy=y+i*25;text(names[i],x,yy+8,15,primary());bar(x+78,yy,w-130,values[i],i===0?D.line:i===1?(D.key==='A'?'#6e5b3d':'#f7edcf'):D.accent,i===0?'line':i===1?'hull':'energy');text(values[i]+'%',x+w,yy+8,15,primary(),'Nunito',50,'right');}}
function partnerCard(x,y,w=338){region('partner',x,y,w,126);panel(x,y,w,126);fit(images.rabbit,x+9,y+13,70,98,{frame:true});text(fixture.partner,x+88,y+31,25,primary(),'Barlow',w-159);text('Nv. 8',x+w-18,y+29,17,primary(),'Nunito',70,'right');resources(x+88,y+49,w-107,[84,96,70],true);text('PARCEIRO ATIVO',x+88,y+112,12,secondary());}
function world(){ctx.drawImage(images.world,0,0,1280,720);}
function explore(long=false){world();region('objective',32,32,424,long?180:152);panel(32,32,424,long?180:152);
 icon('pin',51,49,24);text('KRONASTA / BOSQUE',89,62,13,secondary());text(fixture.area,53,96,29,primary(),'Barlow',380);text(fixture.part,53,119,12,secondary());wrap(long?fixture.longObjective:fixture.objective,53,148,380,17,primary(),24);
 panel(1026,32,222,58);icon('book',1044,45,26);hint('M','Kronasta',1083,67);region('map',1026,32,222,58);
 partnerCard(32,562,338);panel(1026,626,222,62);hint('Esc','Menu',1047,663);region('menu-hint',1026,626,222,62);
 panel(499,459,280,52,{selected:true});hint('Z','Examinar marco',518,491,selectedInk(true));region('interact',499,459,280,52);
 if(D.key==='C'){line([[72,562],[72,548],[127,548]],D.accent,2);spool(72,548,17);}
}
function battle(){ctx.drawImage(images.arena,0,0,1280,720);
 // Existing combat atlases, same cells/scales in every direction.
 fit(images.rabbit,266,226,220,280,{frame:true});fit(images.rival,784,186,305,290,{frame:true,flip:true});
 line([[88,520],[325,424],[382,396]],'#273d47',2);line([[1190,472],[974,391],[917,372]],'#273d47',2);
 panel(32,32,274,72);if(D.key==='C'){spool(68,67,27);text('KAEL',110,61,23,primary(),'Barlow');text('Tamer · Nv. 3',110,85,15,primary());}else{text('KAEL',52,61,23,primary(),'Barlow');text('Tamer · Nv. 3',52,85,15,primary());}
 panel(954,32,294,140);text('Lacertubo',975,66,29,primary(),'Barlow',185);text('Nv. 8',1228,64,17,primary(),'Nunito',55,'right');text('GUARDIÃO DAS VEREDAS',975,88,12,secondary());resources(975,104,252,[62,78],true);region('rival',954,32,294,140);
 if(D.key==='C'){circle(640,81,49,D.ink,D.accent,3);circle(640,81,42,D.ink,D.edge,1);line([[594,74],[587,71],[587,38],[619,38]],D.paper,2);text('42',640,86,42,primary(),'Barlow',100,'center');text('SEGUNDOS',640,107,12,primary(),'Nunito',100,'center');}else{panel(570,32,140,94);text('42',640,82,42,primary(),'Barlow',100,'center');text('SEGUNDOS',640,107,12,primary(),'Nunito',115,'center');}region('timer',570,32,140,100);
 panel(519,143,242,39,{plain:true});text('Rodada 1 / Vento',629,169,16,primary(),'Nunito',185,'center');line([[710,164],[734,164],[728,159]],primary(),2);line([[734,164],[728,169]],primary(),2);
 panel(32,477,335,211);text('Rabbito',51,514,30,primary(),'Barlow');text('Nv. 8',344,513,18,primary(),'Nunito',60,'right');resources(52,540,292,[84,96,70]);text('PARCEIRO ATIVO',52,668,12,secondary());region('partner',32,477,335,211);
 panel(391,574,857,114);const actions=[['Z','Cortar','cut'],['X','Habilidade','kite'],['C','Esquivar','guard'],['V','Puxão','spool']];
 actions.forEach(([k,label,ic],i)=>{let xx=409+i*205;panel(xx,590,190,77,{selected:i===0,plain:true});icon(ic,xx+15,610,29,selectedInk(i===0));text(label,xx+57,620,22,selectedInk(i===0),'Barlow',120);text(k+'  ·  '+(i===1?'15 energia':i===3?'Disputar linha':'Pronto'),xx+57,644,13,selectedMuted(i===0),'Nunito',122);region('action-'+i,xx,590,190,77);});
 panel(924,492,324,54,{plain:true});hint('Esc','Pausar duelo',944,525);
}
const options=[['Soulmonsters','kite'],['Itens','bag'],['Missões','book'],['Emblemas','badge'],['Tamer','profile'],['Oficina','spool'],['Salvar','save'],['Configurações','gear']];
function pause(long=false){world();rect(0,0,1280,720,'#0a2026bb');
 region('pause-shell',32,32,1216,656);panel(32,32,1216,656,{plain:true});
 if(D.key==='B'){rect(49,46,648,48,D.accent);text('KRONASTA / QUADRO DO PIPEIRO',62,81,30,D.ink,'Barlow');}
 else{text('JORNADA DO PIPEIRO',62,83,34,primary(),'Barlow');}
 text('KAEL',1113,78,25,primary(),'Barlow',110,'right');text('₱ '+fixture.money,1216,78,19,primary(),'Nunito',100,'right');
 line([[62,105],[1217,105]],D.key==='A'?D.edge:D.edge,1);
 if(D.key==='C'){line([[82,126],[82,168],[548,168],[548,282],[82,282],[82,394],[548,394],[548,506],[82,506],[82,574]],D.accent,3);spool(82,124,21);tail(82,572,D.accent);}
 options.forEach(([label,ic],i)=>{const x=62+(i%2)*258,y=143+Math.floor(i/2)*109;panel(x,y,238,86,{selected:i===0});icon(ic,x+20,y+26,34,selectedInk(i===0));text(label,x+68,y+41,26,selectedInk(i===0),'Barlow',155);text(i===0?'3 parceiros':i===3?'0 de 12':i===6?'Registrar jornada':'Abrir',x+68,y+65,13,selectedMuted(i===0));if(D.key==='C'){spool(x+5,y+43,11);if(i===0)tail(x+233,y+62,D.accent);}region('option-'+i,x,y,238,86);});
 panel(602,133,614,428,{plain:true});
 text('SEU PARCEIRO',626,167,13,secondary());text('Rabbito',626,205,39,primary(),'Barlow',270);text('Nv. 8',626,232,19,primary());
 fit(images.rabbit,812,181,149,200,{frame:true});
 resources(626,279,172,[84,96,70]);
 // Portrait is clipped to its own image region; cannot cover data or text.
 ctx.save();ctx.beginPath();ctx.rect(974,157,218,245);ctx.clip();fit(images.kael,974,147,218,360);ctx.restore();
 line([[626,397],[1193,397]],D.edge,1);text('PRÓXIMO PASSO',626,428,13,secondary());
 wrap(long?fixture.longObjective:fixture.objective,626,460,548,21,primary(),30);
 text('Bosque dos Ventos · Trilha das Copas',626,537,16,secondary(),'Nunito',548);
 panel(62,603,1154,53,{plain:true});hint('Z','Selecionar',83,637);hint('X','Voltar',287,637);text('Gerencie seus parceiros e cuide do Elo.',1193,638,18,primary(),'Nunito',670,'right');region('footer',62,603,1154,53);
}
function components(){rect(0,0,1280,720,D.key==='A'?'#e7e2d3':'#10242e');text('CONSTRUÇÃO / SEM CENÁRIO, SEM ELENCO, SEM LOGO',40,57,23,D.key==='A'?D.ink:D.paper,'Barlow');
 if(D.key==='C'){line([[61,89],[61,78],[512,78],[512,263],[533,263]],D.accent,2);spool(61,79,14);tail(533,263,D.accent);}
 panel(40,100,460,139);text('PLACA + UNIÃO + FOCO',66,148,30,primary(),'Barlow');resources(66,175,398,[84,96],true);
 for(let n=0;n<4;n++){const xx=550+(n%2)*320,yy=100+Math.floor(n/2)*111;panel(xx,yy,280,90,{selected:n===1,plain:n===3});icon(options[n][1],xx+19,yy+26,30,selectedInk(n===1));text(['Normal','Selecionado','Indisponível','Pressionado'][n],xx+65,yy+52,25,n===2?secondary():selectedInk(n===1),'Barlow');if(n===3)line([[xx+12,yy+10],[xx+262,yy+10]],D.edge,3);if(n===2){line([[xx+245,yy+62],[xx+258,yy+75]],secondary(),2);line([[xx+245,yy+75],[xx+258,yy+62]],secondary(),2);}}
 text('INDICADORES COM NOME + VALOR + FORMA',40,368,23,D.key==='A'?D.ink:D.paper,'Barlow');panel(40,393,460,170);resources(66,432,398,[84,96,70]);
 panel(550,393,600,170);text('Assinatura em pequena escala',576,435,28,primary(),'Barlow');for(let n=0;n<6;n++)icon(options[n][1],580+n*82,470,36);
 text('Revisão interna de linguagem. Não comprova reconhecimento por jogadores.',40,650,18,D.key==='A'?D.ink:D.paper);
}
const sizes=[[1280,720],[1920,1080],[1024,768],[1280,800]];
for(const [key,data] of Object.entries(directions)){
 D={...data,key};const folder=path.join(here,key);await fs.mkdir(folder,{recursive:true});
 for(const [mode,draw] of Object.entries({exploracao:()=>explore(),batalha:battle,pausa:()=>pause(),texto_longo:()=>pause(true),componentes:components})){
  const c=createCanvas(1280,720);ctx=c.getContext('2d');current=[];draw();
  const overflow=current.filter(r=>r.type==='text'&&r.overflow);if(overflow.length)console.log(key,mode,'TEXT OVERFLOW',overflow.map(r=>r.text));
  const file=key+'/'+mode+'.png';await fs.writeFile(path.join(here,file),c.toBuffer('image/png'));records.push({direction:key,mode,file,dimensions:[1280,720]});
  if(['exploracao','batalha','pausa'].includes(mode)){
   // Uniform fit, not a claim of Godot responsive implementation.
   for(const [w,h] of sizes){const scale=Math.min(w/1280,h/720),ox=(w-1280*scale)/2,oy=(h-720*scale)/2;
    const out=createCanvas(w,h),oc=out.getContext('2d');oc.fillStyle='#0a1c26';oc.fillRect(0,0,w,h);oc.drawImage(c,ox,oy,1280*scale,720*scale);
    const nativeFile=`${key}/${mode}-${w}x${h}.png`;if(w!==1280||h!==720)await fs.writeFile(path.join(here,nativeFile),out.toBuffer('image/png'));
    const regions=current.filter(r=>r.type==='region');const minimumMargin=Math.min(...regions.flatMap(r=>[ox+r.x*scale,oy+r.y*scale,w-ox-(r.x+r.w)*scale,h-oy-(r.y+r.h)*scale]));
    checks.push({direction:key,mode,width:w,height:h,policy:'uniform fit / letterbox',minimumContentMargin:Math.round(minimumMargin*10)/10,textOverflow:overflow.map(r=>r.text),regions:regions.length,minimumFont:Math.round(Math.min(...current.filter(r=>r.type==='text').map(r=>r.size))*scale*10)/10});
   }
  }
  if(mode==='componentes'){
   const image=ctx.getImageData(0,0,1280,720);for(let n=0;n<image.data.length;n+=4){const l=Math.round(.2126*image.data[n]+.7152*image.data[n+1]+.0722*image.data[n+2]);image.data[n]=image.data[n+1]=image.data[n+2]=l;}ctx.putImageData(image,0,0);await fs.writeFile(path.join(folder,'componentes-cinza.png'),c.toBuffer('image/png'));
  }
 }
}
const board=createCanvas(1560,1102);ctx=board.getContext('2d');rect(0,0,1560,1102,'#f5f0e4');
for(let i=0;i<3;i++){const key=['A','B','C'][i];D={...directions[key],key};text(key+'  /  '+D.name,24+i*516,42,30,'#173b3e','Barlow');for(let j=0;j<3;j++){const mode=['exploracao','batalha','pausa'][j],im=await loadImage(path.join(here,key,mode+'.png'));ctx.drawImage(im,24+i*516,65+j*338,492,277);text(['Exploração','Batalha','Pausa'][j],24+i*516,365+j*338,20,'#173b3e','Barlow');}}
await fs.writeFile(path.join(here,'comparativo.png'),board.toBuffer('image/png'));
await fs.writeFile(path.join(here,'fixtures.json'),JSON.stringify({fixture,directions,assets,base:[1280,720],records},null,2)+'\n');
const failed=checks.filter(r=>r.textOverflow.length||r.minimumContentMargin<20);
await fs.writeFile(path.join(here,'auditoria-geometrica.json'),JSON.stringify({checks,failed,scope:'Static Canvas composition only. No Godot runtime, input hardware, browser or player recognition test.',warning:'Smallest text reaches 9.6 px in the 1024-wide uniform-fit preview. Final adaptive layout and enlarged text remain production work.'},null,2)+'\n');
console.log(`Rendered ${records.length} main/proof images; ${checks.length} size checks; ${failed.length} geometric failures.`);
if(failed.length)process.exitCode=1;
