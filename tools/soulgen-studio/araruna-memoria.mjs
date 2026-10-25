import {validate} from './model.mjs';
export async function createArarunaMemoria(){
 const response=await fetch('/art/soulgen/keys/araruna-memoria/color-rig-v2/araruna-memoria.soulgen.json');
 if(!response.ok)throw Error('O rig do ArarunaMemoria não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
