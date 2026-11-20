"""Testes do contrato, sem gerar arte ou abrir serviços externos."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
from validar_chart import validate


def sample():
    def node(id, stage):
        return {'id': id, 'name': id, 'kind': 'stage', 'stage': stage,
                'identity': 'Identidade de teste', 'story': 'História de teste',
                'decision_status': 'proposed', 'production_status': 'brief'}
    return {'family_id': 'familia-teste', 'nodes': [node('base', 2), node('nova', 3)],
            'edges': [{'from': 'base', 'to': 'nova', 'kind': 'reweaving',
                       'reason': 'Relação causal de teste', 'decision_status': 'proposed'}]}


class ChartTests(unittest.TestCase):
    def test_variable_size_and_undecided_stage(self):
        d = sample()
        self.assertEqual(validate(d, Path('.')), [])
        d['nodes'][1]['stage'] = None
        self.assertEqual(validate(d, Path('.')), [])
        d['nodes'] = d['nodes'][:1]
        d['edges'] = []
        self.assertEqual(validate(d, Path('.')), [])

    def test_duplicate_ids_and_dangling_edge(self):
        d = sample()
        d['nodes'].append(copy.deepcopy(d['nodes'][0]))
        self.assertTrue(any('duplicado' in e for e in validate(d, Path('.'))))
        d = sample()
        d['edges'][0]['to'] = 'inexistente'
        self.assertTrue(any('inexistente' in e for e in validate(d, Path('.'))))

    def test_possession_is_not_a_healthy_stage(self):
        d = sample()
        d['edges'][0]['kind'] = 'possession'
        self.assertTrue(any('estado narrativo' in e for e in validate(d, Path('.'))))
        d['nodes'][1]['kind'] = 'state'
        self.assertEqual(validate(d, Path('.')), [])

    def test_material_adaptation_and_stage_delta(self):
        d = sample()
        d['nodes'][1]['kind'] = 'configuration'
        d['nodes'][1]['stage'] = 2
        d['edges'][0].update(kind='configuration', stage_delta=0)
        self.assertEqual(validate(d, Path('.')), [])
        d['edges'][0]['stage_delta'] = 1
        self.assertTrue(any('contradiz' in e for e in validate(d, Path('.'))))

    def test_files_and_approval_scope(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            d = sample()
            d['nodes'][0].update(brief='brief.md', decision_status='approved')
            errors = validate(d, base)
            self.assertTrue(any('arquivo' in e for e in errors))
            self.assertTrue(any('aprovação' in e for e in errors))
            (base/'brief.md').write_text('Teste', encoding='utf-8')
            d['nodes'][0]['approval_note'] = 'Aprovação parcial de teste; sem integração'
            self.assertEqual(validate(d, base), [])

    def test_malformed_field_types_report_errors(self):
        d = sample()
        d['nodes'][0]['kind'] = []
        d['nodes'][0]['decision_status'] = {}
        d['edges'][0]['kind'] = []
        self.assertTrue(validate(d, Path('.')))
        self.assertTrue(validate([], Path('.')))

    def test_cli_exit_codes(self):
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder)/'chart.json'
            runner = Path(__file__).with_name('validar_chart.py')
            for valid in [True, False]:
                d = sample()
                if not valid:
                    d['edges'][0]['to'] = 'ausente'
                p.write_text(json.dumps(d), encoding='utf-8')
                result = subprocess.run([sys.executable, '-X', 'utf8', str(runner), str(p)], capture_output=True, text=True, encoding='utf-8')
                self.assertEqual(result.returncode, 0 if valid else 1)
                self.assertEqual(json.loads(result.stdout)['ok'], valid)


if __name__ == '__main__':
    unittest.main()
