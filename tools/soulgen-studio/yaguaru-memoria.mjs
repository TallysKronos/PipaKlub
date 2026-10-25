import {validate} from './model.mjs';
export async function createYaguaruMemoria(){
 const response=await fetch('/art/soulgen/keys/yaguaru-memoria/color-rig-v2/yaguaru-memoria.soulgen.json');
 if(!response.ok)throw Error('O rig do YaguaruMemoria não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
