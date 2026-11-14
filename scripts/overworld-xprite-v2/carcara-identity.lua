local root=assert(app.params.root)
local out=root..'/art/creatures/carcara-hibrido-v1';app.fs.makeAllDirectories(out)
local input=app.open(root..'/art/creatures/soulmonsters-overworld-v2/carcara/duas-vistas.png');local source=Image(input.cels[1].image);input:close()
local sprite=Sprite(112,112,ColorMode.RGB);sprite.layers[1].name='asas-articuladas-fonte';local wingsLayer=sprite.layers[1];local coreLayer=sprite:newLayer();coreLayer.name='identidade-original-bloqueada'
local function inside(x,y,p)local hit=false;local j=#p;for i=1,#p do local a,b=p[i],p[j];if(a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then hit=not hit end;j=i end;return hit end
local rigs={
 {body={{44,61},{56,50},{70,62},{58,80},{54,80}},l={45,65},r={67,64}},
 {body={{43,61},{55,50},{69,61},{60,80},{55,80}},l={46,66},r={66,63}}
}
local function wingSide(x,y,rig)
 if y<54 or y>77 or inside(x+.5,y+.5,rig.body)then return 0 end
 return x<56 and 1 or 2
end
local function rotate(src,pivot,angle)
 local im=Image(112,112,ColorMode.RGB);local a=angle*math.pi/180;local c,s=math.cos(a),math.sin(a)
 for y=0,111 do for x=0,111 do
  local dx,dy=x-pivot[1],y-pivot[2];local sx=math.floor(pivot[1]+dx*c+dy*s+.5);local sy=math.floor(pivot[2]-dx*s+dy*c+.5)
  if sx>=0 and sx<112 and sy>=0 and sy<112 then local v=src:getPixel(sx,sy);if app.pixelColor.rgbaA(v)>0 then im:drawPixel(x,y,v)end end
 end end;return im
end
local cleanup={['1:1']={{65,78},{65,79}},['1:3']={{48,53},{47,54},{63,53},{64,53},{65,53},{64,54},{65,54}},['1:4']={{42,61},{44,56},{44,57},{43,58},{66,53},{67,53},{68,53},{66,54},{67,54},{45,53},{44,54},{45,54}},['1:5']={{48,53}},['2:1']={{66,78},{67,74}},['2:2']={{63,77}},['2:3']={{46,55},{45,56},{47,54}},['2:4']={{43,55},{43,56},{44,54}},['2:6']={{64,78}}}
local records={};local frame=0
for _,action in ipairs({'idle','walk'})do local count=action=='idle'and 4 or 6;local atlas=Image(count*112,224,ColorMode.RGB)
 for view=1,2 do
  local rig=rigs[view];local src=Image(source,Rectangle((view-1)*112,0,112,112));local core=Image(112,112,ColorMode.RGB);local parts={Image(112,112,ColorMode.RGB),Image(112,112,ColorMode.RGB)};local mask=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do local p=src:getPixel(x,y);local side=wingSide(x,y,rig);if side>0 then parts[side]:drawPixel(x,y,p)else core:drawPixel(x,y,p);if app.pixelColor.rgbaA(p)>0 then mask:drawPixel(x,y,app.pixelColor.rgba(255,255,255,255))end end end end
  if action=='idle'then src:saveAs(out..'/fonte-'..(view==1 and'sw'or'nw')..'.png');mask:saveAs(out..'/core-mask-'..(view==1 and'sw'or'nw')..'.png')end
  for pose=1,count do frame=frame+1;if frame>1 then sprite:newEmptyFrame()end
   local durations=action=='idle'and{750,200,750,200}or{140,100,120,140,100,120};sprite.frames[frame].duration=durations[pose]/1000
   local wings=Image(112,112,ColorMode.RGB);local corePose=Image(core)
   if action=='idle'then local a=(pose==2 or pose==3)and 3 or 0;wings:drawImage(rotate(parts[1],rig.l,-a));wings:drawImage(rotate(parts[2],rig.r,a))
   else local angle=({-20,-7,12,24,8,-10})[pose];wings:drawImage(rotate(parts[1],rig.l,-angle));wings:drawImage(rotate(parts[2],rig.r,angle))end
   if action=='walk'then for _,p in ipairs(cleanup[view..':'..pose]or{})do assert(app.pixelColor.rgbaA(corePose:getPixel(p[1],p[2]))==0);wings:drawPixel(p[1],p[2],0)end end
   sprite:newCel(wingsLayer,frame,wings,Point(0,0));sprite:newCel(coreLayer,frame,corePose,Point(0,0));local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,frame);atlas:drawImage(flat,Point((pose-1)*112,(view-1)*112));records[#records+1]={action=action,view=view==1 and'sw'or'nw',pose=pose}
  end
  local tag=sprite:newTag(frame-count+1,frame);tag.name=action..(view==1 and'-sw'or'-nw')
 end
 atlas:saveAs(out..'/'..action..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/carcara-hibrido.aseprite');sprite:close()
local reopened=app.open(out..'/carcara-hibrido.aseprite');local differences=0;local fi=0
for _,action in ipairs({'idle','walk'})do local n=action=='idle' and 4 or 6;local atlas=Image{fromFile=out..'/'..action..'.png'};for view=1,2 do for pose=1,n do fi=fi+1;local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(reopened,fi);for y=0,111 do for x=0,111 do if flat:getPixel(x,y)~=atlas:getPixel((pose-1)*112+x,(view-1)*112+y)then differences=differences+1 end end end end end end
local qa=assert(io.open(out..'/auditoria-aseprite.json','w'));qa:write(json.encode({frames=#reopened.frames,layers=#reopened.layers,tags=#reopened.tags,atlas_differences=differences}));qa:close();reopened:close()
local doc=assert(io.open(out..'/poses.json','w'));doc:write(json.encode(records));doc:close();print('Carcara identity locked:20 frames')
