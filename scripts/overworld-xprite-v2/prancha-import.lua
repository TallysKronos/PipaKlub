-- Import real ImageGen poses without replacing their anatomy or gesture.
-- All crop/scale/placement decisions are explicit in the inspected layout JSON.
-- Manual pixel corrections are a final transparent overlay.
local root=assert(app.params.root)
local configPath=assert(app.params.layout)
local file=assert(io.open(configPath,'r'));local config=json.decode(file:read('*a'));file:close()
local out=app.params.out or root..'/'..assert(config.folder)
local editable=out..'/'..assert(config.id)..'-prancha.aseprite'
app.fs.makeAllDirectories(out)
local ref=app.open(root..'/'..assert(config.source))
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
local identityAudit={}
local locks={}
local function insidePolygon(x,y,p)
 local hit=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j];if(a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then hit=not hit end;j=i end
 return hit
end
if config.source_core_lock then
 for vi,view in ipairs({'sw','nw'})do
  local spec=assert(config.source_core_lock.views[view]);local mask=Image(112,112,ColorMode.RGB)
  local base=Image(reference,Rectangle((vi-1)*112,0,112,112))
  for y=0,111 do for x=0,111 do
   local moving=false
   for _,r in ipairs(spec.moving_regions)do if x>=r[1]and y>=r[2]and x<r[3]and y<r[4]then moving=true end end
   for _,p in ipairs(spec.protected_polygons or{})do if insidePolygon(x+.5,y+.5,p)then moving=false end end
   if not moving then mask:drawPixel(x,y,pc.rgba(255,255,255,255))end
  end end
  mask:saveAs(out..'/core-original-'..view..'.png');base:saveAs(out..'/source-original-'..view..'.png')
  locks[view]={mask=mask,base=base}
 end
end
local function applyIdentity(flat,action,view,pose)
 local lock=locks[view];if not lock then return end
 local replaced=0;local diffs=0
 for y=0,111 do for x=0,111 do if pc.rgbaA(lock.mask:getPixel(x,y))>0 then
  local source=lock.base:getPixel(x,y);if flat:getPixel(x,y)~=source then replaced=replaced+1 end
  -- Copy transparent canonical gaps as well; no generated second face survives.
  flat:drawPixel(x,y,source);if flat:getPixel(x,y)~=source then diffs=diffs+1 end
 end end end
 assert(diffs==0);identityAudit[#identityAudit+1]={action=action,view=view,pose=pose,canonical_core_differences=diffs,generated_pixels_replaced=replaced,transparent_gaps_protected=true}
end
for _,action in ipairs({'idle','walk'})do
 local n=action=='idle'and 4 or 6
 local atlas=Image(n*112,224,ColorMode.RGB);local populated=false
 for _,view in ipairs({'sw','nw'})do
  local entry
  for _,s in ipairs(config.sheets)do if s.action==action and s.view==view then entry=s end end
  local authored=action=='idle'and config.authored_idle
  if entry or authored then
  populated=true
  if authored then
   local viewIndex=view=='sw'and 0 or 1
   local base=Image(reference,Rectangle(viewIndex*112,0,112,112))
   local region=assert(authored.views[view].region)
   local breathing=assert(authored.views[view].edits)
   for pose=1,n do
    count=count+1;if count>1 then sprite:newEmptyFrame()end
    sprite.frames[count].duration=config.idle_durations[pose]/1000
    local flat=Image(base)
    local changed=0
    if pose==2 or pose==3 then
     for _,e in ipairs(breathing)do
      assert(e.x>=region[1]and e.x<region[3]and e.y>=region[2]and e.y<region[4])
      local old=base:getPixel(e.x,e.y)
      assert(pc.rgbaA(old)>0,'Idle detail outside body')
      local tone=pc.rgba(tonumber(e.color:sub(1,2),16),tonumber(e.color:sub(3,4),16),tonumber(e.color:sub(5,6),16),255)
      assert(seen[tone],'Idle color outside source palette')
      flat:drawPixel(e.x,e.y,tone)
     end
    end
    for y=0,111 do for x=0,111 do
     local a,b=base:getPixel(x,y),flat:getPixel(x,y)
     assert(pc.rgbaA(a)==pc.rgbaA(b),'Idle silhouette moved')
     if a~=b then
      assert(x>=region[1]and x<region[3]and y>=region[2]and y<region[4],'Protected idle pixels changed')
      changed=changed+1
     end
    end end
    applyIdentity(flat,action,view,pose)
    sprite:newCel(original,count,base,Point(0,0))
    sprite:newCel(mapped,count,base,Point(0,0))
    sprite:newCel(manual,count,flat,Point(0,0))
    atlas:drawImage(flat,Point((pose-1)*112,viewIndex*112))
    log[#log+1]={action='idle',view=view,pose=pose,source=config.source,method='stable approved rest pose; local authored detail',changed_pixels=changed,region=region,protected_regions_exact=true,silhouette_exact=true}
   end
  else
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
   local exteriorCleared=0
   if entry.clear_light_exterior then
    -- Only an explicitly flagged contaminated sheet: flood exterior transparency
    -- and near-white sticker pixels; enclosed pale anatomy remains protected.
    local visited={};local queue={};local cursor=1
    local function push(x,y)
     if x<0 or y<0 or x>=112 or y>=112 then return end
     local key=y*112+x;if visited[key]then return end
     local p=src:getPixel(x,y);local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
     local light=math.min(r,g,b)>=(entry.exterior_light_min or 210) and math.max(r,g,b)-math.min(r,g,b)<=(entry.exterior_light_spread or 45)
     if pc.rgbaA(flat:getPixel(x,y))==0 or light then visited[key]=true;queue[#queue+1]={x,y}end
    end
    for p=0,111 do push(p,0);push(p,111);push(0,p);push(111,p)end
    while cursor<=#queue do local p=queue[cursor];cursor=cursor+1;local x,y=p[1],p[2]
     if pc.rgbaA(flat:getPixel(x,y))>0 then flat:drawPixel(x,y,0);exteriorCleared=exteriorCleared+1 end
     push(x-1,y);push(x+1,y);push(x,y-1);push(x,y+1)
    end
   end
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
   applyIdentity(flat,action,view,pose)
   -- The complete corrected cel supports explicit alpha erasure. The unmodified
   -- normalized generation remains on the hidden original layer for audit.
   sprite:newCel(original,count,src,Point(0,0))
   sprite:newCel(mapped,count,paletteBase,Point(0,0))
   sprite:newCel(manual,count,flat,Point(0,0))
   atlas:drawImage(flat,Point((pose-1)*112,view=='sw'and 0 or 112))
   if action=='walk' and pose==(entry.master_pose or 1)then
    flat:saveAs(out..'/mestre-walk-'..view..'.png')
    local large=Image(448,448,ColorMode.RGB)
    for py=0,447 do for px=0,447 do large:drawPixel(px,py,flat:getPixel(math.floor(px/4),math.floor(py/4)))end end
    large:saveAs(out..'/mestre-walk-'..view..'-4x.png')
   end
   log[#log+1]={action=action,view=view,pose=pose,source=entry.path,crop={cell.x,cell.y,cell.w,cell.h},scale=entry.scale,placement={cell.offset_x,cell.offset_y},manual_edits=#(cell.edits or{}),exterior_pixels_cleared=exteriorCleared}
  end
  end
  local tag=sprite:newTag(count-n+1,count);tag.name=action..'-'..view
  end
 end
 if populated then atlas:saveAs(out..'/'..action..'.png')end
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(editable)
local report=assert(io.open(out..'/importacao.json','w'));report:write(json.encode(log));report:close()
if config.source_core_lock then
 local identity=assert(io.open(out..'/core-original-audit.json','w'));identity:write(json.encode({source=config.source,method='positive canonical source mask copied LAST including transparent gaps; generated moving regions only',frames=identityAudit}));identity:close()
end
sprite:close()
-- Reopen the saved source and compare every flattened frame to the actual atlas.
-- This checks file export, not anatomy or visual approval.
local saved=app.open(editable)
local checked=0
for _,action in ipairs({'idle','walk'})do
 local n=action=='idle'and 4 or 6
 local present=false
 for _,s in ipairs(config.sheets)do if s.action==action then present=true end end
 if action=='idle'and config.authored_idle then present=true end
 if present then
  local opened=app.open(out..'/'..action..'.png')
  local atlas=Image(opened.cels[1].image);opened:close()
  for _,view in ipairs({'sw','nw'})do
   local entry
   for _,s in ipairs(config.sheets)do if s.action==action and s.view==view then entry=s end end
   if entry or(action=='idle'and config.authored_idle)then
    for pose=1,n do
     checked=checked+1
     local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(saved,checked)
     for y=0,111 do for x=0,111 do
      assert(flat:getPixel(x,y)==atlas:getPixel((pose-1)*112+x,(view=='sw'and 0 or 112)+y),'Saved ASE/PNG mismatch')
     end end
    end
   end
  end
 end
end
local audit=assert(io.open(out..'/auditoria-aseprite.json','w'))
audit:write(json.encode({frames=checked,layers=#saved.layers,tags=#saved.tags,atlas_pixels_exact=true}));audit:close()
saved:close()
