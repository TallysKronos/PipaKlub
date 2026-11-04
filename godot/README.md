# Soulmonsters: Elo das Ruínas — campanha Godot

Cena principal: `scenes/campaign.tscn`, Godot 4.7.2 Compatibility, Windows x64. Execute `Iniciar.ps1` ou `exports/windows/Soulmonsters.exe` junto de `Soulmonsters.pck`. Para gerar novamente: `Exportar.ps1 -GodotPath <executável>`; templates oficiais Windows precisam estar instalados. A pasta exportada inclui licenças do motor e hashes em `build-info.json`. Binários ficam fora do Git.

## Implementado

- Três jornadas locais sem login, abertura de Kael, nascimento/nome de Rabbito, rua, professor e cinco lições de voo.
- Oficina nativa em cinco etapas: primeira escolha, rabiolas encontradas, reserva de estoque, cancelamento com devolução, restauração após falha, qualidade/variante e parceiros com UUID.
- Portão da rua leva ao Jardim das Pipas, depois à Clareira do Papel e às Veredas ilustradas. Os dois mapas iniciais reutilizam o renderizador JS para exportar chão e objetos separados; colisões, pontos de interação e entradas vêm das plantas originais. Nas duas áreas iniciais, navegação por teclado; clique para caminhar permanece disponível nas Veredas.
- Morro do Sol completo: cinco mapas originais, Zeca, Bia, Juninho e Lia simultâneos, Tião e Mikka; séries de rodadas, passagens por vitória, revanches, dificuldade adaptativa, XP, moedas e rabiola única. Entrada pela Rua dos Ventos, retorno à cidade e conexão ao parque. Clique para caminhar ou WASD/setas, com respeito aos desníveis.
- Cinco baús com recompensas originais e coleta única. Nina aceita a missão; vencer Lacertubo remove o boss e libera a rabiola de missão. Devolução fica salva. O jogador recebe separadamente a rabiola de Lacertubo.
- Encontros somente no mato, espécies e nível sorteados antes da luta, primeira rabiola garantida e proteção após sete vitórias sem drop. Combate pode ser salvo/retomado, encerrado por fuga e concede desgaste/XP uma vez.
- Coleção, escolha do parceiro, seguidor correspondente, bolsa e reparos gratuitos com o professor.
- Filtro CRT ativado por padrão, opção para desativar e tela cheia, separados dos slots.

## Controles

WASD/setas: mover; E/Enter: interagir por proximidade. No Morro e nas Veredas, clique para caminhar; nas Veredas, M para visão geral, sem lista de destinos revelados. Batalhas: Espaço cortar, Q habilidade, Shift esquiva, R puxão, G guarda, F assinatura de Rabbito. Bancada: mouse e A/D, com instruções por etapa. Esc salva e volta ao menu; na oficina pede para cancelar a montagem. Perda de foco pausa treino/combate/oficina.

## Persistência

`%APPDATA%/PipaKlub/campaign/slot-1.json` a `slot-3.json`. Configurações em `settings.cfg`. Temporário verificado, backup da gravação anterior, recuperação e bloqueio de schema futuro. Saves web/protótipos não são importados. Recibos impedem reaplicar operações na jornada carregada; não impedem edição/restauração manual nem certificam parceiros online. Não há lock entre duas instâncias nem Steam Cloud.

## Verificações autorizadas — 25/10/2026

- `godot --headless --path godot --script res://tests/campaign_checks.gd`: 206 verificações, zero falhas.
- `godot --headless --path godot --script res://tests/campaign_view_checks.gd`: 23 verificações, zero falhas.
- Referências geradas diretamente do código JS com `node scripts/godot-campaign-reference.mjs`: três montagens completas, comandos dos quatro tipos e trechos de 12 segundos das duas fases do boss. Isso não prova equivalência de todo o motor online.
- Testes usam pastas únicas `campaign-checks-<UUID>` e `campaign-view-checks-<UUID>`. Vitória sintética é usada explicitamente para testar transações e transições; não é playtest de dificuldade.
- Capturas visuais de parque, intro do boss e vitória em 1280×720; captura não grava jornada nem comprova um playthrough.

## Limites da entrega

Ainda faltam áudio, controle completo da bancada, remapeamento de gamepad, especializações, todas as manobras de linha, revisão integral de dificuldade e playtest humano contínuo desde novo jogo. As cinco lições do tutorial foram comparadas com traços completos do original; isso não comprova equivalência de todo o motor de combate. Campanha não chama rede, mas não foi validada com a rede fisicamente desativada.

Steamworks/App ID ainda não existem. Publicação, conquistas, Cloud e online opcional não estão implementados. Política de certificação dos parceiros continua pendente. PIP-60 permanece em andamento.

## Protótipos anteriores

`Iniciar.ps1 -Prototype` abre a antiga cena ilustrada sem economia de campanha. `-Test` executa a revisão de navegação desse protótipo; não executa os testes de campanha acima. Documentação: `assets/illustrated/README.md`. O pátio de escala e `scenes/main.tscn` continuam separados. Conversão Soulgen pausada em `art/soulgen/CONTINUIDADE.md`: próximo é Platofolha.

## Revisão das HUDs
Combate com ícones do kit Papel e Bambu, estados de recarga/energia, barras nomeadas e percentuais; salvar/fugir disponíveis na pausa. Exploração com painéis de contraste para localização, missão e moedas. Capturas revisadas em 1280×720; outros formatos e navegação por controle ainda pendentes. Verificações de campanha: 141 + 17 aprovadas após a revisão.

Tutorial: sequências completas das cinco lições geradas do JavaScript original e reproduzidas na Godot. Corrigidos vento sobre Nozinho, início do especial e acionamento de R por pressionamento. Comparação cobre conclusão e posição/energia/acertos/bloqueios/pontuação finais de cada sequência; não equivale a paridade de toda entrada possível. São agora 176 verificações de domínio e 17 de integração aprovadas. Tutorial com etapa e instruções roláveis; coleção com retrato, condição e progresso de XP. Capturas revisadas em 1280×720.

## Integração do percurso do parque

`node scripts/godot-park-sync.mjs` exporta as duas áreas iniciais. Usa SOULGEN_CANVAS_MODULE, como o sincronizador da campanha. Não gera arte nova nem copia colisões à mão; objetos ficam em PNGs separados com profundidade. Rigs ambientais estão exportados na pose inicial, ainda sem animação nativa. A fonte TMJ/renderer JS continua canônica; refazer o export após editar essas plantas.

Verificação atual: 188 verificações de domínio, 23 de integração e 1510 de geometria (probes comparadas ao JS e acesso às interações), todas aprovadas em dados isolados. Geometria: `godot --headless --path godot --script res://tests/park_checks.gd`. As 1510 verificações não são 1510 cenários de gameplay: a maioria compara pontos permitidos/proibidos. Capturas do Jardim e Clareira inspecionadas em 1280×720. Ainda sem playthrough humano completo, controle físico ou avaliação de dificuldade.

## Controles centralizados

Configurações → Controles permite remapear 12 ações do teclado e restaurar padrões. Conflitos são recusados; setas, Enter, Tab e Esc ficam reservados à navegação. Preferências persistem fora dos slots. A campanha lê ações nomeadas; dicas da HUD de batalha seguem teclado/controle. O analógico tem zona morta radial de 0,2 e mantém intensidade nas salas e nos mapas do parque. Desconexão pausa treino/batalha/oficina e avisa na exploração. Menus usam foco nativo; retomar solta o foco para Espaço continuar sendo ataque.

Controle: analógico esquerdo move, A/× interage, X/□ corta, Y/△ habilidade, B/○ esquiva, RB/R1 puxão, LB/L1 guarda, R3 assinatura, View/Select mapa nas Veredas, Start retorna ao menu com save. Ainda sem remapeamento dos botões do controle, glifos detectados por modelo ou bancada totalmente operável sem mouse. Não declarar suporte completo a Steam Deck.

Validação de entrada: `godot --headless --path godot --script res://tests/controls_checks.gd` — 19 verificações aprovadas usando eventos simulados e configurações em pasta isolada. Persistência/regras 188 e integração 23 também aprovadas após integrar os controles. Nenhum controle físico foi testado. Tela de remapeamento inspecionada em 1280×720. Build Windows regenerada sem erros.

## Percurso contínuo validado — 25/10/2026

Executado roteiro novo jogo → professor → cinco lições → oficina com gestos reais → três mapas do parque → Nina → vitória real sobre Lacertubo → coleta/devolução → salvar/retomar → voltar ao professor/reparar. Sem conceder itens, XP ou vitória diretamente. 105 verificações aprovadas na execução com encontro aleatório/fuga; 7 adicionais confirmaram a carga em processo novo. Runtime acelerado, não playtest humano de dificuldade. Corrigido bloqueio de save intermediário da oficina após recortar, causado pela representação numérica da direção do vento no JSON.

Roteiro: `godot --headless --path godot --script res://tests/journey_playthrough.gd`. Usa uma pasta nova e isolada; o número de verificações varia se houver encontro aleatório. Relatório e limitações em [PLAYTEST-2026-10-25.md](PLAYTEST-2026-10-25.md). Persistência/regras agora: 206 verificações aprovadas, incluindo ida/volta JSON em todas as etapas da oficina. Entrada: 19; integração: 23. Executável Windows exportado iniciou e encerrou com código 0 no smoke headless; isso não equivale ao percurso integral dentro do release ou a teste de instalação Steam.


## Morro jogável — 25/10/2026

`node scripts/godot-morro-sync.mjs` exporta diretamente os cinco mapas e diálogos
originais, NPCs, geometria, desníveis, grafo de navegação e regras da demo.
`tests/journey_playthrough.gd -- --with-morro` percorreu Novo jogo → oficina →
Morro inteiro → cidade → parque → Lacertubo → missão de Nina → reparo, com
198 verificações e nenhuma falha, usando comandos e callbacks das telas.
Inclui salvar/retomar a disputa de três participantes e revisitar os mapas
conquistados. Não concede parceiros, inventário ou vitórias artificiais.

Regras: 377 verificações; transações isoladas: 47 (derrota, fuga, revanche e
rabiola única); geometria e navegação: ver contagem em MORRO-PLAYTEST-2026-10-25.md.
Ao carregar um combate, ele fica pausado até o jogador escolher Retomar.

Medição gráfica local em 1280×720, RTX 3060, limite de 60 FPS, 150 amostras por
cena após 60 frames de aquecimento: medianas de 16,64–16,66 ms; p95 de
16,72–16,99 ms. São medições deste PC; não certificam hardware mínimo.
Relatório e limites: `MORRO-PLAYTEST-2026-10-25.md`.
