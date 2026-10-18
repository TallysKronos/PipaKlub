// Presentation gates use a fresh server snapshot, never optimistic/local victories.
export function createNeighborhoodRoad(chapters){
 if(!Array.isArray(chapters)||!chapters.length||new Set(chapters.map(c=>c.id)).size!==chapters.length||new Set(chapters.map(c=>c.stage)).size!==chapters.length)throw Error('Sequência de bairro inválida');
 const index=id=>chapters.findIndex(c=>c.id===id),cleared=(progress,stage)=>Number.isInteger(progress?.stars?.[stage])&&progress.stars[stage]>0;
 function canEnter(id,progress){const i=index(id);return i>=0&&(i===0||!!progress&&chapters.slice(0,i).every(c=>cleared(progress,c.stage)));}
 function gate(id,progress){const i=index(id);if(i<0)return {state:'invalid'};if(!progress)return {state:'pending',chapter:chapters[i]};if(!canEnter(id,progress)||!cleared(progress,chapters[i].stage))return {state:'locked',chapter:chapters[i]};return {state:i===chapters.length-1?'complete':'open',chapter:chapters[i],next:chapters[i+1]||null};}
 return {chapters,index,canEnter,gate,cleared};
}
