-- Native Aseprite round trip; separate batch process, no user document edits.
local root = app.params['root']
assert(root, 'Pass --script-param root=PROJECT_ROOT')
local motions = {'idle','walk','run','interact','attack','hurt','victory','defeat','swim','climb'}
local out = root .. '/tmp/kael-v2-native/'
app.fs.makeAllDirectories(out)
local report = {}
for _, motion in ipairs(motions) do
  local sprite = app.open(root .. '/art/characters/kael-compatible-sheets-v2/kael-' .. motion .. '.aseprite')
  assert(sprite and sprite.width == 48 and sprite.height == 64, motion .. ': canvas')
  assert(sprite.colorMode == ColorMode.INDEXED, motion .. ': indexed mode')
  assert(#sprite.layers == 8, motion .. ': editable layers')
  for i, frame in ipairs(sprite.frames) do
    local img = Image(sprite.width, sprite.height, ColorMode.RGB)
    img:drawSprite(sprite, i)
    img:saveAs(out .. motion .. '-' .. i .. '.png')
  end
  report[#report+1] = {motion=motion, frames=#sprite.frames, tags=#sprite.tags, layers=#sprite.layers}
  sprite:close()
end
local f = assert(io.open(out .. 'aseprite-report.json', 'w'))
f:write(json.encode(report)); f:close()
print('Native Aseprite sheets verified and rendered')
