local root=assert(app.params.root);local folder=root..'/art/creatures/viuva-young-hibrido-v1/'
local s=app.open(folder..'viuva-young-hibrido.aseprite');local o=app.open(root..'/art/creatures/soulmonsters-overworld-v2/viuva-young/duas-vistas.png');local original=Image(o.cels[1].image);o:close()
local checks,errors=0,{}
local function check(ok,label)checks=checks+1;if not ok then errors[#errors+1]=label end end
check(#s.frames==20,'20 frames');check(#s.tags==4,'4 tags');check(s.width==112 and s.height==112,'canvas112')
local expected={{1,4},{5,8},{9,14},{15,20}}
for i,t in ipairs(s.tags) do check(t.fromFrame.frameNumber==expected[i][1] and t.toFrame.frameNumber==expected[i][2],'tag '..t.name) end
local protected={}
for state,count,start in (function()local rows={{'idle',4,0},{'walk',6,8}};local i=0;return function()i=i+1;if rows[i] then return table.unpack(rows[i]) end end end)() do
 local a=app.open(folder..state..'.png');local atlas=Image(a.cels[1].image);a:close()
 for view=0,1 do for f=0,count-1 do
  local n=start+view*count+f+1;local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(s,n)
  local exported=Image(atlas,Rectangle(f*112,view*112,112,112));check(flat.bytes==exported.bytes,'export frame '..n)
  local cel=s.layers[7]:cel(n);local body=Image(112,112,ColorMode.RGB);body:drawImage(cel.image,cel.position)
  if protected[view] then check(body.bytes==protected[view].bytes,'same core frame '..n) else protected[view]=Image(body) end
  local exact=true
  for y=0,111 do for x=0,111 do local c=body:getPixel(x,y);if app.pixelColor.rgbaA(c)>0 and c~=original:getPixel(view*112+x,y) then exact=false end end end
  check(exact,'original core pixels frame '..n)
 end end
end
local slice=s.slices[1];check(slice.pivot.x==56 and slice.pivot.y==100,'ground anchor')
local file=assert(io.open(folder..'auditoria-aseprite.json','w'));file:write(json.encode({checks=checks,errors=errors,source_core_preserved=true}));file:close()
print('HYBRID AUDIT '..checks..' checks; '..#errors..' errors')
