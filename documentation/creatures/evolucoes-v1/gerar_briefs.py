"""Publica o estudo documental a partir de direções autorais explícitas; não gera arte."""
from pathlib import Path
import html
import json

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
sources = json.loads((BASE / 'fontes.json').read_text(encoding='utf-8-sig'))
directions = json.loads((BASE / 'direcoes.json').read_text(encoding='utf-8-sig'))
dex = {x['id']: x for x in json.loads((ROOT / 'assets/pipa-dex.json').read_text(encoding='utf-8-sig'))['entries']}
by_id = {x['id']: x for x in sources}
grouped = {'azulao': ['azulfazo', 'azulfazo-possuido'], 'retalho-original': ['retalho-mascarada'], 'pipa-dragao': ['pipa-dragao-desatada']}
names = {'doberman-c': 'Dóber — design C', 'rai': 'Rai / Saber', 'retalho-original': 'Retalho — original e mascarada', 'pipa-dragao': 'Pipa-Dragão — sobrecarregada e desatada', 'capivara-boia': 'Capivara-Boia — opção D', 'veskoro': 'Veskoro', 'mormaco': 'Mormaço'}
labels = {'aprovada': 'Rotas evolutivas aprovadas; pré-evolução proposta', 'decisao': 'Proposta condicionada a decisão de identidade', 'origem': 'Proposta condicionada à origem narrativa', 'estado': 'Distinguir evolução natural de mudança de estado', 'guardiao': 'Proposta condicionada ao papel de guardião', 'lenda': 'Preferir estudo de estados; evolução não estabelecida'}
questions = {
 'aprovada': 'Desenvolver primeiro B/velocidade e C/inteligência já aprovadas ou avaliar a pré-evolução? Recomendação: consolidar as rotas existentes antes de acrescentar uma origem.',
 'decisao': 'Resolver a decisão específica descrita nos limites antes de abrir a geração. A proposta ainda não determina nome definitivo nem parentesco.',
 'origem': 'A criatura pode ter uma fase anterior no mundo, apesar da origem particular já narrada? Recomendação: preservar a cena de criação e estudar primeiro um futuro amadurecimento.',
 'estado': 'Há espaço narrativo para uma evolução natural além dos estados já existentes? Recomendação: não chamar as mudanças de estado de evolução só para completar uma linha.',
 'guardiao': 'Os guardiões são indivíduos singulares, espécies com ciclo de vida ou títulos? Recomendação: guardar estas direções como exploração visual até definir isso, sem inserir filhotes no mapa.',
 'lenda': 'Eremor admite desenvolvimento biológico ou apenas manifestação/recolhimento? Recomendação: estudar primeiro o despertar com a mesma identidade.',
}

def link_source(s):
    return '../../../../' + s.replace('\\', '/')

def write(path, body):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding='utf-8')

records = []
index_rows = []
sections = []
continuity = {
 'rabbito': 'Registro existente no web: Velocista → Rastro dos Ventos → Arauto da Tempestade; Condutor → Mestre dos Fios → Tecelão da Aurora; Rabbitknight é especial e não tem sequência. A proposta abaixo explora mobilidade e pode servir ao primeiro caminho, mas não substitui os outros nem aprova novos sprites para eles. A conciliação de classes, formas e remonta está em CHART-E-PRIORIDADES.md.',
 'platyx': 'A bíblia determina Platyx único e reservado à redenção de Grampo. Uma fase anterior ou posterior, se escolhida, é do mesmo indivíduo; não autoriza captura, outro exemplar, empréstimo ao jogador ou encontro selvagem.',
 'retalho-original': 'A seção 7.4 da bíblia contém uma proposta de Retalho evoluir sozinho, que precisa ser conciliada com a remonta da seção 6. Não apagar essa possibilidade nem tratá-la como decisão final. O reencontro com Heleana tem ramificações decididas conforme a escolha de Kael; uma forma nova não deve redefinir esse vínculo.',
 'mormaco': 'A atualização visual da bíblia determina que a libertação devolve Mormaço à forma livre. Isso difere da consequência trágica decidida para Azulfazo de Gollia; a possessão não tem uma consequência universal para todos os parceiros.',
}
for n, d in enumerate(directions, 1):
    d = dict(d)
    ident = d['id']
    name = names.get(ident, dex.get(ident, {}).get('name', ident.capitalize()))
    status = labels.get(d.get('especial'), 'Pré-evolução e evolução propostas; sem chart confirmado')
    refs = [by_id[x] for x in [ident] + grouped.get(ident, [])]
    source_md = '\n'.join('- [' + x['id'] + '](' + link_source(x['source']) + ')' + (' · [notas do rig](' + link_source(x['readme']) + ')' if x.get('readme') else '') for x in refs)
    story = dex.get(ident, {}).get('story', [])
    narrative = '\n\n'.join(story) if story else 'Consultar as notas do rig e as decisões específicas citadas abaixo. A leitura de comportamento neste brief é proposta de direção quando não está documentada na fonte.'
    habit = dex.get(ident, {}).get('habitat', 'Sem habitat adicional fixado por este estudo.')
    context = continuity.get(ident, 'Nenhum vínculo evolutivo adicional é estabelecido por este brief. Ler os limites específicos e o mapa de decisões antes de produzir arte.')
    d['continuidade'] = context
    question = questions.get(d.get('especial'), 'Comparar as duas direções com a base antes de escolher o próximo concept. Este brief não define nível, item, atributo, habitat novo ou disponibilidade da evolução.')
    body = f'''# {n:02d}. {name} — brief de família

Data: 2026-11-03 · ID de referência: `{ident}`

**Estado:** {status}. Só as decisões explicitamente registradas como aprovadas são cânone; todo novo estágio abaixo é proposta.

**Sentido de “fase” neste brief:** uma configuração de corpo menor ou mais desenvolvida, não prova de nascimento ou crescimento biológico. O autor aprovou Remonta / Reweaving e os nomes Cafifa → Pipa → Arraia → Pandorga; consulte [a decisão](../../DECISOES-NOMENCLATURA.md). A aplicação por espécie, os requisitos e o funcionamento da oficina continuam propostas. O estudo visual não os distribui automaticamente nem substitui os caminhos de classe já registrados.

**Continuidade:** {context}

## Referência existente e estudo

{source_md}

**Âncoras observadas na arte:** {d['ancoras']}

**Leitura para o design:** {d['leitura']}

**Habitat registrado no Dex:** {habit}

### Texto de origem disponível

{narrative}

Os parágrafos acima vêm do catálogo quando disponível. Os blocos seguintes são direção criativa, não história incorporada ao jogo.

## Brief da pré-evolução — proposta

{d['pre']}

**Objetivo da prancha:** mostrar uma etapa com função e proporção próprias, reconhecível pelas âncoras da base. Não basta reduzir o tamanho ou aumentar os olhos. Quando o texto recomenda adiar a forma, produzir primeiro a comparação documental, sem inventar infância canônica.

## Brief da evolução — proposta ou decisão indicada

{d['evo']}

**Objetivo da prancha:** demonstrar o ganho de função através de anatomia, postura e movimento. A identidade precisa sobreviver sem nome, aura ou efeito de ataque; não há obrigação de ganhar forma humana, asas ou armadura.

## Paleta e material

{d['cor']}

Traço 2D mangá limpo, planos grandes de cor e sombra curta. Contorno legível para posterior spritelização no Soulgen. Papel, linha e vareta devem integrar a anatomia onde a família já os usa; não impor remendos a todas as criaturas nem transformar toda superfície em losango.

## Limites específicos e decisão pendente

{d['limite']}

{question}

## Pacote de criação depois da escolha

1. Base atual ao lado de três silhuetas da etapa escolhida, na mesma escala de apresentação. Variar distribuição de massa e função, preservando as âncoras deste brief.
2. Testar duas paletas dentro da direção acima; conferir também em cinza e em miniatura.
3. Prancha limpa de frente/três quartos, perfil e costas, expressão neutra, esforço/ataque, dano e alegria. Mostrar um gesto funcional descrito no brief, sem depender de partículas para explicar o corpo.
4. Só depois de aprovação, preparar separação de cabeça, torso, membros, asas, rabiola com seu fio e faces completas. Não criar um rig definitivo a partir de peças que escondem anatomia ausente.

## Conferência específica

- [ ] As âncoras listadas continuam reconhecíveis sem legenda.
- [ ] O novo gesto e a nova proporção distinguem o estágio da base.
- [ ] Os limites específicos acima foram conferidos lado a lado com a referência.
- [ ] A paleta tem separação de massas sem excesso de retalhos ou textura.
- [ ] A mudança foi classificada corretamente: estágio natural, ramificação ou estado.
- [ ] Aprovação de concept registrada antes de alterar chart, animações ou jogo.
'''
    write(BASE / 'briefs' / f'{ident}.md', body)
    records.append({**d, 'nome': name, 'estado': status, 'referencias': refs, 'brief': f'briefs/{ident}.md'})
    index_rows.append(f"| {n:02d} | [{name}](briefs/{ident}.md) | {status} |")
    paragraphs = [('Identidade existente', d['ancoras']), ('Leitura', d['leitura']), ('Continuidade', context), ('Pré-evolução — proposta', d['pre']), ('Evolução', d['evo']), ('Cor', d['cor']), ('Limites e decisão', d['limite'] + ' ' + question)]
    sections.append(f'<article id="{ident}"><span class="tag">{html.escape(status)}</span><h2>{n:02d}. {html.escape(name)}</h2>' + ''.join(f'<h3>{html.escape(k)}</h3><p>{html.escape(v)}</p>' for k,v in paragraphs) + f'<p><a href="briefs/{ident}.md">Abrir brief completo e fontes</a></p></article>')

assert len(directions) == 50
assert len({x['id'] for x in directions}) == 50
covered = {x['id'] for d in directions for x in [by_id[d['id']]] + [by_id[y] for y in grouped.get(d['id'], [])]}
assert covered == set(by_id), (covered ^ set(by_id))
assert set(dex).issubset(covered)
for s in sources:
    assert (ROOT / s['source']).exists(), s['source']
    if s.get('readme'):
        assert (ROOT / s['readme']).exists(), s['readme']
write(BASE / 'briefs.json', json.dumps(records, ensure_ascii=False, indent=2) + '\n')
write(BASE / 'README.md', '''# Pré-evoluções e evoluções — estudo do elenco existente

2026-11-03 · Base local `ffda7042` · branch `codex/integracao-atualizada-local`.

**54 referências visuais estudadas, organizadas em 50 dossiês de identidade.** O número não equivale a 50 famílias evolutivas confirmadas: agrupa somente os vínculos já conhecidos e deixa os parentescos restantes em aberto. Os 36 registros do Dex entram no estudo, inclusive desenhos antigos ainda sem conversão completa.

[Abrir leitura visual do estudo](index.html) · [Estudo de evolução em Digimon: Armor, DNA e outros mecanismos](ESTUDO-DIGIMON.md) · [Fonte estruturada](briefs.json) · [Manifesto das imagens](fontes.json) · [Decisões de chart e prioridades](CHART-E-PRIORIDADES.md).

**Atualização após a escolha do autor:** [Remonta / Reweaving e os quatro nomes de estágio estão aprovados](../DECISOES-NOMENCLATURA.md). A distribuição por espécie permanece proposta. [Abrir o primeiro chart completo para teste: Azulão](../azulao-chart-v1/index.html).

## Como foi estudado

Conferência visual estática das 54 referências em seis folhas de contato, consulta dos textos do Dex e das notas disponíveis de arte/rig. A prancha A/B/C do Azulfazo foi conferida separadamente. Este trabalho não audita animações nem prova a jogabilidade de novos estágios. Não foram geradas novas criaturas.

Fontes principais: `assets/pipa-dex.json`, referências identificadas em cada brief, `art/soulgen/keys/*/README.md`, decisões da família Azulfazo e seções de regras/progressão/personagens da bíblia. O registro legado de classes do Rabbito foi conferido na migração 023 e no cliente web; não é prova de implementação equivalente no Godot. Onde a narrativa não está definida, comportamento e parentesco aparecem como proposta.

As referências são os desenhos existentes encontrados nesta base, incluindo arte legada; sua presença não torna todo tratamento visual antigo uma aprovação atual. Novos concepts devem seguir o traço 2D mangá limpo do projeto e as instruções mais recentes do autor: criaturas com cor e anatomia, sem obrigação de retalhos.

## Regras de continuidade

- **Evolução não exige reprodução ou infância biológica:** a remonta preserva a identidade na alma/rabiola. Cafifa → Pipa → Arraia → Pandorga é a nomenclatura aprovada, sem atribuição automática a estes desenhos. “Filhote” nos briefs descreve proporção visual de uma fase menor; não estabelece origem canônica. Requisitos de oficina ainda são propostas.
- O Rabbito já tem caminhos de classe registrados no web: Velocista → Rastro dos Ventos → Arauto da Tempestade; Condutor → Mestre dos Fios → Tecelão da Aurora; Rabbitknight especial sem sequência. O novo estudo visual não os apaga nem promete sua integração no Godot.
- Azulão tem três rotas já aprovadas: A ataque/Azulfazo de Gollia, B velocidade, C inteligência. B e C têm arquiteturas próprias preservadas; nomes específicos e requisitos continuam em aberto.
- Azulfazo possuído, Mormaço possuído, Retalho mascarada e Pipa-Dragão desatada/sobrecarregada são tratados como estados narrativos, não como provas de evolução natural.
- B/C dos guardiões, alternativas de Capivara-Boia e outras opções reservadas pelo autor não são automaticamente evoluções dos escolhidos.
- Não atribuir níveis, stats, afinidades, condições de evolução, locais de captura ou nomes definitivos neste estudo.
- A classificação de Eremor e as origens de Nozinho/Rabbito exigem cuidado narrativo; não inventar filhotes para preencher uma cadeia.

## Briefs individuais

| Nº | Identidade / conjunto conhecido | Estado do trabalho |
| --- | --- | --- |
''' + '\n'.join(index_rows) + '''

## Folhas de contato usadas na revisão

![Referências 01–09](referencias/lote-01.jpg)
![Referências 10–18](referencias/lote-02.jpg)
![Referências 19–27](referencias/lote-03.jpg)
![Referências 28–36](referencias/lote-04.jpg)
![Referências 37–45](referencias/lote-05.jpg)
![Referências 46–54](referencias/lote-06.jpg)
''')

nav = '<a href="../azulao-chart-v1/index.html">Chart completo do Azulão</a><a href="ESTUDO-DIGIMON.md">Estudo de Digimon: Armor, DNA e outros mecanismos</a>' + ''.join(f'<a href="#{r["id"]}">{html.escape(r["nome"])}</a>' for r in records)
contact = ''.join(f'<figure><img loading="lazy" src="referencias/lote-{n:02d}.jpg" alt="Folha de contato {n}"><figcaption>Referências {(n-1)*9+1:02d}–{n*9:02d} · arte existente</figcaption></figure>' for n in range(1,7))
write(BASE / 'index.html', '''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soulmonsters · Estudo de famílias</title><style>
:root{color-scheme:light;font-family:system-ui,sans-serif;background:#f4f0e5;color:#18313b}body{margin:0}header,main{max-width:1120px;margin:auto;padding:32px 24px}header{border-bottom:3px solid #c56b35}h1{font-size:clamp(28px,5vw,48px);max-width:800px}h2{font-size:26px}h3{font-size:16px;margin-bottom:8px}p{line-height:1.65;max-width:900px}a{color:#125c70}nav{display:flex;gap:8px;flex-wrap:wrap;margin:24px 0}nav a{padding:8px 12px;border:1px solid #bdc5bf;border-radius:20px;text-decoration:none;background:#fffaf0}article{background:#fffdf7;padding:28px;margin:28px 0;border:1px solid #d9d2c2;border-left:5px solid #28767e;scroll-margin-top:20px}.tag{font-size:13px;color:#784624}summary{cursor:pointer;font-size:20px;font-weight:650}figure{margin:24px 0}figure img{width:100%;max-width:900px;height:auto}figcaption{font-size:14px;color:#56656b}footer{padding:24px 0;border-top:1px solid #bdc5bf}button{background:#18313b;color:white;padding:10px 16px;border:0;cursor:pointer}.notice{border-left:4px solid #c56b35;padding-left:16px}
</style><header><p>SOULMONSTERS · DIREÇÃO DE CRIATURAS · 03.11.2026</p><h1>Famílias que crescem sem perder a própria identidade.</h1><p>54 referências existentes · 50 briefs individuais. Propostas de pré-evolução e evolução, separadas de estados narrativos e das decisões já aprovadas.</p><p class="notice">Este documento prepara a criação. Não aprova novos estágios nem altera o chart do jogo.</p><p><a href="CHART-E-PRIORIDADES.md">Decisões e ordem recomendada</a> · <a href="README.md">Índice documental</a> · <a href="briefs.json">Dados completos</a></p></header><main><details><summary>Ver as 54 referências estudadas</summary>''' + contact + '''</details><nav aria-label="Ir para uma família">''' + nav + '''</nav>''' + '\n'.join(sections) + '''<footer>Traço 2D mangá, anatomia legível, cor com intenção. Papel e linha integram o corpo; não obrigam todas as criaturas a usar retalhos.</footer></main></html>''')
print(json.dumps({'referencias':len(covered),'briefs':len(records),'fontes_existentes':True,'duplicatas':False}, ensure_ascii=False))
