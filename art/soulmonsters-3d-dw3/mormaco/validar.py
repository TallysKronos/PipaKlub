"""Round trip the delivered GLB through Blender, then measure its deformed mesh."""
import json
from pathlib import Path
import sys

import bpy


def check(condition, message):
    if not condition:
        raise RuntimeError(message)


def load_asset(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = list(bpy.context.scene.objects)
    rigs = [o for o in objects if o.type == 'ARMATURE']
    check(len(rigs) == 1, 'O GLB precisa trazer um único esqueleto.')
    rig = rigs[0]
    bones = {b.name for b in rig.data.bones}
    needed = {'Cabeça', 'Tronco', 'Cauda'} | {
        f'{part} {end} {side}' for part in ('Raiz', 'Dobra', 'Pata')
        for end in ('frente', 'trás') for side in ('E', 'D')
    }
    check(needed <= bones, f'Ossos ausentes: {needed - bones}')
    # Blender creates a non-exported icosphere for joint display during import.
    meshes = [o for o in objects if o.type == 'MESH'
              and any(c.name != 'glTF_not_exported' for c in o.users_collection)]
    check(meshes, 'O GLB não contém malhas.')
    for o in meshes:
        check(any(m.type == 'ARMATURE' and m.object == rig for m in o.modifiers),
              f'Malha sem armature: {o.name}')
        bone_groups = {g.index for g in o.vertex_groups if g.name in bones}
        for v in o.data.vertices:
            weight = sum(g.weight for g in v.groups if g.group in bone_groups)
            check(abs(weight - 1.0) < .012, f'Peso inválido em {o.name}, vértice {v.index}')

    image_nodes = [n for m in bpy.data.materials if m.node_tree
                   for n in m.node_tree.nodes if n.type == 'TEX_IMAGE']
    check(image_nodes, 'O GLB não trouxe texturas ligadas aos materiais.')
    textures = set()
    for node in image_nodes:
        img = node.image
        check(img and min(img.size) > 0 and img.packed_file, 'Textura ausente ou externa.')
        textures.add(img.name)
    return rig, meshes, textures


def claw_positions(rig, meshes):
    animation = rig.animation_data
    clip = next((a for a in bpy.data.actions if a.name.startswith('Firmar apoio')), None)
    check(clip and animation, 'A animação Firmar apoio não foi importada.')
    check(clip.frame_range[0] <= 1 and clip.frame_range[1] >= 40, 'Clipe incompleto.')
    # Activate the selected clip explicitly when more than one action is exported.
    animation.use_nla = False
    animation.action = clip
    if len(clip.slots) == 1:
        animation.action_slot = clip.slots[0]
    claws = [o for o in meshes if o.name.startswith('Unha frente')]
    for side in ('E', 'D'):
        check(len([o for o in claws if o.name.startswith(f'Unha frente {side}')]) == 3,
              f'Quantidade incorreta de unhas na pata {side}.')
    paws = {}
    for end in ('frente', 'trás'):
        for side in ('E', 'D'):
            label = f'{end} {side}'
            prefixes = tuple(f'{part} {label}' for part in ('Membro', 'Unha', 'Falange'))
            paws[label] = [ob for ob in meshes if ob.name.startswith(prefixes)]
            check(any(ob.name.startswith(prefixes[0]) for ob in paws[label]),
                  f'Malha do membro ausente na pata {label}.')
    ground_tolerance = .0005
    ground = {}
    samples = {}
    for frame in (1, 10, 18, 29, 40):
        bpy.context.scene.frame_set(frame)
        dg = bpy.context.evaluated_depsgraph_get()
        samples[frame] = {}
        ground[frame] = {}
        for label, pieces in paws.items():
            min_z = float('inf')
            for ob in pieces:
                evaluated = ob.evaluated_get(dg)
                positions = [evaluated.matrix_world @ v.co for v in evaluated.data.vertices]
                if positions:
                    min_z = min(min_z, min(p.z for p in positions))
                if ob in claws:
                    samples[frame][ob.name] = positions
            ground[frame][label] = round(min_z, 6)
            check(min_z >= -ground_tolerance,
                  f'Pata {label} atravessou o chão no quadro {frame} (Z {min_z:.6f}).')
            if label != 'frente E' or frame in (1, 40):
                check(min_z <= ground_tolerance,
                      f'Pata {label} perdeu o apoio no quadro {frame} (Z {min_z:.6f}).')
    def delta(a, b, name):
        return max((point - previous).length
                   for point, previous in zip(samples[a][name], samples[b][name]))
    active = [delta(1, 18, o.name) for o in claws if o.name.startswith('Unha frente E')]
    still = [delta(1, 18, o.name) for o in claws if o.name.startswith('Unha frente D')]
    returned = [delta(1, 40, o.name) for o in claws]
    check(min(active) > .025, 'Uma ou mais unhas da pata ativa não acompanham o movimento.')
    check(max(still) < .001, 'A pata de apoio escorregou.')
    check(max(returned) < .001, 'As unhas não voltaram à pose de início.')
    return {'clip': clip.name, 'unha_ativa_min': min(active),
            'apoio_max': max(still), 'erro_no_retorno': max(returned),
            'z_min_patas_por_quadro': ground, 'tolerancia_solo': ground_tolerance}


path = (Path(sys.argv[sys.argv.index('--') + 1]) if '--' in sys.argv
        else Path(__file__).resolve().with_name('Mormaco.glb')).resolve()
rig, meshes, textures = load_asset(path)
report = claw_positions(rig, meshes)
report.update(arquivo=str(path), ossos=len(rig.data.bones), malhas=len(meshes),
              texturas=sorted(textures))
print('VALIDAÇÃO GLB OK ' + json.dumps(report, ensure_ascii=False))
