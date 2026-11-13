-- Specific reconstructed pixel poses. Video guides gait; it supplies no pixels.
local root=assert(app.params.root)
local out=root..'/art/creatures/viuva-young-hibrido-v1'
app.fs.makeAllDirectories(out)
local opened=app.open(root..'/art/creatures/soulmonsters-overworld-v2/viuva-young/duas-vistas.png')
local source=Image(opened.cels[1].image)
local palette=Palette(#opened.palettes[1])
for i=0,#opened.palettes[1]-1 do palette:setColor(i,opened.palettes[1]:getColor(i)) end
opened:close()
local sprite=Sprite(112,112,ColorMode.RGB);sprite:setPalette(palette)
local layers={}
local names={'pata-distante-1','pata-distante-2','pata-distante-3','pata-proxima-1','pata-proxima-2','pata-proxima-3','corpo-rosto-asas-preservados'}
sprite.layers[1].name=names[1];layers[1]=sprite.layers[1]
for i=2,#names do layers[i]=sprite:newLayer();layers[i].name=names[i] end
local function rgba(r,g,b)return app.pixelColor.rgba(r,g,b,255)end
local C={outline=rgba(2,1,1),shadow=rgba(51,35,46),shade=rgba(62,44,55),bone=rgba(251,233,210),far=rgba(241,214,189),light=rgba(253,251,239),red=rgba(213,16,55),hot=rgba(248,40,76),darkred=rgba(176,14,44)}
local function round(v)return math.floor(v+.5)end
local function pixel(im,x,y,c)x=round(x);y=round(y);if x>=0 and x<112 and y>=0 and y<112 then im:drawPixel(x,y,c) end end
local function line(im,a,b,c)
 local x,y=round(a[1]),round(a[2]);local tx,ty=round(b[1]),round(b[2]);local dx=math.abs(tx-x);local sx=x<tx and 1 or -1;local dy=-math.abs(ty-y);local sy=y<ty and 1 or -1;local err=dx+dy
 while true do pixel(im,x,y,c);if x==tx and y==ty then break end;local e=2*err;if e>=dy then err=err+dy;x=x+sx end;if e<=dx then err=err+dx;y=y+sy end end
end
local function inside(x,y,p)
 local hit=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j];if (a[2]>y)~=(b[2]>y) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then hit=not hit end;j=i end
 return hit
end
local function poly(im,p,c,outline)
 local minx,miny,maxx,maxy=112,112,0,0
 for _,v in ipairs(p) do minx=math.min(minx,v[1]);miny=math.min(miny,v[2]);maxx=math.max(maxx,v[1]);maxy=math.max(maxy,v[2]) end
 for y=math.floor(miny),math.ceil(maxy) do for x=math.floor(minx),math.ceil(maxx) do if inside(x+.5,y+.5,p) then pixel(im,x,y,c) end end end
 if outline then for i=1,#p do line(im,p[i],p[i%#p+1],outline) end end
end
local function bone(im,a,b,width,far,taper)
 local dx,dy=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dy*dy);local nx,ny=-dy/length,dx/length
 local tip=taper and .25 or width*.38
 local p={{a[1]+nx*width*.5,a[2]+ny*width*.5},{b[1]+nx*tip,b[2]+ny*tip},{b[1]-nx*tip,b[2]-ny*tip},{a[1]-nx*width*.5,a[2]-ny*width*.5}}
 poly(im,p,far and C.far or C.bone,C.outline)
 -- Single darker edge and a warm-lit interior; no filtering or new colours.
 if length>5 then line(im,{a[1]+.6,a[2]+1},{b[1]+.5,b[2]-(taper and 2 or 1)},C.shadow) end
 if length>7 then line(im,{a[1]-.5,a[2]+1},{b[1]-.5,b[2]-3},far and C.far or C.bone) end
end
local rigs={
 {
  core={{{33,63},{43,63},{47,69},{46,78},{41,84},{35,82},{32,77}},{{50,68},{62,67},{68,73},{67,79},{59,82},{51,77}}},
  legs={
   {r={47,73},k={40,77},a={39,83},t={38,89},phase=3,far=true},
   {r={65,72},k={72,75},a={74,81},t={78,88},phase=0,far=true},
   {r={37,76},k={31,79},a={28,85},t={25,91},phase=0,fur=true},
   {r={52,75},k={47,79},a={45,86},t={44,96},phase=3},
   {r={62,74},k={66,79},a={69,86},t={71,96},phase=0},
   {r={59,76},k={55,80},a={54,87},t={53,98},phase=3}
  }
 },
 {
  core={{{43,61},{59,60},{65,66},{65,72},{60,79},{53,81},{46,77},{43,69}},{{62,65},{74,66},{81,72},{83,80},{80,86},{71,88},{65,85},{61,78}}},
  legs={
   {r={62,70},k={66,73},a={67,79},t={64,85},phase=0,far=true},
   {r={46,72},k={40,76},a={38,81},t={36,88},phase=3,far=true},
   {r={51,73},k={46,78},a={44,86},t={42,95},phase=0},
   {r={61,74},k={63,80},a={64,87},t={67,95},phase=3},
   {r={75,80},k={82,83},a={85,88},t={85,95},phase=0,fur=true},
   {r={56,74},k={53,79},a={52,88},t={54,98},phase=3}
  }
 }
}
-- Six authored contact/down/push/lift/pass/reach keys, rather than a pixel warp.
local keys={
 {k={-1,0},a={-2,1},t={-3,1},support=true},
 {k={0,0},a={0,0},t={0,0},support=true},
 {k={1,0},a={2,-1},t={3,-1},support=true},
 {k={1,-1},a={2,-3},t={3,-3},support=false},
 {k={0,-2},a={-1,-4},t={0,-5},support=false},
 {k={-1,-1},a={-2,-1},t={-3,-2},support=false}
}
local function plus(a,b)return {a[1]+b[1],a[2]+b[2]}end
local tags,documented={},{};local frame=0
for _,action in ipairs({'idle','walk'}) do
 local count=action=='walk' and 6 or 4
 local atlas=Image(count*112,224,ColorMode.RGB)
 for view=1,2 do
  local rig=rigs[view];local src=Image(source,Rectangle((view-1)*112,0,112,112));local core=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do
   if y<70 or inside(x,y,rig.core[1]) or inside(x,y,rig.core[2]) then core:drawPixel(x,y,src:getPixel(x,y)) end
  end end
  for pose=1,count do
   frame=frame+1;if frame>1 then sprite:newEmptyFrame() end
   sprite.frames[frame].duration=action=='walk' and ({.14,.10,.12,.14,.10,.12})[pose] or ({.40,.15,.40,.15})[pose]
   local record={action=action,view=view==1 and 'sw' or 'nw',pose=pose,legs={}}
   for n,leg in ipairs(rig.legs) do
    local key=keys[(pose-1+leg.phase)%6+1]
    if action=='idle' then
     key={k={0,pose==2 or pose==3 and -1 or 0},a={0,pose==3 or pose==4 and -1 or 0},t={0,0},support=true}
     key.k[2]=(pose==2 or pose==3) and -1 or 0;key.a[2]=(pose==3 or pose==4) and -1 or 0
    end
    local r,k,a,t=leg.r,plus(leg.k,key.k),plus(leg.a,key.a),plus(leg.t,key.t)
    local im=Image(112,112,ColorMode.RGB)
    bone(im,r,k,4,leg.far,false);bone(im,k,a,3.5,leg.far,false);bone(im,a,t,3,leg.far,true)
    poly(im,{{a[1]-2,a[2]-1},{a[1]+1,a[2]-2},{a[1]+2,a[2]+1},{a[1]-1,a[2]+2}},C.red,C.darkred)
    line(im,{a[1]-1,a[2]-1},{a[1]+1,a[2]-1},C.hot)
    if leg.fur then
     poly(im,{{t[1]-2,t[2]-3},{t[1]+1,t[2]-4},{t[1]+3,t[2]-1},{t[1]+2,t[2]+2},{t[1],t[2]+3},{t[1]-3,t[2]+1}},C.shadow,C.outline)
     line(im,{t[1]+1,t[2]-2},{t[1]+1,t[2]+1},C.far)
     pixel(im,t[1]-1,t[2]+1,C.shade)
    end
    sprite:newCel(layers[n],sprite.frames[frame],im,Point(0,0))
    record.legs[#record.legs+1]={root=r,knee=k,cuff=a,toe=t,support=key.support}
   end
   sprite:newCel(layers[7],sprite.frames[frame],core,Point(0,0))
   local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,frame)
   atlas:drawImage(flat,Point((pose-1)*112,(view-1)*112));documented[#documented+1]=record
  end
  tags[#tags+1]={name=action..(view==1 and '-sw' or '-nw'),first=frame-count+1,last=frame}
 end
 atlas:saveAs(out..'/'..action..'.png')
end
for _,t in ipairs(tags) do local tag=sprite:newTag(t.first,t.last);tag.name=t.name end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/viuva-young-hibrido.aseprite')
local record=assert(io.open(out..'/poses.json','w'));record:write(json.encode(documented));record:close()
print('HYBRID:20frames;6drawn leg chains;source core preserved;no generated pixels')
