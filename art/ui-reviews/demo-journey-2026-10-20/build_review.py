from pathlib import Path
from html import escape as esc
import json, zipfile
from PIL import Image

root=Path(__file__).resolve().parent
repo=root.parents[2]
issues=[]
def issue(id,priority,title,status,kind,evidence,impact,fix,accept,shots,source=''):
    issues.append(dict(id=id,priority=priority,title=title,status=status,kind=kind,evidence=evidence,impact=impact,fix=fix,accept=accept,shots=shots,source=source))

issue('DEMO-01','P0','Recarga do convite deixava a tela sem interface','Corrigido parcialmente','Defeito funcional',
'Na sala com duas contas, recarregar a página com ?sala= deixou apenas o fundo e a faixa do ambiente local. O quintal, a abertura e a tela de amigos estavam ocultos, sem erro no console.',
'Um jogador que abre um convite ou recarrega pode achar que o jogo parou e abandonar a demo.',
'Foi adicionada offerRoomInvitation(): a sessão autenticada recebe a tela de entrada com código preenchido e pode cancelá-la para voltar ao quintal. A recuperação do assento é o problema separado DEMO-02.',
'Abrir um convite autenticado, recarregar e cancelar sempre deixa um caminho visível. Reteste visual e teste de regressão passaram.',
['34-online-recarregar.png','37-convite-corrigido.png'],'src/courtyard-client.js:40; art.test.mjs: signed-in room invitation')
issue('DEMO-02','P1','Reentrada não recupera o jogador da partida','Aberto','Defeito funcional',
'Após entrar, recarregar e tentar Entrar novamente, a mesma conta recebe “Você já entrou nesta sala”. O anfitrião continua vendo a partida até o convidado expirar; não há retomada automática do controle.',
'A demo online não tem um fluxo confiável para uma interrupção comum de navegador. O convite voltar a aparecer não resolve a continuidade da partida.',
'Implementar retomada autenticada do mesmo assento, vinculada à conta, preservando rodada e placar. Se o assento expirou, explicar e oferecer retorno ou nova entrada. Nunca devolver controle a outra conta.',
'Duas contas: atualizar a aba por 1 s e por mais tempo, reconectar sem duplicar jogador e sem transferir assento. Testar também sala encerrada e código expirado.',
['38-reentrada-bloqueada.png'],'src/index.html: online(action); src/courtyard-client.js: offerRoomInvitation')
issue('DEMO-03','P1','A versão atual libera conteúdo além da demo','Aberto','Escopo de lançamento',
'Após Mikka, Beira-Mar foi selecionada e liberada no mapa, com Explorar Beira-Mar disponível. A missão do quintal também passou a apontar para essa trilha.',
'O recorte “início + primeiro bairro + online” ainda não existe no produto; esconder um botão não seria uma barreira suficiente.',
'Criar uma política de conteúdo da demo compartilhada por navegação e servidor. Permitir Morro do Sol e os modos online aprovados; recusar fases fora do recorte sem apagar progresso ou coleções.',
'Um pedido direto a uma fase fora da demo também é recusado. Reabrir conta antiga ou usar link não contorna o limite. Jogar online continua disponível.',
['31-fora-do-recorte-demo.png'],'src/trails.js; src/courtyard-client.js: openCity; src/backend.js')
issue('DEMO-04','P1','O final do bairro promete continuação imediata','Aberto','Experiência da demo',
'O texto de vitória de Mikka diz que há outro vento chamando na Beira-Mar e que o bairro seguinte espera pelo jogador. As ações são invocador, caminho e mapa; não há conclusão específica da demo.',
'A pessoa termina sem saber que completou a amostra e pode perceber o limite futuro como conteúdo faltando.',
'Criar um encerramento da demo depois da recompensa, com resumo do vínculo e do bairro, salvamento confirmado e ações claras para online, explorar novamente e voltar ao clube. Só mostrar links de comunidade ou loja que já existam.',
'O jogador identifica que concluiu a demo, sabe o que ainda pode jogar e pode voltar à conclusão sem ganhar prêmios duplicados.',
['28-mikka-vitoria.png'],'src/encounter-story-client.js; src/trails.js: história de morro-5')
issue('DEMO-05','P1','Ataque e rebicada usam nomes que se confundem','Aberto','Aprendizado',
'A segunda lição chama o ataque com Espaço de rebique. A HUD tem Puxão no R, enquanto as regras também falam em ATACAR, uma ação que não aparece como botão no leque atual.',
'O iniciante pode tentar cumprir a lição usando R, sem entender por que o ataque de Espaço é outra ação.',
'Fixar um vocabulário único: ataque/corte básico, manobra de linha/rebicada, habilidade do parceiro e esquiva. Mostrar o comando de ataque na HUD ou em uma ajuda sempre acessível.',
'Um jogador novo consegue explicar a diferença entre Espaço, R, Q/E e Shift após o tutorial, sem consultar uma parede de regras.',
['10-tutorial-passagem-720.png'],'src/first-flight.js: lessons; src/index.html: showRules; src/switch-ui-client.js: action fan')
issue('DEMO-06','P1','A esquiva é cobrada antes de ser praticada','Aberto','Aprendizado',
'As cinco lições cobrem movimento, ataque, recuperação, habilidade e um corte contra Nozinho parado. Zeca já apresenta anel de ameaça e recomenda esquivar; a dupla acrescenta seleção de alvo e cruzamentos simultâneos.',
'Há um salto de leitura entre o treino seguro e os desafios. As derrotas desta auditoria, sozinhas, não medem dificuldade: o teste automatizado tem tempos de reação próprios.',
'Ensinar uma esquiva guiada e o significado do anel antes do primeiro rival. Antes da dupla, apresentar um exemplo curto de escolha de cruzamento e alvo. Preservar desafio após o aprendizado.',
'A pessoa executa ao menos uma esquiva e identifica um ataque válido antes de entrar na primeira disputa real.',
['18-zeca-derrota.png','22-dupla.png'],'src/first-flight.js; src/trails.js: morro-1 e morro-3')
issue('DEMO-07','P1','A primeira habilidade é aprovada só por apertar a tecla','Aberto','Aprendizado',
'A quarta lição termina quando a habilidade entra em recarga. A conclusão diz que cada parceiro tem seu jeito, mas não explica ali o Puxão preciso de Brisa nem pede aproveitar seu efeito.',
'O jogador conhece a tecla, mas pode não entender custo, benefício, duração ou momento de uso.',
'Mostrar nome e efeito da habilidade do parceiro equipado e pedir um uso que demonstre seu benefício. Distinguir animação de efeito válido no combate.',
'A lição mostra o efeito específico e deixa claro quando ele começou, terminou e ficou disponível de novo.',
['11-tutorial-concluido.png','29-parceiro-nivel7.png'],'src/first-flight.js: lesson 4; src/engine.js: types')
issue('DEMO-08','P1','Diálogo fechado continuava cobrindo o bairro','Corrigido','Defeito visual e funcional',
'Ao entrar no Morro, o diálogo do Sr. Assis continuava visível e citava o quintal. O DOM tinha hidden=true, mas .pilot-dialogue forçava display:grid!important e vencia o estado fechado.',
'Uma grande parte do cenário e dos controles ficava encoberta na primeira chegada ao bairro.',
'Adicionada uma regra específica para .pilot-dialogue[hidden]. Reteste mostrou display:none e permitiu conversar com Zeca pelo fluxo normal.',
'Diálogo aberto é visível; fechar, mudar de área e iniciar combate escondem a camada por completo, inclusive os controles.',
['13-bairro-dialogo-antigo.png','16-morro-dialogo-corrigido.png'],'src/pilot-ui.css: .pilot-dialogue[hidden]')
issue('DEMO-09','P2','As instruções de caminhada somem na abertura','Aberto','Orientação',
'No quarto e na sala, o painel mostra lugares e Examinar/E, mas não mostra as instruções de movimento; o piloto esconde #openingHint.',
'É possível avançar pelos nomes dos lugares, porém a exploração com o personagem não fica evidente para quem chega sem conhecer os comandos.',
'Exibir uma ajuda curta de movimento e interação na primeira exploração e após troca de dispositivo. Reduzir a ajuda depois que a pessoa demonstra a ação.',
'WASD/setas, clique para caminhar e E/confirmar são descobertos sem depender de conhecimento anterior.',
['02-quarto-exploracao.png','08-sala.png'],'src/pilot-ui.css: #openingHint; src/opening-room-client.js')
issue('DEMO-10','P2','Nível do pipeiro e do parceiro parecem contraditórios','Aberto','Clareza de progressão',
'Depois dos cinco encontros, Brisa estava no nível 7, mas o cabeçalho do jogador continuava no nível 1. A ficha mostrava “Histórico: 0 conquistas”, embora o bairro estivesse vencido; esse contador representa outro tipo de conquista.',
'O progresso é persistido, mas os nomes podem fazer a pessoa pensar que suas vitórias não contaram.',
'Rotular Nível do pipeiro e Nível do Pipamon, explicar como cada um evolui e nomear o contador de capturas/transferências de forma específica. Mostrar vitórias de trilha em um lugar próprio.',
'O jogador distingue XP de conta, XP individual, vitórias e capturas de propriedade.',
['29-parceiro-nivel7.png','42-colecao-dois-parceiros-1080.png'],'src/pipamon-level-client.js; src/menu-ui.js: inventoryCaptures; src/plaza-client.js: refreshPlazaHUD')
issue('DEMO-11','P2','Resultados abrem com foco em fechar','Aberto','Navegação',
'Nas telas de vitória e derrota, o foco inicial foi para o X. O caminho útil, revanche ou próximo encontro, fica em outra região.',
'Quem joga por teclado ou controle precisa procurar a ação principal após cada duelo.',
'Definir foco contextual em Tentar novamente, Ver meu caminho ou encerramento da demo, preservando a opção de sair e o retorno de foco.',
'Confirmar depois do resultado executa a ação destacada e esperada, sem fechar por engano.',
['18-zeca-derrota.png','19-zeca-vitoria.png'],'src/index.html: modal; src/results-client.js; src/encounter-story-client.js')
issue('DEMO-12','P2','Código da sala quebra em linhas na HUD','Aberto','Layout',
'Em 1280 x 720, o chip lateral do código dividiu os seis caracteres em mais de uma linha. O código completo continuou disponível no menu da partida.',
'Ler ou ditar o convite pela HUD fica mais difícil.',
'Usar uma área suficiente para seis caracteres, sem quebra, e uma ação de copiar claramente identificada. Preservar o código inteiro no menu.',
'Seis caracteres e o rótulo cabem em 720p e 1080p, com escala de texto maior.',
['33-online-menu-convidado.png'],'src/battle-hud-painted.css: .room-chip')
issue('DEMO-13','P2','Validação do código e foco do convite são genéricos','Aberto','Entrada online',
'Digitar 123 e confirmar exibiu a validação genérica do navegador. No convite corrigido, o código veio preenchido, mas o foco inicial ainda foi para Criar sala.',
'Um convidado pode não entender o formato ou criar outra sala em vez de entrar na recebida.',
'Informar “Código de 6 caracteres” e erro contextual. Em link de convite, focar Entrar e priorizar essa ação; no acesso normal pelo menu, manter Criar sala.',
'Código curto, inexistente, expirado e sala cheia produzem mensagens úteis. Confirmar em um convite entra na sala recebida.',
['37-convite-corrigido.png','38-reentrada-bloqueada.png'],'src/courtyard-client.js: offerRoomInvitation; src/index.html: joinForm e openSheet')
issue('DEMO-14','P2','Fila rápida mistura espera por pessoas e entrada de bots','Aberto','Clareza do online',
'A busca mostrou contagem e aviso de que bots completariam a sala, junto da mensagem de que a partida começa quando alguém entrar. A sala foi preenchida por Zeca, Bia e Nando.',
'A pessoa pode interpretar que depende de outro humano para começar ou não distinguir os bots no placar.',
'Usar estados próprios para busca, preenchimento por IA e contagem de início. Marcar IA/bot no placar da partida rápida, preservando os nomes narrativos nas Trilhas.',
'A UI comunica de forma consistente quantas pessoas e bots estão na sala e quando a partida começa.',
['35-partida-rapida-bots.png'],'src/index.html: combatReadout e banner; src/engine.js: QUICK e fillBots')
issue('DEMO-15','P1','A primeira recompensa pode ser perdida num ritual ainda novo','Aberto','Risco de experiência',
'A invocação avisa antes de iniciar que consome a rabiola, permite três tentativas e danifica o item ao fechar ou recarregar. O ritual foi concluído com sucesso pelo teclado nesta auditoria; não foi testada a perda do item.',
'A única rabiola do primeiro chefe pode virar uma frustração antes de o jogador conhecer a mecânica. É um risco de desenho da demo, não um bug de consumo comprovado.',
'Oferecer uma primeira invocação guiada, consulta do feitiço antes do consumo e um caminho claro de recuperação da recompensa. Definir a política antes de publicar.',
'O jogador entende a mecânica e a consequência antes de gastar sua primeira recompensa. Testar falha, interrupção, reenvio e eventual recuperação.',
['36-invocacao-primeira-recompensa.png','40-ritual-1080.png'],'src/summon-client.js: summonNotice; migrations 007/008/014')
issue('DEMO-16','P2','Sucesso de invocação não leva ao parceiro novo','Aberto','Conclusão de recompensa',
'Raio de sol foi confirmado na coleção, mas a tela não ofereceu uma ação principal direta de Ver parceiro ou Equipar. Foi necessário fechar e abrir a coleção.',
'O momento de descoberta termina em navegação administrativa, enfraquecendo o vínculo com o segundo parceiro.',
'Adicionar Ver parceiro e Equipar como ações claras, com equipamento confirmado pelo servidor. Manter Brisa equipada até a escolha explícita.',
'A conquista leva à ficha correta e equipar funciona sem duplicar nem consumir outra rabiola.',
['41-invocacao-confirmada.png','42-colecao-dois-parceiros-1080.png'],'src/summon-client.js: updateSummonRun')
issue('DEMO-17','P3','A apresentação do presente reaparece na retomada','Aberto','Polimento de continuidade',
'Recarregar depois de guardar o presente e antes de levá-lo à mesa repetiu a apresentação da Rabiola Antiga. Não foi observada duplicação de parceiro ou recompensa.',
'A retomada parece repetir uma aquisição já confirmada, embora seja apenas a cena.',
'Persistir ou reconstruir o momento de apresentação com uma frase de retomada, sem simular novo recebimento.',
'A retomada deixa claro o objetivo atual e não sugere entrega repetida.',
['05-presente.png','07-nome-persistente.png'],'src/opening-client.js; src/opening-room-client.js')

coverage=[
('Abertura','Concluído','TV, desenhos, bancada, última vareta, presente, nascimento, nome e saída de casa.'),
('Persistência inicial','Concluído','Retomada antes da invocação, nome Brisa e saída do quarto preservados. Um parceiro após recargas.'),
('Primeiro voo','Concluído','Cinco lições feitas com comandos reais. Saída e retomada verificadas na terceira lição.'),
('Morro do Sol','Concluído','Vitórias reais contra Zeca, Bia, Juninho/Lia, Tião e Mikka; derrotas e revanches também percorridas.'),
('Recompensas e save','Concluído','200 moedas das primeiras vitórias do bairro nesta sessão; Brisa nível 7; rabiola única verificada após recarga.'),
('Segundo parceiro','Concluído','Rabiola do chefe usada no ritual; feitiço consultado e lançado pelo teclado; coleção final com Brisa e Raio de sol.'),
('Sala privada','Parcial','Duas contas na mesma sala, movimentos/ataques do anfitrião e coleção casual preservada. Não foi concluída uma partida privada completa de duas pessoas ativas.'),
('Recarga online','Reprovado','Tela vazia corrigida e retestada; recuperação do mesmo assento ainda bloqueada por “Você já entrou nesta sala”.'),
('Partida rápida','Concluído no fluxo','Busca, preenchimento com bots, partida e resultado observados. Não é teste de latência real ou capacidade.'),
('Layout','Amostras','Jornada em 1280 x 720; convite, ritual e coleção também em 1920 x 1080. Sem aprovação global de todos os estados ou dispositivos.'),
('Fora do recorte','Reprovado','Beira-Mar liberada e encerramento aponta ao segundo bairro. A política de demo ainda precisa existir.'),
('Cadastro e e-mail reais','Não testado','Autenticação local de fixtures; sem cadastro, senha real, SMTP ou confirmação de e-mail de produção.'),
('Rede real, controle e celular','Não testado','Sem duas redes físicas, latência artificial, teste de carga, controle físico, Steam Input ou auditoria completa em celular.')]

summary='A abertura e os cinco encontros do Morro do Sol foram concluídos. O ciclo de parceiro, combate, desbloqueio, recompensa, salvamento e invocação já funciona. A demo ainda não está pronta para lançamento: falta delimitar seu conteúdo, dar um encerramento próprio e recuperar uma sessão multiplayer interrompida.'
method='Auditoria local em 20/10/2026, usando um slot novo (.local/demo-journey-audit-20261020). Kael começou sem parceiros; o segundo cliente usou a fixture Ana com coleção preexistente. Navegação por botões reais, mouse e teclado. Nos duelos, sequências de comandos se orientaram pelos avisos visíveis de cruzamento e ameaça; não houve alteração de vitória, inventário ou estado interno para avançar. Isso não substitui playtests humanos e não mede dificuldade pelo número de tentativas.'
fixed='Duas correções pontuais foram feitas para continuar a auditoria: respeito ao atributo hidden nos diálogos do piloto e apresentação de convite para conta autenticada. A segunda tem um teste de regressão novo. A retomada do assento não foi implementada.'
next_steps=[
'Recuperação online: restaurar o assento autenticado após recarga, com sala encerrada, expiração, retorno e placar corretos.',
'Recorte real da demo: política no servidor e na navegação para início + Morro do Sol + modos online aprovados, sem apagar progresso existente.',
'Encerramento: trocar o convite imediato à Beira-Mar por conclusão da demo, recompensa e caminhos para online/replay.',
'Tutorial: alinhar os nomes das ações, praticar esquiva e demonstrar o efeito da habilidade antes do primeiro rival.',
'Recompensa: primeiro ritual guiado e saída de sucesso para a ficha do novo parceiro.',
'Reteste de lançamento: cadastro real em homologação, duas máquinas/redes, latência e desconexão, controle físico, 720p/1080p e fluxo completo sem ferramentas de desenvolvimento.'
]

md=['# Auditoria da jornada da demo - PipaKlub','',summary,'','## Método','',method,'',fixed,'','Os IDs DEMO abaixo são locais deste relatório; nenhum ticket ou comentário foi publicado no Linear. Nenhum push, deploy ou migração de produção foi realizado.','',
'## Resultado jogável','',
'- Brisa nasceu, recebeu o nome escolhido e permaneceu único após as recargas.',
'- Zeca e Bia foram vencidos; a dupla teve derrota e revanche; Tião e Mikka foram vencidos. Os caminhos foram liberados na ordem.',
'- A líder não estava revelada antes da liberação do último encontro.',
'- As primeiras vitórias do bairro confirmaram 25 + 30 + 36 + 41 + 68 = 200 moedas nesta sessão. Brisa chegou ao nível 7.',
'- A rabiola de Raio de sol apareceu uma vez na mochila após recarregar e depois foi usada com sucesso. A coleção final contém dois parceiros.',
'- No casual com duas contas, a coleção do convidado permaneceu com dois exemplares. A conta do protagonista recebeu XP por corte entre contas.',
'','## Cobertura','', '| Área | Resultado | Evidência / limite |','|---|---|---|']
for a,b,c in coverage:md.append('| '+a+' | '+b+' | '+c+' |')
md+=['','## Problemas e recomendações','']
for i in issues:
 md += [f"### {i['id']} - {i['priority']} - {i['title']}",'',f"**{i['status']} · {i['kind']}**",'', '**Observado:** '+i['evidence'],'','**Efeito para o jogador:** '+i['impact'],'','**Correção / recomendação:** '+i['fix'],'','**Critério de aceite:** '+i['accept'],'','**Implementação relacionada:** '+i['source'],'']
 for shot in i['shots']:md += [f'![{i["id"]} - {shot}]({shot})','']
md+=['## O que manter','',
'A identidade brasileira do bairro, as falas dos moradores, o nascimento do parceiro, o nome individual, os rostos da coleção e o ritmo de desbloqueio em cinco encontros formam uma base coerente. O salvamento confirmado e a proteção explícita do casual comunicam regras úteis. A mudança de páginas das fichas melhora a consulta sem esconder o Pipamon.',
'','## Ordem de trabalho para a demo','']
md += [f'{n}. {s}' for n,s in enumerate(next_steps,1)]
md += ['','## Verificação técnica após as correções','',
'Builds Worker e Pages concluídos. Suíte: 270 testes, 269 aprovados na execução padrão e um teste de socket bloqueado por EACCES do sandbox. Esse teste de WebSocket passou isoladamente com permissão para o socket local. git diff --check não apontou erros. Console da sessão do protagonista sem erros capturados; a tela vazia era um problema de navegação, não uma exceção JavaScript.',
'','## Limites e pendências','',
'Não houve validação de cadastro/e-mail reais, entrega SMTP, migração em homologação, Render, build instalado de Windows, Steam Input, controle físico, duas redes, oito jogadores, degradação de rede ou uso prolongado. Não foi testada a falha das três tentativas de invocação nesta passagem; o sucesso foi confirmado. Os testes automatizados não equivalem a uma aprovação da demo com pessoas.',
'','A primeira mensagem de sessão da abertura não se repetiu após isolar abas de outros servidores locais. Ela fica registrada como interferência de ambiente a investigar, sem ser contabilizada como defeito de produção.',
'','Os prints originais foram mantidos. Alguns nomes de arquivos refletem o momento de captura; o manifesto descreve o estado efetivamente observado.']
(root/'AUDITORIA-DEMO.md').write_text('\n'.join(md),encoding='utf-8')
(repo/'AUDITORIA-DEMO-2026-10-20.md').write_text('# Auditoria da demo\n\nRelatório completo com cobertura, achados e prints em [art/ui-reviews/demo-journey-2026-10-20/AUDITORIA-DEMO.md](art/ui-reviews/demo-journey-2026-10-20/AUDITORIA-DEMO.md).\n\n'+summary+'\n\nCorreções aplicadas nesta auditoria: diálogo fechado respeita hidden; convite autenticado deixa de produzir tela vazia. Recuperação do assento online e recorte da demo continuam pendentes.\n',encoding='utf-8')

images=[]
for p in sorted(root.glob('*.png')):
 with Image.open(p) as im:dimensions=list(im.size)
 images.append(dict(file=p.name,dimensions=dimensions,kind='Captura própria do ambiente local',date='2026-10-20'))
data=dict(date='2026-10-20',summary=summary,method=method,coverage=coverage,issues=issues,images=images,nextSteps=next_steps)
(root/'auditoria.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

cards=''
for i in issues:
 photos=''.join(f'<figure><a href="{s}" target="_blank"><img loading="lazy" src="{s}" alt="{esc(i["id"]+" - "+s,quote=True)}"></a><figcaption>{esc(s)}</figcaption></figure>' for s in i['shots'])
 cards+=f'''<article data-priority="{i['priority']}" data-open="{'false' if i['status']=='Corrigido' else 'true'}"><div class="badges"><b>{i['id']} · {i['priority']}</b><span>{esc(i['status'])}</span><small>{esc(i['kind'])}</small></div><h2>{esc(i['title'])}</h2><p><strong>Observado</strong> {esc(i['evidence'])}</p><p><strong>Por que importa</strong> {esc(i['impact'])}</p><p><strong>Próxima ação</strong> {esc(i['fix'])}</p><p><strong>Como aprovar</strong> {esc(i['accept'])}</p><div class="photos">{photos}</div><p class="source">{esc(i['source'])}</p></article>'''
rows=''.join(f'<tr><th scope="row">{esc(a)}</th><td>{esc(b)}</td><td>{esc(c)}</td></tr>' for a,b,c in coverage)
steps=''.join(f'<li>{esc(s)}</li>' for s in next_steps)
html=f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PipaKlub · Auditoria da demo</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#f8f4e8;color:#183f36;font:17px/1.65 system-ui,sans-serif}}main{{max-width:1200px;margin:auto;padding:48px 28px}}h1{{font-size:clamp(36px,5vw,60px);line-height:1.1;max-width:950px}}h2{{font-size:26px;line-height:1.25}}.lead{{font-size:22px;max-width:960px}}a{{color:#9b431d}}.kicker{{font-size:13px;letter-spacing:.12em;text-transform:uppercase;font-weight:800}}section{{margin:44px 0}}table{{border-collapse:collapse;width:100%;font-size:15px}}th,td{{text-align:left;vertical-align:top;border-bottom:1px solid #c7bda6;padding:12px}}th{{min-width:140px}}.table{{overflow:auto}}article{{border:1px solid #c9bca2;background:#fffdf7;border-radius:10px;padding:24px;margin:24px 0}}article p strong{{display:block;font-size:13px;text-transform:uppercase;letter-spacing:.05em;color:#766242}}.badges{{display:flex;gap:12px;align-items:center;flex-wrap:wrap;font-size:13px}}.badges b{{background:#255c4e;color:#fff6df;padding:5px 10px;border-radius:4px}}article[data-priority=P1] .badges b,article[data-priority=P0] .badges b{{background:#a14124}}.photos{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}}figure{{margin:0}}figure img{{width:100%;height:auto;display:block;border:1px solid #d3c9b6}}figcaption,.source{{font-size:12px;color:#6b6252;overflow-wrap:anywhere}}select{{font:inherit;padding:8px 12px;background:white;border:1px solid #a99470;border-radius:5px;margin-left:8px}}li{{margin:12px 0}}[hidden]{{display:none!important}}@media(max-width:760px){{main{{padding:28px 16px}}.photos{{grid-template-columns:1fr}}article{{padding:18px}}}}@media print{{article{{break-inside:avoid}}.filter{{display:none}}}}
</style><main><p class="kicker">Revisão jogável · 20 outubro 2026 · Ambiente local</p><h1>A jornada funciona.<br>A demo precisa de um fechamento.</h1><p class="lead">{esc(summary)}</p><p><a href="AUDITORIA-DEMO.md">Relatório editável</a> · <a href="auditoria.json">Dados da auditoria</a> · <a href="contact-sheet.jpg">Acervo visual</a></p><section><h2>O que foi testado</h2><p>{esc(method)}</p><p>{esc(fixed)}</p><div class="table"><table><thead><tr><th>Área</th><th>Resultado</th><th>Evidência e limite</th></tr></thead><tbody>{rows}</tbody></table></div></section><section><h2>Prioridades para lançar</h2><ol>{steps}</ol></section><section><div class="filter"><label for="priority">Achados <select id="priority"><option value="">Todos</option><option>P0</option><option>P1</option><option>P2</option><option>P3</option></select></label></div>{cards}</section><section><h2>Verificação técnica e limites</h2><p>Builds Worker e Pages concluídos. 270 testes: 269 aprovados na suíte padrão, mais o teste de WebSocket aprovado isoladamente após bloqueio do socket pelo sandbox. As correções são locais; sem push, deploy, comentário no Linear ou migração de produção.</p><p>Cadastro e e-mail reais, Render, redes físicas distintas, latência, carga, controle físico, Steam Input e auditoria completa em celular continuam pendentes. Esta passagem não testa a perda das três tentativas do ritual. A análise de dificuldade precisa de jogadores humanos.</p></section></main><script>document.getElementById('priority').addEventListener('change',function(){{document.querySelectorAll('article').forEach(a=>a.hidden=!!this.value&&a.dataset.priority!==this.value)}})</script></html>'''
(root/'index.html').write_text(html,encoding='utf-8')
archive=repo/'output/pipaklub-auditoria-demo-2026-10-20.zip'
archive.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in root.iterdir():
  if p.is_file() and p.suffix in ['.png','.jpg','.json','.md','.html']:
   z.write(p,'auditoria-demo/'+p.name)
print(json.dumps(dict(images=len(images),issues=len(issues),archive=str(archive)),ensure_ascii=False))
