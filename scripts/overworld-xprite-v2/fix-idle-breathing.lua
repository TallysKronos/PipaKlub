-- Two specific idle repairs. Rest pose stays fixed and only thorax shading breathes.
local root=assert(app.params.root)
local pc=app.pixelColor
local function hex(h)return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
local specs={
 {id='alvacordo',regions={
   {{54,65,66,77}},
   {{49,55,62,66}}
  },
  edits={
   {{57,66,'f1d9ce'},{58,66,'f1d9ce'},{59,66,'f1d9ce'},{60,66,'f1d9ce'},{57,67,'bda49c'},{58,67,'bda49c'},{59,67,'f1d9ce'},{60,67,'f1d9ce'},{58,68,'f1d9ce'},{59,68,'f1d9ce'},{60,68,'f1d9ce'},{61,68,'bda49c'}},
   {{52,57,'f1d9ce'},{53,57,'f1d9ce'},{54,57,'f1d9ce'},{55,57,'f1d9ce'},{52,58,'bda49c'},{53,58,'f1d9ce'},{54,58,'f1d9ce'},{55,58,'f1d9ce'},{56,58,'f1d9ce'},{53,59,'f1d9ce'},{54,59,'f1d9ce'},{55,59,'f1d9ce'},{56,59,'bda49c'}}
  }},
 {id='papisco',regions={
   {{48,80,59,92}},
   {{49,79,59,90}}
  },
  edits={
   {{51,84,'f2e5d8'},{52,84,'f2e5d8'},{53,84,'f2e5d8'},{51,85,'f2e5d8'},{52,85,'f2e5d8'},{53,85,'f2e5d8'},{54,85,'f2e5d8'},{52,86,'f2e5d8'},{53,86,'f2e5d8'},{54,86,'f2e5d8'},{55,86,'f2e5d8'},{55,87,'f2e5d8'}},
   {{51,82,'1e1e24'},{52,82,'1e1e24'},{53,82,'1e1e24'},{54,82,'1e1e24'},{51,83,'2f2e35'},{52,83,'2f2e35'},{53,83,'2f2e35'},{54,83,'2f2e35'},{55,83,'2f2e35'},{52,84,'2f2e35'},{53,84,'2f2e35'},{54,84,'2f2e35'},{55,84,'2f2e35'}}
  }}
}
local function inRegion(x,y,regions)
 for _,r in ipairs(regions)do if x>=r[1]and x<r[3]and y>=r[2]and y<r[4]then return true end end
 return false
end
for _,spec in ipairs(specs)do
 local folder=root..'/art/creatures/'..spec.id..'-prancha-v1'
 local doc=app.open(folder..'/'..spec.id..'-prancha.aseprite')
 assert(#doc.frames==20)
 local opened=app.open(folder..'/idle.png')
 local original=Image(opened.cels[1].image);opened:close()
 local beforeWalk=app.open(folder..'/walk.png')
 local walk=Image(beforeWalk.cels[1].image);beforeWalk:close()
 local visible
 for _,layer in ipairs(doc.layers)do if layer.isVisible then visible=layer end end
 assert(visible,'Missing visible final layer')
 local breathing=doc:newLayer();breathing.name='Correcao idle • torax fixo'
 local atlas=Image(448,224,ColorMode.RGB)
 local report={}
 for view=1,2 do
  local base=Image(original,Rectangle(0,(view-1)*112,112,112))
  for pose=1,4 do
   local frame=(view-1)*4+pose
   local final=Image(base)
   if pose==2 or pose==3 then
    for _,e in ipairs(spec.edits[view])do
     assert(inRegion(e[1],e[2],spec.regions[view]))
     local old=base:getPixel(e[1],e[2])
     assert(pc.rgbaA(old)>0,'Breathing pixel outside body')
     final:drawPixel(e[1],e[2],hex(e[3]))
    end
   end
   local changed=0
   for y=0,111 do for x=0,111 do
    local a,b=base:getPixel(x,y),final:getPixel(x,y)
    if a~=b then assert(inRegion(x,y,spec.regions[view]),'Protected pixel changed');changed=changed+1 end
    assert(pc.rgbaA(a)==pc.rgbaA(b),'Silhouette moved')
   end end
   -- Final layer replaces the original drifting cel; all source layers remain hidden for audit.
   local cel=visible:cel(frame)
   if cel then cel.image=base else doc:newCel(visible,frame,base,Point(0,0))end
   local delta=Image(112,112,ColorMode.RGB)
   for _,e in ipairs(spec.edits[view])do
    if(pose==2 or pose==3)and base:getPixel(e[1],e[2])~=final:getPixel(e[1],e[2])then delta:drawPixel(e[1],e[2],final:getPixel(e[1],e[2]))end
   end
   doc:newCel(breathing,frame,delta,Point(0,0))
   doc.frames[frame].duration=({.75,.20,.75,.20})[pose]
   atlas:drawImage(final,Point((pose-1)*112,(view-1)*112))
   report[#report+1]={view=view==1 and'sw'or'nw',pose=pose,changed_pixels=changed,regions=spec.regions[view],silhouette_exact=true,protected_regions_exact=true}
  end
 end
 -- Six walking poses in each view must remain byte-exact, including source-cel composition.
 for view=0,1 do for pose=0,5 do
  local frame=9+view*6+pose
  local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(doc,frame)
  for y=0,111 do for x=0,111 do assert(flat:getPixel(x,y)==walk:getPixel(pose*112+x,view*112+y),'Walk changed')end end
 end end
 doc:saveAs(folder..'/'..spec.id..'-prancha.aseprite')
 atlas:saveAs(folder..'/idle.png')
 -- Compare all saved frames against exported atlas after reopening.
 doc:close()
 local saved=app.open(folder..'/'..spec.id..'-prancha.aseprite')
 for view=0,1 do for pose=0,3 do
  local frame=1+view*4+pose
  local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(saved,frame)
  for y=0,111 do for x=0,111 do assert(flat:getPixel(x,y)==atlas:getPixel(pose*112+x,view*112+y),'Idle ASE mismatch')end end
 end end
 local info=assert(io.open(folder..'/idle-fix-regioes.json','w'))
 info:write(json.encode({id=spec.id,date='2026-11-13',head_feet_core_translation={0,0},walk_exact=true,frames=report,durations_ms={750,200,750,200}}));info:close()
 saved:close()
 print(spec.id..': fixed idle; silhouette fixed; only thorax colors differ; walk exact')
end
