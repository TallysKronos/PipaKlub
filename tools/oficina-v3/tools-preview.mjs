import {drawCraftTool} from './look.mjs';
import {drawCraftHand} from './hand.mjs';
const g=document.getElementById('tools').getContext('2d');
function draw(t){
 g.fillStyle='#254f49';g.fillRect(0,0,1100,440);
 [['mao','Mão aberta → pegada'],['pegada','Segurando a vareta'],['tesoura','Recorte o papel']].forEach(([id,label],i)=>{
  const x=183+i*366;g.save();g.translate(x,id==='tesoura'?95:170);g.scale(3,3);
  if(id==='pegada'){g.strokeStyle='#6e492d';g.lineWidth=10;g.beginPath();g.moveTo(-32,-5);g.lineTo(35,8);g.stroke();g.strokeStyle='#edc77e';g.lineWidth=6;g.stroke();drawCraftHand(g,1);}
  else drawCraftTool(g,id,id==='tesoura',t/1000,(1-Math.cos(t/600))/2);g.restore();
  g.fillStyle='#fff0ce';g.font='700 23px Georgia';g.textAlign='center';g.fillText(label,x,355);
  g.fillStyle='#d7bb7b';g.font='14px Trebuchet MS';g.fillText(id==='tesoura'?'Duas lâminas · pivô · cabos vazados':id==='mao'?'Dedos se fecham suavemente':'Pegada fechada, pulso e punho unidos',x,385);
 });requestAnimationFrame(draw);
}requestAnimationFrame(draw);
