import fs from 'node:fs/promises';
import {png} from './png.mjs';
import {pack} from './autotile.mjs';
const out=new URL('../../art/environment/topdown-plants-pixel-v1/',import.meta.url);
for(const id of ['pedra-da-margem','junco-da-margem','vitoria-regia']){
 const data=new Uint32Array(64*64),put=(x,y,c)=>{if(x>=0&&x<64&&y>=0&&y<64)data[y*64+x]=pack(c);};
 for(let y=0;y<64;y++)for(let x=0;x<64;x++){
  if(id==='pedra-da-margem'){
   const dx=(x-32)/19,dy=(y-40)/12;
   if(dx*dx+dy*dy<1){let c='354e4b';if(dx*dx+dy*dy<.8)c=y<36?'a3b4a2':x<33?'788e80':'566e65';if(y===32&&x>24&&x<38)c='c1cdb4';if(x>36&&y>38&&x-y===-3)c='354e4b';put(x,y,c);}
  }else if(id==='vitoria-regia'){
   const dx=(x-32)/18,dy=(y-46)/7;
   if(dx*dx+dy*dy<1&&!(x>32&&y<46&&x-32>(46-y)*1.5)){put(x,y,dx*dx+dy*dy>.74?'204e43':y<45?'76af58':'4b8a4b');if(y===46&&x<32)put(x,y,'9cc877');}
   if(Math.abs(x-33)+Math.abs(y-39)<5)put(x,y,Math.abs(x-33)+Math.abs(y-39)<2?'efd488':'d991ab');
  }
 }
 if(id==='junco-da-margem')for(let k=0;k<7;k++){
  const endX=18+k*4,endY=15+(k*7)%17;
  for(let y=endY;y<=52;y++){const t=(52-y)/(52-endY),x=Math.round(32+(endX-32)*t);put(x,y,'264b39');put(x+1,y,'82a95c');if(k%2===0&&y<endY+8){put(x-1,y,'795037');put(x,y,'be9159');}}
 }
 await fs.writeFile(new URL(id+'.png',out),png({width:64,height:64,data}));
}
console.log('Pedra, junco e vitória-régia: sprites 64×64, pivô [32,52].');
