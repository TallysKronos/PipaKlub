# Kael — folhas compatíveis v2

**Status artístico: rejeitado pelo usuário por aparência ruim e baixa legibilidade.** A verificação técnica abaixo não equivale a aprovação visual. Preservar como estudo e não instalar na campanha. Nova direção em `../kael-ds-style-study-v3/`.

Pacote editável para revisão artística. Não substitui o personagem na campanha. Produzido em pixels indexados pelo Pixelgen, com 16 cores opacas + transparência binária, reaproveitando a identidade da cabeça cardinal do estudo nativo original de Kael (não os corpos da biblioteca de 256 quadros rejeitada). Corpos, poses, diagonais e ações têm um novo desenho por camadas. Não é um recorte de uma prancha de IA.

## Contrato de encaixe

- Célula **48×64**, pivô **24,62**, escala 1×, sem trim nem redimensionamento.
- Todas as folhas PNG medem **384×512**: 8 colunas × 8 linhas.
- Linhas: **S, SO, O, NO, N, NE, E, SE**. Quadros de cada ciclo ficam nas primeiras colunas; células restantes são transparentes.
- A escada vertical existe somente em **N**, na quinta linha. `climbdown-N` toca os mesmos quatro quadros ao contrário. Caminhar em uma rampa usa a direção de caminhada correspondente; não confundir com a escada vertical.
- As folhas podem ser empilhadas na ordem do `manifest.json`, sem ajustar personagens. `kael-completo.png` já contém essa montagem: **384×5120**. Os atlas descrevem os recortes exatos, durações e sequências; não animar as células vazias.

| Folha | Quadros por direção | Total |
|---|---:|---:|
| idle | 2 | 16 |
| walk | 4 | 32 |
| run | 6 | 48 |
| interact | 4 | 32 |
| attack | 6 | 48 |
| hurt | 2 | 16 |
| victory | 4 | 32 |
| defeat | 4 | 32 |
| swim | 4 | 32 |
| climb / climbdown | 4 compartilhados, somente N | 4 |

São **292 desenhos e 74 sequências**. Contando a descida que reaproveita quadros, há 296 entradas de reprodução.

## Arquivos

Cada ação contém `kael-ACAO.png`, `.atlas.json`, `.pixelgen.json` e `.aseprite`. Os projetos editáveis têm layout compacto, oito camadas reais, paleta compartilhada, pose por quadro, ficha de personagem e tags. A paleta, célula e pivô são os mesmos; o atlas corresponde ao PNG de runtime com espaços reservados. Abra o JSON no botão **Abrir arquivo** do Pixelgen ou o Aseprite diretamente.

`kael-completo.tres` é um SpriteFrames verificado no Godot 4.7.2. Copie o PNG completo para `res://assets/characters/kael-compatible-sheets-v2/kael-completo.png` e carregue o recurso em AnimatedSprite2D; use filtro Nearest e offset `(0,-30)` se centered estiver ativo, para o pivô de apoio 24,62 numa célula 48×64. Alternativa: centered=false e offset=(-24,-62). Tempos são preservados; `attack` representa o gesto de comando do domador, sem os efeitos do Soulmon.

`review-*.png` são pranchas para inspeção, não atlas de runtime. `preview-*.gif` mostram o ciclo SE (escada em N). `review-directions.png` permite comparar o mesmo personagem nas oito vistas; `review-grounds.png` mostra a leitura em diferentes pisos.

## Conferências e limites

- As dez ações passaram no `check` do Pixelgen. Avisos geométricos permanecem em `audit.json`: menor contraste à noite, contato do contorno com o limite em algumas poses e variação de apoio esperada em corrida/ações. Eles não são certificados de animação perfeita.
- Aseprite 1.3.18.6 abriu os dez documentos indexados, oito camadas por documento, e renderizou os **292 quadros**. A comparação automática confirmou RGBA dos pixels visíveis e alpha exatos contra os projetos, os PNGs individuais e o PNG montado. Resultado em `native-verification.json`.
- Godot carregou as **74 animações**, 296 entradas de reprodução, texturas 48×64 e tempos positivos num projeto temporário. Nenhuma integração/substituição automática na campanha.
- A revisão artística independente detectou cabeça separada do tronco no ajoelhamento; o acompanhamento da cabeça foi corrigido nos quadros 3–4 de derrota. A comparação preferiu a correção, sem bloqueios restantes, nota 7,3/10 como rascunho editável.
- Refinamentos possíveis: balanço de braços frontal/traseiro, inclinação da corrida e antecipação do gesto de ataque. O nado é recortado na linha da água e depende do cenário para comunicar profundidade. A aprovação artística final é do usuário.

Reprodução: `node tools/pixelgen/examples/build-kael-sheets-v2.mjs`. Verificação nativa: executar Aseprite em batch com `--script-param root=RAIZ_DO_PROJETO --script tools/pixelgen/examples/verify-kael-sheets-v2.lua`, depois `node tools/pixelgen/examples/verify-kael-sheets-v2.mjs`. Os fontes originais são locais do projeto; esta entrega não atribui licença externa nova às imagens legadas.
