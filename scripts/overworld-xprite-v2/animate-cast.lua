-- Batch Aseprite rigs. Input masks are stored per creature/view for correction.
local root=assert(app.params.root)
local queue=json.decode(assert(io.open(root..'/art/creatures/overworld-animacoes-v1/anatomias.json','r')):read('*a'))
local idleMs={320,140,220,320,140,220,200,240}
local walkMs={110,90,90,100,110,90,90,100}
local breath={0,0,1,1,1,0,0,0}
local wave={0,1,2,1,0,-1,-2,-1}
local gait={-1,-.67,0,.67,1,.67,0,-.67}
local names={'nucleo','cabeca','apendice-esquerdo','apendice-direito','apoio-esquerdo','apoio-direito'}
local function round(n)return math.floor(n+.5)end
local first=tonumber(app.params.first) or 1
local last=tonumber(app.params.last) or #queue
for position=first,math.min(last,#queue) do
 local config=queue[position];local id=config.id;local kind=config.anatomy
 if not app.params.only or string.find(','..app.params.only..',',','..id..',',1,true) then
 local out=root..'/art/creatures/soulmonsters-overworld-v2/'..id..'/animacoes-v1'
 app.fs.makeAllDirectories(out)
 local opened=app.open(root..'/art/creatures/soulmonsters-overworld-v2/'..id..'/duas-vistas.png')
 local source=Image(opened.cels[1].image);opened:close()
 local sprite=Sprite(112,112,ColorMode.RGB);sprite.layers[1].name=names[1]
 local layers={sprite.layers[1]}
 for i=2,#names do layers[i]=sprite:newLayer();layers[i].name=names[i] end
 local count=0;local tags={}
 for _,state in ipairs({'idle','walk'}) do
  local atlas=Image(896,224,ColorMode.RGB)
  for view=1,2 do
   local spec=config.views[view];local b=spec.bounds
   local src=Image(source,Rectangle((view-1)*112,0,112,112))
   local points={};local w,h=b[3]-b[1],b[4]-b[2]
   for y=0,111 do for x=0,111 do
    local c=src:getPixel(x,y)
    if app.pixelColor.rgbaA(c)>0 then
     local part=1
     if kind=='serpentino' or kind=='nadador' then
      part=y<spec.head_row and 2 or (x<spec.center and 3 or 4)
     elseif kind=='pequeno' then
      part=y>=spec.hip_row and (x<spec.center and 5 or 6) or (y<spec.head_row and 2 or 1)
     elseif kind=='quadrupede' or kind=='multipatas' then
      if y>=spec.hip_row then part=x<spec.center and 5 or 6
      elseif x<b[1]+w*.38 then part=2
      elseif x>b[1]+w*.80 then part=4 end
     else
      if y>=spec.hip_row then part=x<spec.center and 5 or 6
      elseif x<spec.core_left and y>=b[2]+h*.12 then part=3
      elseif x>spec.core_right and y>=b[2]+h*.12 then part=4
      elseif y<spec.head_row then part=2 end
     end
     points[#points+1]={x=x,y=y,c=c,part=part,key=y*112+x}
    end
   end end
   for frame=1,8 do
    count=count+1;if count>1 then sprite:newEmptyFrame() end
    sprite.frames[count].duration=(state=='idle' and idleMs[frame] or walkMs[frame])/1000
    local images={};for i=1,#names do images[i]=Image(112,112,ColorMode.RGB) end
    local mapped={}
    for _,p in ipairs(points) do
     local x,y,part=p.x,p.y,p.part
     local dx,dy=0,0
     local nearGround=math.max(0,math.min(1,(b[4]-1-y)/math.max(3,h*.15)))
     local flex=math.max(0,math.min(1,(y-spec.hip_row)/math.max(4,b[4]-spec.hip_row-1)))
     local reach=part==3 and (spec.core_left-x)/math.max(1,spec.core_left-b[1]) or (x-spec.core_right)/math.max(1,b[3]-spec.core_right)
     reach=math.max(0,math.min(1,reach))
     if state=='idle' then
      if part==1 then dy=breath[frame]
      elseif part==2 then dy=config.coupled_head and breath[frame] or breath[(frame+6)%8+1]
      elseif part==3 or part==4 then
       dy=breath[frame];dx=round(wave[(frame+5)%8+1]*.45*reach)*nearGround
      end
     else
      if kind=='serpentino' or kind=='nadador' then
       dx=round(wave[(frame+(part==2 and 0 or 2)-1)%8+1]*nearGround*(y<spec.hip_row and 1 or .5))
       dy=part==2 and breath[frame] or 0
      elseif kind=='voador' then
       dy=(part==3 or part==4) and round(wave[frame]*spec.amplitude*math.min(1,math.abs(x-spec.center)/math.max(8,w*.4))) or breath[(frame+3)%8+1]
       if part==5 or part==6 then dy=0 end
      elseif part==5 or part==6 then
       local f=part==5 and frame or (frame+3)%8+1
       dx=round(gait[f]*spec.stride*flex)
       -- A rolling toe remains supported; flex happens above the ground row.
       dy=-round(math.max(0,wave[f])*.65*flex*nearGround)
      elseif part==1 or part==2 then dy=breath[frame]
      else
       local phase=part==3 and frame or (frame+3)%8+1
       dx=round(gait[phase]*reach);dy=breath[(frame+5)%8+1]
      end
     end
     if state=='walk' and config.steady_walk and part<5 then dy=0 end
     dx=round(dx);dy=round(dy)
     -- Keep original canvas margins and the ground plane, never scale the art.
     local nx=math.max(0,math.min(111,x+dx));local ny=math.max(0,math.min(99,y+dy))
     images[part]:drawPixel(nx,ny,p.c)
     mapped[p.key]={x=nx,y=ny,c=p.c,part=part}
    end
    -- Close internal one-pixel cracks at a regional seam using the original
    -- FOUR-neighbour edges. Diagonals here would fatten the outside contour.
    for _,p in ipairs(points) do
     local a=mapped[p.key]
     for _,v in ipairs({{1,0},{0,1}}) do
      local qx,qy=p.x+v[1],p.y+v[2]
      local z=qx<112 and qy<112 and mapped[qy*112+qx] or nil
      if z then
       local length=math.max(math.abs(z.x-a.x),math.abs(z.y-a.y))
       if length>1 and length<=5 then
        for s=1,length-1 do images[a.part]:drawPixel(round(a.x+(z.x-a.x)*s/length),round(a.y+(z.y-a.y)*s/length),a.c) end
       end
      end
     end
    end
    -- Reconnect genuinely separated joints only. Bridging every original
    -- neighbour thickens outlines and inflates volume on armoured creatures.
    local parents={}
    local function find(k)
     if parents[k]~=k then parents[k]=find(parents[k]) end
     return parents[k]
    end
    local function join(a,z)
     if parents[a] and parents[z] then parents[find(a)]=find(z) end
    end
    for _,a in pairs(mapped) do local key=a.y*112+a.x;parents[key]=key end
    for key in pairs(parents) do
     local x,y=key%112,math.floor(key/112)
     for _,v in ipairs({{1,0},{0,1},{1,1},{-1,1}}) do
      local qx,qy=x+v[1],y+v[2]
      if qx>=0 and qx<112 and qy<112 then join(key,qy*112+qx) end
     end
    end
    for _,p in ipairs(points) do
     local a=mapped[p.key]
     for _,v in ipairs({{1,0},{0,1},{1,1},{-1,1}}) do
      local qx,qy=p.x+v[1],p.y+v[2]
      local z=qx>=0 and qx<112 and qy<112 and mapped[qy*112+qx] or nil
      if z then
       local length=math.max(math.abs(z.x-a.x),math.abs(z.y-a.y))
       if length>1 and length<=5 and find(a.y*112+a.x)~=find(z.y*112+z.x) then
        local previous=a.y*112+a.x
        for s=1,length do
         local nx,ny=round(a.x+(z.x-a.x)*s/length),round(a.y+(z.y-a.y)*s/length)
         local key=ny*112+nx
         if not parents[key] then
          parents[key]=key;images[a.part]:drawPixel(nx,ny,a.c)
         end
         join(previous,key);previous=key
        end
       end
      end
     end
    end
    for i=1,#names do sprite:newCel(layers[i],sprite.frames[count],images[i],Point(0,0)) end
    local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,count)
    atlas:drawImage(flat,Point((frame-1)*112,(view-1)*112))
   end
   tags[#tags+1]={name=state..(view==1 and '-sw' or '-nw'),first=count-7,last=count}
  end
  atlas:saveAs(out..'/'..state..'.png')
 end
 -- Create tags only after all frames: Aseprite auto-expands a terminal tag.
 for _,t in ipairs(tags) do local tag=sprite:newTag(t.first,t.last);tag.name=t.name end
 local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
 sprite:saveAs(out..'/'..id..'-animado.aseprite');sprite:close()
 print(position..'/'..#queue..' '..id..' '..kind)
 end
end
