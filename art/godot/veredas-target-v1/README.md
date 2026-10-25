# Cena-alvo das Veredas — direção unificada v1

Estado: conceito para avaliação artística. Não substitui o mapa ou os assets do jogo. Geração com ImageGen integrado, usando somente referências do nosso projeto: captura do pátio Godot para funções espaciais, Nina para identidade e Kael para identidade. Wakfu é referência de composição isométrica e clareza de formas; a ambientação, personagens e motivos continuam os de Soulmonsters.

## Alvo visual

Cena compacta, próxima dos personagens, com terra ocre, verdes moderados, água azul-petróleo e sombras frias. Contornos coloridos, grandes massas de cor e poucos detalhes. Trilha legível, árvores agrupadas e barranco sustentado. Ponte, rampas, margens e patamares precisam parecer parte do mesmo terreno. Objetos cotidianos e pequenos motivos de pipa sustentam a identidade brasileira.

A captura Godot fornecida é referência de conteúdo e escala, não de acabamento. A proposta deve abandonar a repetição ruidosa do chão e a disparidade entre sprites, árvores e materiais. Uma ilustração não garante alinhamento técnico em 2:1: a planta de navegação e a grade serão reconstruídas/validadas na etapa de produção.

## Desmembramento depois da avaliação

| Família | Peças a produzir | Contrato |
| --- | --- | --- |
| Piso | Grama baixa, terra e variantes discretas | Mesmo tamanho de célula; repetição examinada em 3×3 |
| Transições | Bordas e cantos de terra/grama | Conexão por vizinhança sem faixas internas |
| Relevo | Topo, faces, base, cantos internos/externos | Altura compatível com piso e navegação |
| Subida | Superfície, cunhas laterais, chegadas | Extremidades coincidentes com os dois patamares |
| Água | Superfície calma, margens, curvas | Camada separada; animação discreta; sem encontro de texturas abrupto |
| Ponte | Deck, cabeceiras, bordas e sombra | Pé nas margens; passagem livre e suporte legível |
| Árvores | Tronco/copa juntos ou peças registradas, variações | Pivô na raiz, colisão no tronco e profundidade pelos pés |
| Vegetação baixa | Grupos de arbustos, folhas e flores | Detalhe concentrado; não esconder defeitos de encaixe |
| Objetos | Baú aberto/fechado, trechos de canos | Escala consistente; estados e pegadas separados |
| Personagens | Kael, Rabbito, Nina em contexto | Mesmo acabamento; identidades preservadas; animações próprias |

## Sequência de produção

1. Avaliar a cena inteira em tamanho semelhante ao jogo: proporções, paleta, contorno, luz e quantidade de textura.
2. Registrar a decisão visual e ajustes necessários antes de produzir dezenas de peças.
3. Gerar/autorizar cada família usando a cena-alvo como referência e especificações de grade, pivô, alpha e estados.
4. Não recortar indiscriminadamente o conceito: remover oclusões, iluminação pintada de objetos vizinhos e partes faltantes; redesenhar módulos para repetição real.
5. Reconstruir o mesmo enquadramento em TileMapLayer e cenas de objetos, comparar com o conceito e testar em movimento.
6. Expandir as Veredas apenas depois da revisão do trecho de referência.

## Critérios de avaliação desta imagem

- Kael e Nina parecem pertencer à mesma família de sprites?
- Chão, árvores, água e rocha têm uma densidade de detalhes semelhante?
- Personagens são legíveis sem depender de HUD ou contorno artificial?
- Ponte e rampa têm entradas livres, apoio e continuidade visual?
- A imagem parece um lugar contínuo, sem plataformas flutuantes?
- O cenário mantém nossa identidade sem copiar arquitetura ou personagens da referência externa?

Esta etapa não afirma existir tileset final, colisão validada, animação ou integração jogável da nova arte. Os arquivos do conceito ficam em art/godot/veredas-target-v1, fora dos assets carregados pelo jogo.
