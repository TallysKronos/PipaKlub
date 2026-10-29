"""Build a flat H3 graph with timed latent keyframe conditioning, no clip joining."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
base = ROOT/'art/pipa-tv-cinematic-v5/workflows/05-kael-tyler-petalas-h3-local.json'
template = ROOT/'art/pipa-tv-cinematic-v6/workflows/h3-multiframe-template.json'
graph = json.loads(base.read_text(encoding='utf-8-sig'))
guide = next(n for n in json.loads(template.read_text(encoding='utf-8-sig'))['nodes']
             if n['type'] == 'MiniMaxH3AddGuide')
nodes = {n['id']: n for n in graph['nodes']}
bridge = copy.deepcopy(nodes[139])
bridge.update(id=150, pos=[-1200, 6000], order=22)
bridge['widgets_values'] = ['pipatv-v6-janela-jardim.png', 'image']
bridge['widgets_values_named'] = {'image': 'pipatv-v6-janela-jardim.png'}
for output in bridge['outputs']:
    output['links'] = []
graph['nodes'].append(bridge)
nodes[150] = bridge
graph['links'] = [l for l in graph['links'] if l[0] != 270]
nodes[136]['outputs'][0]['links'] = []
nodes[126]['inputs'][1]['link'] = None
link_id = 300


def connect(source, slot, target, input_name, kind):
    global link_id
    link_id += 1
    target_slot = next(i for i, p in enumerate(nodes[target]['inputs']) if p['name'] == input_name)
    graph['links'].append([link_id, source, slot, target, target_slot, kind])
    nodes[target]['inputs'][target_slot]['link'] = link_id
    nodes[source]['outputs'][slot].setdefault('links', []).append(link_id)


previous = 136
for index, (image_id, frame) in enumerate([(137, 0), (150, 72), (139, 168), (139, -1)]):
    node_id = 160 + index
    node = copy.deepcopy(guide)
    node.update(id=node_id, pos=[100 + index*360, 6000], order=23+index)
    for pin in node['inputs']:
        pin['link'] = None
    for pin in node['outputs']:
        pin['links'] = []
    node['widgets_values'] = [frame]
    node['widgets_values_named'] = {'frame_idx': frame}
    graph['nodes'].append(node)
    nodes[node_id] = node
    connect(previous, 0, node_id, 'positive', 'CONDITIONING')
    connect(136, 1, node_id, 'latent', 'LATENT')
    connect(119, 0, node_id, 'vae', 'VAE')
    connect(image_id, 0, node_id, 'image', 'IMAGE')
    previous = node_id
connect(previous, 0, 126, 'conditioning', 'CONDITIONING')
graph['last_node_id'] = 163
graph['last_link_id'] = link_id
out = ROOT/'art/pipa-tv-cinematic-v6/workflows/06-plano-continuo-guias-h3-local.json'
out.write_text(json.dumps(graph, ensure_ascii=False, indent=2), encoding='utf-8')
print(out)
