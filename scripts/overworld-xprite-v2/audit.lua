local root=app.params.root
local list=assert(io.open(app.params.list,"r"))
local errors=0
local passed=0
for id in list:lines() do
  local folder=root.."/"..id
  local doc=assert(app.open(folder.."/"..id.."-overworld.aseprite"))
  assert(doc.width==112 and doc.height==112 and #doc.frames==2,id.." source format")
  local flat=app.open(folder.."/duas-vistas.png")
  local sheet=Image(flat.cels[1].image)
  local mismatch=0
  for frame=1,2 do
    local image=Image(112,112,ColorMode.RGB)
    image:drawSprite(doc,frame)
    for y=0,111 do for x=0,111 do
      local expected=sheet:getPixel((frame-1)*112+x,y)
      local actual=image:getPixel(x,y)
      if app.pixelColor.rgbaA(expected)~=app.pixelColor.rgbaA(actual) or (app.pixelColor.rgbaA(expected)>0 and expected~=actual) then mismatch=mismatch+1 end
    end end
  end
  local hasPivot=false
  for _,slice in ipairs(doc.slices) do
    if slice.pivot and slice.pivot.x==56 and slice.pivot.y==100 then hasPivot=true end
  end
  if mismatch>0 or not hasPivot then
    print("FAIL "..id.." mismatch="..mismatch.." pivot="..tostring(hasPivot))
    errors=errors+1
  else
    passed=passed+1
  end
  flat:close();doc:close()
end
list:close()
print("ASEPRITE "..passed.." matches "..errors.." failures")
if errors>0 then error("Editable source validation failed") end
