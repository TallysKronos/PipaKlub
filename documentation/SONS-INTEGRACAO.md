# Efeitos sonoros · integração nativa

Integração local do pacote V1 na campanha Godot. O serviço `sound_director.gd` é filho persistente do front end e sobrevive às trocas de página. `sound_observer.gd` lê as transições de apresentação e os sinais oficiais do combate; nenhum cálculo de dano, prêmio ou persistência foi transferido para o áudio.

O catálogo registra 94 eventos conectados e 21 reservados. A contagem indica pontos de código, não cobertura de execução em uma partida.

## Comportamento conectado

- Botões nativos: foco, confirmar e voltar. Pausa, retomada, mapa, mochila e diálogos têm sinais adicionais.
- Passos: distância realmente percorrida; sem deslocamento, sem som. A rua usa a classificação de piso do cenário; os parques usam a região de matinho; interiores usam madeira. O deslocamento da mãe também é acompanhado. Deslocamentos grandes de reposicionamento são ignorados. A transmissão em vídeo não recebe passos duplicados do quarto nativo.
- Ambientes: vento na vila/morro e folhas nos parques. Loops param ao trocar de contexto e pausam junto do jogo. As texturas de IA ficam reservadas até edição/escuta de loop.
- Oficina: encaixe de vareta, início/aperto de nó, sucesso, recorte com limite de 4 Hz, erro/rasgo, rajada, equilíbrio, início de elo, conclusão de etapa e reposição. O nascimento vem do parceiro realmente incluído no snapshot confirmado.
- Combate: `damage_applied` determina linha/estrutura, crítico, linha cortada e quebra. `combat_feedback` determina bloqueio/esquiva confirmados. Ataques, guarda, puxão, habilidade, preparação/liberação de assinatura e fases são acompanhados pela mudança aceita nos timers do modelo. Não tocar impacto só por apertar Espaço. O tutorial, que não possui os mesmos sinais, usa diferenças reais de HP/estrutura/bloqueios.
- Resultados: vitória/derrota/fuga e exercício concluído; retorno de energia e guarda; alerta de linha baixa espaçado em seis segundos.
- Progresso: diferenças entre snapshots após gravação confirmada determinam itens, moedas, novos avistamentos, XP, nível, objetivo, reparo e seleção de parceiro. O primeiro snapshot ao carregar uma jornada é só baseline. Operações já aplicadas não geram uma nova mudança e não repetem premiações.
- Chamados: estudos de voz do parceiro ao equipar. Eles continuam sujeitos à revisão artística por escuta.

## Mixagem e ciclo de vida

Carregamento sob demanda dos streams; não abrir 215 sons no início. Limite global de 24 vozes, limite por evento, cooldown e alternância de variantes sem repetição imediata. Buses UI, SFX e Ambience separados. Proteção de pico com AudioEffectHardLimiter no Master a -1 dB, sem ganho adicional. A proteção não equivale a uma medição de true peak da mixagem final.

Efeitos de contexto são encerrados ao mudar de tela. Confirmações de inventário/progresso e nascimento sobrevivem à troca imediata de tela, para não serem cortados antes de ouvir. Pausa geral e pausa local de batalha/oficina interrompem a reprodução de efeitos do jogo, preservando os sons de menu. Perda de foco pausa as vozes. Retomar foco não desfaz uma pausa explícita do jogador.

Configurações → Áudio oferece volume geral, efeitos, menus/diálogos e ambientes; zero silencia. O sinal breve de cada fala é opcional e desligado por padrão. Valores ficam no arquivo de preferências do dispositivo, separados dos saves; entradas inválidas são rejeitadas ou limitadas entre zero e um. O áudio dos vídeos existentes segue o volume geral. Não houve escolha automática das músicas experimentais para a trilha.

## Distribuição e limites

O catálogo JSON foi incluído no filtro do preset Windows; os WAVs são recursos importados. Sons de mecânicas futuras e texturas não editadas permanecem no catálogo como reserva, sem inventar ações de gameplay. `art/sfx-study-v1/integration.json` lista as conexões de código e as reservas; `integration_status` não significa aprovação auditiva.

Verificação realizada: importação dos 215 WAVs e análise estática de GDScript. A verificação de recursos reportou zero erros e quatro avisos anteriores à tarefa (três imports de imagens de prova e uma textura ilustrada de fallback). Não foi executada suíte de testes, playthrough, revisão auditiva da mistura, exportação final, commit ou publicação.

Para reproduzir a documentação do catálogo depois de regerar assets, executar `tools/document-sfx-integration.py` por último.

Correção após uso no editor: substituída a atribuição de `Array.filter()` por remoção em ordem inversa, preservando `Array[AudioStreamPlayer]`. Diagnóstico pontual em execução com driver de áudio Dummy passou para lista vazia, vozes ativas, liberadas, agendadas para exclusão e concluídas. Isso verifica o ciclo de vida, sem constituir revisão auditiva ou playthrough.

## Passos · revisão de conforto V2

Música de título e prólogo adicionada em `art/opening-theme-v1/`; ver o README dessa pasta para a origem, uso de referência, processamento e limites da revisão. Bus Music e controle Música são independentes dos efeitos. O filme da TV mantém seu áudio.

Os vinte WAVs de passos foram refeitos como contatos curtos de sola, com ruído filtrado e menor conteúdo agudo. Removidos os impactos afinados compartilhados com objetos; madeira conserva apenas uma ressonância grave discreta. Picos de arquivo entre -18 e -20 dBFS, ganho de reprodução -6 dB e variação adicional de até -1,5 dB. Não repetir as duas últimas variantes da mesma superfície. Intervalo mínimo de 280 ms e distância de 54 px / 0,8 célula; folhas extras no máximo a cada 1,2 s e com ganho -18 dB. Passos da mãe também reduzidos.

Reprodução parcial: `tools/refine-soulmonsters-footsteps.py` atualiza somente os vinte WAVs, catálogos e medições, preservando os outros efeitos e metadados de integração. Audição comparável em `art/sfx-study-v1/previews/footsteps-v2.mp3` (pedra, terra, grama e madeira, cinco contatos de cada). O ZIP e a montagem geral `world.mp3` são da primeira entrega; para os passos atuais use a prévia V2 ou o catálogo individual. A melhoria perceptiva ainda depende da escuta do usuário no jogo.
