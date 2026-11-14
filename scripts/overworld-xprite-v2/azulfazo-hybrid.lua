-- Azulfazo: pose geometry authored directly on the final pixel grid.
-- Video reference supplies timing and joint directions, never raster pixels.
local root=assert(app.params.root)
local out=root..'/art/creatures/azulfazo-hibrido-v1'
app.fs.makeAllDirectories(out)
local opened=app.open(root..'/art/creatures/soulmonsters-overworld-v2/azulfazo/duas-vistas.png')
local source=Image(opened.cels[1].image)
local palette=Palette(#opened.palettes[1])
for i=0,#opened.palettes[1]-1 do palette:setColor(i,opened.palettes[1]:getColor(i)) end
opened:close()
local sprite=Sprite(112,112,ColorMode.RGB)
sprite:setPalette(palette)
local layers={}
local names={'asa-distante-desenhada','asa-proxima-desenhada','pernas-garras-reconstruidas','corpo-rosto-cauda-preservados','nos-das-asas'}
sprite.layers[1].name=names[1];layers[1]=sprite.layers[1]
for i=2,#names do layers[i]=sprite:newLayer();layers[i].name=names[i] end
local function color(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
local C={ink=color('172644'),black=color('000109'),deep=color('022fa0'),blue=color('0b41b3'),light=color('1f6ded'),sky=color('3685f5'),cream=color('f9dbac'),bright=color('fbe9cd'),sand=color('d9b08b'),dark=color('453742'),brown=color('c17731'),gold=color('f0a92b'),sun=color('fbdc5f'),orange=color('dc8c1d'),claw=color('7a676d')}
local function round(x)return math.floor(x+.5)end
local function pixel(im,x,y,c) x=round(x);y=round(y);if x>=0 and x<112 and y>=0 and y<112 then im:drawPixel(x,y,c)end end
local function line(im,a,b,c)
 local x,y=round(a[1]),round(a[2]);local tx,ty=round(b[1]),round(b[2])
 local dx=math.abs(tx-x);local sx=x<tx and 1 or -1;local dy=-math.abs(ty-y);local sy=y<ty and 1 or -1;local e=dx+dy
 while true do pixel(im,x,y,c);if x==tx and y==ty then break end;local ee=e*2;if ee>=dy then e=e+dy;x=x+sx end;if ee<=dx then e=e+dx;y=y+sy end end
end
local function inside(x,y,p)
 local hit=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j];if (a[2]>y)~=(b[2]>y) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then hit=not hit end;j=i end
 return hit
end
local function poly(im,p,c,outline)
 local minx,miny,maxx,maxy=112,112,0,0
 for _,v in ipairs(p)do minx=math.min(minx,v[1]);miny=math.min(miny,v[2]);maxx=math.max(maxx,v[1]);maxy=math.max(maxy,v[2])end
 for y=math.floor(miny),math.ceil(maxy)do for x=math.floor(minx),math.ceil(maxx)do if inside(x+.5,y+.5,p)then pixel(im,x,y,c)end end end
 if outline then for i=1,#p do line(im,p[i],p[i%#p+1],outline)end end
end
local function disc(im,x,y,c)
 poly(im,{{x-2,y-1},{x,y-3},{x+2,y-2},{x+3,y},{x+2,y+3},{x,y+3},{x-2,y+1}},c,C.ink)
 pixel(im,x,y-1,C.sky);pixel(im,x+1,y-1,C.sky)
end
local wings={
 outline={{0,0},{.44,-.03},{.85,-.20},{1.05,-.43},{1.02,-.10},{.94,.15},{1.20,-.02},{1.17,.22},{1.02,.43},{.93,.48},{1.24,.30},{1.18,.58},{.97,.78},{.88,.82},{1.15,.71},{1, .99},{.73,1.17},{.64,1.09},{.82,1.05},{.57,1.25},{.30,1},{.12,.50}},
 cloth={{.03,.05},{.40,.02},{.77,-.03},{.96,.12},{.93,.31},{.78,.39},{.93,.44},{.88,.65},{.69,.76},{.75,.83},{.57,1},{.39,.96},{.20,.68}},
 shade={{.12,.37},{.40,.23},{.71,.18},{.92,.22},{.88,.34},{.76,.41},{.89,.47},{.84,.63},{.68,.75},{.71,.84},{.55,.96},{.39,.90},{.22,.66}},
 highlight={{.13,.10},{.43,.07},{.73,.03},{.91,.14},{.90,.22},{.71,.17},{.45,.20},{.17,.29}},
}
local function wing(im,anchor,dx,dy,fan,near,bend)
 local function p(u,v)
  -- Two segments: the secondary feathers follow the distal spar with a delayed elbow.
  local q=math.max(0,u-.48)
  return {anchor[1]+u*dx+v*fan[1]+q*bend[1],anchor[2]+u*dy+v*fan[2]+q*bend[2]}
 end
 local function points(a)local b={};for _,v in ipairs(a)do b[#b+1]=p(v[1],v[2])end;return b end
 poly(im,points(wings.outline),near and C.light or C.blue,C.ink)
 -- Shadow separates four real primary feathers, never a repeating noisy texture.
 for _,a in ipairs({{{.15,.55},{.55,.43},{1.01,.16},{1.05,.31},{.83,.57},{.47,.73}},{{.23,.74},{.62,.63},{1.02,.47},{1.01,.64},{.79,.89},{.47,1.08}},{{.4,.94},{.73,.83},{.91,.82},{.77,1.02},{.6,1.12}}}) do poly(im,points(a),C.deep)end
 poly(im,points(wings.cloth),C.cream,C.deep)
 poly(im,points(wings.shade),C.sand)
 poly(im,points(wings.highlight),near and C.bright or C.cream)
 -- Distinct three cream sails with individually inked blue curls.
 for _,a in ipairs({{{.80,.15},{.68,.07},{.56,.12},{.53,.24},{.63,.30},{.71,.25},{.69,.20},{.63,.20}},{{.76,.50},{.65,.43},{.53,.47},{.50,.60},{.60,.67},{.70,.63},{.69,.56},{.62,.56}},{{.52,.83},{.43,.75},{.31,.80},{.31,.92},{.41,.98},{.50,.93},{.48,.87},{.41,.87}}}) do
  local pts=points(a);for i=1,#pts-1 do line(im,pts[i],pts[i+1],C.blue)end
 end
 -- The bamboo leading spar is connected from shoulder through the fold to the tip.
 local rod={p(0,0),p(.49,-.02),p(.89,-.18)}
 for i=1,2 do line(im,{rod[i][1]-1,rod[i][2]+1},{rod[i+1][1]-1,rod[i+1][2]+1},C.brown);line(im,rod[i],rod[i+1],C.gold);line(im,{rod[i][1],rod[i][2]-1},{rod[i+1][1],rod[i+1][2]-1},C.sun)end
 local knot=p(.88,-.18)
 pixel(im,knot[1]-1,knot[2],C.brown);pixel(im,knot[1],knot[2]+1,C.gold)
 return {root=anchor,elbow=p(.49,-.02),tip=p(.89,-.18)}
end
local rigs={
 {roots={{43,63},{61,62}},hips={{44,84},{58,87}},feet={{39,90},{57,96}},head={{43,45},{53,43},{64,48},{65,64},{63,75},{65,87},{61,90},{50,90},{38,86},{38,68},{35,63},{36,57},{40,53}}},
 {roots={{48,61},{64,62}},hips={{49,83},{60,85}},feet={{46,89},{54,95}},head={{48,43},{58,43},{65,49},{66,64},{65,75},{66,87},{60,90},{48,90},{43,83},{42,66},{41,55},{43,49}}}
}
local keys={
 -- Wings open, shoulder level, downstroke, lower turn, recovery, return.
 {l={-25,-22},r={27,-21},fan={0,21},bend={0,0},feet={{-3,0},{3,-4}}},
 {l={-29,-5},r={30,-6},fan={-2,19},bend={0,2},feet={{-1,0},{2,-5}}},
 {l={-20,17},r={22,19},fan={-5,13},bend={-2,3},feet={{2,0},{-1,-3}}},
 {l={-14,21},r={16,21},fan={-6,11},bend={-3,2},feet={{3,-4},{-3,0}}},
 {l={-25,4},r={27,5},fan={-3,17},bend={-2,1},feet={{1,-5},{-1,0}}},
 {l={-26,-14},r={28,-13},fan={0,20},bend={-1,0},feet={{-2,-3},{2,0}}},
}
local function foot(im,hip,toe,far)
 local ankle={toe[1]+2,toe[2]-5}
 poly(im,{{hip[1]-2,hip[2]-1},{hip[1]+2,hip[2]-1},{ankle[1]+2,ankle[2]},{ankle[1]+1,ankle[2]+4},{ankle[1]-2,ankle[2]+3},{ankle[1]-2,ankle[2]}},far and C.orange or C.gold,C.dark)
 line(im,{hip[1]-1,hip[2]},{ankle[1]-1,ankle[2]+1},far and C.gold or C.sun)
 poly(im,{{toe[1]-6,toe[2]-2},{toe[1]-3,toe[2]-4},{toe[1],toe[2]-4},{toe[1]+3,toe[2]-3},{toe[1]+6,toe[2]-3},{toe[1]+7,toe[2]-1},{toe[1]+6,toe[2]+1},{toe[1]+2,toe[2]},{toe[1],toe[2]+3},{toe[1]-2,toe[2]+2},{toe[1]-3,toe[2]},{toe[1]-6,toe[2]+1}},far and C.gold or C.sun,C.ink)
 for _,offset in ipairs({{-5,0},{0,2},{5,0}}) do
  local x,y=toe[1]+offset[1],toe[2]+offset[2]
  poly(im,{{x-1,y-2},{x+1,y-2},{x+2,y},{x+1,y+1},{x-1,y+1},{x-2,y+2},{x-2,y}},C.claw,C.black)
  pixel(im,x,y-1,C.claw);pixel(im,x,y,C.claw)
 end
end
local records={}
local frame=0
for _,action in ipairs({'idle','walk'}) do
 local count=action=='idle' and 4 or 6
 local atlas=Image(count*112,224,ColorMode.RGB)
 for view=1,2 do
  local rig=rigs[view]
  local src=Image(source,Rectangle((view-1)*112,0,112,112))
  local core=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do
   local keep=(y<46 and x>=43 and x<=78)or(y>=46 and y<49 and x>=43 and x<=64)or inside(x,y,rig.head)or(y>=76 and x>=63)
   if action=='idle' and y>=84 then keep=true end
   if action=='walk' and y>=89 and x<67 then keep=false end
   if keep then core:drawPixel(x,y,src:getPixel(x,y))end
  end end
  -- These tiny fragments belonged to the old wing spar beside the crest,
  -- not to the crest itself; its complete two feathers remain unchanged.
  if view==1 then core:drawPixel(78,45,0)
  else for _,p in ipairs({{77,45},{78,45},{73,44},{72,45},{73,45},{74,45}})do core:drawPixel(p[1],p[2],0)end end
  for pose=1,count do
   frame=frame+1;if frame>1 then sprite:newEmptyFrame()end
   sprite.frames[frame].duration=action=='walk'and({.14,.10,.12,.14,.10,.12})[pose]or({.40,.15,.40,.15})[pose]
   local key=keys[pose]
   if action=='idle' then local dy=({-22,-20,-18,-20})[pose];key={l={-25,dy},r={27,dy+1},fan={0,21},bend={0,0},feet={{0,0},{0,0}}}end
   local left=Image(112,112,ColorMode.RGB)
   local right=Image(112,112,ColorMode.RGB)
   local lroot,rroot=rig.roots[1],rig.roots[2]
   local lf={-key.fan[1],key.fan[2]}
   local ls=wing(left,lroot,key.l[1],key.l[2],lf,false,{-key.bend[1],key.bend[2]})
   local rs=wing(right,rroot,key.r[1],key.r[2],key.fan,true,key.bend)
   sprite:newCel(layers[1],frame,left,Point(0,0))
   sprite:newCel(layers[2],frame,right,Point(0,0))
   local legs=Image(112,112,ColorMode.RGB)
   if action=='walk' then for n=1,2 do local d=key.feet[n];foot(legs,rig.hips[n],{rig.feet[n][1]+d[1],rig.feet[n][2]+d[2]},n==1)end end
   sprite:newCel(layers[3],frame,legs,Point(0,0))
   sprite:newCel(layers[4],frame,core,Point(0,0))
   local nodes=Image(112,112,ColorMode.RGB);disc(nodes,lroot[1],lroot[2],C.blue);disc(nodes,rroot[1],rroot[2],C.blue)
   sprite:newCel(layers[5],frame,nodes,Point(0,0))
   local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,frame)
   atlas:drawImage(flat,Point((pose-1)*112,(view-1)*112))
   records[#records+1]={action=action,view=view==1 and'sw'or'nw',pose=pose,left=ls,right=rs,feet=key.feet}
  end
  local tag=sprite:newTag(frame-count+1,frame);tag.name=action..(view==1 and'-sw'or'-nw')
 end
 atlas:saveAs(out..'/'..action..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/azulfazo-hibrido.aseprite')
local posefile=assert(io.open(out..'/poses.json','w'));posefile:write(json.encode(records));posefile:close()
print('Azulfazo hybrid: 20 frames, native wings and talons, retained source body/face.')
sprite:close()
