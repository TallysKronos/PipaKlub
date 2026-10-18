const canvas=document.getElementById('wallCanvas'),g=canvas.getContext('2d'),scale=3/16;
try{
 const kit=await fetch('/assets/world/quintal-kit-v1/manifest.json').then(r=>r.json()),image=new Image();image.src='/assets/world/quintal-kit-v1/walls-v2.png';await image.decode();
 function piece(id,x,y,length){const f=kit.frames[id],vertical=f.wallAxis==='y',sw=f.wallAxis==='x'&&length!==undefined?length/scale:f.w,sh=vertical&&length!==undefined?length/scale:f.h;g.drawImage(image,f.x,f.y,sw,sh,x,y,sw*scale,sh*scale);}
 function run(id,x,y,length){const vertical=kit.frames[id].wallAxis==='y';for(let p=0;p<length;p+=102)piece(id,x+(vertical?0:p),y+(vertical?p:0),Math.min(102,length-p));}
 function ring(x,y,w,h){piece('wall-corner',x,y);piece('wall-ne',x+w-42,y);piece('wall-sw',x,y+h-42);piece('wall-se',x+w-42,y+h-42);run('wall-horizontal',x+42,y,w-84);run('wall-south',x+42,y+h-42,w-84);run('wall-vertical',x,y+42,h-84);run('wall-east',x+w-42,y+42,h-84);}
 g.fillStyle='#173b44';g.font='600 16px system-ui';g.fillText('NORTE · 8 repetições',48,34);run('wall-horizontal',48,48,816);g.fillText('SUL · 8 repetições',48,126);run('wall-south',48,140,816);
 g.fillText('OESTE / LESTE',40,238);run('wall-vertical',48,256,816);run('wall-east',144,256,816);
 g.fillText('QUATRO QUINAS · FUNDO CLARO',270,238);ring(270,256,648,306);
 g.fillStyle='#20343c';g.fillRect(252,624,690,390);g.fillStyle='#f8efd4';g.fillText('MESMAS PEÇAS · FUNDO ESCURO',270,656);ring(270,680,648,306);
 document.getElementById('wallStatus').textContent='Montagem carregada: sem plantas ou sombras externas ocultando as junções.';
}catch(e){document.getElementById('wallStatus').textContent='Falha ao carregar: '+e.message;}
