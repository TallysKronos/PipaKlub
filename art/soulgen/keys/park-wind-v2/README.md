# Parque dos Ventos — arte 2D, revisão 02

Revisão orientada pelo rascunho do usuário de 22/10/2026. A composição incorpora cerca, mata externa, entrada identificável, placa, canteiros, iluminação e mobiliário. O acabamento segue a preferência explícita pelas primeiras referências: desenho 2D limpo, contorno definido, poucas sombras por material e massas amplas de folhas. A densidade do rascunho orienta a organização espacial; sua textura pictórica não é o alvo.

## Identidade

- Coreto de telha coral, estrutura verde-petróleo e base creme.
- Madeira em tom mel, flores coral/creme, grama clara, mata externa mais escura.
- Losango de pipa repetido de forma pontual nos remates da placa, luminária e mastro; uma árvore tem uma pipa.
- Vegetação agrupada junto às bordas. A circulação permanece clara, com terra dourada e piso claro no largo.
- Nada de texturas densas de folhas, ruído de pedra ou bolhas aleatórias no gramado. O detalhe vem de encaixes, silhuetas e hierarquia.

## Arquivos e movimento

16 módulos PNG com alpha real; dimensões e recortes em `slices.json`. Foram recortados individualmente, sem assumir que a grade gerada era regular. Componentes desconectados de sprites vizinhos são descartados por alpha, mantendo a cor e a antialiasagem do componente principal. As fontes originais permanecem intactas.

`tree`, `treeLandmark`, `windsock`, `bunting` e `kite`: projetos Soulgen v1, com `idle` de seis segundos e fechamento de ciclo. Troncos e mastros têm bases fixas; a pipa oscila suavemente e sua linha acompanha o mesmo pivô transformado. Os arquivos `.soulgen.json` incorporam suas imagens para importação no Studio. A árvore com pipa adiciona um filho à copa; os outros objetos não recebem movimentos de criaturas. Avisos sobre a ausência de `flight/skill/hurt/victory` são recomendações do perfil padrão do editor, não erros destes props.

Coreto, bancos, placa, canteiros, flores, arbustos, luminárias e lixeiras são estáticos. Os PNGs `fenceA/B` ficam como referência da família; a cerca contínua da prévia é desenhada em Canvas a partir dos pontos do mapa, para compartilhar os postes nas juntas e manter a inclinação exata. A placa recebe o minimapa real do parque desenhado em Canvas sobre o painel.

## Reconstrução e prévia

```sh
python scripts/prepare-park-flat.py
node scripts/build-park-wind-rigs.mjs park-wind-v2
node scripts/preview-park-isometric.mjs
node --test world-isometric.test.mjs
```

Python requer Pillow. Prévia: `http://127.0.0.1:5241/`. Novas bases de colisão e cercas estão em `src/park-isometric-layout.js`; o mapa de produção não é sobrescrito. O servidor lê as fontes do parque e constrói uma cópia para este piloto. Kael mantém suas quatro vistas atuais. Integração com a campanha e medição de desempenho continuam fora desta entrega.

## Proveniência

`source-atlas.png` foi criado pelo `image_gen` integrado a partir de um brief original: atlas de 16 peças, câmera elevada 2:1, contornos verde-petróleo, dois tons por material, grandes massas de folhas, madeira mel, creme e coral, sem cenário ou letras e com fundo transparente. O rascunho e as referências enviados pelo usuário orientaram a composição e a direção; seus pixels não foram extraídos para o jogo. A geração original e seus metadados são preservados; os recortes são derivados locais.
