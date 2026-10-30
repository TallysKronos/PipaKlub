// Explicit bindings to current Godot consumers. Never accept filesystem paths from HTTP.
const npcNames={professor:'Professor Assis',mae:'Mãe do Kael',nina:'Nina',bia:'Bia',juninho:'Juninho',lia:'Lia',zeca:'Zeca',tiao:'Tião'};
const asset=(id,label,project,png,runtime=png)=>({id,label,project,png,runtime});
export const characters=[
 {id:'kael',name:'Kael',role:'Protagonista',group:'Campanha',inGame:true,assets:[
  asset('kael-walk','Caminhada · 8 direções','art/characters/kael-video-eight-directions-v1/pacote/kael-eight.pixelgen.json','art/characters/kael-video-eight-directions-v1/pacote/kael-walk-eight.png','godot/assets/kael-video/kael-walk-eight.png'),
  asset('kael-jump','Salto de barranco','art/characters/kael-video-jump-v1/pacote/kael-jump.pixelgen.json','art/characters/kael-video-jump-v1/pacote/kael-jump.png','godot/assets/kael-video/kael-jump.png'),
  asset('kael-item','Receber item','art/characters/kael-video-item-v1/pacote/kael-item.pixelgen.json','art/characters/kael-video-item-v1/pacote/kael-item.png','godot/assets/kael-video/kael-item.png')
 ]},
 ...Object.entries(npcNames).map(([id,name])=>({id,name,role:id==='mae'?'Família':id==='professor'?'Professor':'NPC',group:'Campanha',inGame:true,assets:[asset(id,'Overworld · 8 direções',`art/characters/npc-ds-directions-v1/pacote/${id}/${id}.pixelgen.json`,`art/characters/npc-ds-directions-v1/pacote/${id}/${id}-directions.png`,`godot/assets/npc-ds/${id}.png`)]})),
 ...Object.entries({iara:'Iara',nilo:'Nilo',dora:'Dora',caue:'Cauê',celina:'Celina'}).map(([id,name])=>({id,name,role:'Pipeiro · duelo opcional',group:'Parque e Veredas',inGame:true,assets:[asset(id,'Overworld · 8 direções',`art/characters/parque-pipeiros-runtime-v1/pacote/${id}/${id}.pixelgen.json`,`art/characters/parque-pipeiros-runtime-v1/pacote/${id}/${id}-directions.png`,`godot/assets/npc-ds/${id}.png`)]})),
 ...['ronne','malvadocia','grunt-feminino','grunt-masculino'].map(id=>{const base=id.startsWith('grunt')?'cerol-grunts-overworld-v1':'cerol-overworld-v1';return {id,name:({ronne:'Ronne',malvadocia:'Malvadocia','grunt-feminino':'Grunt feminino','grunt-masculino':'Grunt masculino'})[id],role:id.startsWith('grunt')?'Grunt':'Líder',group:'Cerol Hunters',inGame:false,assets:[asset(id,'Overworld · 8 direções',`art/characters/${base}/pacote/${id}/${id}.pixelgen.json`,`art/characters/${base}/pacote/${id}/${id}-directions.png`)]};})
];
export const bindings=new Map(characters.flatMap(c=>c.assets.map(a=>[a.id,{...a,characterId:c.id,inGame:c.inGame}])));
