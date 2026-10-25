import {validate} from './model.mjs';
// Migrate facial textures only. Never replace the player's placement or animation.
export async function upgradeLoboFaces(project){
 if(project.creatureId!=='lobo-cordeiro'||project.expressionRevision>=2)return project;
 const head=project.parts.find(p=>p.id==='head');
 if(!head||head.asset!=='head'||head.source.join(',')!=='0,0,355,331'||!['happy','fierce','hurt'].every(id=>head.faces?.[id]?.asset===id))return project;
 const canonical=await createGuardian('lobo-cordeiro'),fixed=canonical.parts.find(p=>p.id==='head');
 if(canonical.expressionRevision!==2)throw Error('As expressões registradas do Lobo não carregaram.');
 const next=structuredClone(project),target=next.parts.find(p=>p.id==='head');
 for(const [id,ref]of Object.entries(fixed.faces)){next.assets[ref.asset]=structuredClone(canonical.assets[ref.asset]);target.faces[id]=structuredClone(ref);}
 target.faceWindows=structuredClone(fixed.faceWindows);next.expressionRevision=2;
 return next;
}
export async function createGuardian(id='lacertubo'){
 if(!['lacertubo','lacertubo-v2','lobo-cordeiro'].includes(id))throw Error('Projeto desconhecido.');
 const response=await fetch('/art/soulgen/keys/'+id+'/color-rig-v2/'+id+'.soulgen.json');
 if(!response.ok)throw Error('O rig do guardião não carregou.');
 const project=await response.json(),report=validate(project);if(!report.ok)throw Error(report.errors.join(' '));return project;
}
export const BASIC_CREATURES={'mata-verde':'Mata verde',azulao:'Azulão','raio-de-sol':'Raio de sol',rabbito:'Rabbito'};
export async function createBasic(id,sizeFor){
 if(!Object.hasOwn(BASIC_CREATURES,id))throw Error('Espécie básica desconhecida.');
 const response=await fetch(`/art/soulgen/keys/${id}/color-rig-v2/${id}.soulgen.json`);
 if(!response.ok)throw Error('Não foi possível abrir '+BASIC_CREATURES[id]);
 const p=await response.json(),audit=validate(p);if(!audit.ok)throw Error(audit.errors.join(' '));
 if(sizeFor)for(const asset of Object.values(p.assets)){const size=await sizeFor(asset.src);if(size.width!==asset.width||size.height!==asset.height)throw Error('Fonte com dimensão diferente: '+asset.name);}
 return p;
}
