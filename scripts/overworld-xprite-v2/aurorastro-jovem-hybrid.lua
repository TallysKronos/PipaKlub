-- Specific four-legged reconstruction. Video guides contact order only.
local root=assert(app.params.root)
local out=root..'/art/creatures/aurorastro-jovem-hibrido-v1'
app.fs.makeAllDirectories(out)
local doc=app.open(root..'/art/creatures/soulmonsters-overworld-v2/aurorastro-jovem/duas-vistas.png')
local source=Image(doc.cels[1].image)
local palette=Palette(#doc.palettes[1]);for i=0,#doc.palettes[1]-1 do palette:setColor(i,doc.palettes[1]:getColor(i))end;doc:close()
local sprite=Sprite(112,112,ColorMode.RGB);sprite:setPalette(palette)
local names={'cauda-preservada','pata-anterior-distante','pata-posterior-distante','pata-anterior-proxima','pata-posterior-proxima','rosto-corpo-pelagem-preservados'}
local layers={};sprite.layers[1].name=names[1];layers[1]=sprite.layers[1]
for i=2,#names do layers[i]=sprite:newLayer();layers[i].name=names[i]end
local function c(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
local C={ink=c('12132c'),fur=c('fce7dd'),shade=c('c0a3b2'),far=c('d1b3a8'),foot=c('3f3a6a'),dark=c('2f2a49'),shine=c('8e769c')}
local tailColors={}
for _,h in ipairs({'038d94','af80d0','94e2cd','073a4a','054e5c','8e65ae','05737f','035e6b','46b0a8'})do tailColors[c(h)]=true end
local function round(x)return math.floor(x+.5)end
local function px(im,x,y,color)x=round(x);y=round(y);if x>=0 and x<112 and y>=0 and y<112 then im:drawPixel(x,y,color)end end
local function line(im,a,b,color)
 local x,y=round(a[1]),round(a[2]);local ex,ey=round(b[1]),round(b[2]);local dx=math.abs(ex-x);local sx=x<ex and 1 or -1;local dy=-math.abs(ey-y);local sy=y<ey and 1 or -1;local e=dx+dy
 while true do px(im,x,y,color);if x==ex and y==ey then break end;local e2=e*2;if e2>=dy then e=e+dy;x=x+sx end;if e2<=dx then e=e+dx;y=y+sy end end
end
local function inside(x,y,p)
 local hit=false;local j=#p
 for i=1,#p do local a,b=p[i],p[j];if(a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then hit=not hit end;j=i end
 return hit
end
local function poly(im,p,color,outline)
 local minx,miny,maxx,maxy=112,112,0,0
 for _,q in ipairs(p)do minx=math.min(minx,q[1]);miny=math.min(miny,q[2]);maxx=math.max(maxx,q[1]);maxy=math.max(maxy,q[2])end
 for y=math.floor(miny),math.ceil(maxy)do for x=math.floor(minx),math.ceil(maxx)do if inside(x+.5,y+.5,p)then px(im,x,y,color)end end end
 if outline then for i=1,#p do line(im,p[i],p[i%#p+1],outline)end end
end
local rigs={
 {tailCut=69,tailX=69,
  legs={
   {hip={37,85},knee={35,89},ankle={34,93},toe={33,96},far=true,phase=0},
   {hip={56,82},knee={59,87},ankle={59,90},toe={57,93},far=true,phase=3},
   {hip={46,85},knee={45,91},ankle={44,96},toe={43,99},phase=3},
   {hip={65,83},knee={67,87},ankle={68,91},toe={67,94},phase=0}
  },
  core={{{24,77},{30,72},{34,74},{41,70},{48,69},{52,72},{51,75},{58,74},{64,76},{68,78},{71,83},{68,86},{62,85},{58,87},{51,88},{48,88},{45,86},{42,87},{40,89},{36,91},{32,93},{28,92},{25,92},{23,89},{25,87}},{{52,74},{55,69},{60,69},{61,65},{63,67},{65,68},{69,67},{70,69},{70,74},{67,77},{60,76}}}
 },
 {tailCut=66,tailX=65,
  legs={
   {hip={37,78},knee={37,82},ankle={36,85},toe={35,88},far=true,phase=0},
   {hip={60,83},knee={62,88},ankle={64,93},toe={64,97},far=true,phase=3},
   {hip={46,82},knee={45,86},ankle={44,89},toe={43,92},phase=3},
   {hip={52,84},knee={53,90},ankle={52,95},toe={51,99},phase=0}
  },
  core={{{26,65},{31,61},{34,64},{39,60},{43,63},{44,67},{48,68},{51,72},{49,74},{53,76},{59,75},{63,78},{65,83},{64,87},{60,88},{57,87},{54,89},{49,89},{46,86},{43,84},{42,81},{38,82},{34,79},{30,78},{28,75},{25,75},{28,72},{26,70}}}
 }
}
-- A diagonal pair supports while the opposite pair passes. The return half swaps them.
local keys={
 {k={-1,0},a={-1,0},t={-3,0},support=true},
 {k={0,0},a={0,0},t={0,0},support=true},
 {k={1,0},a={1,-1},t={3,-1},support=true},
 {k={1,-1},a={2,-2},t={3,-3},support=false},
 {k={0,-2},a={0,-3},t={0,-4},support=false},
 {k={-1,-1},a={-2,-2},t={-3,-2},support=false},
}
local function add(a,b)return{a[1]+b[1],a[2]+b[2]}end
local function segment(im,a,b,width,far)
 local dx,dy=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dy*dy);if length<1 then return end
 local nx,ny=-dy/length*width/2,dx/length*width/2
 poly(im,{{a[1]+nx,a[2]+ny},{b[1]+nx*.65,b[2]+ny*.65},{b[1]-nx*.65,b[2]-ny*.65},{a[1]-nx,a[2]-ny}},far and C.far or C.fur,C.ink)
 line(im,{a[1]+1,a[2]+1},{b[1]+1,b[2]-1},far and C.shade or C.far)
end
local function leg(im,hip,knee,ankle,toe,far)
 segment(im,hip,knee,4.7,far);segment(im,knee,ankle,3.4,far);segment(im,ankle,{toe[1]+1,toe[2]-1},3.7,far)
 poly(im,{{hip[1]-3,hip[2]-2},{hip[1],hip[2]-3},{hip[1]+3,hip[2]-1},{hip[1]+2,hip[2]+3},{hip[1]+1,hip[2]+2},{hip[1],hip[2]+4},{hip[1]-2,hip[2]+1},{hip[1]-3,hip[2]+2}},far and C.far or C.fur,C.shade)
 poly(im,{{toe[1]-3,toe[2]-3},{toe[1],toe[2]-4},{toe[1]+3,toe[2]-3},{toe[1]+4,toe[2]-1},{toe[1]+3,toe[2]},{toe[1]-3,toe[2]},{toe[1]-4,toe[2]-1}},C.foot,C.ink)
 line(im,{toe[1]-2,toe[2]-2},{toe[1],toe[2]-3},C.shine)
 line(im,{toe[1],toe[2]-1},{toe[1],toe[2]},C.dark)
end
local records={};local frame=0
for _,action in ipairs({'idle','walk'})do
 local count=action=='idle'and 4 or 6
 local atlas=Image(112*count,224,ColorMode.RGB)
 for view=1,2 do
  local rig=rigs[view]
  local src=Image(source,Rectangle((view-1)*112,0,112,112))
  local core=Image(112,112,ColorMode.RGB)
  local tail=Image(112,112,ColorMode.RGB)
  for y=0,111 do for x=0,111 do
   local color=src:getPixel(x,y)
   local body=inside(x,y,rig.core[1])or(rig.core[2]and inside(x,y,rig.core[2]))
   if tailColors[color]then body=false end
   local isTail=(y<88 and(y<rig.tailCut or x>=rig.tailX or tailColors[color]))and not body
   if isTail then tail:drawPixel(x,y,color)end
   local keep=body
   if action=='idle'and not isTail then keep=true end
   if keep then core:drawPixel(x,y,src:getPixel(x,y))end
  end end
  for pose=1,count do
   frame=frame+1;if frame>1 then sprite:newEmptyFrame()end
   sprite.frames[frame].duration=action=='idle'and({.40,.15,.40,.15})[pose]or({.14,.10,.12,.14,.10,.12})[pose]
   -- A one-pixel tail settling preserves every swirl and the ivory spar.
   local offset=action=='idle'and({{0,0},{1,0},{1,-1},{0,0}})[pose]or({{0,0},{1,0},{1,-1},{0,-1},{-1,0},{0,0}})[pose]
   local tailPose=Image(112,112,ColorMode.RGB);tailPose:drawImage(tail,Point(offset[1],offset[2]))
   sprite:newCel(layers[1],frame,tailPose,Point(0,0))
   local rec={action=action,view=view==1 and'sw'or'nw',pose=pose,legs={},tailOffset=offset}
   for n,l in ipairs(rig.legs)do
    local im=Image(112,112,ColorMode.RGB)
    local key=keys[(pose-1+l.phase)%6+1]
    if action=='idle'then key={k={0,0},a={0,0},t={0,0},support=true}end
    local knee,ankle,toe=add(l.knee,key.k),add(l.ankle,key.a),add(l.toe,key.t)
    if action=='walk'then leg(im,l.hip,knee,ankle,toe,l.far)end
    sprite:newCel(layers[n+1],frame,im,Point(0,0))
    rec.legs[#rec.legs+1]={hip=l.hip,knee=knee,ankle=ankle,toe=toe,support=key.support}
   end
   sprite:newCel(layers[6],frame,core,Point(0,0))
   local flat=Image(112,112,ColorMode.RGB);flat:drawSprite(sprite,frame)
   atlas:drawImage(flat,Point((pose-1)*112,(view-1)*112));records[#records+1]=rec
  end
  local tag=sprite:newTag(frame-count+1,frame);tag.name=action..(view==1 and'-sw'or'-nw')
 end
 atlas:saveAs(out..'/'..action..'.png')
end
local slice=sprite:newSlice(Rectangle(0,0,112,112));slice.name='apoio';slice.pivot=Point(56,100)
sprite:saveAs(out..'/aurorastro-jovem-hibrido.aseprite')
local info=assert(io.open(out..'/poses.json','w'));info:write(json.encode(records));info:close()
sprite:close()
print('Aurorastro jovem: 20 poses; four drawn leg chains; exact source coat and tail patterns.')
