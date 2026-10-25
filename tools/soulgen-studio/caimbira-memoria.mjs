import {validate} from './model.mjs';
export async function createCaimbiraMemoria(){
 const response=await fetch('/art/soulgen/keys/caimbira-memoria/color-rig-v2/caimbira-memoria.soulgen.json');
 if(!response.ok)throw Error('O rig do CaimbiraMemoria não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
