import {geometryPreview} from './geometry-preview.mjs';
let layout;
self.onmessage=({data})=>{
 try{
  if(data.layout)layout=data.layout;
  const result=geometryPreview(layout,data.options);
  self.postMessage({id:data.id,result},result.data?[result.data.buffer,result.mask.buffer]:[]);
 }catch(error){self.postMessage({id:data.id,result:{valid:false,message:'Não foi possível preparar a prévia: '+error.message}});}
};
