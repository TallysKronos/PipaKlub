// Detail pages keep the creature and identity on screen while only the reading area scrolls.
// DOM nodes are moved, not cloned: existing renderers and server actions keep their references.
export function createDetailPages(root,{id,label,pages,onChange=()=>{}}){
 const doc=root.ownerDocument,bar=doc.createElement('nav'),body=doc.createElement('div');
 bar.className='pilot-detail-tabs';bar.setAttribute('role','tablist');bar.setAttribute('aria-label',label);bar.dataset.detailTabs=id;
 body.className='pilot-detail-body';
 let active=0;
 const panels=pages.map((page,i)=>{
  const tab=doc.createElement('button');tab.type='button';tab.id=id+'-tab-'+i;tab.textContent=page.label;
  tab.setAttribute('role','tab');tab.setAttribute('aria-controls',id+'-page-'+i);
  const panel=doc.createElement('section');panel.id=id+'-page-'+i;panel.className='pilot-detail-page';panel.tabIndex=0;
  panel.setAttribute('role','tabpanel');panel.setAttribute('aria-labelledby',tab.id);
  for(const node of page.nodes||[])if(node)panel.append(node);
  tab.onclick=()=>select(i);
  tab.onkeydown=e=>{
   if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){
    e.preventDefault();e.stopPropagation();select(e.key==='Home'?0:e.key==='End'?pages.length-1:active+(e.key==='ArrowRight'?1:-1),true);
   }else if(e.key==='ArrowDown'){e.preventDefault();e.stopPropagation();panel.focus({preventScroll:true});}
  };
  panel.onkeydown=e=>{
   if(e.target!==panel)return;
   if(e.key==='ArrowLeft'){e.preventDefault();e.stopPropagation();tabs[active].focus({preventScroll:true});return;}
   if(['ArrowUp','ArrowDown','PageUp','PageDown','Home','End'].includes(e.key)){
    e.preventDefault();e.stopPropagation();
    const amount=e.key==='Home'?-panel.scrollHeight:e.key==='End'?panel.scrollHeight:(e.key.endsWith('Up')?-1:1)*(e.key.startsWith('Page')?panel.clientHeight*.8:56);
    panel.scrollTop+=amount;
   }
  };
  bar.append(tab);body.append(panel);return panel;
 });
 const tabs=[...bar.children];
 function select(index,focus=false){
  active=(index+pages.length)%pages.length;
  tabs.forEach((tab,i)=>{tab.setAttribute('aria-selected',String(i===active));tab.tabIndex=i===active?0:-1;panels[i].hidden=i!==active;});
  if(focus)tabs[active].focus({preventScroll:true});
  onChange(active);return panels[active];
 }
 root.classList.add('pilot-paged-detail');root.append(bar,body);select(0);
 return {bar,body,panels,select,step:(n,focus=true)=>select(active+n,focus),get active(){return active;}};
}
