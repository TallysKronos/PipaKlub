import {clone} from './model.mjs';

export const KAEL_OPTIONS={
 view:[['south','Frente'],['west','Esquerda'],['east','Direita'],['north','Costas']],
 skin:[['mel','Mel'],['claro','Claro'],['castanho','Castanho'],['escuro','Escuro']],
 hair:[['spiky','Desfiado'],['curly','Ondulado']],
 hairColor:[['navy','Azul-noite'],['brown','Castanho'],['black','Preto'],['copper','Acobreado']],
 outfit:[['blue','Jaqueta azul'],['clay','Jaqueta terracota']]
};

// Appearance selects registered textures, never moves joints or replaces animation tracks.
export function customizeKael(project,changes={}){
 if(project.avatar?.kind!=='kael-modular-v1')throw Error('Este projeto não é um avatar modular do Kael.');
 const next={...project.avatar.appearance,...changes};
 for(const [key,value]of Object.entries(next))if(key==='view'||!KAEL_OPTIONS[key]?.some(([id])=>id===value))throw Error('Aparência inválida: '+key);
 const slots={head:'head-'+next.skin,hair:'hair-'+next.hair+'-'+next.hairColor,body:'body-'+next.outfit+'-'+next.skin,armLeft:'arm-left-'+next.outfit+'-'+next.skin,armRight:'arm-right-'+next.outfit+'-'+next.skin,legLeft:'leg-left-'+next.skin,legRight:'leg-right-'+next.skin};
 for(const [id,asset]of Object.entries(slots))if(!project.assets[asset]||!project.parts.some(p=>p.id===id))throw Error('Peça de personalização ausente: '+id);
 for(const [id,asset]of Object.entries(slots)){
  const p=project.parts.find(p=>p.id===id),a=project.assets[asset];p.asset=asset;
  p.source=project.avatar.revision>=2?clone(project.avatar.views[project.avatar.view][p.id].source):[0,0,a.width,a.height];
 }
 project.avatar.appearance=next;return project;
}

export function setKaelDirection(project,view){
 const a=project.avatar,bind=a?.views?.[view];if(a?.kind!=='kael-modular-v1'||!bind)throw Error('Direção indisponível para este avatar.');
 if(project.parts.some(p=>!bind[p.id]))throw Error('A montagem foi modificada; abra uma cópia do preset para mudar de direção.');
 const index=a.directions.indexOf(view);if(index<0)throw Error('Direção inválida.');
 for(const p of project.parts)Object.assign(p,clone(bind[p.id]));
 project.anatomy={version:1,ratios:[],behind:[{part:'body',other:'head'},{part:'head',other:'hair'}],joints:['armLeft','armRight','head','hair'].map(id=>{const p=project.parts.find(p=>p.id===id),parent=project.parts.find(q=>q.id===p.parent),[x,y]=p.pivot;return {part:id,parent:parent.id,anchor:[(x-p.rect[0])/p.rect[2],(y-p.rect[1])/p.rect[3]],socket:[(x-parent.rect[0])/parent.rect[2],(y-parent.rect[1])/parent.rect[3]],maxGap:.01};})};
 a.view=view;return project;
}

export async function createKael(sizeFor){
 const {project}=await import('../../art/soulgen/keys/kael-v2/rig-data.mjs');
 const result=clone(project);
 if(sizeFor)for(const a of Object.values(result.assets)){
  const actual=await sizeFor(a.src);
  if(actual.width!==a.width||actual.height!==a.height)throw Error('Dimensões diferentes na fonte do Kael: '+a.name);
 }
 return result;
}
