import {rampNeighbors} from './ramp-rules.mjs';
import {focusAllows,protectedChange} from './level-focus.mjs';
import {validRamp,cleanRamps} from './terrain.mjs';
export function geometryEdit(a,{tool,cell,size=1,mode='set',level=1,remove=false,visited=new Set(),focus=null,cellsOverride=null,direction='n',stairs=false,rampWidth=1}){
 const invalid=message=>({valid:false,changed:false,message,cells:[]});
 if(cell<0||cell>=a.levels.length)return invalid('Aponte para o mapa.');
 if(!focusAllows(a,cell,focus))return invalid('Andar protegido. Escolha o andar '+a.levels[cell]+' ou destrave o foco.');
 if(tool==='ramp'&&rampWidth>1){const step=['e','w'].includes(direction)?a.width:1;let next=a,changed=false;const cells=[];for(let k=0;k<rampWidth;k++){const i=cell+k*step;if(i>=a.levels.length||step===1&&Math.floor(i/a.width)!==Math.floor(cell/a.width)||a.levels[i]!==a.levels[cell])return invalid('A largura precisa de uma base plana e espaço no mapa.');const result=geometryEdit(next,{tool,cell:i,direction,stairs,remove,focus,rampWidth:1});if(!result.valid)return result;next=result.next;changed=changed||result.changed;cells.push(i);}return {valid:true,next,changed,cells,message:(stairs?'Escada':'Rampa')+' · largura '+rampWidth+' tiles · ligação válida'};}
 const next={...a,...(a.stairs?{stairs:[...a.stairs]}:{}),levels:[...a.levels],ramps:[...a.ramps],floors:[...a.floors]},cells=[];
 if(tool==='height'){
  const candidates=cellsOverride??Array.from({length:size*size},(_,k)=>{const x=cell%a.width+k%size,y=Math.floor(cell/a.width)+Math.floor(k/size);return x<a.width&&y<a.height?y*a.width+x:-1;});
  for(const i of candidates){if(i<0||i>=a.levels.length||!focusAllows(a,i,focus))continue;cells.push(i);if(visited.has(i))continue;
   next.levels[i]=mode==='raise'?Math.min(12,a.levels[i]+1):mode==='lower'?Math.max(0,a.levels[i]-1):level;next.ramps[i]=null;
  }
  cleanRamps(next);
 }else if(tool==='ramp'){
  cells.push(cell);
  if(remove){if(!a.ramps[cell])return invalid('Não há rampa aqui para remover.');next.ramps[cell]=null;if(next.stairs)next.stairs[cell]=false;}
  else{
   if(!validRamp(a,cell,direction)){
    const {high:north,low:south}=rampNeighbors(a,cell,direction);
    if(north<0||south<0)return invalid('A rampa precisa de espaço nos dois patamares da direção escolhida.');
    if(a.ramps[north]||a.ramps[south])return invalid('Os dois patamares precisam ser planos.');
    if(a.levels[north]!==a.levels[cell]+1)return invalid('O patamar de subida precisa estar exatamente uma cota acima.');
    return invalid('O patamar de entrada precisa estar na mesma cota da base.');
   }
   next.ramps[cell]=direction;if(stairs||next.stairs){next.stairs=next.stairs??Array(a.levels.length).fill(false);next.stairs[cell]=stairs;}if(!a.ramps[cell]){next.floors[cell]='dirt';for(const i of Object.values(rampNeighbors(a,cell,direction)))if(focusAllows(a,i,focus)&&next.floors[i]==='grass')next.floors[i]='dirt';}
  }
 }else return invalid('Ferramenta geométrica desconhecida.');
 if(next.stairs)next.stairs=next.stairs.map((v,i)=>!!v&&!!next.ramps[i]);
 const protection=protectedChange(a,next,focus);if(protection)return invalid(protection);
 const changed=next.levels.some((v,i)=>v!==a.levels[i])||next.ramps.some((v,i)=>v!==a.ramps[i])||next.floors.some((v,i)=>v!==a.floors[i])||!!next.stairs?.some((v,i)=>v!==!!a.stairs?.[i]);
 const removed=a.ramps.reduce((sum,r,i)=>sum+Number(!!r&&!next.ramps[i]),0);
 let message=tool==='height'?(mode==='raise'?'Subir uma cota':mode==='lower'?'Baixar uma cota':'Nivelar na cota '+level):remove?'Remover rampa':'Rampa · ligação válida entre os patamares';
 if(!changed)message='Sem alteração · este ponto já está ajustado';else if(tool==='height'&&removed)message+=' · remove '+removed+' rampa(s) sem apoio';
 return {valid:true,next,changed,cells,message};
}
