// Native indexed key-pose rig. No image resizing, sprite rotation or generated in-betweens.
import fs from 'node:fs/promises';
import {serialize,validateProject,audit} from '../core.mjs';
import {compositeAll} from '../document.mjs';
import {aseprite} from '../aseprite.mjs';
import {atlas} from '../animation.mjs';
import {godotResource} from '../godot.mjs';
const root=new URL('../../../',import.meta.url),out=new URL('art/characters/kael-eight-directions-v1/',root);
await fs.mkdir(out,{recursive:true});
const original=JSON.parse(await fs.readFile(new URL('art/characters/rpg-overworld-study-v1/pixelgen-native-v1/kael-professor.pixelgen.json',root),'utf8'));
const W=48,H=64,empty=()=>new Uint8Array(W*H),palette=original.palette;
const C={outline:3,shade:5,hair:10,hairLight:13,coat:12,coatDark:8,pants:14,skin:25,skinShade:21,white:28,cyan:23,cyanDark:20,shirt:6};
function pixel(a,x,y,c){x=Math.round(x);y=Math.round(y);if(x>=0&&x<W&&y>=0&&y<H)a[y*W+x]=c;}
function rect(a,x,y,w,h,c){for(let yy=y;yy<y+h;yy++)for(let xx=x;xx<x+w;xx++)pixel(a,xx,yy,c);}
function poly(a,points,c){for(let y=0;y<H;y++)for(let x=0;x<W;x++){let inside=false;for(let i=0,j=points.length-1;i<points.length;j=i++){const [xi,yi]=points[i],[xj,yj]=points[j];if((yi>y+.5)!==(yj>y+.5)&&(x+.5)<(xj-xi)*(y+.5-yi)/(yj-yi)+xi)inside=!inside;}if(inside)pixel(a,x,y,c);}}
function line(a,p,q,c,w=1){let [x,y]=p.map(Math.round),[tx,ty]=q.map(Math.round),dx=Math.abs(tx-x),sx=x<tx?1:-1,dy=-Math.abs(ty-y),sy=y<ty?1:-1,e=dx+dy;for(;;){rect(a,x-Math.floor(w/2),y-Math.floor(w/2),w,w,c);if(x===tx&&y===ty)break;const e2=2*e;if(e2>=dy){e+=dy;x+=sx;}if(e2<=dx){e+=dx;y+=sy;}}}
function shift(source,dx,dy){const a=empty();for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(source[y*W+x])pixel(a,x+dx,y+dy,source[y*W+x]);return a;}
// Cardinal head artwork is the existing approved native asset. Diagonal faces are repainted on-grid.
function head(dir){const cardinal={S:0,O:1,E:2,N:3},base=cardinal[dir]??(dir.includes('N')?3:0),a=empty();for(let y=0;y<31;y++)for(let x=0;x<W;x++)a[y*W+x]=original.frames[base].indices[y*W+x];
 if(dir==='SE'||dir==='SO'){const s=dir==='SE'?1:-1;
  // Replace front face, preserve the asymmetric swept hair silhouette.
  poly(a,[[15,22],[32,22],[34,26],[30,30],[21,31],[15,27]],C.skinShade);
  poly(a,[[16+s,22],[30+s,22],[32+s,26],[28+s,29],[22+s,30],[17+s,27]],C.skin);
  const eye=s>0?29:18,far=s>0?21:27;
  rect(a,eye,24,3,4,C.white);rect(a,eye+(s>0?1:0),24,2,4,C.outline);
  rect(a,far,24,2,3,C.white);rect(a,far+(s>0?1:0),24,1,3,C.outline);
  line(a,[eye-1,22],[eye+2,22],C.shade);pixel(a,25+s*3,28,C.skinShade);
  poly(a,[[12,18],[18,18],[23,23],[19,23],[16,21],[13,22]],C.hair);
  poly(a,[[28,18],[35,19],[33,24],[30,22]],C.shade);
 }
 if(dir==='NE'||dir==='NO'){const s=dir==='NE'?1:-1;
  // Away-facing three-quarter: nape and one ear/cheek sliver, no frontal eyes.
  const x=s>0?32:14;
  poly(a,[[x,24],[x+3,24],[x+3,28],[x,30],[x-1,27]],C.skinShade);
  rect(a,x+1,25,2,3,C.skin);line(a,[x,23],[x+2,23],C.shade);
  poly(a,[[17,27],[31,27],[29,31],[21,31]],C.shade);
 }
 return a;}
const directions=[['S',0,1],['SO',-.7,.7],['O',-1,0],['NO',-.7,-.7],['N',0,-1],['NE',.7,-.7],['E',1,0],['SE',.7,.7]];
// Explicit contact/pass keys and unequal holds. Each pose specifies limb geometry, not a global sprite bob.
const cycles=[
 ['idle',[{breath:0,ms:700},{breath:-1,ms:350}],true],
 ['walk',[{step:1,ms:140,bob:1},{step:0,ms:100},{step:-1,ms:140,bob:1},{step:0,ms:100,pass:1}],true],
 ['run',[{step:1.7,ms:90,bob:1},{step:.8,ms:70,bob:0,lift:3},{step:0,ms:70,bob:-2,lift:4},{step:-1.7,ms:90,bob:1},{step:-.8,ms:70,lift:3},{step:0,ms:70,bob:-2,pass:1,lift:4}],true],
 ['interact',[{reach:0,ms:140},{reach:.5,crouch:2,ms:120},{reach:1,crouch:3,ms:280},{reach:.3,crouch:1,ms:180}],false],
 ['attack',[{throw:-.5,lean:-1,ms:160},{throw:-1,lean:-2,ms:130},{throw:1,lean:2,ms:60},{throw:1,lean:2,ms:110},{throw:.5,lean:1,ms:160},{throw:0,ms:220}],false],
 ['hurt',[{hurt:1,lean:-2,bob:1,ms:90},{hurt:.5,lean:-1,ms:250}],false],
 ['victory',[{cheer:.5,ms:120},{cheer:1,bob:-1,ms:200},{cheer:.8,ms:130},{cheer:1,bob:-1,ms:350}],false],
 ['fall',[{crouch:3,hurt:1,ms:120},{crouch:7,hurt:1,ms:160},{down:.6,ms:140},{down:1,ms:700}],false]
];
const p={kind:'pixelgen',version:2,name:'Kael · 8 direções · biblioteca de movimentos',width:W,height:H,cols:16,rows:16,palette,settings:{margin:2},layers:['Partes distantes e rabiolas','Pernas e calçados','Tronco e fones','Braço próximo e mãos','Cabeça'].map(name=>({name,visible:true,locked:false})),frames:[],sequences:[]};
function pose(d,key){const [dir,dx,dy]=d,side=Math.abs(dx),back=dy<0,bob=key.bob||0,crouch=key.crouch||0,lean=(key.lean||0)*dx,down=key.down||0;
 const a=Array.from({length:5},empty),[tails,legs,body,arms,face]=a;
 const running=(key.lift||Math.abs(key.step||0)>1),cx=24+lean+(running?dx*2:0),by=bob+crouch,hipY=47+by,shoulderY=33+by+(key.breath||0),spread=4;
 // Foot targets differ along the projected facing axis; far foot is shaded and raised.
 const step=key.step||0;
 for(const sign of [-1,1]){const near=sign===1,hip=[24-dy*sign*3,hipY+dx*sign],stride=step*sign;
  const foot=[24-dy*sign*spread+dx*stride*5,Math.min(61,60+dx*sign+dy*stride*1.5-(stride<0?Math.abs(stride)*2:0)-(key.lift||0))];
  const knee=[hip[0]+(foot[0]-hip[0])*.5-dx*Math.abs(stride)*1.5,53+by*.4-Math.abs(stride)*(running?3:1.5)];
  line(legs,hip,knee,C.outline,6);line(legs,knee,[foot[0],foot[1]-2],C.outline,6);
  line(legs,hip,knee,near?C.pants:C.shade,4);line(legs,knee,[foot[0],foot[1]-2],near?C.pants:C.shade,4);
  rect(legs,Math.round(foot[0])-3,Math.round(foot[1])-3,7,4,C.outline);rect(legs,Math.round(foot[0])-2,Math.round(foot[1])-3,5,2,C.coatDark);rect(legs,Math.round(foot[0])-2,Math.round(foot[1]),5,1,C.white);
  if(sign===1)line(legs,[hip[0]-2,hipY+3],[hip[0]+2,hipY+3],C.shade,2);
 }
 const bw=side>.9?4:side>.2?6:8;
 rect(body,Math.round(cx)-3,29+by,7,6,C.outline);
 rect(body,Math.round(cx)-2,30+by,5,4,back?C.coatDark:C.skinShade);
 poly(body,[[cx-bw,shoulderY],[cx+bw,shoulderY],[cx+bw-1,46+by],[cx+4,49+by],[cx-5,49+by],[cx-bw+1,44+by]],C.outline);
 poly(body,[[cx-bw+1,shoulderY+1],[cx+bw-1,shoulderY+1],[cx+bw-2,45+by],[cx-5,47+by],[cx-bw+2,44+by]],back?C.coat:C.shirt);
 if(!back){const center=cx+dx*2;poly(body,[[cx-bw+1,shoulderY+1],[center-3,shoulderY+1],[center-4,44+by],[cx-bw+1,46+by]],C.coat);poly(body,[[center+3,shoulderY+1],[cx+bw-1,shoulderY+1],[cx+bw-2,46+by],[center+4,44+by]],C.coatDark);
  for(const s of (side>.9?[1]:[-1,1])){const fx=Math.round(center+s*(side>.9?1:3));rect(body,fx-1,33+by,3,5,C.cyanDark);rect(body,fx,33+by,2,4,C.cyan);}
 }else{line(body,[cx-bw+2,shoulderY+2],[cx-bw+2,43+by],C.coatDark);line(body,[cx+bw-2,shoulderY+2],[cx+bw-2,43+by],C.coatDark);}
 for(const s of [-1,1]){const x=cx+s*(bw-1),drag=(step||0)*s;
  line(tails,[x,43+by],[x+s*2-dx*drag*2,52+by+Math.abs(drag)],C.outline,3);line(tails,[x,43+by],[x+s*2-dx*drag*2,51+by+Math.abs(drag)],C.white,1);
 }
 for(const s of [-1,1]){const limb=side>.2&&s===-1?tails:arms,shoulder=[cx-dy*s*bw,shoulderY+2+dx*s],swing=-step*s;
  let elbow=[shoulder[0]+dx*swing*2-dy*s,40+by+dx*s],hand=[shoulder[0]+dx*swing*4-dy*s,45+by+dy*swing*2+dx*s];
  if(running){elbow=[shoulder[0]+dx*swing*2-dy*s*2,40+by+dx*s];hand=[shoulder[0]+dx*swing*4+dy*s*3,37+by+dy*swing*4+dx*s];}
  if(key.reach){elbow=[shoulder[0]+dx*4*key.reach,shoulderY+7];hand=[cx+dx*14*key.reach+s*3,43+by+dy*5*key.reach];}
  if(key.throw!==undefined&&s===1){const t=key.throw;elbow=[cx+dx*(t>0?8:-5)+s*4,shoulderY+(t>0?dy*3:-3)];hand=[Math.max(3,Math.min(44,cx+dx*(t>0?15:-8)+s*3)),shoulderY+(t>0?dy*10:-7)];}
  if(key.hurt){elbow=[cx+s*6,39+by];hand=[cx+s*2,37+by];}
  if(key.cheer){elbow=[cx+s*(bw+3),shoulderY-2*key.cheer];hand=[cx+s*(bw+4),shoulderY-10*key.cheer];}
  line(limb,shoulder,elbow,C.outline,5);line(limb,elbow,hand,C.outline,5);line(limb,shoulder,elbow,s===-1?C.coatDark:C.coat,3);line(limb,elbow,hand,s===-1?C.coatDark:C.coat,3);
  line(limb,[shoulder[0]-1,shoulder[1]], [elbow[0]-1,elbow[1]],C.white,1);
  rect(limb,Math.round(hand[0])-2,Math.round(hand[1])-1,5,4,C.outline);rect(limb,Math.round(hand[0])-1,Math.round(hand[1]),3,2,C.skin);pixel(limb,hand[0]-1,hand[1]+2,C.skinShade);
 }
 const h=head(dir),moved=shift(h,Math.round(lean+(running?dx*3:0)),Math.max(-1,bob)+crouch);face.set(moved);
 if(down){ // Authored fallen key: horizontal torso and bent leg silhouette; no sprite rotation.
  a.forEach(c=>c.fill(0));const yy=down>.8?58:54;
  line(legs,[30,yy-6],[37,yy-9],C.outline,7);line(legs,[37,yy-9],[42,yy-5],C.outline,7);line(legs,[30,yy-6],[37,yy-9],C.shade,5);line(legs,[37,yy-9],[42,yy-5],C.shade,5);rect(legs,40,yy-6,5,3,C.coatDark);rect(legs,40,yy-3,5,1,C.white);
  line(legs,[30,yy-3],[36,yy],C.outline,7);line(legs,[36,yy],[42,yy],C.outline,6);line(legs,[30,yy-3],[36,yy],C.pants,5);line(legs,[36,yy],[42,yy],C.pants,4);rect(legs,40,yy-2,5,3,C.coatDark);rect(legs,40,yy+1,5,1,C.white);
  poly(body,[[17,yy-15],[28,yy-15],[35,yy-8],[33,yy],[21,yy]],C.outline);poly(body,[[18,yy-14],[27,yy-14],[33,yy-8],[31,yy-1],[21,yy-1]],C.coat);line(body,[28,yy-11],[32,yy-7],C.white,1);rect(body,25,yy-9,3,4,C.cyan);
  line(arms,[18,yy-5],[25,yy-1],C.outline,5);line(arms,[18,yy-5],[25,yy-1],C.coatDark,3);rect(arms,24,yy-2,4,3,C.skin);
  // New foreshortened head silhouette for the floor key, not an upright head pasted onto it.
  poly(face,[[5,yy-15],[8,yy-20],[12,yy-20],[14,yy-26],[20,yy-25],[24,yy-29],[25,yy-23],[30,yy-25],[28,yy-17],[31,yy-17],[29,yy-11],[26,yy-7],[15,yy-6],[8,yy-9]],C.outline);
  poly(face,[[6,yy-15],[9,yy-19],[14,yy-18],[15,yy-25],[20,yy-24],[23,yy-27],[24,yy-22],[28,yy-23],[26,yy-16],[29,yy-16],[27,yy-11],[24,yy-9],[13,yy-9],[8,yy-11]],C.hair);
  poly(face,[[9,yy-17],[15,yy-16],[22,yy-20],[19,yy-16],[25,yy-18],[21,yy-14],[14,yy-13]],C.hairLight);
  if(!back){poly(face,[[8,yy-12],[13,yy-12],[17,yy-10],[24,yy-12],[27,yy-10],[25,yy-5],[18,yy-3],[11,yy-5],[8,yy-8]],C.skinShade);poly(face,[[9,yy-11],[13,yy-11],[17,yy-9],[24,yy-11],[25,yy-9],[24,yy-6],[18,yy-4],[12,yy-6]],C.skin);line(face,[12,yy-8],[15,yy-7],C.outline);line(face,[20,yy-7],[23,yy-8],C.outline);}
  else{poly(face,[[9,yy-13],[27,yy-13],[26,yy-7],[20,yy-4],[12,yy-7]],C.shade);rect(face,25,yy-8,3,3,C.skinShade);}
  if(dx>0){ // Opposite floor silhouette, with the hair redrawn in the original sweep rather than mirrored.
   for(const cel of [tails,legs,body,arms]){const old=cel.slice();cel.fill(0);for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(old[y*W+x])pixel(cel,47-x,y,old[y*W+x]);}
   face.set(shift(face,10,0));
  }
 }
 return a;}
for(const d of directions)for(const [action,keys,loop]of cycles){const start=p.frames.length;
 for(const [i,key]of keys.entries()){const cels=pose(d,key);p.frames.push({name:`${action}-${d[0]}-${i+1}`,duration:key.ms,cels,indices:empty()});}
 p.sequences.push({name:`${action}-${d[0]}`,start,end:p.frames.length-1,loop,direction:'forward'});
}
compositeAll(p);const canonical=validateProject(JSON.parse(JSON.stringify(serialize(p))));
await fs.writeFile(new URL('kael-library.pixelgen.json',out),JSON.stringify(serialize(canonical)));
await fs.writeFile(new URL('kael-library.aseprite',out),aseprite(canonical));
await fs.writeFile(new URL('kael-library-atlas.json',out),JSON.stringify(atlas(canonical,'kael-library-sheet.png'),null,2));
await fs.writeFile(new URL('kael-library.tres',out),godotResource(canonical,'res://assets/characters/kael/kael-library-sheet.png'));
await fs.writeFile(new URL('audit.json',out),JSON.stringify(audit(canonical),null,2));
// Review turnarounds and direction-specific small editable projects.
for(const d of directions){const sequences=canonical.sequences.filter(s=>s.name.endsWith('-'+d[0])),start=sequences[0].start;
 const part={...canonical,name:`Kael · ${d[0]} · 8 movimentos`,cols:8,rows:4,frames:canonical.frames.slice(start,start+32),sequences:sequences.map(s=>({...s,start:s.start-start,end:s.end-start}))};
 await fs.writeFile(new URL(`kael-${d[0]}.pixelgen.json`,out),JSON.stringify(serialize(part)));
}
console.log(JSON.stringify(audit(canonical)));
