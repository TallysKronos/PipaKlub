export const WATERFALLS=[{id:'cachoeira-fina',name:'Cachoeira · fio de água',width:32},{id:'cachoeira-dupla',name:'Cachoeira · queda dupla',width:64},{id:'cachoeira-ampla',name:'Cachoeira · cortina ampla',width:96}].map(w=>({...w,waterfall:true,family:'Cachoeiras',anchor:[24,8]}));
export const isWaterfall=id=>WATERFALLS.some(w=>w.id===id);
