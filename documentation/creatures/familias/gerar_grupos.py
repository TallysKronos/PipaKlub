"""Organização editorial por grupos; execute após gerar_catalogo.py."""
from pathlib import Path
from collections import defaultdict
from html import escape
import json, os, re, unicodedata, csv

D=Path(__file__).resolve().parent;R=D.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def dump(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def rel(p):return os.path.relpath(p,D).replace('\\','/')
def slug(s):return re.sub('[^a-z0-9]+','-',unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower()).strip('-')
catalog=read(D/'catalogo.json');config=read(D/'grupos-config.json')
families={f['id']:f for f in catalog['families']}
assert len(families)==len(catalog['families']),'Famílias duplicadas por chart'
records={};family_keys=defaultdict(set);node_keys=defaultdict(set)
for f in catalog['families']:
    for n in f['nodes']:
        if n.get('reference_only'):continue
        key='shared:'+n['id'] if n['id'] in ('entreflor','paleorix') else f['id']+':'+n['id']
        record={**n,'key':key,'family_id':f['id'],'family_name':f['name'],'group_ids':[]}
        if key not in records or f['id']=='entrelacos':records[key]=record
        family_keys[f['id']].add(key);node_keys[n['id']].add(key)

# Cada registro recebe uma vinheta autoral e uma indicação para a prancha.
lore={};family=None
for number,line in enumerate((D/'lore-por-criatura.txt').read_text(encoding='utf-8-sig').splitlines(),1):
    if not line.strip():continue
    if line.startswith('# '):
        family=line[2:].strip()
        continue
    fields=[field.strip() for field in line.split('|')]
    if family is None or len(fields)!=3 or not all(fields):
        raise ValueError(f'lore-por-criatura.txt:{number} — esperado ID | lore | prancha dentro de uma família')
    nid,story,sketch=fields
    key=f'{family}:{nid}'
    if key in lore:raise ValueError(f'lore-por-criatura.txt:{number} — ficha duplicada {key}')
    lore[key]=dict(story=story,sketch=sketch)
missing_lore=sorted(records.keys()-lore.keys())
unknown_lore=sorted(lore.keys()-records.keys())
if missing_lore or unknown_lore:
    raise ValueError(f'Lore sem cobertura exata. Faltam {missing_lore}. Sobram {unknown_lore}.')
for key,record in records.items():record['concept_lore']=lore[key]

groups=config['groups'];problems=[]
for g in groups:
    for fid in g['families']:
        if fid not in families:problems.append(g['id']+': família não encontrada '+fid)
    for nid in g['nodes']:
        if nid not in node_keys:problems.append(g['id']+': forma não encontrada '+nid)
    for source in g['sources']:
        if not (R/source).exists():problems.append(g['id']+': fonte não encontrada '+source)
assert not problems,problems

# Coleções do Dex preservadas como camada histórica, sem reconciliação forçada com a campanha.
legacy=defaultdict(list)
for entry in read(R/'assets/pipa-dex.json')['entries']:
    if entry.get('collection') and entry['id'] in node_keys:legacy[entry['collection']].append(entry['id'])
for title,ids in legacy.items():
    groups.append(dict(id='dex-'+slug(title),name='Dex legado · '+title,kind='colecao_dex_legado',description='Coleção registrada no Dex anterior. Mantida como referência editorial; o título não resolve vínculos, habitats ou hierarquias da campanha atual.',families=[],nodes=ids,sources=['assets/pipa-dex.json'],population_proposal='Consultar a coleção como histórico de criação e confrontar cada identidade com a bíblia antes de usá-la na campanha.',affiliation='Título de coleção não estabelece facção nem substitui os guardiões atuais.'))

labels={'conjunto_criado':'Conjunto já criado','colecao_transversal':'Coleção transversal de designs','classificacao_editorial':'Afinidade editorial proposta','estados_narrativos':'Estados da mesma identidade','mecanismo_transversal':'Mecanismo transversal','colecao_dex_legado':'Coleção do Dex legado'}
covered=set()
for g in groups:
    keys=set()
    for fid in g['families']:keys.update(family_keys[fid])
    for nid in g['nodes']:keys.update(node_keys[nid])
    g['member_keys']=sorted(keys);g['label']=labels[g['kind']]
    g['counts']=dict(records=len(keys),families=len({records[k]['family_id'] for k in keys}),art=sum(bool(records[k]['art']) for k in keys))
    g['related_families']=sorted({records[k]['family_id'] for k in keys})
    g['lineage_note']='Família selecionada traz suas pré-formas como contexto de linhagem; isso não dá ao bebê título, patente, afiliação ou habitat do adulto.' if g['families'] else 'Seleção de formas específicas; outras formas da linhagem não herdam este vínculo automaticamente.'
    for key in keys:records[key]['group_ids'].append(g['id'])
    covered.update(keys)

uncovered=sorted(set(records)-covered)
if uncovered:
    raise AssertionError('Criaturas sem grupo editorial: '+', '.join(uncovered))
assert len(records)==catalog['counts']['unique_records'],(len(records),catalog['counts'])
for g in groups:assert len(g['member_keys'])==len(set(g['member_keys']))
sources_missing=[]
for key,n in records.items():
    for field in ['art','source','brief','rig']:
        if n.get(field) and not (R/n[field]).is_file():sources_missing.append(key+':'+field)
assert not sources_missing,sources_missing
counts=dict(groups=len(groups),unique_records=len(records),families=catalog['counts']['families'],group_memberships=sum(len(g['member_keys']) for g in groups),reservations=len(catalog['reservations']))
data=dict(date=config['date'],scope='Organização documental de designs para povoamento do universo; nenhum spawn, alinhamento, raridade ou código do jogo alterado.',counts=counts,groups=groups,records=list(records.values()),family_context=[dict(id=f['id'],name=f['name'],keys=sorted(family_keys[f['id']]),sources=f['sources'],edges=f['edges']) for f in catalog['families']],reservations=catalog['reservations'],rules=['Grupo temático não é família evolutiva ou facção.','Um design pode participar de vários grupos sem duplicar a identidade.','Filhotes contextualizam a linhagem; não herdam cargos ou afiliações.','Possessão, máscara e sobrecarga são estados, não espécies.','Armadura escura não implica Carretel Negro; Conde v2 é forma adulta aprovada visualmente.','Coleções do Dex legado permanecem separadas da campanha atual.','Reservas e estudos rejeitados não entram no elenco ativo.'])
dump(D/'grupos.json',data)
with (D/'Plano-de-povoamento.csv').open('w',encoding='utf-8-sig',newline='') as out:
    writer=csv.writer(out,delimiter=';')
    writer.writerow(['Chave da identidade','Nome','Família','Maturidade','Natureza','Estado visual','Grupos de referência','Arte no repositório','Área a planejar','Momento narrativo a planejar','Função do encontro a planejar','Disponibilidade a decidir'])
    for key,n in sorted(records.items()):
        writer.writerow([key,n['name'],n['family_name'],n['stage'],n['kind'],n['status'],' | '.join(next(g['name'] for g in groups if g['id']==gid) for gid in n['group_ids']),n.get('art') or '','','','',''])
catalog['groups_index']='grupos.json'
catalog['population_groups']=[{k:g[k] for k in ['id','name','kind','counts','member_keys']} for g in groups]
for f in catalog['families']:
    f['population_group_ids']=sorted({gid for key in family_keys[f['id']] for gid in records[key]['group_ids']})
    for n in f['nodes']:
        key='shared:'+n['id'] if n['id'] in ('entreflor','paleorix') else f['id']+':'+n['id']
        n['population_group_ids']=records[key]['group_ids'] if key in records and not n.get('reference_only') else []
dump(D/'catalogo.json',catalog)

lines=['# Grupos do universo Soulmonsters','', '**Atualizado em 10 de novembro de 2026.**','',f"**{counts['groups']} grupos de navegação · {counts['families']} famílias · {counts['unique_records']} registros únicos.** As {counts['group_memberships']} participações somam sobreposições; não são espécies adicionais.",'','[Abrir atlas visual](grupos.html) · [Famílias completas](FAMILIAS.md) · [Dados estruturados](grupos.json).','','## Como usar para povoar o universo','', '1. Escolha um grupo já criado ou uma afinidade editorial.', '2. Abra a criatura e a linhagem para escolher o estágio visual adequado.', '3. Confira a fonte e o estado do design; habitats, alinhamento e disponibilidade exigem decisão própria.', '4. Registre depois a área, o momento narrativo e a função do encontro. Este documento não os implementa.','', 'Pré-formas aparecem no grupo como contexto de linhagem. Um bebê de uma família de cavaleiro não passa a integrar uma ordem por nascimento. Ninguém é transformado em vilão por usar armadura preta.','','## Índice','', '| Grupo | Natureza | Famílias representadas | Formas/contextos |','|---|---|---:|---:|']
for g in groups:lines.append(f"| [{g['name']}](#{g['id']}) | {g['label']} | {g['counts']['families']} | {g['counts']['records']} |")
for g in groups:
    lines += ['',f'<a id="{g["id"]}"></a>',f'## {g["name"]}','',f"**{g['label']}.** {g['description']}",'',g['lineage_note'],'','**Uso para povoamento — proposta:** '+g['population_proposal'],'',g['affiliation'],'','| Forma | Família | Maturidade | Estado visual | Arte / fonte |','|---|---|---|---|']
    for key in sorted(g['member_keys'],key=lambda k:(records[k]['family_name'],records[k].get('grade') or 9,records[k]['name'])):
        n=records[key];art=f"[Arte]({rel(R/n['art'])})" if n.get('art') else 'Sem arte individual resolvida'
        lines.append(f"| {n['name']} · `{key}` | {n['family_name']} | {n['stage']} | {n['status']} | {art} · [Fonte]({rel(R/n['source'])}) |")
    lines += ['','**Fontes do conjunto/classificação:** '+', '.join(f'[{Path(s).name}]({rel(R/s)})' for s in dict.fromkeys(g['sources']))+'.']
lines += ['','## Reservas e rejeitados','', 'As 17 reservas visuais continuam no apêndice do catálogo familiar. Não foram inseridas como espécies acabadas. Mantigardo rejeitado e versões superadas permanecem no histórico, sem entrar nos Lords atuais.','','## Identidade e autoria das decisões','', 'Família e IDs originais preservados. Azulão/Azulongo, Brotim do cervo/Brotim de Mata Verde e nomes parecidos não foram fundidos. O catálogo consolidou os três documentos recentes do Rabbito na mesma família, adicionando duas formas sem duplicar a base. A aprovação visual do Conde refere-se exclusivamente ao concept-v2 com juba.','','## Regenerar','', '`python documentation/creatures/familias/gerar_catalogo.py` e depois `python documentation/creatures/familias/gerar_grupos.py`. A classificação editável está em `grupos-config.json`; as decisões explícitas recentes em `decisoes-visuais.json`.','']
lines[8:8]=[
    'As fichas da galeria incluem **Lore para concept** e **Na prancha**. O primeiro texto descreve um comportamento ou traço da forma; o segundo indica como representá-lo em desenho. Os dois são propostas de criação. A nota do catálogo de origem e o link da fonte dão acesso ao contexto anterior.',
    '',
    'Para revisar uma proposta, edite [a fonte de lore](lore-por-criatura.txt) no bloco da família correspondente. Cada linha guarda ID, lore e indicação de prancha, separados por `|`. Os entrelaços compartilhados ficam no bloco `shared`. Rode o gerador de grupos após salvar.',
    '',
]
(D/'GRUPOS.md').write_text('\n'.join(lines),encoding='utf-8')

template=Path(__file__).with_name('grupos-template.html').read_text(encoding='utf-8')
payload=json.dumps(data,ensure_ascii=False).replace('<','\\u003c')
(D/'grupos.html').write_text(template.replace('__CATALOG_DATA__',payload),encoding='utf-8')
report=dict(date=config['date'],counts=counts,duplicate_family_ids=[],uncovered_records=uncovered,missing_references=sources_missing,invalid_selectors=problems,distinct_keys=len(records),group_membership_count=sum(len(g['member_keys']) for g in groups),approval_checks={n['id']:n['art'] for n in records.values() if n['id'].startswith('rabbito-')},scope='Validação de dados e caminhos, não teste de gameplay ou nova auditoria visual dos designs.')
dump(D/'validacao-grupos.json',report)
print(json.dumps(report,ensure_ascii=False,indent=2))
