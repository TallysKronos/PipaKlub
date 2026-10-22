"""Append the supplied design-reference study to freshly built benchmark outputs.

Run through build_benchmark.py, which rebuilds the historical section first.
Original attachments remain byte-identical; only document placement is scaled.
"""
from pathlib import Path
from io import BytesIO
import hashlib
import html
import json

FIELDS = [
    ('silhouette', 'Silhueta e proporção'), ('color', 'Cor e hierarquia de valores'),
    ('construction', 'Construção, vistas e acessórios'), ('expression', 'Expressão e atuação'),
    ('animation', 'Continuidade e custo de animação'), ('application', 'Aplicação original ao PipaKlub'),
    ('avoid', 'O que não transferir'), ('checks', 'Critérios de revisão'),
]

INTRO = (
    'Ampliação de 21/10/2026: 18 pranchas fornecidas pelo responsável pelo PipaKlub, '
    'sendo 12 de personagens humanos e 6 de criaturas. As duas primeiras pranchas '
    'mostram duas pessoas cada: o conjunto reúne 14 designs humanos principais. '
    'O foco é aprender decisões de construção e produção, não atribuir autoria a '
    'desenhistas específicos nem reproduzir personagens das franquias.'
)
METHOD = (
    'Cada ficha separa observação visual, interpretação de atuação e proposta para o '
    'PipaKlub. Identificadores REF-01 a REF-18 seguem exatamente a ordem dos anexos. '
    'Usamos títulos descritivos; Olivia e Lusamine são nomes legíveis nas próprias '
    'folhas. A origem editorial e a autoria individual dos demais materiais não '
    'foram verificadas. Não traduzimos nem inferimos regras a partir das notas '
    'japonesas pequenas. Na REF-08 há aviso de material de desenvolvimento: não '
    'tratá-la como prova de modelo final. São desenhos estáticos, não testes de animação.'
)
LIMITS = (
    'As imagens originais foram copiadas sem alteração para referencias-design/. '
    'O manifesto preserva ordem, nome original, dimensões e SHA-256. Escalas, '
    'simplificações e entregáveis sugeridos abaixo são propostas nossas, não medidas '
    'oficiais das referências. Elas ficam no benchmark, fora dos assets de produção '
    'e do build do jogo. A seção histórica de HUD, datada de 20/10/2026, permanece '
    'como registro daquele piloto; esta ampliação não revalida seus problemas atuais.'
)

HUMAN = [
    ('Uma massa dominante, sinais de apoio',
     'Escolher uma forma primária reconhecível: chapéu largo, gola, mecha, jaleco ou '
     'cabelo preso. Acrescentar sinais secundários só quando reforçam função e '
     'individualidade. A cabeça precisa continuar distinguível sem cor e sem objeto. '
     'A dupla rural/urbana da REF-01 e os dois atletas da REF-02 demonstram contrastes '
     'de massa; não fornecem um figurino pronto para o nosso elenco.'),
    ('Papéis por gesto, não apenas por tema',
     'Professor observa e demonstra; reparador segura ferramentas de maneira plausível; '
     'rival protege ou expõe sua linha com uma atitude própria. Criar ao menos um gesto '
     'cotidiano além da pose de combate. As REF-03, 04, 10 e 11 mostram a utilidade de '
     'pequenas vinhetas de trabalho ou descanso.'),
    ('Família do clube sem apagar diferenças',
     'Compartilhar materiais, um acento ou uma marca pequena. Variar idade, proporção, '
     'massa capilar, distribuição de peso e comportamento. A REF-08 é útil para coesão '
     'de dupla; as REF-06 e 09 para assimetria e massa dominante. Não deduzir caráter, '
     'ocupação ou habilidade a partir de tom de pele, gênero ou corpo.'),
    ('Cor tem área e função',
     'Definir cor dominante, suporte e acento. Avaliar em escala de cinza e no fundo '
     'real. Um personagem não se torna original apenas por recolorir uma roupa '
     'reconhecível. Se cada acessório recebe um acento saturado, o rosto perde prioridade. '
     'A região de maior contraste deve servir a leitura desejada, não decorar tudo.'),
    ('Figurino com continuidade',
     'Desenhar frente, perfil e costas; indicar lado dos acessórios, percurso de alças, '
     'sobreposição e estados removíveis. Óculos, chapéus e bolsas devem ter uma versão '
     'isolada quando sua construção for ambígua. A ficha é um contrato para vários '
     'artistas, não só uma prancha bonita.'),
    ('Expressão preserva anatomia',
     'Olhos, sobrancelhas, mandíbula e postura atuam juntos. Comparar seis emoções '
     'sem trocar implantação de orelhas, tamanho do crânio ou identidade da franja. '
     'A REF-12 mostra a utilidade de reunir expressões ao redor do mesmo modelo. '
     'Detalhe de desenho não substitui repertório emocional.'),
]

CREATURE = [
    ('Espécie + construção + temperamento',
     'Definir animal ou forma-base, como ela existe em papel/vareta/nó e como seu '
     'corpo comunica temperamento. Se o papel só aparece como mochila de pipa '
     'presa a um animal convencional, a integração almática ainda está fraca. '
     'Selecionar um ou dois componentes estruturais em vez de empilhar ornamentos.'),
    ('Órgão dominante e espaço negativo',
     'Cauda na REF-14, asas na REF-16 e juba na REF-17 organizam toda a espécie. '
     'Criar uma hierarquia própria para cada Pipamon. Verificar vãos entre membros, '
     'cabeça e apêndices; eles sustentam reconhecimento em miniatura e durante '
     'sobreposição com linhas e efeitos.'),
    ('Conexões visíveis e funcionais',
     'Rabiola nasce em ponto documentado; membrana prende em estrutura; crina '
     'acompanha cabeça/pescoço; pétalas têm linha ou suporte. O comprimento pode '
     'parecer menor por perspectiva, mas não variar arbitrariamente. Esta regra '
     'responde diretamente a falhas anteriores de cauda solta e peças flutuantes.'),
    ('Uma espécie tem mais de um estado',
     'Repouso, alerta, antecipação, ação, recuperação e dano precisam manter a '
     'mesma identidade. A REF-18 oferece contraste de temperamento; a REF-15 '
     'explica assinatura de ação; a REF-13, peso e postura. Não inferir dano, '
     'raridade ou evolução a partir da aparência de qualquer referência.'),
    ('Materiais e efeitos em camadas distintas',
     'Papel recebe planos e vincos; bambu é estrutura; linha é conexão; brilho '
     'é apresentação. Manter o modelo base legível sem aura. Nas faixas de level '
     'existentes, partículas não podem apagar focinho, linha inimiga ou ponto de '
     'contato. A análise artística não altera os limites de level ou status.'),
    ('Raridade com direção, não inflação',
     'Uma criatura rara pode ter uma transformação de vela, silhueta incomum ou '
     'relação narrativa especial. Coroa, ouro, sino, cristal e brilho em toda '
     'criatura tornam o elenco uniforme. Um motivo bem resolvido vale mais que '
     'muitas famílias de ornamentos sem relação.'),
]

MATRIX = [
    ('Massa da cabeça e roupa', 'REF-01, 02, 05, 09, 12', 'Rosto identificável sem objeto; corpo distinto em silhueta.'),
    ('Ofício e comportamento', 'REF-01, 03, 04, 07, 10, 11', 'Um gesto de rotina e uma pega plausível por objeto.'),
    ('Pertencimento ao elenco', 'REF-02, 08', 'Materiais comuns; cabeças e atitudes diferentes.'),
    ('Assimetria e camadas', 'REF-02, 06, 10, 11', 'Mapa esquerdo/direito e estados de acessórios.'),
    ('Expressões consistentes', 'REF-03, 05, 06, 12, 18', 'Mudança de emoção sem redesenho de identidade.'),
    ('Peso e anatomia', 'REF-13, 15, 17, 18', 'Base de apoio, articulações e volumes coerentes.'),
    ('Apêndice dominante', 'REF-14, 16, 17, 18', 'Âncora, volume e comprimento documentados.'),
    ('Assinatura de ação', 'REF-13, 14, 15, 16, 18', 'Ação compreensível sem partículas ou brilho.'),
]

BRIEFS = [
    ('Kael e Tyler: protagonistas com identidades separadas',
     'Kael usa o atlas aprovado como referência de identidade, não o figurino de '
     'nenhuma folha deste acervo. Tyler é filho do Sr. Assis e tem mechas brancas: '
     'fixar forma, posição e quantidade visual dessas mechas. Propor gestos e '
     'distribuição de massa diferentes para os dois. A semelhança familiar pode '
     'vir de uma atitude ou pequeno detalhe, sem fazê-los recolorizações.'),
    ('Sr. Assis: reconhecimento antes do detalhe',
     'Homem de 45 anos, sem barba, cabelo preto com fios brancos, óculos de aviação '
     'na testa, jaleco com crachá, polo azul e calça marrom. Esse contrato vem '
     'do projeto. No chibi, rosto, jaleco e óculos dominam; o texto do crachá '
     'não precisa ser legível. Usar as referências para estudar camadas e '
     'gestos de professor, sem substituir sua roupa.'),
    ('Rivais e moradores do Morro',
     'Partir dos designs atuais de Zeca, Bia, Juninho, Lia e Tião. Antes de '
     'redesenhar, montar uma comparação lado a lado de silhueta, gesto, '
     'paleta e função no bairro. Alterações que mudem rosto/roupa exigem '
     'uma proposta explícita; este benchmark não aprova mudanças silenciosas '
     'no elenco. NPCs de trabalho têm objeto, pega e rotina próprios.'),
    ('Tigre de Tyler: presas e rabiola de cerejeira',
     'A espécie deve ser lida por quadrupedia, focinho, presas e distribuição '
     'de peso, não por coroas e joias. Definir uma rabiola com módulos de '
     'pétalas presos a linha contínua, ponto de origem no corpo e ritmo de '
     'vento. Separar cauda corporal de rabiola se ambas existirem. Tirar '
     'partículas e ainda reconhecer o Pipamon é um critério de aceitação.'),
    ('Ornitorrinco do antagonista: astúcia observável',
     'Manter bico, cauda achatada e corpo do ornitorrinco como prioridades. '
     'Atitude astuta pode aparecer no centro de gravidade, olhar lateral '
     'e proteção de um objeto, sem estereotipar morador, roupa periférica '
     'ou tom de pele como criminalidade. Integrar membranas/placas de papel '
     'à anatomia e definir o repouso além da pose de ataque.'),
    ('Morcegos de Hamelim: família, variação e voo',
     'Usar o design aprovado de Flautrevo e o contexto narrativo já existente. '
     'Agrupar membranas em superfícies legíveis, manter cabeça e orelhas '
     'próprias e documentar varetas/pivôs. Variações de grupo podem vir de '
     'tamanho e ritmo, sem fabricar espécies novas por geração aleatória. '
     'A REF-16 ensina abertura de superfície, não um desenho de asa a copiar.'),
]

PIPELINE = [
    ('1. Briefing e identidade', 'Nome/ID, papel narrativo, traços aprovados, referência de identidade e referência técnica separadas. Para existente, apontar atlas/manifesto consumidor; para novo, registrar o que ainda é proposta.'),
    ('2. Exploração de forma', 'Comparar poucas alternativas de silhueta antes do acabamento. Proposta: três direções com a mesma função; escolher a mais legível e justificar. Não é obrigatório entregar três se o usuário já aprovou um conceito.'),
    ('3. Modelo de construção', 'Frente, três quartos, perfil e costas conforme as vistas usadas; volumes e linha de apoio comuns; acessórios isolados e lados marcados. Criatura inclui diagrama de rabiola, membrana ou outro órgão dominante.'),
    ('4. Atuação e estados', 'Humanos: neutro, alegria, preocupação, irritação, surpresa e determinação como repertório inicial proposto. Criaturas: repouso, alerta, antecipação, ação, recuperação e dano conforme animações reais do consumidor.'),
    ('5. Redução para jogo', 'Fazer provas de retrato, corpo inteiro e overworld na escala vigente. Separar microdetalhes de história dos sinais que sobrevivem no chibi. Não inventar uma célula universal de 64 ou 128 px sem consultar os atlas atuais.'),
    ('6. Atlas e inspeção', 'Dimensões, alpha, frames, duração, pivô, margens, orientação, filtro e nomes vêm do consumidor. Conferir animação sobre cenário real, cauda contínua e ausência de recorte. Prancha estática não aprova movimento.'),
    ('7. Integração e registro', 'Registrar arquivo, origem, revisão, status artístico/técnico, consumidor e screenshot. Separar aprovado, integrado localmente e publicado. Nenhum novo design deste capítulo foi gerado ou integrado ao game.'),
]

RUBRIC = [
    ('Identidade e silhueta', 'Reconhecível sem cor, objeto ou aura; distinto dos vizinhos do elenco.'),
    ('Proporção e volume', 'Mesmas massas, comprimento e apoio entre vistas e poses.'),
    ('Cor e leitura', 'Foco facial e valores funcionam sobre o fundo de uso.'),
    ('Construção', 'Lados, conexões, camadas e materiais inequívocos.'),
    ('Atuação', 'Emoções/ações compreensíveis sem trocar a identidade.'),
    ('Originalidade', 'Princípio reinterpretado; ausência de combinação reconhecível copiada.'),
    ('Contrato técnico', 'Tamanho, alpha, pivô, tempos e nomes conferidos com o consumidor.'),
    ('Uso real', 'Retrato, vitrine, overworld ou arena inspecionados conforme o destino.'),
]


def build(root: Path, pdf: Path, with_pdf=False):
    records = json.loads((root/'design-analises.json').read_text(encoding='utf-8'))
    sources = json.loads((root/'referencias-design/manifest.json').read_text(encoding='utf-8'))
    assert len(records) == len(sources) == 18
    assert [r['id'] for r in records] == [s['id'] for s in sources]
    for r,s in zip(records,sources):
        assert all(r.get(key) for key,_ in FIELDS)
        path=root/s['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==s['sha256']
    md=['## Ampliação: character design e creature design', '', INTRO, '', '### Método e origem', '', METHOD, '', LIMITS, '']
    for title,items in [('Direção para humanos',HUMAN),('Direção para Pipamons',CREATURE)]:
        md += ['### '+title,'']
        for label,text in items: md += ['#### '+label,'',text,'']
    md += ['### Mapa de consulta cruzada','','| Problema | Referências | Entrega esperada |','| --- | --- | --- |']
    for a,b,c in MATRIX: md += [f'| {a} | {b} | {c} |']
    md += ['','### Análise das 18 pranchas','']
    for r,s in zip(records,sources):
        md += [f'#### {r["id"]} - {r["title"]}', '', f'![{r["id"]}: {r["title"]}]({s["file"]})','',f'**Origem:** anexo do usuário. Original: `{s["originalFilename"]}`. Dimensões: {s["dimensions"][0]} x {s["dimensions"][1]} px.','']
        for key,label in FIELDS: md += [f'**{label}.** {r[key]}','']
    for title,items in [('Aplicações propostas para o elenco',BRIEFS),('Contrato de próxima produção',PIPELINE),('Ficha de auditoria',RUBRIC)]:
        md += ['### '+title,'']
        for label,text in items: md += ['#### '+label,'',text,'']
    md += ['A ficha usa os estados pendente, revisar ou aprovado com evidência. Não há pontuação automática: cauda desconectada, identidade trocada, alpha inadequado ou recorte de partes necessárias impedem aprovação técnica, mesmo que a ilustração seja bonita. As recomendações não concedem personagens, itens, skills ou raridades ao jogador.','',
           '### Encaminhamento','','Consultar este capítulo junto do `MANUAL-DE-ASSETS.md` e da skill local `pipaklub-production`. Usar a prancha aprovada do próprio personagem como referência de identidade. Este estudo orienta futuras criações; não substitui o modelo vigente nem aprova redesenhos automaticamente.','']
    full='\n'.join(md)
    (root/'DESIGN-PERSONAGENS-E-CRIATURAS.md').write_text('# Estudo de personagens e criaturas\n\n'+full,encoding='utf-8')
    base_md=root/'BENCHMARK.md'
    base_md.write_text(base_md.read_text(encoding='utf-8')+'\n\n'+full,encoding='utf-8')
    esc=html.escape
    parts=['<section id="design-study"><p class="label">Ampliação / 21 outubro 2026</p><h2>Personagens e criaturas: construir identidade</h2>',f'<p>{esc(INTRO)}</p><p>{esc(METHOD)}</p><p>{esc(LIMITS)}</p>', '<p><a href="DESIGN-PERSONAGENS-E-CRIATURAS.md">Capítulo editável</a> · <a href="referencias-design/manifest.json">Origem dos 18 anexos</a></p>']
    for title,items in [('Direção para humanos',HUMAN),('Direção para Pipamons',CREATURE)]:
        parts += [f'<h3>{title}</h3>']+[f'<h4>{esc(a)}</h4><p>{esc(b)}</p>' for a,b in items]
    parts += ['<h3>Pranchas e análises individuais</h3>']
    for r,s in zip(records,sources):
        category='Personagens humanos' if s['category']=='personagens' else 'Criaturas'
        parts += [f'<article class="design-reference"><header><small>{r["id"]} / {category}</small><h3>{esc(r["title"])}</h3></header><div class="design-columns"><a href="{s["file"]}" target="_blank"><img loading="lazy" src="{s["file"]}" alt="{esc(r["title"])}"></a><div>']
        for key,label in FIELDS:parts += [f'<p><b>{label}.</b> {esc(r[key])}</p>']
        parts += [f'</div></div><p class="meta">Anexo fornecido pelo usuário / {s["dimensions"][0]} × {s["dimensions"][1]} px / original preservado / autoria individual não verificada.</p></article>']
    for title,items in [('Aplicações propostas para o elenco',BRIEFS),('Contrato de próxima produção',PIPELINE),('Ficha de auditoria',RUBRIC)]:
        parts += [f'<h3>{title}</h3>']+[f'<h4>{esc(a)}</h4><p>{esc(b)}</p>' for a,b in items]
    parts += ['<p>Estados de revisão: pendente, revisar ou aprovado com evidência. Cauda desconectada, identidade trocada ou partes necessárias recortadas não passam por uma média de notas.</p></section>']
    page=(root/'index.html').read_text(encoding='utf-8')
    page=page.replace('</main>',''.join(parts)+'</main>')
    page=page.replace('</style>','.design-reference{margin:24px 0}.design-columns{display:grid;grid-template-columns:minmax(260px,1fr) minmax(0,1.2fr);align-items:start}.design-columns img{max-height:850px;object-fit:contain;background:white}.design-reference h3{margin:5px 0}.design-columns p{font-size:15px;line-height:1.55;padding:10px 20px}#design-study h3{margin-top:30px}@media(max-width:850px){.design-columns{grid-template-columns:1fr}} </style>')
    page=page.replace("document.querySelectorAll('article').forEach", "document.querySelectorAll('article[data-category]').forEach")
    page=page.replace('<p><a href="BENCHMARK.md">','<p><a href="#design-study">Novo: personagens e criaturas</a> · <a href="BENCHMARK.md">')
    (root/'index.html').write_text(page,encoding='utf-8')
    if with_pdf:append_pdf(root,pdf,records,sources)
    print(f'Design study: {len(records)} references; {len(full.split())} words; originals verified.')


def append_pdf(root,pdf,records,sources):
    from reportlab.pdfgen import canvas
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import Paragraph
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.colors import HexColor
    from reportlab.lib.utils import ImageReader
    from PIL import Image
    from pypdf import PdfReader,PdfWriter
    pdfmetrics.registerFont(TTFont('DesignArial','C:/Windows/Fonts/arial.ttf'))
    pdfmetrics.registerFont(TTFont('DesignArialB','C:/Windows/Fonts/arialbd.ttf'))
    old=PdfReader(str(pdf));offset=len(old.pages)
    buffer=BytesIO();c=canvas.Canvas(buffer,pagesize=(842,595));W,H=842,595
    style=ParagraphStyle('study',fontName='DesignArial',fontSize=10.4,leading=14,textColor=HexColor('#183d3b'),spaceAfter=0)
    bold=ParagraphStyle('studybold',parent=style,fontName='DesignArialB',fontSize=11.2,leading=14.5)
    small=ParagraphStyle('studysmall',parent=style,fontSize=8,leading=11)
    n=0;outline=[]
    def para(text,x,y,width,st=style):
        p=Paragraph(html.escape(text),st);_,height=p.wrap(width,1000)
        if y-height < 42:raise ValueError(f'Page {offset+n} overflows: {text[:55]}')
        p.drawOn(c,x,y-height);return y-height-9
    def begin(title,label):
        nonlocal n
        n+=1;c.setFillColor(HexColor('#faf6e9'));c.rect(0,0,W,H,fill=1,stroke=0)
        c.setFillColor(HexColor('#183d3b'));c.setFont('DesignArialB',9);c.drawString(34,H-29,'PIPAKLUB / '+label)
        size=21
        while pdfmetrics.stringWidth(title,'DesignArialB',size)>W-68:size-=.5
        c.setFont('DesignArialB',size);c.drawString(34,H-61,title)
        c.setStrokeColor(HexColor('#d3cbb9'));c.line(34,31,W-34,31)
        c.setFont('DesignArial',8);c.drawString(34,17,'21/10/2026 | Estudo dos anexos | Orientação para criações futuras')
        c.drawRightString(W-34,17,str(offset+n))
    def section(title,items,label='DIREÇÃO DE DESIGN'):
        begin(title,label);y=H-92
        for a,b in items:y=para(a,34,y,W-68,bold);y=para(b,34,y,W-68)
        c.showPage()
    section('Personagens e criaturas: como ler este capítulo', [('Escopo',INTRO),('Método',METHOD),('Origem e limites',LIMITS)])
    for title,items in [('Humanos: forma, papel e cor',HUMAN[:3]),('Humanos: continuidade e atuação',HUMAN[3:]),('Pipamons: espécie e construção',CREATURE[:3]),('Pipamons: estados, materiais e raridade',CREATURE[3:])]:section(title,items)
    section('Mapa de consulta cruzada',[(a,b+' | '+d) for a,b,d in MATRIX[:4]])
    section('Mapa de consulta: criaturas e movimento',[(a,b+' | '+d) for a,b,d in MATRIX[4:]])
    for r,s in zip(records,sources):
        outline.append((r['id']+' - '+r['title'],offset+n))
        begin(r['id']+' | '+r['title'],'REFERÊNCIA / '+('HUMANOS' if s['category']=='personagens' else 'CRIATURAS'))
        with Image.open(root/s['file']) as im:
            iw,ih=im.size;scale=min((W-68)/iw,430/ih);dw,dh=iw*scale,ih*scale
            c.drawImage(ImageReader(im), (W-dw)/2, 66+(430-dh)/2,width=dw,height=dh,mask='auto')
        para('Anexo do usuário; original preservado. '+str(iw)+' x '+str(ih)+' px. Análise na página seguinte. Autoria individual não verificada.',34,58,W-68,small)
        c.showPage()
        begin(r['id']+' | Análise e tradução para o PipaKlub','LEITURA DE DESIGN')
        for x,fields in [(34,FIELDS[:4]),(438,FIELDS[4:])]:
            y=H-91
            for key,label in fields:y=para(label,x,y,369,bold);y=para(r[key],x,y,369)
        c.showPage()
    for title,items in [('Aplicação: protagonistas e moradores',BRIEFS[:3]),('Aplicação: novos parceiros e criaturas',BRIEFS[3:]),('Produção: do briefing ao modelo',PIPELINE[:3]),('Produção: da atuação ao jogo',PIPELINE[3:]),('Auditoria: identidade e atuação',RUBRIC[:4]),('Auditoria: originalidade e integração',RUBRIC[4:])]:section(title,items)
    section('Como usar na próxima criação',[
        ('Consultar o modelo aprovado','Este capítulo acompanha o MANUAL-DE-ASSETS.md e a skill pipaklub-production. Usar referência do próprio personagem para identidade; usar as folhas deste acervo para estudar construção e decisões visuais.'),
        ('Estados de aprovação','Registrar pendente, revisar ou aprovado com evidência. Não usar uma nota média para aceitar cauda desconectada, mudança de identidade, alpha inadequado ou recorte de parte necessária.'),
        ('Limite desta entrega','Não foram criados nem integrados novos personagens ao jogo. Briefs e critérios são propostas de produção; a aparência não concede skills, drops, raridade, level ou propriedade.'),
        ('Arquivos de consulta','As 18 análises e originais estão no HTML e no Markdown do benchmark. referencias-design/manifest.json identifica cada anexo e seu SHA-256. Clique no original na galeria para examinar detalhes sem redução.')])
    c.save();buffer.seek(0);appendix=PdfReader(buffer);writer=PdfWriter();writer.append(old)
    writer.append(appendix,import_outline=False)
    parent=writer.add_outline_item('Personagens e criaturas - 21/10/2026',offset)
    for label,index in outline:writer.add_outline_item(label,index,parent=parent)
    writer.add_metadata({'/Title':'PipaKlub - Benchmark de HUD, personagens e criaturas','/Author':'PipaKlub - estudo de referências','/Subject':'Benchmark visual com ampliação dos 18 anexos de design'})
    tmp=pdf.with_suffix('.tmp.pdf')
    with tmp.open('wb') as f:writer.write(f)
    tmp.replace(pdf)
    print(f'PDF: {offset} historical + {len(appendix.pages)} design pages = {len(writer.pages)} pages.')
