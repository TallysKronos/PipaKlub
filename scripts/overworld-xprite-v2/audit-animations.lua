local root=assert(app.params.root)
local data=json.decode(assert(io.open(root..'/art/creatures/overworld-animacoes-v1/anatomias.json')):read('*a'))
data[#data+1]={id='azulfazo'}
local checked=0;local errors={}
for _,entry in ipairs(data) do
 local id=entry.id;local folder=root..'/art/creatures/soulmonsters-overworld-v2/'..id..'/animacoes-v1/'
 local sprite=app.open(folder..id..'-animado.aseprite')
 local function check(ok,message) checked=checked+1;if not ok then errors[#errors+1]=id..': '..message end end
 check(sprite~=nil,'arquivo editavel')
 if sprite then
  -- Repair only the original pilot's auto-extended tag metadata; pixels unchanged.
  if id=='azulfazo' then for i,t in ipairs(sprite.tags) do t.toFrame=sprite.frames[i*8] end;sprite:saveAs(folder..id..'-animado.aseprite') end
  check(#sprite.frames==32,'32 frames');check(#sprite.tags==4,'4 tags')
  check(sprite.width==112 and sprite.height==112,'canvas')
  for i,t in ipairs(sprite.tags) do check(t.fromFrame.frameNumber==(i-1)*8+1 and t.toFrame.frameNumber==i*8,'intervalo '..t.name) end
  for si,state in ipairs({'idle','walk'}) do
   local atlas=app.open(folder..state..'.png');local ref=Image(atlas.cels[1].image);atlas:close()
   for row=0,1 do for col=0,7 do
    local n=(si-1)*16+row*8+col+1
    local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,n)
    local cell=Image(ref,Rectangle(col*112,row*112,112,112))
    check(flat.bytes==cell.bytes,'PNG x editavel '..n)
   end end
  end
  sprite:close()
 end
end
local file=assert(io.open(root..'/art/creatures/overworld-animacoes-v1/auditoria-aseprite.json','w'))
file:write(json.encode({models=#data,checks=checked,errors=errors}));file:close()
print('ASEPRITE '..#data..' modelos; '..checked..' checks; '..#errors..' errors')
