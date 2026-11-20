# Mapeamento de melhorias — Soulmonsters Studio

Revisão: 06/11/2026. Base: código de `tools/plant-lab`, capturas e problemas encontrados durante a construção do editor. Este documento propõe trabalho futuro; não declara as propostas implementadas nem autoriza integração com a campanha.

## Base existente

Atualização das duas primeiras entregas: controles contextuais da ST-03 implementados; ST-01 implementada para materiais de piso/preenchimento, paredes, encaixe de cachoeiras e volume de altura/rampas. A simulação geométrica roda em segundo plano e mostra razões de invalidez antes do clique. Ver [entrega e validação](PREVIAS-E-CONTROLES-CONTEXTUAIS.md). As demais propostas continuam futuras.

Terceira entrega: **ST-02 implementada**, com atenuação, proteção opcional, rampas compartilhadas entre cotas e preferências separadas do documento. Ver [foco por andar](FOCO-POR-ANDAR.md). Próxima prioridade sugerida: ST-04, projetos e recuperação.

- Pisos, relevo em até 12 cotas, rampas para o norte e revestimentos de paredes independentes.
- Autotiling com 47 encaixes, materiais de chão, vegetação e florestas conectadas.
- Pintura de piso presa à cota inicial da pincelada; origem dos materiais acompanha os contornos arredondados.
- Biblioteca com busca e categorias; painéis separados de Terreno, Paredes e Cachoeiras.
- Cachoeiras em três larguras, quatro quadros, encaixe no desnível e recorte por água/faces visíveis. Quedas voltadas para o sul.
- Camadas com visibilidade/bloqueio, seleção de objetos, copiar/colar, desfazer/refazer e teste com Kael.
- Um documento salvo localmente, importação/exportação JSON e exportação de projeto Godot independente.

Limites observados: mapa de 8×8 a 40×32 células, até 1.500 objetos, colisões de objetos circulares de 12 px, seleção de região restrita a objetos e jogador de teste sem caminhada animada. Há referências antigas no README que precisam acompanhar a evolução do produto.

## Ordem proposta

P0: confiança e clareza durante a edição. P1: produtividade e construção de mapas jogáveis. P2: acabamento, conteúdo e escala. Esforços são relativos, sem estimativa de prazo: pequeno, médio e grande. Prioridade indica ordem sugerida, não urgência de correção de um defeito comprovado.

| ID | Prioridade | Melhoria | Resultado esperado | Esforço | Dependências |
|---|---|---|---|---|---|
| ST-01 | P0 | Prévia exata de pintura e colocação | Mostrar os pixels/área que serão alterados, incluindo curvas e recorte por andar; indicar local inválido antes de clicar | Médio | Geometria e picking existentes |
| ST-02 | P0 | Foco em um andar | Escolher a cota de trabalho, atenuar outras cotas e oferecer trava explícita; manter o comportamento atual de pincelada como padrão | Médio | ST-01 |
| ST-03 | P0 | Ferramentas e propriedades contextuais | Mostrar largura de cachoeira ao editar quedas, ação de altura no relevo e material ao pintar paredes; reduzir controles sem efeito na ferramenta atual | Médio | Nenhuma |
| ST-04 | P0 | Projetos e recuperação | Nomear, salvar e abrir vários mapas, guardar versões recuperáveis e permitir voltar ao estado anterior a importações/amostras | Médio | Modelo de documento |
| ST-05 | P0 | Validador de mapa com localização | Apontar cachoeiras sem água, conexões quebradas, objetos sem apoio e spawn inválido; clicar no aviso centraliza o problema | Médio | Geometria existente |
| ST-06 | P1 | Pincéis redondo, linha, retângulo e laço | Desenhar morros e caminhos com menos aparência de grade e menos cliques, mantendo precisão e isolamento por cota | Médio | ST-01, ST-02 |
| ST-07 | P1 | Selecionar e copiar terreno | Copiar uma região com pisos, alturas, paredes e objetos; prévia de colagem com escolha de manter alturas absolutas ou adaptar ao apoio | Grande | ST-01, ST-04 |
| ST-08 | P1 | Construtor guiado de rio e cachoeira | Traçar nascente e destino; pré-visualizar canal, queda e poço, mostrando quais células serão escavadas; aplicar em um único desfazer | Grande | ST-01, ST-05, ST-07 |
| ST-09 | P1 | Rampas e escadas com orientação | Escolher direção, largura e patamares de origem/destino; recortar corretamente o barranco e testar passagem nos dois sentidos | Grande | ST-01, ST-05 |
| ST-10 | P1 | Carimbos de composição | Salvar e reutilizar uma pequena clareira, lago, ruína ou trecho de bairro com seus materiais e apoios | Médio | ST-07 |
| ST-11 | P1 | Colisão adequada a cada objeto | Configurar círculos, retângulos ou polígonos na base; separar copa visível de tronco bloqueador | Grande | Contrato de assets, ST-05 |
| ST-12 | P1 | Eventos e rotas jogáveis | Colocar spawn, saídas, NPCs, encontros, gatilhos e itens; visualizar ligações e condições sem escrever código | Grande | Contrato da campanha, ST-04, ST-05 |
| ST-13 | P1 | Integração reimportável com Godot | Publicar áreas no contrato do jogo preservando IDs, eventos e mudanças feitas em cenas; mostrar diferenças antes de substituir arquivos | Grande | ST-04, contrato da campanha; ST-12 para eventos |
| ST-14 | P2 | Paletas e coleções por bioma | Favoritos, recentes e conjuntos de Kronasta, ruínas, bosque e brejo; pisos, paredes e plantas compatíveis apresentados juntos | Médio | Metadados de assets |
| ST-15 | P2 | Variação visual controlada | Escolher pesos de variantes e densidade de vegetação com semente estável; oferecer repetição exata e prévia | Médio | ST-01, ST-14 |
| ST-16 | P2 | Água com profundidade e correnteza | Diferenciar margem rasa, água funda e direção de fluxo; variar espuma e cascatas sem mudar a escala dos pixels | Grande | ST-08 |
| ST-17 | P2 | Minimap e marcadores | Navegar entre áreas e selecionar problemas/eventos em mapas maiores sem perder a posição de trabalho | Médio | ST-04 |
| ST-18 | P2 | Teste com personagem animado | Idle e caminhada, diagnóstico de colisão e possibilidade de começar o teste no ponto clicado | Médio | Sprites aprovados, ST-11 |
| ST-19 | P2 | Gerenciador de assets | Importar sprites/atlas, definir grade, pivô, colisão e animações, validando dimensões e duplicatas | Grande | Contrato de assets, ST-04, ST-11 |
| ST-20 | P2 | Mapas maiores e desempenho medido | Ampliar o limite somente após medir; atualizar apenas regiões alteradas, controlar caches e particionar o mapa quando necessário | Grande | Medição, ST-17, ST-13 |

## Critérios de aceite das primeiras entregas

### ST-01 — Prévia exata

- Em um canto interno/externo, a prévia coincide com o resultado aplicado.
- Pincéis grandes não sugerem pintura no andar protegido.
- Parede mostra a lateral afetada; cachoeira mostra boca, queda e impacto na geometria real.
- Verde indica colocação válida; indicação inválida inclui texto com a causa, sem depender apenas de cor.
- Não altera o mapa até o gesto ser confirmado; cancelar não entra no histórico.

### ST-02 — Foco em um andar

- A cota escolhida permanece identificada na interface.
- Andares atenuados continuam visíveis para contexto, mas protegidos enquanto a trava estiver ativa.
- A trava é opcional, tem estado visível e não interfere no modo Jogar/exportação.
- Rampas mostram a ligação entre cotas; não são tratadas como planos independentes sem explicação.

### ST-03 — Propriedades contextuais

- Escolher um material da biblioteca ativa a ferramenta correspondente e mostra seu nome.
- Controles de altura não aparecem como se alterassem a pintura de paredes ou cachoeiras.
- Ao trocar ferramenta, materiais escolhidos são preservados e campos pertinentes continuam sincronizados.
- Busca/filtros não escondem silenciosamente a biblioteca recém-aberta.
- O fluxo comum funciona pelo mouse; atalhos aceleram sem serem obrigatórios.

### ST-04 — Projetos e recuperação

- Dois mapas podem ser salvos e reabertos sem sobrescrever um ao outro.
- Importar JSON e abrir uma amostra permitem recuperar o documento anterior após recarregar a página.
- Salvamento informa claramente sucesso, pendência ou falha; JSON continua disponível como cópia portátil.
- O histórico de versões tem limite explícito e não cresce indefinidamente.
- IDs e metadados sobrevivem a salvar/reabrir e migrações de formato.

### ST-05 — Validador

- Avisos incluem localização e explicação concreta; não tratam toda área isolada intencional como erro.
- Identifica queda sem origem/destino de água, rampa desconectada e spawn sem superfície caminhável.
- Objetos deliberadamente decorativos podem receber exceção registrada.
- Não modifica o mapa automaticamente; reparos mostram prévia e podem ser desfeitos.

## Sequência de trabalho sugerida

1. **Editar com confiança:** ST-03 → ST-01 → ST-02 → ST-04 → ST-05.
2. **Construir com velocidade:** ST-06 → ST-07 → ST-10 → ST-08 → ST-09.
3. **Produzir áreas para a campanha:** alinhar cedo o contrato da ST-13; implementar ST-11, ST-12 e a reimportação conforme esse contrato.
4. **Ampliar variedade e escala:** ST-14 a ST-20, conforme necessidades reais das áreas em produção.

Eu começaria por **ST-03 e ST-01**: nossos problemas recentes apareceram quando a interface não mostrava com clareza o que seria pintado ou qual superfície receberia a ação.

## Verificação transversal

- Inspecionar capturas gerais e ampliadas, sem objetos ocultando juntas, incluindo bordas retas/curvas, cantos internos/externos, bocas de rampas e margens de água.
- Verificar preservação de cotas e materiais, desfazer/refazer e salvar/reabrir, além do caminho feliz.
- Conferir interfaces em 1920×1080, 1440×900, 1280×720 e 844×390; telas compactas podem usar rolagem/painéis recolhíveis, com comandos essenciais acessíveis.
- Comparar visual e comportamento no Studio e no Godot para os sistemas compartilhados.
- Testes de pixels e geometria protegem contratos, mas não substituem revisão artística e teste de uso.
- Não integrar menus ou mapas na campanha nem fazer merge sem a autorização combinada.

## Entrega local — 06/11/2026

Os vinte itens foram implementados no Studio. Consulte [IMPLEMENTACAO-20-MELHORIAS.md](IMPLEMENTACAO-20-MELHORIAS.md) para a matriz de evidências, [MANUAL-DO-STUDIO.md](MANUAL-DO-STUDIO.md) para uso e [INTEGRACAO-GODOT.md](INTEGRACAO-GODOT.md) para reimportação sem sobrescrever mudanças manuais. A campanha não recebeu merge automático.
