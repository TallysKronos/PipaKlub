from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont
import json, hashlib, shutil, os
from html import escape
D=Path(__file__).resolve().parent
R=D.parents[2]
A=R/'art/creatures/alvacordo-family-v1'
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
specs=[
 ('farpim','Farpim','Bebê','exec-d5535218-f7c4-427f-919e-86a69aace190.png','concept-v1','Flutuar e sentir a direção da linha.','Corpo único de pipa inflada, duas orelhas, sem membros, uma flâmula; olhos suaves.','Aprende a seguir antes de conduzir.','Não consegue se ancorar sozinho.'),
 ('papisco','Papisco','Criança','exec-7ed477d5-1771-460a-89a6-c523fbe84eb6.png','concept-v1','Experimentar a tensão.','Bípede pequeno, quatro membros, orelha dobrada, peito-pipa e punhos de papel.','Descobre como puxar sem romper.','A curiosidade pode fazê-lo perder o apoio.'),
 ('velcao','Velcão','Jovem','exec-88eca9d5-2098-420c-9034-745823594c3b.png','concept-v1','Interceptar uma trajetória.','Quadrúpede de quatro patas, velas laterais nos ombros, focinho alongado e cauda-pluma.','Troca a brincadeira pela leitura do movimento do grupo.','As velas abertas ocupam espaço em passagens estreitas.'),
 ('alvacordo','Alvacordo','Adulto','exec-010f052a-ae86-445b-9a96-dc2a6a967115.png','concept-v2','Capturar e redirecionar linhas.','Bípede alto digitígrado, duas mãos e dois pés, armações recurvas nos antebraços e manto de pelo-papel.','Deixa de apenas perseguir: aprende a proteger e coordenar.','Manter as duas armações tensionadas exige apoio firme.')]
nodes=[]
for i,(id,name,age,file,version,action,anatomy,story,tradeoff) in enumerate(specs):
 P=A/id/version; P.mkdir(parents=True,exist_ok=True)
 shutil.copy2(G/file,P/'concept.png')
 brief=f'# {name} — {age}\n\n## Definido pelo autor\nNova linha husky siberiano/border collie, pelos de papel, inspiração estrutural nas quatro formas X citadas. Direção Soulmonsters 45/45/10.\n\n## Proposta\nNome {name}; estágio {age}; anatomia: {anatomy} Ação: {action} História: {story} Limitação: {tradeoff} Mantém carvão/branco/petróleo, faixa branca assimétrica, olhos âmbar, nós vermelhos e rabiola.\n\n## Desconhecido\nElemento, habitat, requisitos, números, obtenção e participação na história. Nenhum foi canonizado. A rabiola preserva a mesma alma.\n'
 (P/'brief.md').write_text(brief,encoding='utf-8')
 review='Imagem inspecionada: '+anatomy+' Paleta e família coerentes; silhueta distinta dos outros estágios. '
 if id=='alvacordo':review+='Correção v2 removeu as flâmulas duplicadas do punho e preservou a rabiola única da cauda. Armações e pontos de fixação ainda precisam de vistas técnicas antes de rig. '
 if id=='velcao':review+='As velas leem visualmente próximas de asas; função de freio é proposta, não demonstrada em animação. '
 review+='Há suaves transições residuais na pintura; concept manga limpo, não pixel art de grade validada. Fundo branco opaco; não recortado, animado ou integrado. Em avaliação pelo autor.'
 (P/'revisao.md').write_text('# Conferência visual\n\n'+review,encoding='utf-8')
 with Image.open(P/'concept.png') as im:dims=list(im.size);mode=im.mode
 manifest=dict(tool='image_gen.imagegen built-in',source=str(G/file),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=dims,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Text only' if id in ['farpim','velcao'] else 'Own Velcao ancestry; adult v2 edits own v1',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated')
 (P/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 nodes.append(dict(id=id,name=name,kind='stage',stage=i+1,maturity=age,identity=anatomy,story=story,action=action,tradeoff=tradeoff,decision_status='proposed',production_status='concept',art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix()))
# Preserve first adult as correction history, not as the current design.
old=A/'alvacordo/concept-v1';shutil.copy2(G/'exec-61282b8f-a085-445f-a804-33edb69955c2.png',old/'concept.png')
(old/'revisao.md').write_text('Histórico substituído por v2: flâmulas pendentes do punho confundiam a rabiola única. Prompt original preservado.',encoding='utf-8')
(old/'manifest.json').write_text(json.dumps(dict(decision_status='superseded',production_status='concept',implementation_status='not_integrated',source=str(G/'exec-61282b8f-a085-445f-a804-33edb69955c2.png'),sha256=hashlib.sha256((old/'concept.png').read_bytes()).hexdigest(),tool='image_gen.imagegen built-in'),indent=2),encoding='utf-8')
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=r,decision_status='proposed') for i,r in enumerate(['O corpo flutuante ganha apoios para experimentar a tensão.','A coordenação vira interceptação: quatro apoios e velas de freio.','A experiência de condução vira proteção: mãos controlam armações de tensão.'])]
(D/'chart.json').write_text(json.dumps(dict(family_id='alvacordo-family-v1',scope='Quatro concepts propostos; nomes e estágios em proposta; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
observations=[('gabumon_x','Gabumon X','Arte oficial: corpo compacto e pelagem envolvente contrastam com focinho e membros expostos.','Contraste de massa macia e apoios; não copiar pele vestida, chifre ou marca abdominal.'),('garurumon_x','Garurumon X','Arte oficial: quadrúpede muito baixo, diagonal de avanço e expansões dorsais. Perfil oficial enfatiza a pelagem endurecida.','Postura e função do material mudam; não copiar espinhos metálicos, listras ou cores.'),('weregarurumon_x','WereGarurumon X','Arte oficial: verticalização, braços longos, mãos em ação e volumes dos membros destacados.','Mudar os apoios e a agência das mãos; não copiar vestuário ou distribuição de armadura.'),('metalgarurumon_x','MetalGarurumon X','Arte e perfil oficiais: versão X bípede com massas de armamento distribuídas no corpo.','Adulto com especialidade e arquitetura próprias; não transportar armas de fogo ou aparência mecha.')]
sources=[]
for slug,title,fact,use in observations:
 p=D/'referencias'/f'{slug}.jpg'
 sources.append(dict(title=title,entity='Bandai / Digimon Web',url=f'https://digimon.net/cimages/digimon/{slug}.jpg',profile_url=f'https://digimon.net/reference_en/detail.php?directory_name={slug}',access='2026-11-04',fact=fact,interpretation=use,proposed_use='Pesquisa estrutural apenas; nunca input de geração',local_art=f'referencias/{slug}.jpg',sha256=hashlib.sha256(p.read_bytes()).hexdigest(),limitation='Perfil não ficou acessível; observação restrita à arte oficial' if slug in ['gabumon_x','weregarurumon_x'] else 'Perfil e arte consultados'))
(D/'fontes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
(D/'CHART.md').write_text('# Família de papel husky / border collie\n\nFarpim → Papisco → Velcão → Alvacordo. Nomes e correspondência de estágios propostos.\n\nHistória: aprender a seguir uma linha, experimentar sua tensão, interceptar trajetórias e finalmente coordenar/proteger. A pelagem ganha função sem cobrir tudo de pequenos vincos. Não é uma rota de gelo definida, montaria ou cavaleiro canônico.\n\n## Pesquisa e limites\nQuatro artes oficiais X abertas e inspecionadas; perfis Garurumon X e MetalGarurumon X lidos. Gabumon X e WereGarurumon X tiveram falha de acesso aos perfis; suas notas são observação visual, não lore. Não tratar esta seleção como única rota oficial universal. A versão MetalGarurumon X é bípede; não confundir com a versão padrão quadrúpede.\n\n'+''.join('### '+t+'\n'+f+'\n\nLeitura aplicada: '+u+'\n\n' for s,t,f,u in observations)+'## Conferência\nQuatro conceitos gerados separadamente e inspecionados entre etapas, usando ferramenta integrada. Só a própria jovem entrou como referência de família; bebê e jovem foram gerados por texto. Adulto v2 remove duplicação de flâmulas no punho. Revisões individuais registram limites. Não há grid técnico, recortes, rig ou integração. Condições e nomes aguardam decisão do autor.\n',encoding='utf-8')
(A/'DECISOES.md').write_text('# Direção proposta\n\nAutor solicitou linha husky siberiano / border collie com pelos de papel, inspirada na progressão X indicada. Quatro concepts em avaliação. Preservar foco mangá limpo, volumes amplos e articulações caninas. Não copiar designs externos. Geração e correção não autorizam integração.',encoding='utf-8')
sheet=Image.new('RGB',(1800,1500),'#f4f3ee');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28);cards=[]
for i,n in enumerate(nodes):
 x=(i%2)*900;y=(i//2)*750
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,640));sheet.paste(t,(x+(900-t.width)//2,y+75+(640-t.height)//2))
 dr.text((x+24,y+20),f"{n['name']} · {n['maturity']} (proposta)",font=font,fill='#173c40')
 cards.append(f'<article><h2>{n["name"]} · {n["maturity"]}</h2><a href="{n["art"]}"><img src="{n["art"]}" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><p><b>Ação:</b> {escape(n["action"])}</p><p><b>Limite proposto:</b> {escape(n["tradeoff"])}</p><a href="{n["brief"]}">Brief</a></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Família Alvacordo</title><style>body{max-width:1250px;margin:auto;padding:28px;background:#f4f3ee;color:#173c40;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:26px}article{padding:24px;background:white}img{width:100%;height:500px;object-fit:contain}a:focus-visible{outline:4px solid #b64429}@media(max-width:700px){.grid{grid-template-columns:1fr}img{height:360px}}</style><h1>Pelagem de papel · quatro estágios</h1><p>Todos em avaliação. Nomes e funções propostos; sem integração.</p><p><a href="CHART.md">Pesquisa e decisões</a> · <a href="fontes.json">Fontes</a> · <a href="familia.png">Comparativo</a></p><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
print('Família salva: quatro concepts, um histórico de correção e chart.')
if (D/'aplicar_armadura_v3.py').exists():
 import runpy
 runpy.run_path(str(D/'aplicar_armadura_v3.py'))
