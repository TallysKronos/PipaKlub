const grid=document.querySelector('#grid'),direction=document.querySelector('#direction'),size=document.querySelector('#size');
let walking=true,dark=false;const players=[];
for(const [id,actor] of Object.entries(window.CHIBI_ATLAS.characters)){
 const article=document.createElement('article'),heading=document.createElement('h2'),stage=document.createElement('div'),canvas=document.createElement('canvas'),link=document.createElement('a'),small=document.createElement('small');
 heading.textContent=actor.name;stage.className='stage';canvas.width=640;canvas.height=440;stage.append(canvas);link.href=actor.image;link.textContent='PNG original · 4×2 · '+actor.size.w+'×'+actor.size.h;small.append(link);article.append(heading,stage,small);grid.append(article);
 const image=new Image();image.src=actor.image;players.push({actor,image,canvas,stage});
}
document.querySelector('#idle').onclick=()=>{walking=false;document.querySelector('#idle').setAttribute('aria-pressed','true');document.querySelector('#walk').setAttribute('aria-pressed','false');};
document.querySelector('#walk').onclick=()=>{walking=true;document.querySelector('#walk').setAttribute('aria-pressed','true');document.querySelector('#idle').setAttribute('aria-pressed','false');};
document.querySelector('#background').onclick=()=>{dark=!dark;for(const p of players)p.stage.classList.toggle('dark',dark);document.querySelector('#background').textContent=dark?'Fundo quadriculado':'Fundo escuro';};
function draw(t){for(const {actor,image,canvas} of players){const g=canvas.getContext('2d');g.clearRect(0,0,640,440);if(!image.complete||!image.naturalWidth)continue;const idx=Number(direction.value)+(walking&&Math.floor(t/170)%2?4:0),f=actor.frames[idx],a=f.footAnchor,s=Number(size.value)*2/actor.referenceHeight;g.imageSmoothingEnabled=false;g.strokeStyle=dark?'#b4d7d8':'#667b6a';g.beginPath();g.moveTo(70,388);g.lineTo(570,388);g.stroke();g.drawImage(image,f.x,f.y,f.w,f.h,320-a.x*s,388-a.y*s,f.w*s,f.h*s);}requestAnimationFrame(draw);}requestAnimationFrame(draw);
