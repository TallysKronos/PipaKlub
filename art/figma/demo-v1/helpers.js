// Reused by the Figma Plugin API steps; no game runtime changes.
const created=[];const mutated=[];
const keep=n=>{created.push(n.id);return n;};
await Promise.all([{family:'Nunito',style:'Regular'},{family:'Nunito',style:'Bold'},{family:'Lilita One',style:'Regular'},{family:'Pixelify Sans',style:'SemiBold'}].map(f=>figma.loadFontAsync(f)));
const vars=Object.fromEntries((await figma.variables.getLocalVariablesAsync()).map(v=>[v.name,v]));
const styles=Object.fromEntries((await figma.getLocalTextStylesAsync()).map(s=>[s.name.split('/').pop(),s]));
const color=n=>figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0}},'color',vars[n.startsWith('palette/')?n:'color/'+n]);
function gap(n,v){n.setBoundVariable('itemSpacing',vars['space/'+v]);}
function pad(n,v){for(const k of ['paddingTop','paddingBottom','paddingLeft','paddingRight'])n.setBoundVariable(k,vars['space/'+v]);}
function round(n,v){for(const k of ['topLeftRadius','topRightRadius','bottomLeftRadius','bottomRightRadius'])n.setBoundVariable(k,vars['radius/'+v]);}
function stack(name,w,h=null,direction='VERTICAL',fill=null,padding=0,spacing=16){const n=keep(figma.createAutoLayout(direction));n.name=name;n.resize(w,h||10);n.primaryAxisSizingMode=h||direction==='HORIZONTAL'?'FIXED':'AUTO';n.counterAxisSizingMode=!h&&direction==='HORIZONTAL'?'AUTO':'FIXED';n.fills=fill?[color(fill)]:[];pad(n,padding);gap(n,spacing);return n;}
async function txt(value,style='Body',width=null,ink='text'){const t=keep(figma.createText());t.name=value.slice(0,60);await t.setTextStyleIdAsync(styles[style].id);t.characters=value;t.fills=[color(ink)];if(width){t.textAutoResize='HEIGHT';t.resize(width,t.height);}return t;}
function pic(key,w,h,fit='FIT'){const n=keep(figma.createRectangle());n.name='Asset / '+key;n.resize(w,h);n.fills=[{type:'IMAGE',imageHash:ASSETS[key].hash,scaleMode:fit}];return n;}
function abs(parent,node,x,y){parent.appendChild(node);node.layoutPositioning='ABSOLUTE';node.x=x;node.y=y;return node;}
function paper(name,w,h=null,padding=24){const p=stack(name,w,h,'VERTICAL','surface',padding,16);p.strokes=[color('border')];p.strokeWeight=3;round(p,16);return p;}
async function heading(parent,title,sub,width){parent.appendChild(await txt(title,'Title',width));if(sub)parent.appendChild(await txt(sub,'Body',width,'muted'));}
function descendants(n){return [n.id,...(n.children?n.children.flatMap(descendants):[])];}
async function button(label,kind='Primary',w=256){const mc=await figma.getNodeByIdAsync(COMPONENTS['Button/'+kind]);const i=mc.createInstance();created.push(...descendants(i));i.name='Action / '+label;const key=Object.keys(mc.componentPropertyDefinitions).find(k=>mc.componentPropertyDefinitions[k].type==='TEXT');i.setProperties({[key]:label});i.resize(w,64);return i;}
async function instance(name,w=null,h=null){const mc=await figma.getNodeByIdAsync(COMPONENTS[name]);const i=mc.createInstance();created.push(...descendants(i));if(w&&h)i.resize(w,h);return i;}
function stage(name,bg,index){const f=stack(name,1440,900,'VERTICAL','canvas',0,0);f.x=80+(index%3)*1600;f.y=80+Math.floor(index/3)*1060;f.clipsContent=true;if(bg){const b=pic(bg,1440,900,'FILL');abs(f,b,0,0);b.constraints={horizontal:'SCALE',vertical:'SCALE'};}return f;}
async function topbar(f,label,back=true){const bar=stack('HUD / Barra superior',1344,64,'HORIZONTAL',null,0,16);bar.primaryAxisAlignItems='SPACE_BETWEEN';bar.counterAxisAlignItems='CENTER';abs(f,bar,48,32);const logo=await txt('pipa club','Heading',200,'palette/white');bar.appendChild(logo);const badge=paper('Contexto',490,64,16);badge.layoutMode='HORIZONTAL';badge.counterAxisAlignItems='CENTER';badge.appendChild(await txt(label,'Label',440));bar.appendChild(badge);if(back){const b=await button('Voltar','Secondary',176);bar.appendChild(b);return b;}return null;}
async function note(f,text){const n=stack('Nota de escopo',1344,null,'VERTICAL','canvas',12,0);n.appendChild(await txt(text,'Meta',1320,'palette/white'));abs(f,n,48,842);return n;}
async function nav(f){const box=stack('Atalhos do clube',104,null,'VERTICAL',null,0,12);abs(f,box,32,150);const targets={};for(const [label,key]of [['Mochila','backpack'],['Pipamons','partners'],['Mapa','map'],['Missões','missions'],['Opções','settings']]){const b=paper('Nav / '+label,104,104,8);b.itemSpacing=4;b.counterAxisAlignItems='CENTER';b.appendChild(pic('icon-'+key,60,60));b.appendChild(await txt(label,'Label'));box.appendChild(b);targets[label]=b.id;}return targets;}
async function actor(f,key,x,y,w=90,h=110){return abs(f,pic(key,w,h),x,y);}
