// Shared presentation: one silhouette, image mask and typography for every signature.
function createSignatureBanner(parent,images){
 // Warm the local illustrations before the short combat announcement begins.
 const loadedImages=Object.values(images).map(asset=>{const img=new Image();img.src=asset.url;return img;});
 const root=document.createElement('aside');root.className='signature-banner';root.hidden=true;root.setAttribute('role','status');root.setAttribute('aria-live','polite');
 root.innerHTML='<div class="signature-cut"><div class="signature-picture"><img alt=""></div><div class="signature-grain" aria-hidden="true"></div><div class="signature-copy"><small>GOLPE DE ASSINATURA</small><span class="signature-mon"></span><strong></strong><p></p></div><span class="signature-diamond" aria-hidden="true">◆</span></div>';
 parent.append(root);let timer=0,generation=0;
 function hide(){clearTimeout(timer);generation++;root.hidden=true;root.classList.remove('signature-enter');}
 function show(id,{enemy=false,duration=820,preview=false}={}){
  const asset=images[id];if(!asset)return;hide();const version=generation;root.dataset.tone=asset.tone;root.dataset.enemy=String(enemy);root.dataset.preview=String(preview);
  const img=root.querySelector('img');img.src=asset.url;img.style.objectPosition=asset.focus;root.querySelector('.signature-mon').textContent=asset.name;root.querySelector('strong').textContent=asset.move;
  root.querySelector('p').textContent=preview?'Cada elo tem sua própria força.':enemy?'Impacto chegando · prepare a guarda (G)':'Seu elo ganha força!';
  root.hidden=false;void root.offsetWidth;root.classList.add('signature-enter');
  if(!preview)timer=setTimeout(()=>{if(generation===version)hide();},duration);
 }
 return {root,show,hide,loadedImages};
}
