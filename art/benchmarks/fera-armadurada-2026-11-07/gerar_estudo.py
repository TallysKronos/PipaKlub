from pathlib import Path
import json,shutil,html,hashlib,re
from PIL import Image
D=Path(__file__).resolve().parent
data=json.loads((D/'analise.json').read_text(encoding='utf-8'))
source=Path('C:/Users/user/AppData/Local/Temp/codex-clipboard-b55725f3-5a2f-4656-a6d0-c65d345c6232.png')
shutil.copy2(source,D/'referencia-usuario.png')
def write(p,t):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
intro='''# Desmontagem visual — fera armadurada

## Resultado da análise

O caráter desta figura nasce de uma fera grande e identificável cujo corpo continua visível entre equipamentos. Não nasce de cobrir um humano com uma couraça e escolher um focinho. Cabeça, pescoço, mãos, postura, armadura parcial e acentos de energia cooperam.

Esse foi o desvio nos nossos testes: preservamos o manequim de cavaleiro, mudamos a cabeça e tentamos corrigir a genericidade diminuindo a paleta. A paleta ficou mais organizada, mas a anatomia, a proporção de corpo coberto e as decisões de função permaneceram próximas do mesmo molde.

## Fonte e limites

Imagem fornecida pelo autor em 2026-11-07. A assinatura visível inclui “Gull” e a data 2022.12.07, mas autoria, personagem e titularidade não foram verificados. Não atribuir o desenho a uma espécie, franquia ou autor identificado apenas pela assinatura. A imagem não foi usada como input de geração. A leitura abaixo examina uma única vista estática; não prova animação, anatomia oculta, funcionamento físico dos equipamentos ou lore. Áreas parcialmente cobertas permanecem ambíguas.

As proporções e distribuições de cor são observações visuais qualitativas. Não foram medidas por segmentação de pixels. Esta referência não é um model sheet de produção e não garante, sozinha, facilidade de animação.

'''
body=''
for i,s in enumerate(data['sections'],1):
 body+=f'## {i}. {s["title"]}\n\n**Visível:** {s["observed"]}\n\n**Leitura:** {s["reading"]}\n\n**Onde nossos testes falharam:** {s["ours"]}\n\n**Aplicação autoral proposta:** {s["transfer"]}\n\n**Teste:** {s["check"]}\n\n'
end='''## O que não deve ser copiado

- A combinação exata de fera leonina branca, aros dourados inscritos, capa violeta, marcas cianas/amarelas e raios.
- Os símbolos, uma suposta tradução deles ou história inventada como se fosse a intenção do artista.
- A musculatura humana desenhada nesta referência como obrigação para nossos Soulmonsters. Usaremos massas de membrana tensionada e juntas de papel vivo.
- A juba, o focinho curto e os punhos gigantes em todos os oito: isso criaria outro uniforme genérico.
- Pelo realista, carne ou rugas sob uma carapaça. O autor já rejeitou esse material para o projeto.

## Regra proposta de construção para o próximo piloto

1. **Identidade antes da armadura:** uma criatura com tipo de crânio, tórax, mãos e apoios próprios, desenhada sem equipamento.
2. **Um verbo corporal:** escolher uma ação que seja visível sem arma nem efeito. Definir qual parte transmite a força e qual sustenta o esforço.
3. **Distribuição de proteção:** cobrir as regiões que precisam cumprir esse verbo; deixar intervalos suficientes para o corpo ser reconhecido. Não usar uma porcentagem universal de pele/papel exposto.
4. **Uma assinatura funcional:** um encaixe, mecanismo de linha ou estrutura de pipa que participe da ação e possa ser explicado. Nó e losango não são enfeites obrigatórios em toda junta.
5. **Materiais com papéis claros:** membrana viva, proteção e tecido/vela devem ter contornos, dobras e zonas próprios.
6. **Poucas famílias cromáticas:** corpo, proteção, contraste e acento. O mesmo material conserva cor-base nas diferentes vistas; a sombra descreve forma em vez de criar novas listras.
7. **Rosto integrado:** cabeça continua sendo criatura sem o helmet; papel organiza seus volumes sem convertê-la numa máscara de origami.
8. **A armadura só entra depois:** preservar o pedido de relevos dracônicos, mas concentrá-los em placas que mereçam essa atenção.
9. **Rabiola única:** a alma continua na peça completa de linha e terminal; cauda, capa ou cordas de arma não viram almas extras.
10. **Conferência em imagem simples:** verificar corpo em silhueta e massas neutras antes de tornar o concept uma prancha detalhada.

## Produção e repetibilidade

Depois de resolver o corpo, a entrega reproduzível precisa separar: cor-base de cada material; sombra e luz como camadas; peça de proteção; membro vivo; ponto de articulação; símbolo fixo e efeito variável. Mostrar frente, perfil e costas permitirá verificar o que esta imagem não mostra. Um concept limpo não certifica recorte ou rig.

O arquivo `tentativas.json` e as imagens de `tentativas-autorais/` preservam o histórico desta revisão. Nenhum desses testes foi promovido a forma aprovada. As oito alternativas solicitadas permanecem uma tarefa criativa em revisão; não há oito alternativas finalizadas. As versões draconianas de helmet fechado continuam intactas.

## Brief mínimo de validação — ainda sem nova arte

**Objetivo:** um Soulmonster fera-cavaleiro cujo corpo seja reconhecível antes do equipamento.

**Decisões que a imagem nova precisa resolver:** massa principal, crânio, instrumento corporal de força, apoio, proteção funcional e assinatura de pipa.

**Evitar no próximo teste:** mais uma recoloração do mesmo corpo; mais um focinho pontudo sobre ombreiras idênticas; repetir a cabeça ou a silhueta desta referência.

O sucesso do próximo piloto será avaliado pela relação causal entre corpo e equipamento, não apenas pelo número de cores ou pela quantidade de detalhes.
'''
write(D/'ANALISE.md',intro+body+end)
attempts=json.loads((D/'tentativas.json').read_text(encoding='utf-8'))
gallery=[]
for a in attempts['attempts']:
 p=D/'tentativas-autorais'/a['name'];p.mkdir(parents=True,exist_ok=True)
 shutil.copy2(a['source'],p/'concept.png');write(p/'prompt.txt',a['prompt']+'\n')
 if a['correction']:write(p/'prompt-correcao.txt',a['correction']+'\n')
 with Image.open(p/'concept.png') as im:dim=[im.width,im.height]
 dump(p/'manifest.json',dict(status=a['status'],source=a['source'],dimensions=dim,sha256=hashlib.sha256((p/'concept.png').read_bytes()).hexdigest(),scope='Histórico de estudo, não asset aprovado ou integrado.'))
 gallery.append(f'<article><a href="tentativas-autorais/{a["name"]}/concept.png"><img loading="lazy" src="tentativas-autorais/{a["name"]}/concept.png" alt="{a["name"]}"></a><h3>{a["name"]}</h3><p>{a["status"]}</p></article>')
buttons=[];articles=[]
for i,s in enumerate(data['sections'],1):
 buttons.append(f'<button class="spot" style="left:{s["x"]}%;top:{s["y"]}%" data-target="p{i}" aria-label="Ponto {i}: {html.escape(s["title"])}" aria-controls="p{i}" aria-pressed="false">{i}</button>')
 articles.append(f'<article class="point" id="p{i}" tabindex="-1"><h2>{i}. {html.escape(s["title"])}</h2><p><b>Visível.</b> {html.escape(s["observed"])}</p><p><b>Leitura.</b> {html.escape(s["reading"])}</p><p><b>Nossos testes.</b> {html.escape(s["ours"])}</p><p><b>Aplicação proposta.</b> {html.escape(s["transfer"])}</p><p class="check">{html.escape(s["check"])}</p></article>')
colors=[('Corpo claro','#eeedf0'),('Sombra do corpo','#a9a6ad'),('Proteção ocre','#ccb174'),('Tecido violeta','#7770af'),('Fundo da capa','#423b46'),('Energia ciana','#42f2f5'),('Marca amarela','#fff35b')]
swatches=''.join(f'<li><span class="swatch" style="background:{c}"></span>{n} <code>{c}</code></li>' for n,c in colors)
css='''*{box-sizing:border-box}html{scroll-padding-top:24px}body{margin:0;background:#131e27;color:#f1eee6;font:17px/1.65 system-ui,sans-serif}main{max-width:1600px;margin:auto;padding:34px 26px}h1{font-size:clamp(30px,4.6vw,60px);line-height:1.13;max-width:1000px}h2{font-size:26px;line-height:1.25}p{max-width:90ch}a{color:#91dfd8}a:focus-visible,button:focus-visible{outline:4px solid #ffe277;outline-offset:4px}.intro{max-width:1100px}.analysis{display:grid;grid-template-columns:minmax(330px,1fr) minmax(450px,1.15fr);gap:32px;margin-top:34px;align-items:start}.reference{position:sticky;top:20px}.map{position:relative;background:white}.map img{width:100%;height:auto;display:block}.spot{position:absolute;transform:translate(-50%,-50%);border:2px solid white;border-radius:50%;background:#123343;color:white;min-width:36px;min-height:36px;font-size:16px;font-weight:750;cursor:pointer;box-shadow:0 1px 4px #0006}.spot[aria-pressed=true]{background:#ffdc78;color:#18252d;border-color:#18252d}.credit{font-size:13px;color:#b7c7cd}.point{background:#1d303e;padding:26px;margin-bottom:22px;border-left:4px solid #4b6977;border-radius:4px}.point.active{border-left-color:#ffdc78;background:#243d4c}.point:focus{outline:3px solid #ffdc78;outline-offset:3px}.check{background:#13242e;padding:14px;color:#a7e0d9}.swatches{list-style:none;padding:0;display:flex;flex-wrap:wrap;gap:12px}.swatches li{display:flex;align-items:center;gap:9px;padding:12px;background:#1d303e;font-size:14px}.swatch{display:inline-block;width:30px;height:30px;border:1px solid #fff5}.history{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.history article{background:#1d303e;padding:16px;overflow-wrap:anywhere}.history img{width:100%;height:300px;object-fit:contain;background:white}.history h3{font-size:17px}footer{margin:48px 0;color:#b7c7cd}@media(max-width:1000px){.analysis{grid-template-columns:1fr}.reference{position:relative;top:0;max-width:650px;margin:auto}.history{grid-template-columns:repeat(2,1fr)}}@media(max-width:550px){main{padding:24px 16px}.point{padding:20px}.history{grid-template-columns:1fr}.spot{min-width:34px;min-height:34px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}'''
script='''document.querySelectorAll('.spot').forEach(b=>b.addEventListener('click',()=>{document.querySelectorAll('.spot').forEach(x=>x.setAttribute('aria-pressed','false'));document.querySelectorAll('.point').forEach(x=>x.classList.remove('active'));b.setAttribute('aria-pressed','true');const p=document.getElementById(b.dataset.target);p.classList.add('active');p.focus({preventScroll:true});p.scrollIntoView({block:'start',behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'});}));'''
write(D/'index.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fera armadurada — anatomia e direção</title><style>'+css+'</style><main><h1>A criatura sustenta a armadura</h1><div class="intro"><p>Desmontagem de uma referência enviada pelo autor. Doze pontos separam o que está visível, o que é interpretação e o que podemos transportar para Soulmonsters.</p><p><b>Diagnóstico:</b> mudar a cabeça e reduzir as cores preservou o manequim dos nossos cavaleiros. Esta figura exige repensar corpo, distribuição de proteção e centro de poder.</p><p><a href="ANALISE.md">Estudo completo e critérios do próximo piloto</a> · <a href="referencia-usuario.png">Imagem original</a> · <a href="#historico">Histórico das tentativas</a></p></div><div class="analysis"><aside class="reference"><div class="map"><img src="referencia-usuario.png" alt="Fera clara de juba branca, braços e pés grandes, proteções ocres localizadas, aros inscritos, capa violeta e marcas cianas. Botões numerados abrem análises por região.">'+''.join(buttons)+'</div><p class="credit">Imagem enviada pelo autor. Crédito visível: Gull, 2022.12.07; identidade e titularidade não verificadas. Análise de uma vista, sem uso como input de geração. Clique num ponto ou use Tab e Enter.</p></aside><div>'+''.join(articles)+'</div></div><h2>Cores agrupadas por função</h2><p>Amostras visuais aproximadas, não uma extração exata nem uma medição percentual. Sombras não são novos materiais. Corpo, proteção, tecido e energia têm papéis estáveis.</p><ul class="swatches">'+swatches+'</ul><h2 id="historico">Histórico: por que a correção ainda estava incompleta</h2><p>Rascunhos próprios preservados para comparação. Nenhum é uma alternativa final aprovada. Não há oito formas alternativas prontas; a multiplicação foi interrompida para atender à análise solicitada.</p><div class="history">'+''.join(gallery)+'</div><footer>Sem nova geração nesta etapa. Concepts anteriores e jogo preservados. O estudo não valida movimento, rig ou produção em várias vistas.</footer></main><script>'+script+'</script></html>')
refs=re.findall(r'(?:src|href)="([^"]+)"',(D/'index.html').read_text(encoding='utf-8'))
missing=[r for r in refs if not r.startswith(('#','http')) and not (D/r).is_file()]
assert not missing,missing
dump(D/'validacao.json',dict(points=len(data['sections']),source_unchanged=hashlib.sha256(source.read_bytes()).hexdigest()==hashlib.sha256((D/'referencia-usuario.png').read_bytes()).hexdigest(),local_links_missing=missing,archived_own_attempts=len(attempts['attempts']),scope='Arquivos e links; não houve inspeção visual no navegador. Imagem de referência copiada sem edição.'))
print('12 análises, imagem original sem alteração, histórico e estudo navegável registrados; links locais conferidos.')
