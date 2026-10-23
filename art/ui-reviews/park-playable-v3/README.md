# Parque dos Ventos — correções da auditoria e passeio jogável

## Entrega

Prévia local em `http://127.0.0.1:5241/`. Não escreve no servidor do jogo, não concede XP/itens na conta e não modifica o mapa de produção.

- Teclado disponível na entrada; controles de inspeção devolvem o foco à exploração. Tab continua disponível e o diálogo nativo mantém o foco no painel.
- Objetos têm seleção própria: clicar na placa, banco, NPC ou fibra aproxima o jogador pelo caminho válido e abre a interação ao chegar. O clique não é mais convertido indiscriminadamente em um destino atrás do desenho.
- Todos os props podem reduzir a opacidade se encobrirem o protagonista; um anel preserva a localização dos pés.
- O bloco sólido que fechava o coreto foi substituído pelas bases de suas colunas. O banco foi afastado da escada. Ao entrar, somente o teto reduz a opacidade; o piso continua visível sob os personagens. A geometria é construída numa cópia do mapa.
- Mensagens de chegada são substituídas quando o jogador retoma movimento manual; marcador mostra o destino.
- Objetivo visível, mapa ampliado com destinos acessíveis por teclado, nomes nas saídas e explicação dos limites da prévia.
- Sr. Assis apresenta uma tarefa: aceitar → coletar explicitamente três fibras → voltar → receber um kit de reparo local uma única vez. Caminhar não concede itens.
- Rabbito acompanha a trilha do jogador. Os sprites existentes são reutilizados; tamanho e filtragem dos personagens foram ajustados. Não é um novo atlas de oito direções.
- Capim com lâminas verticais, brisa e reação à passagem. Copas variam levemente em largura/rotação dentro da mesma família; ainda não são três novos desenhos de árvores.
- Esc/Menu pausa a caminhada e abre mapa, salvar/carregar local e sons opcionais. Arquivo salvo é validado antes de restaurar tarefa e posição. Slot local: `soulmonsters.park-preview.v1`.
- Sons curtos de passos e interação são sintetizados após ativação explícita; não há trilha/ambiente sonoro final. Vento pode ser pausado independentemente do personagem.

## Verificação

39 testes direcionados: `park-exploration`, `world-isometric`, `park-coherence`, `world-navigation`, `world-map`.

Os novos testes cobrem: progressão com aceitação e coleta explícitas; proteção contra coleta/recompensa duplicadas; saves corrompidos/incompatíveis; localização de ações; acesso às escadas; todos os destinos e trajeto completo com posições seguras. A verificação de rotas respeita as curvas efetivamente percorridas por `nav.step`, que pode completar dois segmentos num frame, em vez de tratar a corda reta entre frames como a trajetória.

Validação manual feita pelo navegador nativo: teclado inicial e após botão; aceite da tarefa; mapa; três coletas; salvar, recarregar e restaurar 1/3 fibras; retorno ao NPC e recebimento de um kit; segunda conversa sem oferta de recompensa; novo salvamento e restauração com 3/3 fibras e exatamente um kit. Evidências complementares ficam nesta pasta.

## Limites

A tarefa e o kit são deste passeio; não integram campanha, oficina, inventário da conta ou combate selvagem de produção. As saídas informam o próximo destino, mas a continuação está fora da prévia. Validar integração entre cenas, aparelhos móveis e desempenho antes de adotar no jogo principal. Não foram medidos FPS nem testado controle físico.
