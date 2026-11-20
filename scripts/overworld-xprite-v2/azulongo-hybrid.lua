-- Azulongo: native segmented swimming poses, no raster warp.
local root=assert(app.params.root)
local out=root..'/art/creatures/azulongo-hibrido-v1'
app.fs.makeAllDirectories(out)
local opened=app.open(root..'/art/creatures/soulmonsters-overworld-v2/azulongo/duas-vistas.png')
local source=Image(opened.cels[1].image)
local palette=Palette(#opened.palettes[1]);for i=0,#opened.palettes[1]-1 do palette:setColor(i,opened.palettes[1]:getColor(i))end;opened:close()
local sprite=Sprite(112,112,ColorMode.RGB);sprite:setPalette(palette)
local layers={};local names={'placas-dorsais-reconstruidas','tronco-cauda-ondulantes','escamas-corda-e-nos','cabeca-peito-bracos-preservados'}
sprite.layers[1].name=names[1];layers[1]=sprite.layers[1];for i=2,#names do layers[i]=sprite:newLayer();layers[i].name=names[i]end
local function c(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
local C={ink=c('030c21'),deep=c('053581'),blue=c('0148a8'),light=c('0165c6'),cyan=c('01afdd'),cream=c('fae3b7'),shade=c('efc995'),sand=c('d6ad7d'),gold=c('fabf0a'),bright=c('fbe13c'),orange=c('e18602'),brown=c('bc6203')}
local function round(x)return math.floor(x+.5)end
local function pixel(im,x,y,color)x=round(x);y=round(y);if x>=0 and x<112 and y>=0 and y<112 then im:drawPixel(x,y,color)end end
local function line(im,a,b,color)
 local x,y=round(a[1]),round(a[2]);local tx,ty=round(b[1]),round(b[2]);local dx=math.abs(tx-x);local sx=x<tx and 1 or -1;local dy=-math.abs(ty-y);local sy=y<ty and 1 or -1;local e=dx+dy
 while true do pixel(im,x,y,color);if x==tx and y==ty then break end;local e2=2*e;if e2>=dy then e=e+dy;x=x+sx end;if e2<=dx then e=e+dx;y=y+sy end end
end
local function inside(x,y,p)
 local hit=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j];if (a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then hit=not hit end;j=i end
 return hit
end
local function poly(im,p,color,outline)
 local minx,miny,maxx,maxy=112,112,0,0
 for _,v in ipairs(p)do minx=math.min(minx,v[1]);miny=math.min(miny,v[2]);maxx=math.max(maxx,v[1]);maxy=math.max(maxy,v[2])end
 for y=math.floor(miny),math.ceil(maxy)do for x=math.floor(minx),math.ceil(maxx)do if inside(x+.5,y+.5,p)then pixel(im,x,y,color)end end end
 if outline then for i=1,#p do line(im,p[i],p[i%#p+1],outline)end end
end
local curves={
 {
  {{48,70},{51,77},{52,84},{47,91},{39,96}},
  {{48,70},{52,77},{55,84},{52,91},{45,96}},
  {{48,70},{50,78},{52,85},{55,91},{62,95}},
  {{48,70},{46,78},{48,85},{55,91},{63,94}},
  {{48,70},{45,77},{44,84},{47,92},{54,96}},
  {{48,70},{46,77},{46,84},{42,91},{35,96}}
 },
 {
  {{57,70},{58,77},{62,84},{69,91},{75,96}},
  {{57,70},{59,77},{65,84},{73,88},{81,92}},
  {{57,70},{58,78},{64,85},{72,90},{80,93}},
  {{57,70},{56,78},{58,85},{65,92},{73,96}},
  {{57,70},{55,77},{54,84},{59,91},{66,96}},
  {{57,70},{56,77},{57,84},{64,90},{72,96}}
 }
}
local function catmull(a,b,c,d,t)
 local t2,t3=t*t,t*t*t
 return { .5*((2*b[1])+(-a[1]+c[1])*t+(2*a[1]-5*b[1]+4*c[1]-d[1])*t2+(-a[1]+3*b[1]-3*c[1]+d[1])*t3),.5*((2*b[2])+(-a[2]+c[2])*t+(2*a[2]-5*b[2]+4*c[2]-d[2])*t2+(-a[2]+3*b[2]-3*c[2]+d[2])*t3)}
end
local function nodes(curve)
 local samples={}
 for i=1,#curve-1 do
  for step=0,3 do
   if i==1 or step>0 then samples[#samples+1]=catmull(curve[math.max(1,i-1)],curve[i],curve[i+1],curve[math.min(#curve,i+2)],step/3)end
  end
 end
 for i,p in ipairs(samples)do
  local a,b=samples[math.max(1,i-1)],samples[math.min(#samples,i+1)]
  local dx,dy=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dy*dy)
  p.nx,p.ny=dy/length,-dx/length
  p.width=6.4-(i-1)/(#samples-1)*3.6
 end
 return samples
end
local function band(im,samples,side,outer,inner,color,outline)
 local p={}
 for _,s in ipairs(samples)do p[#p+1]={s[1]+side*s.nx*s.width*outer,s[2]+side*s.ny*s.width*outer}end
 for i=#samples,1,-1 do local s=samples[i];p[#p+1]={s[1]+side*s.nx*s.width*inner,s[2]+side*s.ny*s.width*inner}end
 poly(im,p,color,outline)
end
local function body(fins,skin,details,curve,side)
 local s=nodes(curve)
 for _,i in ipairs({2,4,6,8,10,12})do
  local p=s[i];local before=s[math.max(1,i-1)];local after=s[math.min(#s,i+1)]
  local dorsal=-side
  local tx,ty=-p.ny,p.nx
  local function q(t,n)return{p[1]+tx*t+dorsal*p.nx*n,p[2]+ty*t+dorsal*p.ny*n}end
  local anchor=q(0,p.width*.65)
  local tip=q(2,p.width+6)
  poly(fins,{q(-3,p.width*.5),q(-2,p.width+3),tip,q(4,p.width+2),q(3,p.width*.6)},C.light,C.ink)
  poly(fins,{anchor,q(-1,p.width+2),q(2,p.width+5),q(3,p.width+2),q(2,p.width*.7)},C.cyan)
 end
 band(skin,s,side,1,-1,C.blue,C.ink)
 band(skin,s,side,.83,-.25,C.cream)
 band(skin,s,side,.83,.50,C.shade)
 band(skin,s,-side,.82,.36,C.light)
 for i=2,#s-1,2 do
  local p=s[i]
  line(details,{p[1]+side*p.nx*p.width*.65,p[2]+side*p.ny*p.width*.65},{p[1]+side*p.nx*p.width*.05,p[2]+side*p.ny*p.width*.05},C.sand)
 end
 for i=1,#s-1 do
  local a,b=s[i],s[i+1]
  local aa={a[1]-side*a.nx*a.width*.35,a[2]-side*a.ny*a.width*.35}
  local bb={b[1]-side*b.nx*b.width*.35,b[2]-side*b.ny*b.width*.35}
  line(details,{aa[1]-1,aa[2]},{bb[1]-1,bb[2]},C.brown)
  line(details,aa,bb,C.gold)
 end
 for _,i in ipairs({2,6,10})do
  local p=s[i];local x,y=round(p[1]-side*p.nx*p.width*.35),round(p[2]-side*p.ny*p.width*.35)
  for dy=-1,1 do for dx=-1,1 do pixel(details,x+dx,y+dy,C.orange)end end
  pixel(details,x,y-1,C.bright);pixel(details,x+1,y-1,C.bright);pixel(details,x,y,C.gold)
 end
 -- The final paper point is attached to the last scale, never a detached ornament.
 local tip=s[#s];local previous=s[#s-1]
 poly(fins,{{previous[1]-side*previous.nx*3,previous[2]-side*previous.ny*3},{tip[1]-side*tip.nx*4,tip[2]-side*tip.ny*4},{tip[1]+(tip[1]-previous[1])*.7,tip[2]+(tip[2]-previous[2])*.7},{tip[1]+side*tip.nx,tip[2]+side*tip.ny}},C.cyan,C.ink)
 return s
end
local poses={};local frame=0
for _,action in ipairs({'idle','walk'})do
 local count=action=='idle'and 4 or 6
 local atlas=Image(count*112,224,ColorMode.RGB)
 for view=1,2 do
  local src=Image(source,Rectangle((view-1)*112,0,112,112))
  local core=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do
   local keep=y<70
   if view==1 and y<82 and x>=57 then keep=true end
   if view==2 and y<80 and x<49 then keep=true end
   if view==2 and y<81 and x>=54 and x<=60 then keep=true end
   if keep then core:drawPixel(x,y,src:getPixel(x,y))end
  end end
  for pose=1,count do
   frame=frame+1;if frame>1 then sprite:newEmptyFrame()end
   sprite.frames[frame].duration=action=='walk'and({.14,.10,.12,.14,.10,.12})[pose]or({.40,.15,.40,.15})[pose]
   local curve={}
   for i,p in ipairs(curves[view][action=='walk'and pose or 1])do
    local dx=action=='idle'and({0,1,2,1})[pose]*(i-1)/4 or 0
    curve[i]={p[1]+dx,p[2]}
   end
   local fins,skin,details=Image(112,112,ColorMode.RGB),Image(112,112,ColorMode.RGB),Image(112,112,ColorMode.RGB)
   local centerline=body(fins,skin,details,curve,view==1 and 1 or -1)
   sprite:newCel(layers[1],frame,fins,Point(0,0));sprite:newCel(layers[2],frame,skin,Point(0,0));sprite:newCel(layers[3],frame,details,Point(0,0));sprite:newCel(layers[4],frame,core,Point(0,0))
   local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,frame);atlas:drawImage(flat,Point((pose-1)*112,(view-1)*112))
   poses[#poses+1]={action=action,view=view==1 and'sw'or'nw',pose=pose,curve=curve}
  end
  local tag=sprite:newTag(frame-count+1,frame);tag.name=action..(view==1 and'-sw'or'-nw')
 end
 atlas:saveAs(out..'/'..action..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/azulongo-hibrido.aseprite')
local data=assert(io.open(out..'/poses.json','w'));data:write(json.encode(poses));data:close()
sprite:close()
print('Azulongo native hybrid: 20 frames; articulated segmented centerline; preserved source head.')
