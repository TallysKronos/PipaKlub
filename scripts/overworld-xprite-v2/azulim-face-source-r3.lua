local root=assert(app.params.root)
local out=root..'/art/creatures/azulim-prancha-v1';local backup=out..'/antes-rosto-fonte-r3';local pc=app.pixelColor
local s=app.open(backup..'/azulim-prancha.aseprite');local layer=s.layers[3]
local approved=app.open(root..'/art/creatures/soulmonsters-overworld-v2/azulim/duas-vistas.png');local source=Image(approved.cels[1].image,Rectangle(0,0,112,112));approved:close()
local rows={[67]={54,61},[68]={52,62},[69]={52,63},[70]={52,64},[71]={52,64},[72]={51,64},[73]={51,64},[74]={51,64},[75]={51,64},[76]={51,64},[77]={51,63},[78]={51,61},[79]={51,59},[80]={51,58},[81]={52,58}}
local function head(x,y)
 if y>=58 and y<=66 then return x>=53 and x<=64 end
 local r=rows[y];return r and x>=r[1]and x<=r[2]or false
end
local function tail(x,y)return y>=82 and x>=45 and x<=58 end
local function protected(x,y)return head(x,y)or tail(x,y)end
local core=Image(112,112,ColorMode.RGB);local left=Image(112,112,ColorMode.RGB);local right=Image(112,112,ColorMode.RGB);local headMask=Image(112,112,ColorMode.RGB);local coreMask=Image(112,112,ColorMode.RGB)
for y=0,111 do for x=0,111 do local p=source:getPixel(x,y)
 if protected(x,y)then core:drawPixel(x,y,p);coreMask:drawPixel(x,y,pc.rgba(255,255,255,255));if head(x,y)then headMask:drawPixel(x,y,pc.rgba(255,255,255,255))end
 elseif x<53 then left:drawPixel(x,y,p)else right:drawPixel(x,y,p)end
end end
headMask:saveAs(out..'/rosto-original-mask-r3.png');coreMask:saveAs(out..'/core-original-mask-r3.png');source:saveAs(out..'/fonte-canonica-sw-r3.png')
local function rotate(im,pivot,degrees)
 local result=Image(112,112,ColorMode.RGB);local a=degrees*math.pi/180;local c,si=math.cos(a),math.sin(a)
 for y=0,111 do for x=0,111 do local dx,dy=x-pivot[1],y-pivot[2];local sx=math.floor(pivot[1]+dx*c+dy*si+.5);local sy=math.floor(pivot[2]-dx*si+dy*c+.5)
 if sx>=0 and sy>=0 and sx<112 and sy<112 then result:drawPixel(x,y,im:getPixel(sx,sy))end end end;return result
end
local audit={};local frameOffset={idle=0,walk=8};local durations={idle={750,200,750,200},walk={140,100,120,140,100,120}}
for _,action in ipairs({'idle','walk'})do local n=action=='idle'and 4 or 6;local result=Image{fromFile=backup..'/'..action..'.png'}
 for pose=1,n do
  local la,ra
  if action=='walk'then la=({0,-35,-75,-95,-50,-10})[pose];ra=({0,30,65,80,40,10})[pose]
  else la=({0,-8,-8,0})[pose];ra=-la end
  local flat=Image(112,112,ColorMode.RGB);flat:drawImage(rotate(left,{52,73},la));flat:drawImage(rotate(right,{63,73},ra))
  -- Positive canonical mask copied LAST, including transparent source pixels.
  for y=0,111 do for x=0,111 do if protected(x,y)then flat:drawPixel(x,y,source:getPixel(x,y))end end end
  local seen={};local crumbs=0
  for y=0,111 do for x=0,111 do local k=y*112+x
   if not seen[k]and pc.rgbaA(flat:getPixel(x,y))>0 then local g={{x,y}};local cursor=1;seen[k]=true
    while cursor<=#g do local p=g[cursor];cursor=cursor+1;for dy=-1,1 do for dx=-1,1 do local nx,ny=p[1]+dx,p[2]+dy;local nk=ny*112+nx
     if nx>=0 and ny>=0 and nx<112 and ny<112 and not seen[nk]and pc.rgbaA(flat:getPixel(nx,ny))>0 then seen[nk]=true;g[#g+1]={nx,ny}end
    end end end
    if #g<=2 then for _,p in ipairs(g)do if not protected(p[1],p[2])then flat:drawPixel(p[1],p[2],0);crumbs=crumbs+1 end end end
   end
  end end
  local diffs=0;for y=0,111 do for x=0,111 do if protected(x,y)and flat:getPixel(x,y)~=source:getPixel(x,y)then diffs=diffs+1 end end end;assert(diffs==0)
  local frame=frameOffset[action]+pose;s:deleteCel(layer:cel(frame));s:newCel(layer,frame,flat,Point(0,0));s.frames[frame].duration=durations[action][pose]/1000
  result:drawImage(flat,Point((pose-1)*112,0),255,BlendMode.SRC)
  audit[#audit+1]={action=action,pose=pose,canonical_head_and_core_differences=diffs,rotation_crumbs_removed=crumbs,left_angle=la,right_angle=ra}
 end
 result:saveAs(out..'/'..action..'.png')
end
s:saveAs(out..'/azulim-prancha.aseprite');s:close()
local saved=app.open(out..'/azulim-prancha.aseprite');local diffs=0;local fi=0
for _,action in ipairs({'idle','walk'})do local n=action=='idle'and 4 or 6;local im=Image{fromFile=out..'/'..action..'.png'}
 for row=0,1 do for pose=1,n do fi=fi+1;local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(saved,fi);for y=0,111 do for x=0,111 do if flat:getPixel(x,y)~=im:getPixel((pose-1)*112+x,row*112+y)then diffs=diffs+1 end end end end end
end
assert(diffs==0);saved:close()
local f=assert(io.open(out..'/rosto-original-audit-r3.json','w'));f:write(json.encode({frames=20,atlas_differences=diffs,source='soulmonsters-overworld-v2/azulim/duas-vistas.png',mask_method='positive canonical head/face/eyes/beak/crest and tail, copied including transparency LAST',sw=audit,nw_unmodified=true}));f:close();print('R3 canonical face restored;20 ASE frames exact')
