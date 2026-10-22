// Construction data shared by the game, preview and tests. No constellation paths.
export const WORKSHOP_STAGES=[
 {id:'frame',name:'Armação',tool:'Varetas de bambu',title:'Dê estrutura ao corpo.',hint:'Toque nos quatro apoios da bancada em ordem, ou use os botões. O gabarito mantém a estrutura alinhada.',action:'Confirmar armação'},
 {id:'knots',name:'Nós',tool:'Linha e amarração',title:'Firme cada encontro.',hint:'Ajuste a tensão para 65. Um nó firme sustenta a vela sem apertar demais a armação.',action:'Firmar os nós'},
 {id:'paper',name:'Papel',tool:'Papel de seda',title:'Revele a forma do parceiro.',hint:'Siga os quatro pontos na bancada, ou use os botões, para recortar e aplicar cada parte do papel.',action:'Aplicar o papel'},
 {id:'balance',name:'Equilíbrio',tool:'Ponto de amarração',title:'Encontre o ponto de voo.',hint:'Mova o ponto de amarração até 50. Observe a inclinação da montagem e a estabilidade.',action:'Confirmar equilíbrio'},
 {id:'soul',name:'Elo',tool:'Rabiola da alma',title:'Uma alma. Um novo começo.',hint:'Equilibre vento e tensão em 50 e una a rabiola. A linha será o elo de manifestação.',action:'Unir rabiola e despertar'}
];
export function workshopInput(){return {joints:[],cuts:[],tension:35,balance:25,wind:35,soulTension:70};}
export function workshopPayload(stage,input){
 if(stage===0)return {joints:[...input.joints]};
 if(stage===1)return {tension:Number(input.tension)};
 if(stage===2)return {cuts:[...input.cuts]};
 if(stage===3)return {balance:Number(input.balance)};
 if(stage===4)return {wind:Number(input.wind),tension:Number(input.soulTension)};
 throw Error('Etapa de montagem inválida.');
}
export function workshopReady(stage,input){return stage===0?input.joints.length===4:stage===2?input.cuts.length===4:stage>=1&&stage<=4;}
export function validWorkshopPayload(stage,payload){
 if(!payload||typeof payload!=='object'||Array.isArray(payload))return false;
 if(stage===0||stage===2){const key=stage===0?'joints':'cuts';return Object.keys(payload).length===1&&Array.isArray(payload[key])&&payload[key].length===4&&payload[key].every((v,i)=>v===i);}
 const keys=stage===1?['tension']:stage===3?['balance']:stage===4?['wind','tension']:[];
 return keys.length>0&&Object.keys(payload).length===keys.length&&keys.every(k=>Number.isInteger(payload[k])&&payload[k]>=0&&payload[k]<=100);
}
export function workshopQuality(stage,input){return stage===1?Math.max(0,100-Math.abs(input.tension-65)*2):stage===3?Math.max(0,100-Math.abs(input.balance-50)*2):stage===4?Math.max(0,100-Math.abs(input.wind-50)-Math.abs(input.soulTension-50)):100;}
export function workshopPose(stage,input,time,reduced=false){
 const motion=reduced?0:1,settled=stage>=5;
 return {rise:settled?Math.sin(time*2)*4*motion:0,tilt:(stage===3?(input.balance-50)*.14:0)+Math.sin(time*1.8)*.8*motion*(settled?1:0),ear:Math.sin(time*2.3)*.025*motion,tail:Math.sin(time*2.3-.7)*.06*motion,glow:stage===4?(workshopQuality(stage,input)/100):settled?1:0};
}
