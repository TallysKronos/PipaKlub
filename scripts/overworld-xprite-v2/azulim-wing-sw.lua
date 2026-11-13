local root=assert(app.params.root)
local out=root..'/art/creatures/azulim-prancha-v1';local backup=out..'/antes-asa-sw-nativa-r2'
local s=app.open(backup..'/azulim-prancha.aseprite');local pc=app.pixelColor
local atlas={idle=Image{fromFile=backup..'/idle.png'},walk=Image{fromFile=backup..'/walk.png'}}
local layer=s.layers[3]
local function alpha(p)return pc.rgbaA(p)>0 end
local function rotate(part,pivot,degrees)
 local im=Image(112,112,ColorMode.RGB);local a=degrees*math.pi/180;local c,si=math.cos(a),math.sin(a)
 for y=0,111 do for x=0,111 do local dx,dy=x-pivot[1],y-pivot[2];local sx=math.floor(pivot[1]+dx*c+dy*si+.5);local sy=math.floor(pivot[2]-dx*si+dy*c+.5)
 if sx>=0 and sy>=0 and sx<112 and sy<112 then im:drawPixel(x,y,part:getPixel(sx,sy))end end end;return im
end
local audit={};local frameOffset={idle=0,walk=8};local durations={idle={750,200,750,200},walk={140,100,120,140,100,120}}
for _,action in ipairs({'idle','walk'})do local n=action=='idle'and 4 or 6;local result=Image(atlas[action])
 for pose=1,n do
  local original=Image(atlas[action],Rectangle((pose-1)*112,0,112,112));local core=Image(112,112,ColorMode.RGB);local l=Image(112,112,ColorMode.RGB);local r=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do local p=original:getPixel(x,y)
   if x<=49 and y>=60 and y<=76 then l:drawPixel(x,y,p)
   elseif x>=63 and y>=64 and y<=85 then r:drawPixel(x,y,p)
   else core:drawPixel(x,y,p)end
  end end
  local la,ra
  if action=='walk'then la=({0,-40,-85,-100,-55,-15})[pose];ra=({0,35,70,85,45,10})[pose]
  else la=({0,-10,-10,0})[pose];ra=-la end
  local wings=Image(112,112,ColorMode.RGB);wings:drawImage(rotate(l,{50,75},la));wings:drawImage(rotate(r,{62,76},ra))
  local flat=Image(wings);flat:drawImage(core)
  -- Delete only disconnected rotation crumbs, never preserved source core.
  local seen={};local removed=0
  for y=0,111 do for x=0,111 do local k=y*112+x
   if not seen[k]and alpha(flat:getPixel(x,y))then local group={{x,y}};local cursor=1;seen[k]=true
    while cursor<=#group do local p=group[cursor];cursor=cursor+1
     for dy=-1,1 do for dx=-1,1 do local nx,ny=p[1]+dx,p[2]+dy;local nk=ny*112+nx
      if nx>=0 and ny>=0 and nx<112 and ny<112 and not seen[nk]and alpha(flat:getPixel(nx,ny))then seen[nk]=true;group[#group+1]={nx,ny}end
     end end
    end
    if #group<=2 then for _,p in ipairs(group)do if not alpha(core:getPixel(p[1],p[2]))then flat:drawPixel(p[1],p[2],0);removed=removed+1 end end end
   end
  end end
  local diffs=0;for y=0,111 do for x=0,111 do if alpha(core:getPixel(x,y))and core:getPixel(x,y)~=flat:getPixel(x,y)then diffs=diffs+1 end end end;assert(diffs==0)
  local frame=frameOffset[action]+pose;local cel=layer:cel(frame);s:deleteCel(cel);s:newCel(layer,frame,flat,Point(0,0));s.frames[frame].duration=durations[action][pose]/1000
  result:drawImage(flat,Point((pose-1)*112,0),255,BlendMode.SRC)
  local mask=Image(112,112,ColorMode.RGB);for y=0,111 do for x=0,111 do if alpha(core:getPixel(x,y))then mask:drawPixel(x,y,pc.rgba(255,255,255,255))end end end
  mask:saveAs(out..'/core-mask-'..action..'-sw-'..pose..'.png')
  audit[#audit+1]={action=action,view='sw',pose=pose,left_angle=la,right_angle=ra,core_differences=diffs,rotation_crumbs_removed=removed}
 end
 result:saveAs(out..'/'..action..'.png')
end
s:saveAs(out..'/azulim-prancha.aseprite');s:close()
local reopened=app.open(out..'/azulim-prancha.aseprite');local diffs=0;local fi=0
for _,action in ipairs({'idle','walk'})do local n=action=='idle'and 4 or 6;local im=Image{fromFile=out..'/'..action..'.png'}
 for row=0,1 do for pose=1,n do fi=fi+1;local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(reopened,fi);for y=0,111 do for x=0,111 do if flat:getPixel(x,y)~=im:getPixel((pose-1)*112+x,row*112+y)then diffs=diffs+1 end end end end end
end
assert(diffs==0,'ASE export mismatch');reopened:close()
local f=assert(io.open(out..'/asas-sw-nativas-audit.json','w'));f:write(json.encode({frames=20,core=audit,atlas_differences=diffs,nw_unmodified=true}));f:close();print('Azulim SW wing keys complete; core exact and ASE exact')
