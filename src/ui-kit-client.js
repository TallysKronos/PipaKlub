/* Decorate existing controls without replacing nodes, listeners or game state. */
function applyUnifiedKit(root=document){
 const match=selector=>[...(root.matches?.(selector)?[root]:[]),...root.querySelectorAll(selector)];
 for(const [skin,selector] of Object.entries(uiKitSurfaces))for(const element of match(selector))element.dataset.kitSurface=skin;
 for(const button of match('button.primary,button.secondary,.journey-actions button,.home-command,.home-footer button,.home-list button,.home-menu-close')){
  if(button.matches('.home-tile,.scene-destination,.city-region,.portrait-card,.dex-entry,.club-tile')||button.closest('.combat-deck,.action-fan'))continue;
  button.dataset.kitButton=button.classList.contains('primary')?'primary':'secondary';
 }
}
applyUnifiedKit();
let kitPending=false;const kitRoots=new Set();
new MutationObserver(records=>{for(const record of records)for(const node of record.addedNodes)if(node.nodeType===1)kitRoots.add(node);
 if(!kitRoots.size||kitPending)return;kitPending=true;Promise.resolve().then(()=>{for(const root of kitRoots)if(root.isConnected)applyUnifiedKit(root);kitRoots.clear();kitPending=false;});
}).observe(document.body,{childList:true,subtree:true});
document.body.classList.add('ui-kit-ready');

// Continue the scene behind aspect-preserving foreground artwork.
for(const [selector,key] of [['.courtyard','home'],['.city-screen','city']]){
 const scene=document.querySelector(selector),url=ART_CONFIG.courtyard?.images?.[key]?.url;
 if(scene&&url)scene.style.setProperty('--scene-backdrop','url('+JSON.stringify(url)+')');
}
