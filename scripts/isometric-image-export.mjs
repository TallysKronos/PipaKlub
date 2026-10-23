import {createRequire} from 'node:module';
import {alphaBounds} from '../tools/iso-studio/model.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}

// A guide is a camera/volume reference, never a destination silhouette.
// Keep a single uniform scale: column registration tears cushions and bends edges.
export async function normalizeIsoImage(source,w,h,destination){
 const src=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const bounds=alphaBounds({width:src.info.width,height:src.info.height,data:src.data});
 if(!bounds)throw Error('Fonte vazia: '+source);
 const fitted=await sharp(source).extract({left:bounds.x,top:bounds.y,width:bounds.w,height:bounds.h})
  .resize(w,h,{fit:'inside',kernel:'lanczos3'}).ensureAlpha().png().toBuffer({resolveWithObject:true});
 const left=Math.floor((w-fitted.info.width)/2),top=h-fitted.info.height;
 await sharp(fitted.data).extend({left,right:w-fitted.info.width-left,top,bottom:0,background:{r:0,g:0,b:0,alpha:0}}).png().toFile(destination);
 const data=await sharp(destination).ensureAlpha().raw().toBuffer();
 return {width:w,height:h,data};
}
