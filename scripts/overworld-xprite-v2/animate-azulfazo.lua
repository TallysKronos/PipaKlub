-- Authored pixel rig for the approved 112px Azulfazo, not a cast-wide warp.
local root=assert(app.params.root)
local out=root..'/art/creatures/soulmonsters-overworld-v2/azulfazo/animacoes-v1'
app.fs.makeAllDirectories(out)
local input=app.open(root..'/art/creatures/soulmonsters-overworld-v2/azulfazo/duas-vistas.png')
local source=Image(input.cels[1].image);input:close()
local sprite=Sprite(112,112,ColorMode.RGB)
sprite.layers[1].name='torso'
local names={'torso','rabiola','asa-distante','asa-proxima','perna-distante','perna-proxima','cabeca'}
local layers={torso=sprite.layers[1]}
for n=2,#names do layers[names[n]]=sprite:newLayer();layers[names[n]].name=names[n] end
local function inside(x,y,p)
 local yes=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j]
  if (a[2]>y)~=(b[2]>y) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then yes=not yes end;j=i
 end
 return yes
end
local rigs={
 {far={{16,32},{34,32},{43,51},{43,70},{36,76},{16,74}},near={{61,39},{89,39},{90,78},{65,80},{59,68},{59,58}},tail={{61,77},{99,75},{100,102},{65,102},{60,86}},left={{28,83},{45,83},{47,96},{28,96}},right={{47,85},{64,85},{65,102},{47,102}},head={{40,28},{77,28},{77,46},{59,50},{61,64},{53,70},{40,65}}},
 {far={{17,32},{35,32},{46,51},{46,72},{38,77},{16,74}},near={{64,40},{91,40},{92,78},{67,81},{63,69},{63,57}},tail={{59,80},{101,76},{102,102},{62,102},{57,88}},left={{35,83},{49,83},{50,97},{34,97}},right={{49,84},{64,84},{64,98},{49,98}},head={{42,28},{78,28},{78,45},{63,49},{64,57},{57,62},{44,60}}}
}
local idle={0,0,1,1,1,0,0,0}
local wingIdle={0,1,1,0,-1,-1,0,0}
local wingWalk={0,2,4,2,0,-2,-3,-1}
local stride={-3,-2,0,2,3,2,0,-2}
local lift={0,0,1,2,2,1,0,0}
local idleMs={320,140,220,320,140,220,200,240}
local walkMs={110,90,90,100,110,90,90,100}
local index=0
for _,state in ipairs({'idle','walk'}) do
 local sheet=Image(896,224,ColorMode.RGB)
 for view=1,2 do
  local base=Image(source,Rectangle((view-1)*112,0,112,112));local rig=rigs[view]
  local parts={};for _,name in ipairs(names) do parts[name]=Image(112,112,ColorMode.RGB) end
  for y=0,111 do for x=0,111 do
   local c=base:getPixel(x,y)
   if app.pixelColor.rgbaA(c)>0 then
    local name='torso'
    if y<49 and x>=43 and x<79 then name='cabeca'
    elseif inside(x,y,rig.tail) then name='rabiola'
    elseif y>=79 and x<(view==1 and 50 or 55) then name='perna-distante'
    elseif y>=79 then name='perna-proxima'
    elseif inside(x,y,rig.far) then name='asa-distante'
    elseif inside(x,y,rig.near) then name='asa-proxima'
    elseif inside(x,y,rig.left) then name='perna-distante'
    elseif inside(x,y,rig.right) then name='perna-proxima'
    elseif inside(x,y,rig.head) then name='cabeca' end
    parts[name]:drawPixel(x,y,c)
   end
  end end
  for f=1,8 do
   index=index+1;if index>1 then sprite:newEmptyFrame() end
   sprite.frames[index].duration=(state=='idle' and idleMs[f] or walkMs[f])/1000
   local body=state=='idle' and idle[f] or ({0,1,0,0,0,1,0,0})[f]
   local mapped={}
   for _,name in ipairs(names) do
    local im=Image(112,112,ColorMode.RGB)
    for y=0,111 do for x=0,111 do
     local c=parts[name]:getPixel(x,y)
     if app.pixelColor.rgbaA(c)>0 then
      local dx,dy=0,body
      if name=='cabeca' then dy=state=='idle' and idle[(f+6)%8+1] or body
      elseif name=='asa-proxima' or name=='asa-distante' then
       local joint=name=='asa-proxima' and 62 or 42
       local amp=state=='idle' and wingIdle[f] or wingWalk[f]
       dy=body+math.floor(amp*math.min(1,math.abs(x-joint)/23)+.5)
      elseif name=='rabiola' then
       local lag=state=='idle' and wingIdle[(f+5)%8+1] or stride[(f+5)%8+1]
       -- The terminal paper knot remains above the ground plane on every pose.
       dy=math.min(0,body+math.floor(lag*math.max(0,x-62)/34+.5))
      elseif name=='perna-proxima' or name=='perna-distante' then
       dy=0
       if state=='walk' then
        local k=name=='perna-proxima' and f or (f+3)%8+1
        local t=math.max(0,math.min(1,(y-79)/17))
        dx=math.floor(stride[k]*t+.5);dy=-math.floor(lift[k]*t+.5)
        -- Near toe rolls on the support row; the ankle and heel rise above it.
        -- Roll the heel, with a toe still supported. Back view's visible foot
        -- sits on row94 because the isometric ground recedes under the actor.
        if name==(view==1 and 'perna-proxima' or 'perna-distante') then
         local ground=view==1 and 99 or 94
         dy=-math.floor(lift[k]*t*math.max(0,(ground-y)/7)+.5)
        end
       end
      end
      local nx,ny=x+dx,y+dy
      if nx>=0 and nx<112 and ny>=0 and ny<112 then
       im:drawPixel(nx,ny,c);mapped[y*112+x]={x=nx,y=ny,c=c,name=name}
      end
     end
    end end
    sprite:newCel(layers[name],sprite.frames[index],im,Point(0,0))
   end
   -- Pixel-authored rig joints: preserve source adjacency where integer posing
   -- opens a one/two-pixel seam (crest base, ankle, heel). No fragment deletion.
   for key,a in pairs(mapped) do
    local x,y=key%112,math.floor(key/112)
    for _,v in ipairs({{1,0},{0,1},{1,1},{-1,1}}) do
     local qx,qy=x+v[1],y+v[2]
     local b=qx>=0 and qx<112 and qy<112 and mapped[qy*112+qx] or nil
     if b then
      local length=math.max(math.abs(b.x-a.x),math.abs(b.y-a.y))
      if length>1 and length<=3 then
       local target=layers[a.name]:cel(index).image
       for s=1,length-1 do
        target:drawPixel(math.floor(a.x+(b.x-a.x)*s/length+.5),math.floor(a.y+(b.y-a.y)*s/length+.5),a.c)
       end
      end
     end
    end
   end
   local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,index)
   sheet:drawImage(flat,Point((f-1)*112,(view-1)*112))
  end
  local tag=sprite:newTag(index-7,index);tag.name=state..(view==1 and '-sw' or '-nw')
 end
 sheet:saveAs(out..'/'..state..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
-- Inserting new frames expands tags that ended on the old last frame.
for i,tag in ipairs(sprite.tags) do tag.toFrame=sprite.frames[i*8] end
sprite:saveAs(out..'/azulfazo-animado.aseprite')
print('AZULFAZO: 32 frames, 7 rig layers, 4 tags')
