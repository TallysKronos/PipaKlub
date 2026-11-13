-- Import real ImageGen poses without replacing their anatomy or gesture.
-- All crop/scale/placement decisions are explicit in the inspected layout JSON.
-- Manual pixel corrections are a final transparent overlay.
local root=assert(app.params.root)
local configPath=assert(app.params.layout)
local file=assert(io.open(configPath,'r'));local config=json.decode(file:read('*a'));file:close()
local out=app.params.out or root..'/art/creatures/anaconda-cavaleiro-prancha-v1'
app.fs.makeAllDirectories(out)
local ref=app.open(root..'/art/creatures/soulmonsters-overworld-v2/anaconda-cavaleiro/duas-vistas.png')
local reference=Image(ref.cels[1].image)
ref:close()
local pc=app.pixelColor
local palette={}
local seen={}
for y=0,111 do for x=0,223 do local color=reference:getPixel(x,y);if pc.rgbaA(color)>0 and not seen[color]then seen[color]=true;palette[#palette+1]=color end end end
local function distance(a,b)
 local dr=pc.rgbaR(a)-pc.rgbaR(b);local dg=pc.rgbaG(a)-pc.rgbaG(b);local db=pc.rgbaB(a)-pc.rgbaB(b)
 return 2*dr*dr+3*dg*dg+2*db*db
end
local cache={}
local function match(color)
 if seen[color]then return color end
 if cache[color]then return cache[color]end
 local closest,best
 for _,p in ipairs(palette)do local score=distance(color,p);if not best or score<best then closest=p;best=score end end
 cache[color]=closest;return closest
end
local sprite=Sprite(112,112,ColorMode.RGB)
local original=sprite.layers[1];original.name='ImageGen • pose normalizada preservada'
local mapped=sprite:newLayer();mapped.name='Cores da fonte • base para revisao'
local manual=sprite:newLayer();manual.name='Revisao manual • pixels e detalhes'
original.isVisible=false
mapped.isVisible=false
local asePalette=Palette(#palette+1);asePalette:setColor(0,Color{r=0,g=0,b=0,a=0})
for i,p in ipairs(palette)do asePalette:setColor(i,Color(p))end
sprite:setPalette(asePalette)
local count=0
local log={}
for _,action in ipairs({'idle','walk'})do
 local n=action=='idle'and 4 or 6
 local atlas=Image(n*112,224,ColorMode.RGB)
 for _,view in ipairs({'sw','nw'})do
  local entry
  for _,s in ipairs(config.sheets)do if s.action==action and s.view==view then entry=s end end
  if entry then
  assert(#entry.cells==n,'Missing generated cells for '..action..'/'..view)
  local input=app.open(root..'/'..entry.path);local image=Image(input.cels[1].image);input:close()
  for pose,cell in ipairs(entry.cells)do
   count=count+1;if count>1 then sprite:newEmptyFrame()end
   sprite.frames[count].duration=(action=='idle'and config.idle_durations or config.walk_durations)[pose]/1000
   local src=Image(112,112,ColorMode.RGB)
   local flat=Image(112,112,ColorMode.RGB)
   local edits=Image(112,112,ColorMode.RGB)
   -- A common scale is used for every frame in this sheet.
   local width=math.floor(cell.w*entry.scale+.5);local height=math.floor(cell.h*entry.scale+.5)
   for y=0,height-1 do for x=0,width-1 do
    local sx=cell.x+math.min(cell.w-1,math.floor((x+.5)/entry.scale))
    local sy=cell.y+math.min(cell.h-1,math.floor((y+.5)/entry.scale))
    local color=image:getPixel(sx,sy)
    local tx,ty=x+cell.offset_x,y+cell.offset_y
    if tx>=0 and ty>=0 and tx<112 and ty<112 then
     src:drawPixel(tx,ty,color)
     if pc.rgbaA(color)>=(entry.alpha_threshold or 128)then flat:drawPixel(tx,ty,match(pc.rgba(pc.rgbaR(color),pc.rgbaG(color),pc.rgbaB(color),255)))end
    end
   end end
   local paletteBase=Image(flat)
   for y=0,111 do for x=0,111 do
    local current=flat:getPixel(x,y)
    for old,new in pairs(config.manual_color_merges or{})do
     local function fromhex(h)return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
     if current==fromhex(old)then flat:drawPixel(x,y,fromhex(new))end
    end
   end end
   for _,edit in ipairs(cell.edits or{})do
    local color=edit.color=='clear'and 0 or pc.rgba(tonumber(edit.color:sub(1,2),16),tonumber(edit.color:sub(3,4),16),tonumber(edit.color:sub(5,6),16),255)
    assert(color==0 or seen[color],'Manual tone outside approved palette')
    flat:drawPixel(edit.x,edit.y,color)
   end
   -- The complete corrected cel supports explicit alpha erasure. The unmodified
   -- normalized generation remains on the hidden original layer for audit.
   sprite:newCel(original,count,src,Point(0,0))
   sprite:newCel(mapped,count,paletteBase,Point(0,0))
   sprite:newCel(manual,count,flat,Point(0,0))
   atlas:drawImage(flat,Point((pose-1)*112,view=='sw'and 0 or 112))
   log[#log+1]={action=action,view=view,pose=pose,source=entry.path,crop={cell.x,cell.y,cell.w,cell.h},scale=entry.scale,placement={cell.offset_x,cell.offset_y},manual_edits=#(cell.edits or{})}
  end
  local tag=sprite:newTag(count-n+1,count);tag.name=action..'-'..view
  end
 end
 atlas:saveAs(out..'/'..action..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/anaconda-cavaleiro-prancha.aseprite')
local report=assert(io.open(out..'/importacao.json','w'));report:write(json.encode(log));report:close()
sprite:close()
