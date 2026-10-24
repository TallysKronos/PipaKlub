import {validate} from './model.mjs';
export async function createGuardian(id='lacertubo'){
 if(!['lacertubo','lacertubo-v2'].includes(id))throw Error('Versão de guardião desconhecida.');
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
