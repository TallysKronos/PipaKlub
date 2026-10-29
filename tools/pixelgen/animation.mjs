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
  return {name:String(s.name||'sequencia').slice(0,80),start:s.start,end:s.end,loop:s.loop!==false};
 });
}
export function duplicateFrame(project,index){
 if(project.frames.length>=256)throw Error('Limite de 256 quadros.');
 const cols=project.cols,rows=Math.ceil((project.frames.length+1)/cols);
 if(rows>16||project.width*project.height*cols*rows>1048576)throw Error('A duplicação excede o limite da grade.');
 const seq=sequencesFor(project).map(s=>({...s,start:s.start>index?s.start+1:s.start,end:s.end>=index?s.end+1:s.end}));
 const f=project.frames[index];project.frames.splice(index+1,0,{...f,name:f.name+'-copia',duration:duration(f),indices:f.indices.slice()});
 project.rows=rows;project.sequences=seq;project.frames.forEach((f,i)=>{f.row=Math.floor(i/cols);f.col=i%cols;});return index+1;
}
export function atlas(project,image){return {meta:{app:'Pixelgen',version:2,image,size:{w:project.width*project.cols,h:project.height*project.rows},scale:1},
 palette:project.palette,sequences:sequencesFor(project).map(s=>({...s})),frames:project.frames.map((f,i)=>({name:f.name,frame:{x:i%project.cols*project.width,y:Math.floor(i/project.cols)*project.height,w:project.width,h:project.height},
 pivot:{x:Math.floor(project.width/2),y:project.height-(project.settings?.margin??2)},duration:duration(f)}))};}
