# Revisão da reconstrução da referência — 16/11/2026

Estado: **parcial; não atingiu a fidelidade pedida para uma réplica final**.

## Passagem de ambientação após a crítica

- Escarpas receberam volumes rochosos fechados, de alturas, larguras e profundidades variadas, conservando a parede contínua abaixo. Cada volume adicional tem suas arestas verificadas com BMesh.
- Contrafortes foram acrescentados na junção dos patamares. A topografia geral ainda mantém uma estilização mais regular que o concept.
- Troncos receberam inclinação, bifurcação e espessura maior. Copas têm menos detalhes miúdos e mais contraste na parte inferior.
- A dispersão complementar de arbustos foi reduzida de 174 para 62 pontos solicitados, com grupos adicionais junto a pedras e raízes; pontos sem apoio continuam rejeitados.
- Trilhas usam curvas e bordas de largura variável. A escada oeste recebeu largura maior e fechamento nas laterais. Lajes baixas ocupam a área de passagem.
- O lago passou a ter contorno curvo, pedras submersas em grupos, zonas rasas, variação de profundidade visual e reflexos finos. A cascata ganhou fluxos irregulares e espuma no impacto.
- O mirante recebeu uma escada até o caminho direito. Seus dois apoios finais foram verificados no contorno de solo disponível.
- O fundo usa uma textura atmosférica procedural de baixa frequência, incorporada ao arquivo Blender, em vez de silhuetas com arestas duras.

A versão anterior desta passagem está em `antes-refino-ambientacao.png`. O acabamento atual segue sendo uma interpretação 3D estilizada, com diferenças visíveis em relação à pintura do concept. Não houve integração no Godot.

## Correção das frestas

As escarpas passaram a usar anéis cíclicos compartilhados. Cada canto tem uma posição intermediária única, reutilizada pelas duas faces vizinhas, em vez de receber deformações independentes. A faixa de grama faz parte da parede e não é uma face sobreposta. Os quatro maciços elevados agora incluem tampas superior e inferior na mesma malha, com normais recalculadas.

A validação BMesh retornou zero bordas abertas e zero arestas não manifold em cada um dos quatro maciços. Nas duas paredes de encaixe (perímetro externo e margem baixa), as únicas bordas abertas são os anéis superior e inferior previstos; não há bordas laterais extras. O gerador interrompe a execução se essas condições falharem. Os números estão em `validacao-referencia.json`, seção `cliff_topology`.

O contraste entre painéis foi reduzido para evitar falsas leituras de buracos. A imagem anterior está em `antes-correcao-frestas.png`; a nova renderização está em `referencia-reconstruida.png`. A correção resolve a continuidade das paredes, sem declarar concluído o acabamento artístico de toda a cena.

A cena 3D foi reconstruída em `mormaco-referencia.blend`, com câmera ortográfica travada, geometria editável, lago rebaixado, três cotas de terreno, escada oeste, cachoeira, mirante, estandartes, rochas, árvores, arbustos e vinhas. Mormaço e o personagem do mirante são planos com os sprites existentes. A imagem original está em `referencia-original.png`; o resultado renderizado está em `referencia-reconstruida.png`.

| Categoria | Avaliação | Diferença observada |
|---|---|---|
| Câmera e enquadramento | Próximo | O diorama ocupa a imagem com orientação e marcos semelhantes. |
| Contorno da base | Próximo | A silhueta geral coincide aproximadamente; a borda ainda é regular. |
| Distribuição dos elementos | Próximo | Escada, lago, mirante, cascata e criatura estão nas regiões correspondentes. |
| Topografia | Parcial | As cotas existem, mas os patamares ainda parecem plataformas empilhadas. |
| Escarpas | Divergente | Faltam volumes rochosos grandes, fraturas e transições naturais do concept. |
| Vegetação | Divergente | Copas ainda têm repetição procedural e desenho diferente dos agrupamentos pintados. |
| Água | Divergente | Faltam transparência, profundidade cromática, reflexos e espuma no acabamento da referência. |
| Trilhas | Divergente | O traçado é legível, mas as bordas e o pavimento precisam de composição mais orgânica. |
| Luz e paleta | Parcial | Cores básicas correspondem; falta o sombreamento pintado e a atmosfera suave. |
| Fundo | Divergente | Silhuetas procedurais têm arestas duras; a referência usa profundidade atmosférica suave. |

Não há aprovação presumida nem integração deste modelo no Godot. Esta entrega conserva a referência e a cena separadas do mapa atual. A próxima passagem de arte deve substituir a linguagem de primitivas por rochas e copas autorais antes de considerar exportação para o jogo.

## Reprodução

Execute o Blender 5.1 em modo background com `--factory-startup --python-exit-code 1 --python art/overworld/pantano-mormaco-v2/blender/reconstruir_referencia.py`, na raiz do projeto. O script reutiliza as funções de construção de `construir_lago.py` e carrega os sprites existentes do projeto. A semente é fixa. A renderização é 1672 × 941 em EEVEE.

## Verificações executadas

- A cena foi salva e renderizada com Blender 5.1.1.
- Houve comparação visual com a referência após mudanças na geometria e no acabamento.
- A vegetação possui filtro de apoio no contorno do respectivo patamar para evitar plantas fora do solo.
- O arquivo JSON registra parâmetros da cena e marcos de construção; não é uma medição automática de fidelidade visual.
