from pathlib import Path
import json
root=Path(r'C:/Users/user/produto/pipa-club-integracao-atualizada')
out=Path(__file__).parent
graph=json.loads((root/'art/characters/kael-video-sprite-v1/minimax-local-api.json').read_text(encoding='utf-8'))
graph['5']['inputs']['image']='alvacordo-attack-ref-576.png'
graph['8']['inputs']['prompt']=(out/'workflows/prompt.txt').read_text(encoding='utf-8')
graph['8']['inputs'].update(width=512,height=512,length=124,ref_image_size='match')
graph['11']['inputs']['noise_seed']=2026110501
graph['13']['inputs']['steps']=16
graph['18']['inputs']['filename_prefix']='Soulmonsters/Alvacordo_attack_crosscut_v1'
assert all('API' not in n['class_type'] for n in graph.values())
(out/'workflows/attack-local.json').write_text(json.dumps(graph,ensure_ascii=False,indent=2),encoding='utf-8')
print('Prepared local H3 graph: 512x512,124frames,24fps,16steps; no external API nodes.')

