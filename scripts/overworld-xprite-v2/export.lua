local root=app.params.root
local scratch=app.params.scratch
local list=assert(io.open(scratch.."/export-ids.txt","r"))
for id in list:lines() do
  if id~="glacerol" and id~="riscavela" and id~="azulfazo" then
  local folder=root.."/"..id
  local src=app.open(scratch.."/"..id.."-base.png")
  assert(src and src.width==224 and src.height==112,id)
  local source=Image(src.cels[1].image)
  src:close()
  local sprite=Sprite(112,112,ColorMode.RGB)
  local layer=sprite.layers[1]
  layer.name="Base Xprite"
  sprite:newEmptyFrame()
  local exported=Image(224,112,ColorMode.RGB)
  for n=1,2 do
    local view=Image(source,Rectangle((n-1)*112,0,112,112))
    if n==1 and (id=="araruna-memoria" or id=="capibaluarte" or id=="mestre-dos-fios") then
      local corrected=Image(view)
      for y=0,111 do for x=0,111 do corrected:drawPixel(x,y,view:getPixel(111-x,y)) end end
      view=corrected
    end
    exported:drawImage(view,Point((n-1)*112,0))
    if n==1 then layer:cel(1).image=view else sprite:newCel(layer,sprite.frames[n],view,Point(0,0)) end
  end
  local retouch=sprite:newLayer()
  retouch.name="Retoques"
  local slice=sprite:newSlice(Rectangle(0,0,112,112))
  slice.name="chao"
  slice.pivot=Point(56,100)
  local front=sprite:newTag(1,1);front.name="frente-sw"
  local rear=sprite:newTag(2,2);rear.name="costas-nw"
  sprite:saveAs(folder.."/"..id.."-overworld.aseprite")
  exported:saveAs(folder.."/duas-vistas.png")
  sprite:close()
  print(id)
  end
end
list:close()
