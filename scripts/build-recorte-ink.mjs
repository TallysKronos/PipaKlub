// PIP-63: slice and normalize drawn source atlases. This does not synthesize ink art.
// The only procedural images are numerical wipe data and periodic halftone fallbacks.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {recorteTokens} from './sync-recorte-tokens.mjs';
const require=createRequire(import.meta.url);
let sharp;
try {sharp=require('sharp');} catch {sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const root=fileURLToPath(new URL('../',import.meta.url));
const out=path.join(root,'godot/assets/ui/recorte-v1');
const sources=path.join(root,'art/ui/recorte-v1/sources');
const colors=recorteTokens();
const rgb=hex=>[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16));
const ink=rgb(colors.nanquim),paper=rgb(colors.papel);
const entries=[];
const clear=(w,h)=>sharp({create:{width:w,height:h,channels:4,background:{r:0,g:0,b:0,alpha:0}}});

async function cell(name,columns,rows,index,mode='ink') {
  const file=path.join(sources,name+'.png'),meta=await sharp(file).metadata();
  const left=Math.round(index%columns*meta.width/columns);
  // The drawn balloon row extends below the nominal half-way line. These
  // reviewed source rectangles preserve the entire shout/thought silhouettes.
  const strokeBounds=[[0,.36],[.40,.62],[.64,1]];
  const top=name==='strokes'?Math.round(meta.height*strokeBounds[index][0]):name==='balloons'?(index<4?0:Math.round(meta.height*.64)):Math.round(Math.floor(index/columns)*meta.height/rows);
  const width=Math.round((index%columns+1)*meta.width/columns)-left;
  const height=name==='strokes'?Math.round(meta.height*strokeBounds[index][1])-top:name==='balloons'?(index<4?Math.round(meta.height*.62):meta.height-top):Math.round((Math.floor(index/columns)+1)*meta.height/rows)-top;
  const {data}=await sharp(file).extract({left,top,width,height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=width,y0=height,x1=-1,y1=-1;
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const k=(y*width+x)*4,light=(data[k]+data[k+1]+data[k+2])/3;
    let alpha=data[k+3];
    // Remove faint source-sheet guides; preserve the actual ink's alpha and holes.
    if(alpha<40 || mode==='white'&&light<225 || mode==='ink'&&light>95)alpha=0;
    const color=mode==='white'?[255,255,255]:mode==='duo'&&light>125?paper:ink;
    data[k]=color[0];data[k+1]=color[1];data[k+2]=color[2];data[k+3]=alpha;
    if(alpha>64){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
  }
  if(x1<0)throw Error('Empty source cell: '+name+'/'+index);
  return sharp(data,{raw:{width,height,channels:4}}).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).png().toBuffer();
}

async function fit(source,w,h,padding=8){
  const image=await sharp(source).resize(w-padding*2,h-padding*2,{fit:'inside'}).png().toBuffer();
  const m=await sharp(image).metadata();
  return clear(w,h).composite([{input:image,left:Math.floor((w-m.width)/2),top:Math.floor((h-m.height)/2)}]).png().toBuffer();
}

// Close a tiled edge's seam in alpha, feathering into the source over 8 logical
// pixels. The hand-drawn corner silhouette is never scaled or regenerated.
async function closeSeams(source,margins,vertical=true){
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const w=info.width,h=info.height,original=Buffer.from(data);
  const [left,top,right,bottom]=margins;
  for(let y=0;y<h;y++){
    if(top&&y>=top&&y<h-bottom)continue;
    const common=original[(y*w+Math.floor(w/2))*4+3];
    for(const join of [left,w-right])for(let d=-16;d<=16;d++){
      const x=join+d;if(x<0||x>=w)continue;
      const k=(y*w+x)*4+3,t=1-Math.abs(d)/16;
      data[k]=Math.round(original[k]*(1-t)+common*t);
    }
  }
  if(vertical)for(let x=0;x<w;x++){
    if(x>=left&&x<w-right)continue;
    const common=original[(Math.floor(h/2)*w+x)*4+3];
    for(const join of [top,h-bottom])for(let d=-16;d<=16;d++){
      const y=join+d;if(y<0||y>=h)continue;
      const k=(y*w+x)*4+3,t=1-Math.abs(d)/16;
      data[k]=Math.round(original[k]*(1-t)+common*t);
    }
  }
  let pigment=ink;
  for(let i=0;i<original.length;i+=4)if(original[i+3]>200){pigment=[original[i],original[i+1],original[i+2]];break;}
  for(let i=0;i<data.length;i+=4){data[i]=pigment[0];data[i+1]=pigment[1];data[i+2]=pigment[2];}
  return sharp(data,{raw:{width:w,height:h,channels:4}}).png().toBuffer();
}

// Preserve the drawn corners uniformly. Reposition bottom/top runs rather than
// vertically stretching a shallow button frame into a square source texture.
async function frame(source,curved=false){
  const resized=await sharp(source).resize({width:304}).png().toBuffer();
  const m=await sharp(resized).metadata();
  const w=m.width,h=m.height,c=80,ch=Math.min(80,Math.floor(h/2)-1);
  const parts=[];
  const cut=async(left,top,width,height,dx,dy,dw=width,dh=height)=>{
    parts.push({input:await sharp(resized).extract({left,top,width,height}).resize(dw,dh,{fit:'fill'}).png().toBuffer(),left:dx,top:dy});
  };
  await cut(0,0,w,ch,8,8);
  await cut(0,h-ch,w,ch,8,312-ch);
  await cut(0,ch,c,h-2*ch,8,8+ch,c,304-2*ch);
  await cut(w-c,ch,c,h-2*ch,312-c,8+ch,c,304-2*ch);
  const assembled=await clear(320,320).composite(parts).png().toBuffer();
  if(!curved)return closeSeams(assembled,[96,96,96,96]);
  // A mirrored half-period gives cloud lobes/dashes a real closed tile instead
  // of alpha-ghosting two different parts of a curved stroke into each other.
  const {data}=await sharp(assembled).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const original=Buffer.from(data);
  for(let y=0;y<320;y++)for(let x=0;x<320;x++){
    const sx=x<160?x:319-x,sy=y<160?y:319-y;
    if(sx!==x||sy!==y)original.copy(data,(y*320+x)*4,(sy*320+sx)*4,(sy*320+sx)*4+4);
  }
  return sharp(data,{raw:{width:320,height:320,channels:4}}).png().toBuffer();
}

async function emit(id,group,master,w,h,extra={}){
  const file=`ink/${group?group+'/':''}${id}.png`;
  const file2=file.replace('.png','@2x.png');
  await fs.mkdir(path.dirname(path.join(out,file)),{recursive:true});
  await sharp(master).resize(w*2,h*2,{fit:'fill'}).png().toFile(path.join(out,file2));
  await sharp(master).resize(w,h,{fit:'fill'}).png().toFile(path.join(out,file));
  entries.push({id,group:group||'transition',file,file_2x:file2,size:[w,h],pivot:[.5,.5],
    alpha:extra.alpha??'straight',filter:'linear',mipmaps:false,repeat:false,
    source:'drawn atlas via built-in image_gen; deterministic slicing and palette normalization',
    approval:'pending-owner-review',...extra});
}

async function outline(source,radius=6){
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const w=info.width,h=info.height,a=new Uint8Array(w*h),result=Buffer.alloc(w*h*4);
  for(let i=0;i<a.length;i++)a[i]=data[i*4+3];
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    const i=y*w+x;if(!a[i])continue;
    let minimum=255;
    for(let dy=-radius;dy<=radius;dy++)for(let dx=-radius;dx<=radius;dx++){
      if(dx*dx+dy*dy>radius*radius)continue;
      minimum=Math.min(minimum,x+dx<0||y+dy<0||x+dx>=w||y+dy>=h?0:a[(y+dy)*w+x+dx]);
    }
    result[i*4]=result[i*4+1]=result[i*4+2]=255;result[i*4+3]=a[i]-minimum;
  }
  return sharp(result,{raw:{width:w,height:h,channels:4}}).png().toBuffer();
}

const frameNames=['panel','ribbon','button','list-item','speech'];
for(let i=0;i<frameNames.length;i++)await emit('frame-'+frameNames[i],'frames',await frame(await cell('frames',3,2,i)),160,160,
  {slice:{mode:'nine_patch',margins:[48,48,48,48],axis_stretch:'tile_fit',draw_center:false,minimum:[96,96]},content_insets:[24,20,24,20],tint:'nanquim',source_atlas:'frames.png',source_cell:i});
for(const [i,name]of ['speech','shout','thought','whisper'].entries())await emit('balloon-'+name,'balloons',await frame(await cell('balloons',4,2,i),true),160,160,
  {slice:{mode:'nine_patch',margins:[48,48,48,48],axis_stretch:'tile_fit',draw_center:false,minimum:[96,160]},content_insets:[30,26,30,26],tail:name==='shout'?'tail-left':'tail-'+({speech:'left',thought:'thought',whisper:'whisper'}[name]),tint:'nanquim',source_atlas:'balloons.png',source_cell:i});
for(const [i,name]of ['left','right','thought','whisper'].entries())await emit('tail-'+name,'balloons',await fit(await cell('balloons',4,2,i+4),160,128,12),80,64,{tint:'nanquim',pivot:[.5,0],source_atlas:'balloons.png',source_cell:i+4});
for(let i=0;i<3;i++)await emit('selection-'+(i+1),'strokes',await fit(await cell('strokes',1,3,i,'white'),640,128,4),320,64,
  {slice:{mode:'three_slice',margins:[48,0,48,0],axis_stretch:'stretch',minimum:[96,64]},tint:'papel',source_atlas:'strokes.png',source_cell:i});

for(let i=0;i<15;i++){
  const kind=i<3?'small':i<6?'medium':i<8?'large':i<12?'drip':'trail';
  const variant=i<3?i+1:i<6?i-2:i<8?i-5:i<12?i-7:i-11;
  const size=kind==='small'?48:kind==='large'?320:120;
  const atlas=i<8?'splats':'drips',cellIndex=i<8?i:i-8;
  const source=await cell(atlas,4,2,cellIndex,'white');
  const master=await fit(source,size*2,size*2,kind==='small'?4:8);
  const extra={family:kind,variant,tint:'white-mask',source_atlas:atlas+'.png',source_cell:cellIndex};
  await emit(`${kind}-${variant}`,'splats',master,size,size,{...extra,form:'filled'});
  await emit(`${kind}-${variant}-outline`,'splats',await outline(master,Math.max(3,Math.min(6,size/12))),size,size,{...extra,form:'outline',outline_width:kind==='small'?2:3});
}
for(const [i,name]of ['sweat','anger','sparkle','surprise','question','heart','dizzy','sigh'].entries())await emit(name,'emotes',await fit(await cell('emotes',4,2,i,'duo'),192,192,10),96,96,
  {tint:'preserve-duotone',source_atlas:'emotes.png',source_cell:i,semantic:name,paper_border_target:4,ink_outline_target:4});
for(const [i,name]of ['new','rare','level','double'].entries())await emit('sticker-'+name,'stickers',await fit(await cell('stickers',2,2,i,'duo'),320,320,10),160,160,
  {tint:'preserve-duotone',live_label:name==='new'?'NOVO!':name==='rare'?'RARO':name==='level'?'NV.':'×2',text_safe_rect:[.25,.38,.5,.24],source_atlas:'stickers.png',source_cell:i});
for(const kind of ['concentration','parallel']){
  const file=path.join(sources,'speed-'+kind+'.png');
  const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  for(let i=0;i<data.length;i+=4){if(data[i]<225||data[i+3]<40)data[i+3]=0;data[i]=data[i+1]=data[i+2]=255;}
  await emit(kind,'speedlines',await sharp(data,{raw:info}).resize(4096,4096).png().toBuffer(),2048,2048,{tint:'white-mask',max_duration_ms:250,source_atlas:'speed-'+kind+'.png'});
}

// Numeric, opaque sampling texture. Silhouette profile comes from drawn large-2.
const profileSource=await fit(await cell('splats',4,2,7,'white'),512,512,8);
const profile=await sharp(profileSource).ensureAlpha().raw().toBuffer();
const radii=Array(360).fill(90);
for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(profile[(y*512+x)*4+3]>128){
  const angle=(Math.atan2(y-256,x-256)+Math.PI*2)%(Math.PI*2),index=Math.floor(angle*180/Math.PI)%360;
  radii[index]=Math.max(radii[index],Math.hypot(x-256,y-256));
}
const smooth=radii.map((_,i)=>Array.from({length:15},(_,j)=>radii[(i+j+353)%360]).reduce((a,b)=>a+b,0)/15);
const size=2048,mask=Buffer.alloc(size*size*4);
for(let y=0;y<size;y++)for(let x=0;x<size;x++){
  const dx=(x+.5)/size-.5,dy=(y+.5)/size-.5;
  const angle=(Math.atan2(dy,dx)+Math.PI*2)%(Math.PI*2),index=Math.floor(angle*180/Math.PI)%360;
  const value=Math.round(Math.min(1,Math.hypot(dx,dy)/(.57*(.72+.28*smooth[index]/256)))*255),k=(y*size+x)*4;
  mask[k]=mask[k+1]=mask[k+2]=value;mask[k+3]=255;
}
await emit('splat_mask','',await sharp(mask,{raw:{width:size,height:size,channels:4}}).png().toBuffer(),1024,1024,
  {alpha:'opaque-data',tint:'grayscale-data',source:'numerical center-out threshold field derived from drawn large-2 silhouette; not an illustration',center_value:0,edge_value:255,color_space:'linear-data'});

for(const [kind,radius]of [['dots-fine',1.35],['dots-dense',2],['dots-ramp',2]]){
  const size=512,data=Buffer.alloc(size*size*4);
  for(let y=0;y<size;y++)for(let x=0;x<size;x++){
    // 16px master step (8px logical), staggered by half a step for 45-degree rows.
    const row=Math.floor(y/16),cx=((x+(row%2)*8)%16)-8,cy=(y%16)-8;
    const r=radius*2*(kind==='dots-ramp'?(x+y)/(2*(size-1)):1);
    const a=Math.round(255*Math.max(0,Math.min(1,r+.5-Math.hypot(cx,cy)))),k=(y*size+x)*4;
    data[k]=data[k+1]=data[k+2]=255;data[k+3]=a;
  }
  await emit(kind,'halftone',await sharp(data,{raw:{width:size,height:size,channels:4}}).png().toBuffer(),256,256,
    {repeat:kind!=='dots-ramp',tint:'nanquim',source:'procedural periodic halftone fallback, not an illustrated asset',spacing:8,max_dot_diameter:radius*2});
}
const manifest={schema:1,id:'recorte-ink-v1',issue:'PIP-63',reference:'art/ui/hud-recorte-v1/ESPECIFICACAO.md#31',
  token_source:'res://scripts/campaign/ui_tokens.gd',tokens:colors,logical_scale:1,master_scale:2,
  source_directory:'art/ui/recorte-v1/sources',provenance:'Built-in image_gen original drawn atlases. See art/ui/recorte-v1/provenance.json. No third-party franchise artwork.',
  global_rules:{text_baked:false,premultiplied_alpha:false,filter:'linear',mipmaps:false,decorations_mouse_filter:'ignore',
    non_repeating_splats:'seeded family bag; no consecutive source variant; rotation and mirror from same event seed',
    motion:'event-driven, never continuous; reduce motion uses a still image with 80ms fade'},
  approval:{technical:'pending-native-review',visual:'pending-owner-review'},assets:entries};
await fs.writeFile(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`PIP-63: ${entries.length} assets, ${entries.length*2} raster exports; drawn sources preserved.`);
