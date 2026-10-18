# Morro do Sol — cinco áreas por vitória

Estado: integrado localmente; revisão artística em andamento. Sem publicação automática.

| Área | Encontro existente | Liberação |
| --- | --- | --- |
| Praça da Chegada | Zeca | Abre a Escadaria da Sombra |
| Escadaria da Sombra | Bia | Abre a Laje dos Ventos |
| Laje dos Ventos | Juninho e Lia | Abre o Mirante |
| Mirante da Caixa-d’água | Tião | Abre o Parque dos Ventos |
| Parque dos Ventos | Campeão do bairro | Libera a saída para a cidade |

Os cinco encontros e suas recompensas não foram recriados. A terceira batalha continua tendo dois rivais, conforme os dados existentes. A identidade do campeão não aparece nas quatro áreas anteriores.

## Fluxo de jogo

O piloto `?overworld=pilot` instala a sequência completa. Cada área tem um encontro, uma chegada ao sul e uma passagem ao norte. Antes da vitória, a passagem possui uma cerca visível com base física. O jogador pode se aproximar e consultar a exigência; não pode atravessar a barreira. O objetivo aponta para o rival dessa área.

Após a confirmação da vitória na conta, a cerca desaparece e o objetivo passa a indicar a saída. O jogador caminha até ela e usa Interagir/E para trocar de mapa. É possível retornar à área anterior, chegando pela saída norte dela. Vitória ou derrota devolve o jogador à área da batalha; uma derrota não abre a próxima passagem.

A liberação usa um snapshot recebido do servidor na sessão atual, isolado por conta. Progresso em cache, resultado local otimista, importação pendente e callback de outra conta não abrem portas. Durante a conferência ou falha de sincronização, a passagem informa que a conta ainda precisa confirmar. As regras de batalha, propriedade e recompensas continuam validadas pelo servidor existente. As coordenadas do overworld são apresentação local, não uma nova fronteira de segurança do backend.

O mapa completo anterior permanece disponível no fluxo normal; a planta modular anterior continua em `?overworld=blockout`. O quintal atualizado foi preservado.

## Briefing e produção de arte

Referência principal: `assets/world/morro-plaza-v1/plaza-base-v1.png`, usada para câmera, escala e acabamento. Referência de personagem: atlas vigente de Kael e novos NPCs chibi. Dimensão solicitada e recebida: 1536 × 1024 em todas as quatro novas fontes, opacas. Uso em tamanho nativo, ator de 64 px, grade de navegação de 32 px e pés de 24 × 24 px.

Invariantes: câmera elevada ortogonal, fachadas voltadas ao sul, materiais de reboco/terracota/pedra, luz superior esquerda, passagem contínua, escadas com desembarque válido e área de encontro livre. Cenários sem NPC, retrato, HUD ou marcador incorporado. Entradas, saídas e NPCs são objetos independentes. Muros longos estão na arquitetura pintada contínua, sem repetir um objeto ilustrado como tile de conexão. A cerca dinâmica usa uma peça existente como objeto único, sem deformação de proporção.

Os caminhos foram medidos na imagem entregue, não copiados cegamente das posições pedidas no prompt. As quatro novas áreas têm seis camadas de objetos e uma camada de imagem. No parque o piso é plano: não foi inventada uma escada física onde a imagem mostra um caminho.

`prompts.json` preserva os prompts completos e o modo integrado image_gen. `manifest.json` registra os arquivos, dimensões e sequência. `scripts/create-morro-road.mjs` reproduz as plantas e os metadados; os PNGs são fontes artísticas preservadas.

## Limites de edição e revisão

Essas plantas abrem no Tiled. São camadas pintadas com objetos de lógica, ainda não um conjunto completo de casas e chão editáveis como tiles individuais. O Ateliê atual espera seis camadas de objetos e kit recortado; não importar estes mapas de imagem nele sem ampliar seu contrato. Bancadas salvas do usuário não foram substituídas.

Pendências artísticas: variar mais a silhueta e a distribuição dos caminhos entre as áreas; revisar saturação e densidade de vegetação na escala da câmera; produzir peças separadas para futuras mudanças de arquitetura. As imagens geradas são a direção atual integrada, não uma aprovação artística automática. A árvore do primeiro trecho conserva sua pendência anterior de franja suave de cor.

## Validação

Os cinco TMJs passaram pelo MCP Tiled sem erros ou avisos nas classes verificadas. Testes cobrem todos os destinos, cercas fechadas e abertas, ordem completa, retorno, carregamento de imagens e isolamento por conta. O teste de cliente percorre as cinco transições com snapshots simulados, verifica a barreira no passe de desenho e impede entrada direta em área bloqueada. O teste de sincronização distingue cache local de vitória efetivamente recebida do servidor.

Builds Worker e Pages e validação ESM executados. A suíte completa passou com 254 testes antes da correção final do passe visual da cerca; depois dessa correção o teste dirigido do cliente passou novamente. A auditoria no navegador usa contas locais isoladas, sem conceder recompensas ou alterar dados de produção.

Conferência final: 46 testes de arte/fluxo e sequência passaram após o ajuste de renderização; o teste dirigido foi repetido após acrescentar o caso de derrota. No navegador, Beto (conta local com vitórias anteriores já confirmadas) atravessou as cinco áreas e retornou do parque ao mirante. Cora permaneceu com zero encontros vencidos e passagem bloqueada na praça. Não foi encenada uma nova campanha inteira no navegador, nem concedida vitória por botão de teste.
