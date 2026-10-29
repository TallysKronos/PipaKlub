// Animation metadata is independent of the artwork and never synthesizes movement.
export function duration(frame){return Math.max(20,Math.min(2000,Math.round(Number(frame?.duration)||150)));}
export function sequencesFor(project){
 if(project.sequences?.length)return project.sequences;
 return Array.from({length:Math.ceil(project.frames.length/project.cols)},(_,row)=>({name:`linha-${row+1}`,start:row*project.cols,end:Math.min(project.frames.length-1,(row+1)*project.cols-1),loop:true}));
}
export function validateSequences(sequences,count){
 if(sequences===undefined)return undefined;
 if(!Array.isArray(sequences)||!sequences.length||sequences.length>256)throw Error('Sequências inválidas.');
 return sequences.map(s=>{
  if(!Number.isInteger(s.start)||!Number.isInteger(s.end)||s.start<0||s.end<s.start||s.end>=count)throw Error('Intervalo de animação inválido.');
  return {name:String(s.name||'sequencia').slice(0,80),start:s.start,end:s.end,loop:s.loop!==false,direction:['reverse','pingpong'].includes(s.direction)?s.direction:'forward'};
 });
}
export function duplicateFrame(project,index){
 if(project.frames.length>=256)throw Error('Limite de 256 quadros.');
 const cols=Math.max(project.cols,Math.ceil((project.frames.length+1)/16)),rows=Math.ceil((project.frames.length+1)/cols);
 if(rows>16||project.width*project.height*cols*rows>1048576||(project.layers?.length||1)*project.width*project.height*(project.frames.length+1)>4194304)throw Error('A duplicação excede o limite da grade.');
 const seq=sequencesFor(project).map(s=>({...s,start:s.start>index?s.start+1:s.start,end:s.end>=index?s.end+1:s.end}));
 const f=project.frames[index];project.frames.splice(index+1,0,{...f,name:f.name+'-copia',duration:duration(f),indices:f.indices.slice(),cels:f.cels?.map(c=>c.slice()),pose:f.pose?structuredClone(f.pose):undefined});
 project.cols=cols;project.rows=rows;project.sequences=seq;project.frames.forEach((f,i)=>{f.row=Math.floor(i/cols);f.col=i%cols;});return index+1;
}
export function playbackOrder(s){const a=Array.from({length:s.end-s.start+1},(_,i)=>s.start+i);if(s.direction==='reverse')return a.reverse();if(s.direction==='pingpong'&&a.length>1)return [...a,...a.slice(1,-1).reverse(),...(s.loop===false?[a[0]]:[])];return a;}
export function deleteFrame(p,index){
 if(p.frames.length===1)throw Error('Mantenha pelo menos um quadro.');
 const seq=sequencesFor(p).filter(s=>s.start!==index||s.end!==index).map(s=>({...s,start:s.start>index?s.start-1:s.start,end:s.end>=index?s.end-1:s.end}));
 p.frames.splice(index,1);p.cols=Math.min(p.cols,p.frames.length);p.rows=Math.ceil(p.frames.length/p.cols);p.frames.forEach((f,i)=>{f.row=Math.floor(i/p.cols);f.col=i%p.cols;});p.sequences=seq.length?seq:[{name:'sequencia',start:0,end:p.frames.length-1,loop:true}];return Math.min(index,p.frames.length-1);
}
export function atlas(project,image){return {meta:{app:'Pixelgen',version:2,image,size:{w:project.width*project.cols,h:project.height*project.rows},scale:1},
 palette:project.palette,sequences:sequencesFor(project).map(s=>({...s})),frames:project.frames.map((f,i)=>({name:f.name,frame:{x:i%project.cols*project.width,y:Math.floor(i/project.cols)*project.height,w:project.width,h:project.height},
 pivot:{x:Math.floor(project.width/2),y:project.height-(project.settings?.margin??2)},duration:duration(f)}))};}
