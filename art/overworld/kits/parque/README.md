# Parque — PIP-85

Kit modular para Jardim das Pipas e Clareira do Papel, integrado à prévia independente Godot. Conceitos de acabamento em `art/overworld/conceitos/parque/`; o jogo continua lendo as células e posições da planta, sem usar essas imagens como fundo navegável.

## Correção atual — volume e restauração do piso

A composição v2 abaixo foi rejeitada: a textura de copas no plano do chão achatava a mata, e a nova grama piorou o piso. Ambos foram retirados do consumo. O gerador voltou às mesmas pinturas da primeira família: canteiro do Bairro para grama, terra e concreto originais; mato/bosque recebem somente os tons anteriores da grama. O shader não mistura cores extras nem aplica vinheta.

A folhagem de borda agora é feita exclusivamente por sprites verticais de arbustos, com âncora, sombra de contato e profundidade próprias. Não há copa de árvore desenhada em polígono de piso. Mantêm-se 13 árvores na planta do Jardim e 14 na Clareira, mais duas árvores de fundo explicitamente posicionadas por área. Os preenchimentos automáticos continuam desligados. As fontes rejeitadas ficam preservadas em `fontes/`, sem referência nos materiais consumidos. Evidência: `documentation/overworld/parque/correcao-volume/`.

## Histórico: composição v2 rejeitada — 27/10

A população de árvores foi refeita após a rejeição do excesso visual: 13 árvores no Jardim e 14 na Clareira, sem árvores automáticas adicionais. A árvore florida central do Jardim e uma árvore da Clareira foram deslocadas para os jardins laterais, liberando a visão dos encontros. Bancos, placas, eventos, acessos e células de encontro mantêm suas posições.

Nova grama de baixo contraste, arbustos baixos de bordadura e material próprio de bosque enquadram as clareiras. As árvores reaproveitadas têm recorte justo e escala de 132 px, ou 144 px nas floridas, sem alterar as proporções. O fundo usa massas de folhagem maiores, perde contraste à distância e não registra colisões extras. Sombras projetadas integram as árvores ao terreno. Fontes e prompts adicionais: `fontes/composicao-v2-geracao.json`. Decisões da planta: `composicao.json`; reprodução: `node tools/overworld/compose_parque.mjs`, seguida da geração do kit e compilação dos dois mapas.

## Conteúdo

- Cinco materiais: grama, terra, mato, piso e bosque. Vinte amostras 64×32 e 128 transições, 16 para cada um dos oito pares solicitados.
- Atlas contínuo 2560×512: cinco pinturas periódicas 512×512. Terra e pedra reaproveitam a família Bairro; grama e bosque receberam fontes próprias na v2, e o mato recebe uma variação de tom da grama. Juntas discretas pertencem à pintura, sem grade sobreposta.
- Coreto com pegada 4×4, âncora `[140,236]` em canvas 280×304. Telhado e pilares visíveis são camadas separadas, com profundidade e transparência individuais. Parte dos apoios traseiros fica ocultada pela cobertura nesta orientação.
- Dois recortes de capim 52×48, base `[26,45]`; duas touceiras por célula de mato, fases de vento por posição. A raiz não se move. Preferência de movimento reduzido desliga o balanço.
- Árvores a/b/florida derivam do kit comum, com normalização específica do Parque. Bancos, postes, placa-mapa, vasos, lixeiras e flores continuam usando o kit comum. Pipas presas aparecem em três árvores da Clareira. Arbustos de bordadura ocupam apenas células de bosque já bloqueadas.
- `parque.isostudio.json` abre o coreto na régua do Iso Studio. `PRANCHA-ESCALA.png` compara com Kael.

## Colisão e terreno

O coreto deixou de bloquear a pegada inteira, e cinco objetos `coreto-post-*`, com `apenas_colisao=true`, bloqueiam os pilares. Na revisão v2, árvores removidas ou deslocadas também liberam seus antigos bloqueios e os objetos mantidos continuam fornecendo sua colisão normal. O mesmo formato comum de peças alimenta o Mapa Studio, o compilador e o modelo Godot. A importação recompilou somente os dois mapas do Parque; a campanha principal continua sem substituição.

## Fontes e reprodução

`fontes/` contém as pinturas originais, a guia arquitetônica SVG/PNG e `geracao.json` com prompts e referências. `tools/overworld/build_parque.py` prepara repetição, amostras, alpha, tamanho e âncoras sem redesenhar as pinturas. A normalização de alpha remove o halo sem apagar as fontes originais.

```powershell
python tools/overworld/build_parque.py
node -e "import('./tools/import-overworld.mjs').then(m=>m.buildPieceScenes())"
```

Abrir `godot/scenes/overworld_preview.tscn` com `--area=jardim-das-pipas --art-preview` ou `--area=clareira-do-papel --art-preview` como argumentos do usuário. O seletor da prévia permite alternar as duas áreas.

## Evidência e limites

`documentation/overworld/parque/captures/`: seis câmeras 1280×720, uma captura 1280×800 e sequência do capim. Importação e renderização nativa sem erros registrados. São revisão de arte e movimento, não testes de percurso, campanha ou combate. O formato 1280×800 não equivale a testar em um Steam Deck físico. Nenhuma suíte de testes executada; nenhuma publicação feita. Aprovação final do kit continua pendente.
