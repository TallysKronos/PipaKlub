import {clone,validateLayout} from './model.mjs';
import {focusAllows} from './level-focus.mjs';
export function varyTerrain(a,cells,{seed=1,weights=[1,1,1],focus=null}={}){
 if(!Number.isSafeInteger(seed)||Math.abs(seed)>2147483647||!Array.isArray(weights)||weights.length!==3||weights.some(w=>!Number.isFinite(w)||w<0||w>1000)||!weights.some(w=>w>0))throw Error('Use semente inteira e três pesos entre 0 e 1000, com soma positiva.');
 const next=clone(a);next.variants=next.variants??Array(a.levels.length).fill(null);let count=0;const total=weights.reduce((x,y)=>x+y,0);
 for(const i of new Set(cells)){if(!Number.isInteger(i)||i<0||i>=a.levels.length||!focusAllows(a,i,focus))continue;let h=(i^seed)>>>0;h=Math.imul(h^(h>>>16),0x45d9f3b)>>>0;h=Math.imul(h^(h>>>16),0x45d9f3b)>>>0;const r=((h^(h>>>16))>>>0)/4294967296*total;next.variants[i]=r<weights[0]?0:r<weights[0]+weights[1]?1:2;count++;}
 if(!count)throw Error('Nenhuma célula editável na região.');return {next:validateLayout(next),count};
}
