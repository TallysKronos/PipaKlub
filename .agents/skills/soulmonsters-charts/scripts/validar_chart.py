"""Valida charts documentais sem impor contagem ou desenho de uma família."""
import argparse
import json
from pathlib import Path

NODE_KINDS = {'stage', 'configuration', 'state'}
EDGE_KINDS = {'reweaving', 'configuration', 'interweaving', 'possession', 'return'}
STATUSES = {'proposed', 'approved', 'rejected', 'superseded'}


def validate(data, base):
    errors = []
    if not isinstance(data, dict):
        return ['A raiz precisa ser um objeto JSON.']
    if not isinstance(data.get('family_id'), str) or not data['family_id'].strip():
        errors.append('family_id ausente ou vazio.')
    nodes, edges = data.get('nodes'), data.get('edges')
    if not isinstance(nodes, list) or not nodes:
        errors.append('nodes precisa conter ao menos um nó.')
        nodes = []
    if not isinstance(edges, list):
        errors.append('edges precisa ser uma lista, mesmo quando vazia.')
        edges = []
    by_id = {}
    for i, node in enumerate(nodes):
        if not isinstance(node, dict):
            errors.append(f'Nó {i}: precisa ser objeto.')
            continue
        ident = node.get('id')
        if not isinstance(ident, str) or not ident.strip():
            errors.append(f'Nó {i}: id ausente ou vazio.')
            continue
        if ident in by_id:
            errors.append(f'ID duplicado: {ident}.')
        by_id[ident] = node
        for field in ['name', 'identity', 'story']:
            if not isinstance(node.get(field), str) or not node[field].strip():
                errors.append(f'{ident}: {field} ausente ou vazio.')
        if not isinstance(node.get('kind'), str) or node['kind'] not in NODE_KINDS:
            errors.append(f'{ident}: kind inválido.')
        stage = node.get('stage')
        if stage is not None and (type(stage) is not int or stage not in range(1, 5)):
            errors.append(f'{ident}: stage deve ser null ou inteiro entre 1 e 4.')
        if not isinstance(node.get('decision_status'), str) or node['decision_status'] not in STATUSES:
            errors.append(f'{ident}: decision_status inválido.')
        if node.get('decision_status') == 'approved' and not node.get('approval_note'):
            errors.append(f'{ident}: aprovação sem nota de evidência/escopo.')
        for field in ['art', 'brief']:
            ref = node.get(field)
            if ref is not None and (not isinstance(ref, str) or not ref.strip()):
                errors.append(f'{ident}: {field} deve ser caminho não vazio ou null.')
            elif ref and not (base / ref).is_file():
                errors.append(f'{ident}: arquivo {field} não encontrado: {ref}.')
    seen = set()
    for i, edge in enumerate(edges):
        if not isinstance(edge, dict):
            errors.append(f'Ligação {i}: precisa ser objeto.')
            continue
        origin, target, kind = edge.get('from'), edge.get('to'), edge.get('kind')
        if not isinstance(origin, str) or not isinstance(target, str):
            errors.append(f'Ligação {i}: from/to devem ser IDs em texto.')
            continue
        key = origin, target, str(kind)
        if key in seen:
            errors.append(f'Ligação duplicada: {key}.')
        seen.add(key)
        if origin not in by_id or target not in by_id:
            errors.append(f'Ligação {i}: ID de origem/destino inexistente.')
            continue
        if origin == target:
            errors.append(f'Ligação {i}: origem e destino iguais.')
        if not isinstance(kind, str) or kind not in EDGE_KINDS:
            errors.append(f'Ligação {i}: kind inválido.')
        if not isinstance(edge.get('decision_status'), str) or edge['decision_status'] not in STATUSES:
            errors.append(f'Ligação {i}: decision_status inválido.')
        if not isinstance(edge.get('reason'), str) or not edge['reason'].strip():
            errors.append(f'Ligação {i}: falta a relação causal em reason.')
        if edge.get('decision_status') == 'approved' and not edge.get('approval_note'):
            errors.append(f'Ligação {i}: aprovação sem nota de evidência/escopo.')
        before, after = by_id[origin], by_id[target]
        a, b = before.get('stage'), after.get('stage')
        stages_valid = type(a) is int and type(b) is int and a in range(1, 5) and b in range(1, 5)
        if kind == 'reweaving':
            if before.get('kind') != 'stage' or after.get('kind') != 'stage':
                errors.append(f'Ligação {i}: remonta de maturidade requer nós stage.')
            if stages_valid and b != a + 1:
                errors.append(f'Ligação {i}: remonta de estágio não avança um grau; explicitar mecanismo distinto.')
        if kind == 'possession' and after.get('kind') != 'state':
            errors.append(f'Ligação {i}: possessão deve apontar para estado narrativo.')
        if kind == 'configuration' and after.get('kind') == 'state':
            errors.append(f'Ligação {i}: adaptação e estado narrativo estão confundidos.')
        if 'stage_delta' in edge:
            delta = edge['stage_delta']
            if type(delta) is not int:
                errors.append(f'Ligação {i}: stage_delta precisa ser inteiro.')
            elif stages_valid and b - a != delta:
                errors.append(f'Ligação {i}: stage_delta contradiz os estágios dos nós.')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('chart', type=Path)
    args = parser.parse_args()
    try:
        data = json.loads(args.chart.read_text(encoding='utf-8-sig'))
    except (OSError, ValueError) as exc:
        print(json.dumps({'ok': False, 'errors': [str(exc)]}, ensure_ascii=False))
        return 1
    errors = validate(data, args.chart.resolve().parent)
    result = {'ok': not errors, 'errors': errors, 'scope': 'Estrutura e arquivos; não valida arte, história, mecânicas ou integração.'}
    if not errors:
        result.update(nodes=len(data['nodes']), edges=len(data['edges']))
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
