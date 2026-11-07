"""Registra as alternativas B/C aprovadas sem substituir as formas anteriores."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
import json,os
D=Path(__file__).resolve().parent;R=D.parents[2]
A=R/'art/creatures/capivara-boia-family-v1/teste-jovem-benchmark-v1'
quote='Gosto de B e C useos como evos alternativas'
items=[
 ('capiboia-contensor','B — Contensor de correnteza','b-quebra-corrente','Quadrúpede baixo de peito largo; dobra de papel em crescente integrada como quebra-corrente.','Aprende a conter o fluxo para proteger uma passagem.','Conter','Manobra lenta ao sustentar o crescente aberto.'),
 ('capiboia-condutor','C — Condutor de canais','c-condutor','Semiereto de dois apoios; membros anteriores com membranas-remo e rabiola de três abas.','Aprende a conduzir a água por movimentos precisos dos membros.','Conduzir','Precisa de margem e apoio para orientar a corrente.')]
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for id,name,folder,identity,story,action,limit in items:
 p=A/folder
 manifest=json.loads((p/'manifest.json').read_text(encoding='utf-8'))
 manifest.update(decision_status='approved',approval_note=quote,approval_date='2026-11-04',approval_scope='Design visual e uso como evolução jovem alternativa do Capiboia; nome definitivo e requisitos não definidos.')
 (p/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 review=p/'revisao.md';text=review.read_text(encoding='utf-8').replace('Não aprovado, não recortado, não animado e não integrado.','Aprovado visualmente; não recortado, não animado e não integrado.')
 if quote not in text:text+='\n\n2026-11-04 — Autor: “'+quote+'”. Aprovação do concept e da posição como alternativa jovem. Observações de produção acima permanecem para a etapa de vistas/rig.\n'
 review.write_text(text,encoding='utf-8')
 rel=lambda file:Path(os.path.relpath(p/file,D)).as_posix()
 n=dict(id=id,name=name,kind='stage',stage=3,age='Jovem',identity=identity,story=story,action=action,tradeoff_proposed=limit,decision_status='approved',approval_note=quote,production_status='concept',implementation_status='not_integrated',name_status='descriptive_label_not_final_species_name',art=rel('concept.png'),brief=rel('brief.md'),unknowns=['Nome definitivo','Requisitos de Remonta','Ligação futura com Marévia ou Capibaluarte'])
 chart['nodes']=[x for x in chart['nodes'] if x['id']!=id]+[n]
 chart['edges']=[x for x in chart['edges'] if x.get('to')!=id]+[dict(**{'from':'capivara-boia','to':id},kind='reweaving',reason=story,decision_status='approved',approval_note=quote,requirements_status='undefined')]
chart['scope']='Linha existente preservada; B e C aprovadas como evoluções jovens alternativas. Nomes e requisitos novos indefinidos; sem integração.'
if any(n['id']=='capiboia-porto' for n in chart['nodes']):chart['scope']+=' Dois adultos propostos acima de B e C, em avaliação.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
note='\n\n## Alternativas jovens aprovadas — 2026-11-04\n\nAutor: “'+quote+'”.\n\nCapiboia → **B — Contensor de correnteza** ou **C — Condutor de canais**, além da Remansa já proposta. B e C são evoluções alternativas de estágio jovem (III Arraia), não sequência uma da outra. Descrições são rótulos de trabalho, não nomes definitivos. Marévia e Capibaluarte permanecem preservados; nenhuma ligação automática deles com B/C foi aprovada. Requisitos, números e habilidades não foram definidos.\n\nA alternativa A permanece estudo não selecionado. Aprovação visual e de ramificação não equivale a rig, animação ou integração.\n'
for target in [D/'CHART.md',R/'art/creatures/capivara-boia-family-v1/DECISOES.md',A/'README.md']:
 text=target.read_text(encoding='utf-8')
 if quote not in text:target.write_text(text+note,encoding='utf-8')
cards=[]
for n in chart['nodes']:
 status='Aprovado' if n['decision_status']=='approved' else 'Proposto'
 cards.append(f'<article><h2>{escape(n["name"])} · {escape(n["age"])}</h2><b>{status}</b><a href="{n["art"]}"><img src="{n["art"]}" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><a href="{n["brief"]}">Brief</a></article>')
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Capiboia · chart</title><style>body{max-width:1200px;margin:auto;padding:28px;background:#edf5ed;color:#163e37;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:360px;object-fit:contain}a{color:#19665a}a:focus-visible{outline:3px solid #cc654c}aside{background:#fff7dc;padding:22px}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Capiboia · caminhos de amadurecimento</h1><p>Gotim → Capiboia → Remansa (proposta), B ou C (aprovadas como alternativas jovens).</p><aside>B e C não são sequência. Nomes definitivos e requisitos seguem indefinidos. Marévia está preservada como proposta adulta da linha anterior. Capibaluarte tem arte aprovada, mas rota ainda não definida. Nenhuma integração nesta etapa.</aside><p><a href="CHART.md">Histórico de decisões</a> · <a href="../../../art/creatures/onze-cavaleiros-v1/capibaluarte/concept-v1/concept.png">Capibaluarte aprovado</a> · <a href="chart.json">Relações estruturadas</a></p><main class="grid">'''+''.join(cards)+'</main></html>'
(D/'index.html').write_text(page,encoding='utf-8')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.paths=[]
 def handle_starttag(self,t,a):self.paths.extend(v for k,v in a if k in ('href','src'))
l=Links();l.feed(page);missing=[p for p in l.paths if not(D/p).is_file()]
result=dict(ok=not missing,nodes=len(chart['nodes']),edges=len(chart['edges']),approved_alternatives=2,missing_links=missing,scope='Estrutura, aprovação e links; sem inspeção de layout no navegador ou integração.')
(D/'validacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result));assert not missing
