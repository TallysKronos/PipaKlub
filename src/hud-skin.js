// Attach skins to a separate decorative layer, never to the content itself.
export function mountHudSkin(layer, frame, atlas) {
 const spec=atlas.slices?.[frame];
 for(const piece of [...layer.children])if(piece.classList.contains('hud-slice'))piece.remove();
 layer.classList.toggle('hud-sliced',!!spec);
 if(!spec){delete layer.dataset.hudSkin;delete layer.dataset.hudSlice;return layer;}
 layer.dataset.hudSkin=frame;layer.dataset.hudSlice=spec.mode;
 const names=spec.mode==='three'?['l','c','r']:['tl','t','tr','l','c','r','bl','b','br'];
 for(const name of names){const piece=layer.ownerDocument.createElement('span');piece.className='hud-slice hud-slice-'+name;piece.setAttribute('aria-hidden','true');layer.append(piece);}
 return layer;
}
