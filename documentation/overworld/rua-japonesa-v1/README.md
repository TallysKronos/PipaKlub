# Rua das Rabiolas

Estudo visual nativo de uma rua de inspiração japonesa para Soulmonsters: pequena loja de pipas com fachada de madeira, casa, máquina de bebidas, banco, vasos e iluminação. Arte gerada com fontes preservados em `art/overworld/kits/rua-japonesa-v1/fontes/`; origem, prompts e variantes em `proveniencia.json`. Banco, vaso e poste reutilizam peças aprovadas do kit comum.

## Terreno e montagem

- Projeção do terreno e dos prédios: 64×32, células 2:1. Paredes e telhados são planos nativos com vértices compartilhados; a pintura das fachadas é uma elevação ortográfica aplicada por UV. Os sprites inteiros antigos de casa e loja ficam preservados, mas não são renderizados.
- Rua na cota 0, passeio +10 px, fundo da canaleta −3 px.
- Os dois acessos descem de +10 para 0. A guia e a canaleta são interrompidas na faixa; as laterais da rampa têm faces triangulares, sem uma parede atravessando a boca.
- Asfalto contínuo com textura 512×512 e bordas opostas iguais; juntas regulares nos blocos de concreto construído.
- Bueiro circular com aro, tampa e emblema de pipa. Grelhas abertas sobre o fundo rebaixado: quadro e barras deixam a canaleta aparecer entre elas.
- Casa e loja têm uma planta retangular explícita inteiramente contida no passeio +10. Os três cantos visíveis da fundação usam a mesma fórmula isométrica e altura da calçada; não há ajuste por um único pixel inferior do sprite. Paredes têm 108 px e a cumeeira sobe mais 34 px. O mobiliário continua com pivôs e escalas registrados em `library.json`.
- Sinalização tátil é um detalhe visual, sem alegação de conformidade com norma de acessibilidade ou projeto viário japonês.

## Abrir

Cena: `godot/scenes/overworld/street/rua-das-rabiolas.tscn`.

No projeto Godot, execute:

```text
godot --path godot --script res://tools/japanese_street_preview.gd -- --live
```

Sem `--live`, a prévia salva cinco capturas nativas 1280×720 e encerra, incluindo casa e loja ampliadas em 2× no renderizador. Importar o projeto antes da primeira execução. O pacote ZIP contém os arquivos da cena e os assets usados, com caminhos relativos à raiz do repositório.

## Revisão e limites

Após a revisão do usuário sobre a casa torta/flutuante, as duas construções foram refeitas em planos nativos. Revisadas capturas com fachadas, sem fachadas e em cores simples, além de acessos, drenagem e capturas nativas ampliadas das duas fundações. A captura sem fachadas esconde somente esse grupo; a vista de geometria também remove a sinalização.

A revisão de estilo seguinte troca a pintura detalhada por `fontes/fachadas-v3-manga.png`: cores mais chapadas, sombras em recortes, janelas com menos barras, madeira sem granulação e vitrine com duas pipas maiores. `fontes/telhado-v3-manga.png` substitui a grade vetorial do telhado por três faixas largas de telhas desenhadas. O runtime normaliza as fachadas em 32 cores e o telhado em 8, sem dithering. Os prompts e fontes anteriores estão preservados. `antes-estilo-manga.png` registra a versão estrutural anterior; a geometria de apoio não mudou nesta revisão.

Esta é uma biblioteca visual isolada. Não modifica campanha, colisões, NPCs, travessia, interação, salvamento ou mapas publicados. Não foram executadas suítes de testes de gameplay.

## Varanda, toldo e janelas — revisão 4

A casa recebe uma varanda com avanço de 0,65 célula, piso a 62 px acima da fundação, espessura de 4 px, apoios diagonais presos à fachada, guarda-corpos laterais e frontal com 21 px. Piso, postes e travessas são peças separadas. O vidro fica atrás do guarda-corpo. A pintura duplicada do guarda-corpo foi removida em `fontes/fachadas-v4-volumes.png`, com fonte e prompt preservados.

A loja recebe toldo em faixas creme/terracota, avanço de 0,8 célula, tecido curvado em três segmentos, braços triangulares fixados na parede e barra frontal fixa. Só a aba inferior responde ao vento; o plano da cobertura e os apoios permanecem rígidos. A cortina anteriormente pintada foi removida para evitar duplicação.

Três janelas têm vidro atrás de molduras projetadas, peitoris que avançam 0,24 célula e duas venezianas abertas em planos separados. A fundação e a planta dos prédios permanecem iguais à revisão anterior. A construção mantém planos de cor, tinta seletiva e sombras recortadas, sem iluminação 3D.

`VARANDA-TOLDO-JANELAS.png` reúne os detalhes nativos ampliados. `TOLDO-ANIMADO.webp` mostra um ciclo de 32 capturas, 4,48 s, produzido da mesma cena. As capturas gerais e ampliadas permitem revisar apoios, encontros e oclusão sem personagem cobrindo-os. A cena continua sendo uma biblioteca visual, sem acesso caminhável à varanda ou interação de abrir janelas.
