"""Consolida fontes locais sem alterar charts, rigs, aprovações ou código do jogo."""
from pathlib import Path
from collections import Counter, defaultdict
import json, re, html, os

D=Path(__file__).resolve().parent
R=D.parents[2]
def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):
    return os.path.relpath(p,D).replace('\\','/')
def repo(p):
    return p.relative_to(R).as_posix()
def resolve(base,value):
    if not isinstance(value,str) or not value:return None
    p=(base/value).resolve()
    return p if p.is_file() else None
def link(p,label='fonte'):
    return '['+label+']('+rel(p)+')' if p else '—'
def stage(n):
    return n.get('maturity') or n.get('age') or {1:'Bebê',2:'Criança',3:'Jovem',4:'Adulto'}.get(n.get('stage'),'Não definido')
def status(n):
    if n.get('decision_status'):return {'approved':'Aprovado visualmente','proposed':'Proposto','rejected':'Rejeitado','superseded':'Superado'}.get(n['decision_status'],n['decision_status'])
    if n.get('visualApproval'):return 'Aprovado visualmente (registro visual)'
    return 'Existente' if n.get('status')=='existente' else 'Estado visual a conferir'
def rg_image(folder):
    if not folder.exists():return None
    for pattern in ['cutout-rig-v*/preview.png','color-rig-v*/concept.png','color-rig-v*/assembly-review.png','cutout-rig-v*/review-full.png','concept-v*/concept.png','concept-v*/prancha.png','concept-v*/prancha-*.png','color-rig/concept.png','**/source.png']:
        ps=sorted(folder.glob(pattern),reverse=True)
        if ps:return ps[0]
    return None
def rig_for(id):
    folder=R/'art/soulgen/keys'/id
    candidates=[p for p in folder.glob('**/*.soulgen.json') if 'portable' not in p.name and not p.name.startswith('author-')]
    if candidates:
        candidates.sort(key=lambda p:('cutout-rig' in str(p),int((re.search(r'-v(\d+)',str(p)) or [None,'0'])[1]),str(p)),reverse=True)
        return candidates[0]
    ps=sorted(folder.glob('**/rig.mjs'),reverse=True)
    return ps[0] if ps else None
families=[]; warnings=[]; charts=[]; seen_ids=set()
names={'azulao':'Azulão','cacaurama':'Cacau e preguiça — dois ramos','capivara-boia':'Capivara aquática / Capiboia','caracol-pneu':'Caracol + pneu','caramund':'Caramelo / Caramund','carcara':'Carcará','cervarco-family-v1':'Cervo / Cervarco','chaspiral':'Chaspiral / chapeleira','coruja-balanca':'Coruja da balança','doberman-c':'Dóber / Dobrácula','estratonte-family-v1':'Fóssil brontossauro / Estratonte','flautrevo':'Flautrevo / morcego flautista','galofuso-family-v1':'Galo de combate / Galofuso','gambalhote':'Gambá / Gambalhote','gata-lunar':'Gata lunar / Noctiluna','hipolanterna-family-v1':'Cavalo-marinho + abóbora','javali-guerreiro':'Javali guerreiro','lobo-cordeiro':'Lobo em pele de cordeiro','mata-verde':'Mata Verde','mico-samurai':'Mico samurai','pangolim-trovao':'Pangolim trovejante','alvacordo-family-v1':'Husky / border collie de papel','rabbito':'Rabbito','rai':'Rai / Saber','raio-de-sol':'Raio de Sol','rexestrato-family-v1':'Fóssil T-rex / Rexestrato','riscaz':'Riscaz','tramino':'Dragão / Tramino','trinca-brasas':'Trinca-brasas / cérbero','urso-polar':'Urso polar / Borealvo','viuva-anjo':'Viúva-negra / Seraf Seda','yaguaru-memoria':'Yaguarú / onça mumificada','anaconda-retrato':'Anaconda do retrato'}
chart_paths=sorted((R/'documentation/creatures').glob('*/chart.json'))
for p in chart_paths:
    if p.parent.name in ['rabbito-chart-v1','cacaurama-preguica-chart-v1','estrato-rex-entrelaco-v1']:continue
    c=read(p);fid=c.get('family_id') or 'azulao'
    sources=[p]; raw=list(c['nodes']);edges=list(c.get('edges',[]))
    if fid=='cacaurama':
        q=R/'documentation/creatures/cacaurama-preguica-chart-v1/chart.json';c2=read(q);sources.append(q)
        ids={n['id'] for n in raw};raw += [n for n in c2['nodes'] if n['id'] not in ids];edges+=c2['edges']
    f={'id':fid,'name':('Lince de Cerco' if fid=='lince-de-cerco' else names.get(fid,fid)),'category':'Famílias com chart','sources':[repo(x) for x in sources],'nodes':[],'edges':edges,'notes':[]}
    for n in raw:
        base=p.parent
        if fid=='cacaurama' and (n['id'].startswith('preguicau') or n['id']=='cacau-baby'):base=sources[-1].parent
        art=resolve(base,n.get('art'));brief=resolve(base,n.get('brief'))
        if fid=='azulao':
            key=n.get('art');art=resolve(p.parent,c.get('sources',{}).get(key))
            own=R/'art/creatures/azulao-family-v1'/n['id']
            for v in ['concept-pipa-v3/concept.png','rosto-adulto-v3/concept.png']:
                if (own/v).exists():art=own/v;break
            brief=next(iter(own.glob('**/brief.md')),None)
        n2={'id':n['id'],'name':n['name'],'kind':n.get('kind','stage'),'stage':stage(n),'grade':n.get('stage'),'status':status(n),'production':n.get('production_status','Concept/documentação'),'story':n.get('story') or n.get('tagline') or n.get('identity',''),'art':repo(art) if art else None,'brief':repo(brief) if brief else None,'source':repo(sources[-1] if base==sources[-1].parent else p),'rig':repo(rig_for(n['id'])) if rig_for(n['id']) else None}
        if fid=='rai' and n['id']=='arauto-da-tempestade':n2['reference_only']=True;n2['story']='Parceiro externo da família Rabbito para o Entrelaço; não é evolução de Rai.'
        if n.get('art') and not art:f['notes'].append('Arte não resolvida no nó '+n['id']+'; consultar fonte em vez de presumir ausência de design.')
        f['nodes'].append(n2);seen_ids.add(n['id'])
    if fid=='cacaurama':f['notes'].append('Bebê Cacau compartilhado pelos ramos fruto e preguiça; contado uma vez. Aprovação do ramo preguiça não aprova automaticamente o ramo fruto. Adulto do fruto está em brief, sem PNG atual nesta pasta.')
    if fid=='mata-verde':f['notes'].append('Brotim também é ID/nome do bebê do cervo em outro chart. Manter identidade qualificada pela família; não é a mesma criatura.')
    if fid=='raio-de-sol':f['notes'].append('Chart usa age em vez de grau numérico; não foi criado jovem. Não preencher essa lacuna por dedução.')
    if fid=='azulao':
        z=R/'art/creatures/azulao-family-v1/azulao-zokk/concept-v1/concept.png'
        f['nodes'].append({'id':'azulao-zokk','name':'Fera marítima do Chifre de Zokk (rótulo)','kind':'configuration','stage':'Não definido','grade':None,'status':'Concept apreciado na conversa; manifesto ainda em avaliação','production':'Concept','story':'Transformação por material raro explorada; posição e requisitos não definidos.','art':repo(z),'brief':None,'source':'art/creatures/azulao-family-v1/DECISOES.md','rig':None})
        f['notes'].append('Alísio (pégaso) e Monção (inseto) são formas especiais; possessão de Azulfazo é estado, não novo degrau. Arte final de Azultor preserva corpo aprovado e rosto adulto revisto; metadados de versões antigas continuam divergentes.')
    if c.get('family_name'):
        f['name']=c['family_name']
    elif fid not in names:
        adult_name=next((n['name'] for n in f['nodes'] if n['id']==fid),None)
        if adult_name:f['name']=adult_name
    previous=next((x for x in families if x['id']==fid),None)
    if previous:
        previous['sources']=list(dict.fromkeys(previous['sources']+f['sources']))
        by_id={n['id']:n for n in previous['nodes']}
        for node in f['nodes']:
            if node['id'] not in by_id:
                previous['nodes'].append(node);by_id[node['id']]=node
            elif node['status'].startswith('Aprovado') and not by_id[node['id']]['status'].startswith('Aprovado'):
                by_id[node['id']].update(node)
        relations={(e['from'],e['to'],e.get('kind')) for e in previous['edges']}
        for edge in f['edges']:
            key=(edge['from'],edge['to'],edge.get('kind'))
            if key not in relations:previous['edges'].append(edge);relations.add(key)
        previous['notes']+=f['notes']
    else:families.append(f)
    charts.append(p)

def extra(fid,id,name,art,source,stage_label='Não definido',kind='configuration',note=''):
    f=next(x for x in families if x['id']==fid)
    f['nodes'].append(dict(id=id,name=name,kind=kind,stage=stage_label,grade=None,status='Consultar decisão na fonte',production='Concept',story=note,art=art,brief=source,source=source,rig=None));seen_ids.add(id)
extra('capivara-boia','capibaluarte','Capibaluarte','art/creatures/onze-cavaleiros-v1/capibaluarte/concept-v1/concept.png','art/creatures/onze-cavaleiros-v1/capibaluarte/DECISOES.md','Adulto / candidato de rota','stage','Cavaleiro visual aprovado; ligação com os ramos B/C não definida.')
extra('capivara-boia','herdeiro-de-ghinues','Herdeiro de Ghinues (rótulo)','art/creatures/capivara-boia-family-v1/herdeiro-de-ghinues/concept-v1/concept.png','art/creatures/capivara-boia-family-v1/herdeiro-de-ghinues/concept-v1/brief.md',note='Remonta Especial proposta pelo Martelo de Ghinues; forma-base e estágio indefinidos. Ghinues é outra criatura, sem design produzido neste estudo.')

# A criança redesenhada e a base Soulgen de Raio de Sol são a mesma identidade.
sol=next(f for f in families if f['id']=='raio-de-sol')
solbase=next(n for n in sol['nodes'] if n['id']=='raio-de-sol-crianca')
solbase['aliases']=['raio-de-sol'];seen_ids.add('raio-de-sol')
sr=rig_for('raio-de-sol');solbase['rig']=repo(sr) if sr else None
sol['notes'].append('raio-de-sol-crianca é ID do concept da base raio-de-sol no Soulgen/Dex; não contado como segunda família.')

dex=read(R/'assets/pipa-dex.json')['entries'];dexmap={x['id']:x for x in dex}
legacy_records={x['id']:x for x in read(R/'art/soulgen/pendentes/inventario.json')['records']}
keys=R/'art/soulgen/keys'
exclusions={'_exemplo-carcara','arvores-frutiferas','basic-color-v1','basic-color-v2','kael','kael-frame-test','kael-mounted-rig-v1','kael-v2','park-wind-v1','park-wind-v2','village-isometric-v1','lacertubo-v2'}
def single(fid,name,ids,notes='',category='Criaturas sem linha evolutiva definida',arts=None):
    f={'id':fid,'name':name,'category':category,'sources':[],'nodes':[],'edges':[],'notes':[notes] if notes else []}
    for id,label in ids:
        folder=keys/id;rig=rig_for(id);art=rg_image(folder)
        if not art:
            legacy=legacy_records.get(id,{}).get('reference')
            if legacy and (R/legacy).is_file():art=R/legacy
        if id=='eremor' and (R/'art/concepts/eremor-v1/eremor.png').is_file():art=R/'art/concepts/eremor-v1/eremor.png'
        if arts and id in arts:art=R/arts[id]
        source=rig or (folder/'README.md' if (folder/'README.md').exists() else R/'assets/pipa-dex.json')
        f['nodes'].append(dict(id=id,name=label,kind='state' if len(ids)>1 else 'stage',stage='Não definido',grade=None,status='Estado conforme fonte; não inferido de existência de pasta',production='Projeto Soulgen existente' if rig else 'Arte/registro existente',story=dexmap.get(id,{}).get('title',''),art=repo(art) if art and art.exists() else None,brief=None,source=repo(source),rig=repo(rig) if rig else None))
        f['sources'].append(repo(source));seen_ids.add(id)
    families.append(f);return f
single('retalho','Retalho — identidade e máscara',[('retalho-original','Retalho original'),('retalho-mascarada','Retalho mascarada / cicatrizes')],'Duas apresentações narrativas da mesma identidade. Não são bebê e adulto; sequência de recuperação depende da história.')
single('mormaco','Mormaço — livre e possuído',[('mormaco','Mormaço livre'),('mormaco-possuido','Mormaço possuído')],'O estado do Carretel Negro não é evolução natural. Consultar DECISOES e bíblia; não presumir nova espécie.',arts={'mormaco':'art/creatures/mormaco/model-c-v1/prancha-c-livre.png','mormaco-possuido':'art/creatures/mormaco/possessed-c-v2/prancha-possuido.png'})
single('pipa-dragao','Pipa-Dragão — sobrecarregada e desatada',[('pipa-dragao','Pipa-Dragão sobrecarregada / químico B'),('pipa-dragao-desatada','Pipa-Dragão desatada')],'Forma desatada é mudança narrativa de sobrecarga; não estágio bebê. Pumas antigos foram preservados como outros conceitos, não esta espécie.')
isolated_names={'eremor':'Eremor','platyx':'Platyx','trovareta':'Trovareta','rabiolava':'Rabiolava','glacerol':'Glacerol','tufanocorte':'Tufanocorte'}
for id in sorted(set(dexmap)|set(p.name for p in keys.iterdir() if p.is_dir() and p.name not in exclusions)):
    if id in seen_ids or id in exclusions:continue
    n=dexmap.get(id,{}).get('name') or isolated_names.get(id,id)
    single(id,n,[(id,n)],'Sem parentesco evolutivo documentado; não unir por semelhança de nome ou tema.')
for id,name in [('lince-de-cerco','Lince de cerco'),('tamandua-tear','Tamanduá-tear'),('ibex-astrolabio','Íbex-astrolábio')]:
    if id in seen_ids:continue
    f=single(id,name,[(id,name)],'Piloto quadrúpede adulto proposto, sem pré-evoluções criadas.',arts={id:'art/creatures/'+id+'/concept-v1/concept.png'})
    n=f['nodes'][0];n['stage']='Adulto (proposta)';n['production']='Concept';n['source']=n['brief']='art/creatures/'+id+'/concept-v1/brief.md'
    m=read(R/'art/creatures'/id/'concept-v1/manifest.json');n['status']=status(m)
    f['sources']=[n['source']]
single('veskoro','Veskoro — crocodiliano de Caio',[('veskoro','Veskoro')],'Crocodiliano-caio é ID antigo do mesmo design. Uma pose de combate não equivale a rig articulado.',arts={'veskoro':'art/creatures/veskoro/battle-v1/source.png'})['sources']=['art/creatures/veskoro/battle-v1/README.md','art/creatures/crocodiliano-caio/concept-v1/brief.md']
for fid,source in [('mormaco','art/creatures/mormaco/DECISOES.md'),('veskoro','art/creatures/veskoro/battle-v1/README.md')]:
    f=next(f for f in families if f['id']==fid)
    for n in f['nodes']:
        if n['source']=='assets/pipa-dex.json':n['source']=source
    if source not in f['sources']:f['sources'].append(source)

fusion=read(R/'documentation/creatures/estrato-rex-entrelaco-v1/chart.json')
f={'id':'entrelacos','name':'Entrelaços — referências cruzadas','category':'Fusões entre famílias','sources':['documentation/creatures/estrato-rex-entrelaco-v1/chart.json','documentation/creatures/rai-chart-v1/chart.json'],'nodes':[],'edges':[],'notes':['Participantes continuam em suas famílias. Resultado contado uma vez; fusão não inventa um quinto estágio.']}
for path,nid,story in [('documentation/creatures/estrato-rex-entrelaco-v1/chart.json','paleorix','Estratonte + Rexestrato → Paleórix.'),('documentation/creatures/rai-chart-v1/chart.json','entreflor','Raiatar + Arauto da Tempestade → Entreflor.')]:
    cp=R/path;c=read(cp);n=next(n for n in c['nodes'] if n['id']==nid);p=resolve(cp.parent,n.get('art'))
    f['nodes'].append(dict(id=nid,name=n['name'],kind='interweaving',stage='Entrelaço; sem grau atribuído',grade=None,status=status(n),production=n.get('production_status','Concept'),story=story,art=repo(p) if p else None,brief=None,source=path,rig=None))
    f['edges'] += [e for e in c['edges'] if e['to']==nid]
families.append(f)

reserve=read(R/'art/soulgen/campaign-redesigns-v1/catalogo-concepts.json')
reservations=[]
for x in reserve['concepts']:
    if x['id'].startswith('reserva-'):
        art=R/'art/soulgen/campaign-redesigns-v1'/x['fonte']
        reservations.append(dict(id=x['id'],name=x['descricao'],option=x.get('opcao'),art=repo(art) if art.exists() else None,source='art/soulgen/campaign-redesigns-v1/catalogo-concepts.json'))
for prefix,file,opts in [('mormaco-v1','art/creatures/mormaco/concept-v1/exploracao-abcd.png','ABCD'),('mormaco-geiser-v2','art/creatures/mormaco/concept-v2-geiser/exploracao-abcd.png','ABD')]:
    for o in opts:reservations.append(dict(id=prefix+'-'+o.lower(),name='Reserva '+prefix+' opção '+o,option=o,art=file,source='art/creatures/reservas/quatro-guardioes-v1.md'))
for o in 'AB':reservations.append(dict(id='puma-pipa-dragao-v3-'+o.lower(),name='Puma roxo preservado '+o,option=o,art='art/creatures/pipa-dragao/concept-v3/exploracao.png',source='art/creatures/dragao-quimico/concept-v1/brief.md'))

# Decisões explícitas recentes, qualificadas por família e versão exata.
decisions_path=D/'decisoes-visuais.json'
if decisions_path.exists():
    for decision in read(decisions_path)['decisions']:
        family=next(f for f in families if f['id']==decision['family_id'])
        node=next(n for n in family['nodes'] if n['id']==decision['node_id'])
        assert (R/decision['art']).is_file(),decision['art']
        node.update(status='Aprovado visualmente',art=decision['art'],approval_note=decision['quote']+' — '+decision['scope'])
        if repo(decisions_path) not in family['sources']:family['sources'].append(repo(decisions_path))

# Avisos de divergência são editoriais; fontes não são reescritas.
warnings += ['Brotim aparece no cervo e em Mata Verde; IDs precisam ser qualificados por família.', 'Azulão e Azulongo são registros distintos; não foi inventada ligação entre eles.', 'Micofolha e mico-samurai; Rexal e Rexestrato; Jaguarluar e Yaguarú também não foram fundidos por semelhança.', 'Há aprovações na conversa que não chegaram aos charts antigos. O catálogo conserva o estado registral e aponta a divergência, sem reaprovar automaticamente.', 'Nomes de trabalho aprovados visualmente não se tornam nomes definitivos de espécie.', 'Existência de rig não comprova integração, animação aprovada ou uso atual no jogo.', 'Ghinues e Zokk são criaturas mencionadas como origem de relíquias; sem design próprio identificado neste levantamento.', 'O tema Onze Cavaleiros é uma coleção transversal, não família biológica nem lista fechada de onze membros aprovados.']
all_records=[(f,n) for f in families for n in f['nodes'] if not n.get('reference_only')]
unique={}
for f,n in all_records:
    key=('shared:'+n['id']) if n['id'] in ['entreflor','paleorix'] else f['id']+':'+n['id']
    unique[key]=(f,n)
counts=dict(families=len([f for f in families if f['category']!='Fusões entre famílias']),families_with_chart=len(charts),unique_records=len(unique),visual_reservations=len(reservations),dex_entries=len(dex),chart_sources=len(chart_paths))
data=dict(date='2026-11-10',scope='Checkout local pipa-club-integracao-atualizada; art/creatures, charts, Soulgen e Dex. Sem integração ou alteração de cânone. Charts da mesma família consolidados por ID.',counts=counts,families=families,reservations=reservations,warnings=warnings)
D.mkdir(parents=True,exist_ok=True)
(D/'catalogo.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

lines=['# Famílias de Soulmonsters — catálogo consolidado','', 'Atualizado em **10 de novembro de 2026**. Documento de organização de criação, não novo cânone ou lista de integração.','', '**Comece pelos [grupos do universo](GRUPOS.md) ou pela [galeria visual por grupos](grupos.html).** Famílias evolutivas e grupos temáticos são eixos diferentes; um grupo não cria parentesco ou facção.','',f"**{counts['families']} agrupamentos familiares**, com {counts['families_with_chart']} fontes de charts consolidadas; **{counts['unique_records']} registros únicos de formas/criaturas**, além de **{counts['visual_reservations']} reservas visuais**. Criaturas isoladas recebem ficha familiar de uma forma, com parentesco ainda indefinido. Contagens incluem briefs sem arte e estados; não são quantidade de espécies prontas para o jogo.",'','## Como ler','', '- Bebê, criança, jovem e adulto descrevem maturidade visual; Cafifa/Pipa/Arraia/Pandorga só são graus confirmados quando a fonte assim decidir.', '- Remonta, forma especial, possessão e Entrelaço têm naturezas diferentes. Nenhum custo, nível ou receita é inventado aqui.', '- A coluna de estado reproduz o registro local. Aprovado visualmente não significa nome, gameplay, rig ou integração aprovados.', '- Versões antigas do mesmo design não viram novas criaturas. Reservas sem parentesco ficam em apêndice.', '- Nesta consolidação, Brotim do cervo e Brotim de Mata Verde permanecem separados. A fusão Entreflor e seu participante externo não duplicam a contagem.','','## Índice de famílias','', '| Família | Formas/referências | Tipo de registro |','|---|---:|---|']
for i,f in enumerate(families,1):lines.append(f"| [{f['name']}](#familia-{i:02d}) | {len(f['nodes'])} | {f['category']} |")
for i,f in enumerate(families,1):
    lines += ['',f'<a id="familia-{i:02d}"></a>',f"## {i:02d}. {f['name']}",'',f"Identificador de organização: `{f['id']}`. Grupo: {f['category']}.",'']
    if f['edges']:
        by={n['id']:n['name'] for n in f['nodes']}
        for e in f['edges']:
            tag={'reweaving':'Remonta','configuration':'Forma especial','possession':'Possessão','interweaving':'Entrelaço'}.get(e.get('kind'),e.get('kind','Relação'))
            lines.append(f"- **{tag}:** {by.get(e['from'],e['from'])} → {by.get(e['to'],e['to'])}. Ligação: {e.get('decision_status','consultar fonte')}.")
    else:lines.append('**Parentesco evolutivo não definido.** As formas narrativas, quando presentes, não representam crescimento automático.')
    lines += ['', '| Forma / ID | Maturidade | Natureza | Estado registral | Arte / produção |','|---|---|---|---|---|']
    for n in f['nodes']:
        art=link(R/n['art'],'Arte') if n['art'] else 'Sem PNG individual resolvido'
        rig=' · '+link(R/n['rig'],'Soulgen') if n.get('rig') else ''
        lines.append(f"| {n['name']} — `{n['id']}` | {n['stage']} | {n['kind']} | {n['status']} | {art}{rig} |")
    lines += ['', '**Identidade e função documentadas:**','']
    for n in f['nodes']:
        if n['story']:lines.append('- **'+n['name']+':** '+n['story'].replace('\n',' '))
    if f['notes']:lines += ['', '**Cuidados e lacunas:**']+['- '+x for x in dict.fromkeys(f['notes'])]
    lines += ['', '**Fontes:** '+', '.join(link(R/s,Path(s).name) for s in dict.fromkeys(f['sources']))+'.']
lines += ['', '## Reservas preservadas para futuros Soulmonsters','', 'Não são evoluções automáticas das criaturas cuja exploração as originou. A mesma prancha pode conter várias reservas.', '', '| Reserva | Opção | Arte | Fonte |','|---|---|---|---|']
for x in reservations:lines.append(f"| {x['name']} — `{x['id']}` | {x['option']} | {link(R/x['art'],'Prancha') if x['art'] else 'Consultar fonte'} | {link(R/x['source'])} |")
lines += ['', '## Lacunas de organização e decisões pendentes','']+['- '+x for x in warnings]
lines += ['', '## Histórico, variantes e alternativas fora do chart','', 'Os diretórios abaixo preservam estudos anteriores, correções ou candidatos. Não contabilizamos cada arquivo como novo Soulmonster. O arquivo `inventario-fontes.json` lista todos os PNGs e manifestos da área de criaturas para rastreabilidade.','']
for p in sorted((R/'art/creatures').iterdir()):
    if p.is_dir():lines.append('- '+link(p,p.name))
lines += ['', '## Atualização','', 'Regenerar com `python documentation/creatures/familias/gerar_catalogo.py`. Ajustes editoriais e aliases ficam neste gerador; não altera os documentos originais. Rig detectado é evidência de arquivo local, não teste de runtime. Não foram abertos todos os PNGs nesta tarefa: a organização utiliza metadados, decisões e revisão das fontes, não uma nova auditoria visual de cada criatura.','']
(D/'FAMILIAS.md').write_text('\n'.join(lines),encoding='utf-8')

def esc(x):return html.escape(str(x),quote=True)
cards=[]
for i,f in enumerate(families,1):
    ns=[]
    for n in f['nodes']:
        art=rel(R/n['art']) if n['art'] else None
        pic='<a href="'+esc(art)+'"><img loading="lazy" src="'+esc(art)+'" alt="'+esc(n['name'])+'"></a>' if art else '<div class="noart">Arte não resolvida<br>Consultar fonte</div>'
        ns.append('<article>'+pic+'<h3>'+esc(n['name'])+'</h3><p class="tag">'+esc(n['stage'])+' · '+esc(n['kind'])+'</p><p>'+esc(n['status'])+'</p><p>'+esc(n['story'])+'</p><a href="'+esc(rel(R/n['source']))+'">Fonte</a>'+(' · <a href="'+esc(rel(R/n['rig']))+'">Soulgen</a>' if n.get('rig') else '')+'</article>')
    edges=''.join('<li>'+esc(e['from'])+' → '+esc(e['to'])+' <b>('+esc(e.get('kind',''))+')</b></li>' for e in f['edges'])
    searchable=' '.join([f['name'],f['id'],f['category']]+[n['name']+' '+n['id'] for n in f['nodes']]).casefold()
    cards.append('<section data-search="'+esc(searchable)+'" data-category="'+esc(f['category'])+'"><h2>'+str(i).zfill(2)+'. '+esc(f['name'])+'</h2><p class="tag">'+esc(f['category'])+'</p><div class="grid">'+''.join(ns)+'</div>'+('<details><summary>Relações documentadas</summary><ul>'+edges+'</ul></details>' if edges else '<p>Parentesco evolutivo não definido.</p>')+''.join('<p class="note">'+esc(x)+'</p>' for x in f['notes'])+'</section>')
categories=sorted(set(f['category'] for f in families))
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Famílias de Soulmonsters</title><style>*{box-sizing:border-box}body{margin:0;background:#f1eee5;color:#182d36;font:16px/1.55 system-ui}header,main{max-width:1500px;margin:auto;padding:32px}header h1{font-size:clamp(30px,4vw,54px);line-height:1.1;margin:10px 0}header p{max-width:900px}.tools{display:flex;gap:12px;flex-wrap:wrap;margin-top:24px}input,select{font:inherit;padding:12px;border:1px solid #82959a;border-radius:6px;background:white}input{flex:1;min-width:210px}section{background:#fff;padding:28px;margin-bottom:28px;border-top:5px solid #254956;border-radius:6px}h2{margin:0 0 8px;font-size:27px}h3{font-size:18px;margin-bottom:6px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin:22px 0}article{min-width:0;border:1px solid #d9e0df;padding:16px;border-radius:6px}img,.noart{width:100%;height:260px;object-fit:contain;background:white}.noart{display:grid;place-content:center;text-align:center;background:#edf1ef;color:#52666c}.tag{font-size:13px;font-weight:700;color:#496b74}.note{padding:12px 16px;background:#fff3d1;border-left:4px solid #a77924}a{color:#126478;text-underline-offset:3px}a:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid #ad452c;outline-offset:4px}details{margin:15px 0}li{overflow-wrap:anywhere}[hidden]{display:none!important}.footer{max-width:1500px;margin:auto;padding:0 32px 48px}.reserve{columns:2;column-gap:30px}@media(max-width:650px){header,main{padding:20px}section{padding:20px}.reserve{columns:1}}</style><header><p>CATÁLOGO DE CRIAÇÃO · 04 NOV 2026</p><h1>Famílias de Soulmonsters</h1><p>Estágios, ramificações, estados e Entrelaços reunidos. Aprovação visual e integração são decisões diferentes; nomes de trabalho continuam identificados nas fontes.</p><p>COUNTS</p><p><a href="FAMILIAS.md">Documento completo</a> · <a href="catalogo.json">Dados estruturados</a> · <a href="auditoria.json">Auditoria de referências</a></p><div class="tools"><input id="search" type="search" aria-label="Buscar família ou Soulmonster" placeholder="Buscar nome, família ou ID"><select id="category" aria-label="Filtrar grupo"><option value="">Todos os grupos</option>OPTIONS</select></div><p id="result" aria-live="polite"></p></header><main>CARDS</main><div class="footer"><h2>Reservas visuais</h2><p>Alternativas preservadas; nenhum parentesco novo inferido.</p><ul class="reserve">RESERVES</ul><h2>Cuidados do catálogo</h2><ul>WARNINGS</ul><p>O levantamento verifica fontes locais e links. Não é nova auditoria visual de todos os PNGs nem teste de integração no jogo.</p></div><script>const q=document.querySelector('#search'),c=document.querySelector('#category'),ss=[...document.querySelectorAll('main section')];function filter(){const term=q.value.trim().toLocaleLowerCase('pt-BR');let visible=0;for(const s of ss){const ok=(!term||s.dataset.search.includes(term))&&(!c.value||s.dataset.category===c.value);s.hidden=!ok;if(ok)visible++}document.querySelector('#result').textContent=visible+' agrupamentos exibidos'}q.addEventListener('input',filter);c.addEventListener('change',filter);filter();</script></html>'''
page=page.replace('COUNTS',esc(f"{counts['families']} agrupamentos familiares · {counts['unique_records']} registros únicos · {counts['visual_reservations']} reservas" )).replace('OPTIONS',''.join('<option>'+esc(x)+'</option>' for x in categories)).replace('CARDS',''.join(cards)).replace('RESERVES',''.join('<li>'+esc(x['name'])+(' · <a href="'+esc(rel(R/x['art']))+'">Prancha</a>' if x['art'] else '')+'</li>' for x in reservations)).replace('WARNINGS',''.join('<li>'+esc(x)+'</li>' for x in warnings))
page=page.replace('04 NOV 2026','07 NOV 2026').replace('<h1>Famílias de Soulmonsters</h1>','<h1>Famílias de Soulmonsters</h1><p><a href="grupos.html">Explorar por grupos do universo →</a> · <a href="GRUPOS.md">Documento de grupos</a></p>')
(D/'index.html').write_text(page,encoding='utf-8')
inventory=[repo(p) for p in (R/'art/creatures').rglob('*') if p.is_file() and p.suffix in ['.png','.json','.md']]
(D/'inventario-fontes.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2),encoding='utf-8')
missing=[]
for f in families:
    for n in f['nodes']:
        for field in ['art','source','brief','rig']:
            if n.get(field) and not (R/n[field]).is_file():missing.append(f['id']+':'+n['id']+':'+field+':'+n[field])
for x in reservations:
    for field in ['art','source']:
        if x.get(field) and not (R/x[field]).is_file():missing.append('reserva:'+x['id']+':'+field+':'+x[field])
audit={'counts':counts,'missing_references':missing,'dex_not_covered':[x['id'] for x in dex if x['id'] not in seen_ids],'creature_keys_not_covered':[p.name for p in keys.iterdir() if p.is_dir() and p.name not in exclusions and p.name not in seen_ids],'excluded_noncreature_keys':sorted(exclusions),'duplicate_names':{name:vals for name,vals in ((name,[f['id']+':'+n['id'] for f,n in unique.values() if n['name']==name]) for name in set(n['name'] for f,n in unique.values())) if len(vals)>1},'inventory_files':len(inventory)}
(D/'auditoria.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(audit,ensure_ascii=False,indent=2))
