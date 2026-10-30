import {pixels} from './core.mjs';
import {compositeAll} from './document.mjs';
import {STYLE_DIRECTIONS} from './character-style.mjs';
// Pack separate animation documents without resizing, trimming, guessing the grid or remapping colours.
export function buildSheetPack(projects,{columns=8}={}){
 if(!projects?.length)throw Error('Informe ao menos um projeto.');
 if(!Number.isInteger(columns)||columns<1||columns>16)throw Error('Colunas devem estar entre 1 e 16.');
 const first=projects[0],w=first.width,h=first.height,pivot={x:Math.floor(w/2),y:h-(first.settings?.margin??2)},identity=first.sheet?.nome||first.name;
 const groups=new Map(),sequences=[],names=new Set(),assigned=new Map(),frames=[];
 for(let pi=0;pi<projects.length;pi++){
  const p=projects[pi];compositeAll(p);
  if(p.width!==w||p.height!==h||JSON.stringify(p.palette)!==JSON.stringify(first.palette)||(p.settings?.margin??2)!==(first.settings?.margin??2))throw Error('Folhas incompatíveis: célula, paleta e pivô devem ser iguais.');
  if((p.sheet?.nome||p.name)!==identity||p.style?.id!==first.style?.id||p.style?.body!==first.style?.body)throw Error('As folhas devem pertencer ao mesmo personagem e perfil.');
  for(const s of p.sequences||[]){
   const match=/^([a-z][a-z0-9-]{0,40})-(S|SO|O|NO|N|NE|E|SE)$/.exec(s.name);if(!match)throw Error(`Nome de sequência inválido: ${s.name}. Use movimento-DIREÇÃO, sem caminhos.`);
   if(names.has(s.name))throw Error(`Sequência duplicada: ${s.name}.`);names.add(s.name);
   const motion=match[1]==='climbdown'?'climb':match[1],dir=match[2];
   if(!groups.has(motion))groups.set(motion,{motion,slots:new Map()});const group=groups.get(motion);
   const sequence={...s,frames:[]};
   for(let fi=s.start;fi<=s.end;fi++){
    if(!p.frames[fi])throw Error(`Quadro inexistente: ${s.name}/${fi}.`);
    const key=`${pi}:${fi}`;
    if(!assigned.has(key)){
     const row=STYLE_DIRECTIONS.indexOf(dir),used=[...group.slots.values()].filter(v=>v.row===row).length;
     if(used>=columns)throw Error(`${motion}-${dir} excede ${columns} colunas; aumente --columns.`);
     const index=frames.length;assigned.set(key,index);group.slots.set(key,{index,row,col:used,rgba:pixels(p,p.frames[fi])});
     frames.push({pose:p.frames[fi].pose?structuredClone(p.frames[fi].pose):undefined,support:p.frames[fi].support?[...p.frames[fi].support]:undefined,name:p.frames[fi].name,source:{project:pi,frame:fi},duration:p.frames[fi].duration,pivot:{...pivot},sheet:`${motion}.png`});
    }
    sequence.frames.push(assigned.get(key));
   }
   if(s.direction==='reverse')sequence.frames.reverse();else if(s.direction==='pingpong'&&sequence.frames.length>1){const a=sequence.frames;sequence.frames=[...a,...a.slice(1,-1).reverse(),...(s.loop===false?[a[0]]:[])];}
   delete sequence.start;delete sequence.end;sequences.push(sequence);
  }
  for(let i=0;i<p.frames.length;i++)if(!assigned.has(`${pi}:${i}`))throw Error(`Quadro sem sequência no projeto ${pi+1}: ${i}.`);
 }
 const width=columns*w,sheetHeight=STYLE_DIRECTIONS.length*h,height=groups.size*sheetHeight;
 if(!height||width*height>16777216||height>16384)throw Error('Pacote grande demais; separe em volumes.');
 const master=new Uint8ClampedArray(width*height*4),sheets=[];
 for(const group of groups.values()){
  const yOffset=sheets.length*sheetHeight,rgba=new Uint8ClampedArray(width*sheetHeight*4);
  for(const slot of group.slots.values()){
   const x=slot.col*w,y=slot.row*h;
   for(let row=0;row<h;row++){
    const strip=slot.rgba.subarray(row*w*4,(row+1)*w*4);rgba.set(strip,((y+row)*width+x)*4);master.set(strip,((y+yOffset+row)*width+x)*4);
   }
   frames[slot.index].frame={x,y:y+yOffset,w,h};frames[slot.index].localFrame={x,y,w,h};
  }
  sheets.push({name:`${group.motion}.png`,motion:group.motion,width,height:sheetHeight,offset:[0,yOffset],rgba});
 }
 return {width,height,rgba:master,sheets,atlas:{meta:{app:'Pixelgen',image:'completo.png',size:{w:width,h:height}},identity,style:first.style?{...first.style}:undefined,cell:[w,h],pivot,palette:first.palette.map(c=>[...c]),directions:[...STYLE_DIRECTIONS],frames,sequences}};
}
