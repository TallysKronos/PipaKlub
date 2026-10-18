# Morro do Sol — planta piloto (PIP-36)

Este é um piloto com kit de cenário aplicado e acabamento em revisão, disponível opcionalmente no jogo. `blockout.tmj` abre no Tiled; suas seis camadas de objetos são a fonte geométrica. O cenário completo continua sendo o padrão.

## Kit aplicado e auditoria local

O piloto agora usa o kit modular em `morro-kit-v1`. `art.json` associa IDs físicos às peças e define apoios, repetições e decorações. `src/world-art.js` compila o plano visual e preserva a proporção dos sprites; as áreas físicas continuam em `blockout.tmj`. A casa da esquina foi ajustada para 448 × 192 px físicos, evitando deformar a fachada. A luminária ganhou base sólida de 24 × 24 px.

Pisos são repetidos e recortados na união das áreas do mapa, com bordas de pedra apenas nas extremidades externas. A escada usa recorte central proporcional dentro do próprio frame, evitando deformação ou leitura de peças vizinhas. O chão completo é guardado em OffscreenCanvas após o carregamento das folhas, evitando redesenhar os ladrilhos a cada quadro. Copas/telhados continuam na fila de profundidade, com transparência ao encobrir Kael.

Auditoria corrigiu a folga entre telhados/fachadas e a falta das novas folhas na lista explícita de arquivos servidos. Todas as folhas passam por carregamento com retry. O piloto é preservado na URL após sair da batalha. Permanecem pendentes os sprites chibi dos rivais (PIP-41), refinamento artístico das bordas e montagem do bairro inteiro. Esta aplicação não encerra a PIP-42 integralmente nem autoriza a expansão da PIP-44.

## Integração inicial (PIP-37)

O piloto agora está integrado de forma opcional: entrar na conta e abrir `/?overworld=pilot`, depois Mapa → Explorar Morro do Sol. A URL normal mantém os cinco encontros do mapa completo. No ambiente de demonstração, autenticar em `/local/cora` primeiro e então abrir a URL com a opção (o redirecionamento de login não conserva os parâmetros).

`src/world-map.js` valida e converte o mapa durante o build; `scripts/art-build.mjs` incorpora os dados ao jogo, sem uma requisição extra e sem caminhos externos. Alterações no Tiled precisam ser salvas e seguidas de novo build. Ambos os builds usam o mesmo contrato. O carregador aceita mapas ortogonais finitos com as seis camadas de retângulos; polígonos, tilesets, camadas de tiles/imagens e templates são rejeitados explicitamente nesta primeira versão. Camadas de grupo com offsets são normalizadas. Estender esse contrato ao kit final conforme necessário.

Os centros acessíveis da grade são convertidos no grafo usado pelo movimento existente, preservando a animação do Kael. O fundo geométrico é deliberadamente provisório. A continuação futura apenas informa o limite do piloto. A escolha de piso em áreas sobrepostas não é suportada: mapas assim são rejeitados, em vez de selecionar um piso acidentalmente. A profundidade visual de primeiro plano segue na PIP-39.

## Colisão e escadas (PIP-38)

`createWorldGeometry` verifica uma área conservadora de 24 × 24 px ao redor dos pés (raio configurado 12). Não usa o retângulo inteiro do sprite. A área precisa estar coberta pela união dos retângulos de chão; as emendas entre trechos contíguos não criam paredes falsas. Sólidos e bordas deixam espaço para os pés. Esta aproximação quadrada é intencionalmente mais restritiva que um círculo em quinas.

Cada ligação do grafo e cada passo de caminhada passam pela mesma verificação. O retângulo varrido pelos pés impede atravessar sólidos finos, e o chão é verificado ao longo do segmento. As rotas são ortogonais; atalhos diagonais que cortam quinas são recusados. O destino válido pode terminar entre centros da grade, mantendo o último segmento seguro. Cliques bloqueados são recusados com aviso e preservam o percurso anterior; destinos sem conexão não teleportam o personagem. Não aproximamos automaticamente um clique em uma casa para seu outro lado.

O ator atualiza `level` durante o percurso. Escadas retangulares verticais só conectam pisos diferentes nas extremidades norte/sul, mediante `connects_to`; a lateral não autoriza mudança de piso. Escadas horizontais ou curvas requerem ampliar o contrato. A posição do parceiro vem do histórico dos passos já percorridos, mantendo o mesmo trajeto. No ponto inicial ele compartilha o apoio do ator até existir histórico para segui-lo; um posicionamento ocioso mais elaborado fica para o acabamento visual.

Testes cobrem união de chão, limites, passagens estreitas, frestas, paredes finas, quinas em L, conexão lateral inválida de escada, destino isolado, proteção durante passos, subida/descida e seguidor. Verificação no navegador confirmou aviso ao clicar na casa e chegada ao patamar da Bia. Nenhum duelo/recompensa foi iniciado para esse teste.

## Profundidade (PIP-39)

Chão é desenhado primeiro. Bases sólidas, partes superiores e atores entram numa fila única ordenada por `level`, `sort_y` e desempate estável. Kael usa o piso atual; parceiro usa o piso do próprio ponto no histórico, que pode ser diferente durante a subida. Rivais usam o piso do encontro. Em empate exato no ponto de apoio, ator fica à frente. O cenário antigo sem Tiled conserva sua ordenação por pés.

`Solids` representa a base física e a fachada provisória; `Foreground` representa copa/telhado/topo de muro sem adicionar colisão por si só. `sort_y` é a coordenada Y dos pés/base no mundo, não a borda da imagem; padrão `y+height`. `level` padrão é 0. Pisos visuais inexistentes e âncoras inválidas fazem o build falhar. As duas partes de um mesmo objeto devem compartilhar piso/âncora. A casa superior recebeu `level=1`.

O mapa inclui copa/tronco e muro/base separados para testar frente e trás, além da cobertura da casa da esquina. As cores e formas são marcadores de autoria, sem texturas finais. Um objeto do piso inferior é desenhado antes dos atores do patamar superior mesmo quando sua âncora Y é maior. Objetos fisicamente compartilhados entre pisos requererão peças separadas por piso.

Testes verificam oclusão diante/atrás, independência do piso do parceiro, precedência entre pisos, desempate e metadados inválidos. A fila não modifica a lista original de atores. As artes finais precisam preservar os pontos de apoio definidos aqui.

Quando uma parte superior do mesmo piso encobre o corpo do jogador, sua opacidade cai para 45%, permitindo localizar Kael sob copas e coberturas. O teste usa a caixa visual aproximada do ator; não é detecção por pixel da arte. Outro piso não dispara essa transparência. Ao passar à frente ou sair da cobertura, a opacidade volta ao normal. A colisão continua na base sólida.

Verificação no navegador: Cora → Mapa → Morro piloto → caminhar até Zeca → abrir Praça de chegada, com parceiro equipado preservado. Sem iniciar batalha nem alterar recompensas. Testes do carregador cobrem identidade dos encontros, conectividade, transições entre pisos, dados inválidos e preservação do mapa completo.

## Escala e direção visual

- Mapa de 1280 × 896 px, unidade de edição de 32 px; a grade é ferramenta de autoria, não acabamento visual.
- Kael: altura visual alvo de 64 px, apoio no centro dos pés, colisor circular proposto de raio 12 px. Validar o recorte real do atlas ao integrar, sem assumir que a célula corresponde à silhueta.
- Viela e escada: 160 px de largura. Passagens futuras: mínimo 64 px; portas: vão de 64 px e altura visual de aproximadamente 96 px.
- Perspectiva superior em três quartos, contorno escuro, sombras simples e luz superior esquerda. Fachadas coloridas, terracota, vegetação e madeira; usar o Kael como referência de escala e linguagem. Evitar texturas fotográficas e perspectiva variável entre peças.
- Separar chão, base física da construção, fachada/telhado e objetos. Personagens nunca devem ser incorporados à pintura.

## Percurso

Entrada no canto inferior esquerdo → praça do Zeca → viela ao norte → escadaria → patamar da Bia. A curva permite descobrir o segundo lugar durante a caminhada. A continuação do bairro está indicada como limite de piloto, sem expor o campeão.

Preservar os identificadores `morro-1` na Praça de chegada e `morro-2` na Escadaria da sombra. As zonas de interação são marcadores de aproximação; não representam tamanho físico do NPC. NPC deve ocupar um ponto de apoio com espaço lateral para passagem. Vencer um encontro e desbloquear outro continuam sendo decisões da campanha, nunca efeitos de caminhar sobre uma zona.

## Contrato proposto para PIP-37

| Camada | Uso |
| --- | --- |
| Walkable | Retângulos acessíveis; `level` identifica o piso. |
| Solids | Bases físicas; fora do chão acessível também é bloqueado por padrão. |
| Foreground | Partes visuais que encobrem atores; `sort_y` e `level` definem apoio/ordenação. |
| Interactions | Zonas de encontros com `stage` e `level`. |
| Spawns | Entrada e piso inicial. |
| Exits | Retorno ao Quintal e limite futuro. |

A escada ocupa uma região exclusiva entre o nível 0 e o nível 1. `connects_to` propõe a ligação; o carregador deverá transformá-la em duas extremidades explícitas, validando o sentido de entrada/saída. Sobreposição visual de pisos não autoriza passagem. Esta semântica ainda precisa ser implementada e testada no jogo.

Colisão deve considerar o raio dos pés e a união de áreas contíguas, evitando frestas artificiais nas bordas dos retângulos. Ordenação considera piso e posição dos pés. Copa/telhado pode sobrepor cabeça; a base sólida permanece inacessível. O parceiro seguidor deve obedecer ao mesmo percurso e conexões.

## Verificação realizada e limites

- MCP leu o mapa, inseriu uma cerca e validou a estrutura sem erros/avisos.
- Verificação preliminar encontrou rota ortogonal conectada entre entrada e patamar, sem cruzar sólidos na amostragem dos centros das células.
- A prévia usa marcadores geométricos, não sprites de Kael/NPCs. Movimento por células serve para discutir a planta; não é o sistema final de caminhada nem prova de colisão contínua, oclusão ou funcionamento da campanha.
- `layout-check.json` registra essa verificação preliminar; não substitui PIP-43.

## Próximas entregas

PIP-37: carregar este contrato; PIP-38: circulação contínua e pisos; PIP-39: profundidade; PIP-40: kit de arte; PIP-41: sprites chibi. PIP-42 integra e PIP-43 audita antes da expansão PIP-44.

Arte necessária para o piloto: piso e bordas de calçada, casa oeste, casa da esquina, casa superior, muros/cantos, cerca, escada, copa/tronco separados e pequenas decorações. Recortes e encaixes devem seguir a planta, com folga para os pés. A aprovação visual das artes finais permanece pendente.
