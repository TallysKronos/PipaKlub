export function createLineStyles(){
 const items=[
  {id:'classic',name:'Linha clássica',price:0,colour:null,dash:[],glow:false},
  {id:'azul',name:'Azul do céu',price:30,colour:'#317bcc',dash:[],glow:false},
  {id:'coral',name:'Coral da laje',price:30,colour:'#d95643',dash:[],glow:false},
  {id:'menta',name:'Brisa de menta',price:40,colour:'#298c71',dash:[],glow:false},
  {id:'pontilhada',name:'Caminho de estrelas',price:60,colour:'#8755bb',dash:[3,6],glow:false},
  {id:'dourada',name:'Fio de luz',price:100,colour:'#c88a16',dash:[],glow:true}
 ];
 const get=id=>items.find(item=>item.id===id)||items[0];
 function apply(context,id,light=false){const style=get(id);if(style.colour)context.strokeStyle=style.colour;context.setLineDash(style.dash);if(style.glow&&!light){context.shadowColor=style.colour;context.shadowBlur=6;}}
 return {items,get,apply};
}
