export function mountView(rig,dir,width=600,height=600){
 const f=rig.directions[dir],zoom=Math.min(width,height)/600*2.6;
 return {f,zoom,x:width/2,y:height*.8833333333,seat:[(f.seat[0]-f.ground[0])*rig.scale,(f.seat[1]-f.ground[1])*rig.scale]};
}
export function insidePolygon(p,polygon=[]){let yes=false;for(let i=0,j=polygon.length-1;i<polygon.length;j=i++){const a=polygon[i],b=polygon[j];if((a[1]>p.y)!==(b[1]>p.y)&&p.x<(b[0]-a[0])*(p.y-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;}
export function mountPaintPoint(rig,dir,role,x,y,width=600,height=600,opaque){
 const v=mountView(rig,dir,width,height),f=v.f,wx=(x-v.x)/v.zoom,wy=(y-v.y)/v.zoom;
 if(role==='mount')return {x:wx/rig.scale+f.ground[0],y:wy/rig.scale+f.ground[1]};
 const dx=(wx-v.seat[0])/rig.riderScale,dy=(wy-v.seat[1])/rig.riderScale;
 const near={x:dx+f.hip[0],y:dy+f.hip[1]},a=-(f.farLegAngle||0)*Math.PI/180;
 const far={x:Math.cos(a)*dx-Math.sin(a)*dy+f.hip[0],y:Math.sin(a)*dx+Math.cos(a)*dy+f.hip[1]};
 const inCrop=p=>p.x>=0&&p.y>=0&&p.x<f.riderRect[2]&&p.y<f.riderRect[3];
 const nearValid=inCrop(near)&&!insidePolygon(near,f.farLeg),farValid=inCrop(far)&&insidePolygon(far,f.farLeg);
 if(nearValid&&(!opaque||opaque(near)||!farValid||!opaque(far)))return {...near,layer:'near'};
 if(farValid)return {...far,layer:'far'};
 return {x:0,y:0,blocked:true};
}
export function drawMountComposite(ctx,rig,dir,mount,rider,{edited,role,otherOpacity=1}={}){
 const {f,zoom,x,y,seat}=mountView(rig,dir,ctx.canvas.width,ctx.canvas.height);
 ctx.clearRect(0,0,ctx.canvas.width,ctx.canvas.height);ctx.save();ctx.translate(x,y);ctx.scale(zoom,zoom);
 function person(far){ctx.save();ctx.globalAlpha=role&&role!=='rider'?otherOpacity:1;ctx.translate(...seat);ctx.rotate(far?(f.farLegAngle||0)*Math.PI/180:0);ctx.scale(rig.riderScale,rig.riderScale);ctx.translate(-f.hip[0],-f.hip[1]);ctx.beginPath();if(!far)ctx.rect(0,0,f.riderRect[2],f.riderRect[3]);if(f.farLeg?.length){ctx.moveTo(...f.farLeg[0]);for(const p of f.farLeg.slice(1))ctx.lineTo(...p);ctx.closePath();}else if(far){ctx.restore();return;}ctx.clip(far?'nonzero':'evenodd');if(role==='rider'&&edited)ctx.drawImage(edited,0,0);else ctx.drawImage(rider,...f.riderRect,0,0,f.riderRect[2],f.riderRect[3]);ctx.restore();}
 function dog(neck=false){ctx.save();ctx.globalAlpha=role&&role!=='mount'?otherOpacity:1;ctx.scale(rig.scale,rig.scale);const r=neck?f.neck:[0,0,f.rect[2],f.rect[3]], [sx,sy,w,h]=r;const image=role==='mount'&&edited?edited:mount;const ox=role==='mount'&&edited?0:f.rect[0],oy=role==='mount'&&edited?0:f.rect[1];ctx.drawImage(image,ox+sx,oy+sy,w,h,sx-f.ground[0],sy-f.ground[1],w,h);ctx.restore();}
 person(true);dog();person(false);if(f.neck)dog(true);ctx.restore();
}
