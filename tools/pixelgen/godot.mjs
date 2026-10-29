import {sequencesFor,playbackOrder,duration} from './animation.mjs';
// Godot 4 SpriteFrames: speed 1 FPS makes relative duration equal seconds.
export function godotResource(p,path){
 if(typeof path!=='string'||!path.startsWith('res://')||!path.endsWith('.png')||/[\n\r\0]/.test(path))throw Error('Informe o caminho res:// da folha PNG no Godot.');
 const lines=[`[gd_resource type="SpriteFrames" load_steps=${p.frames.length+2} format=3]`,'',`[ext_resource type="Texture2D" path=${JSON.stringify(path)} id="1_sheet"]`,''];
 p.frames.forEach((_,i)=>lines.push(`[sub_resource type="AtlasTexture" id="Atlas_${i}"]`,'atlas = ExtResource("1_sheet")',`region = Rect2(${i%p.cols*p.width}, ${Math.floor(i/p.cols)*p.height}, ${p.width}, ${p.height})`,''));
 const names=new Set(),animations=sequencesFor(p).map(s=>{let name=s.name,n=2;while(names.has(name))name=s.name+'-'+n++;names.add(name);return '{\n"frames": ['+playbackOrder(s).map(i=>`{ "duration": ${duration(p.frames[i])/1000}, "texture": SubResource("Atlas_${i}") }`).join(',\n')+`],\n"loop": ${s.loop!==false},\n"name": &${JSON.stringify(name)},\n"speed": 1.0\n}`;});
 lines.push('[resource]','animations = ['+animations.join(',\n')+']','');return lines.join('\n');
}
