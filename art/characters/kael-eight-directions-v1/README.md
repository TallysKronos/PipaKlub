# Kael — biblioteca de teste em oito direções

Rascunho para experimentar movimentos no Pixelgen. Não substitui o personagem na campanha.

**Status artístico: rejeitado pelo usuário por baixa legibilidade.** Preservado como estudo técnico e fonte editável. A revisão do usuário substitui a avaliação interna abaixo; este conjunto não deve ser usado como arte aprovada.

- Célula: **48×64 pixels**, alpha binário, 24 cores efetivamente usadas; paleta compartilhada de 32 cores opacas + transparente.
- Folha: **768×1024**, grade 16×16, 256 quadros.
- Direções: S, SO, O, NO, N, NE, E, SE.
- 64 sequências: 8 movimentos × 8 direções. Pivô fixo **24,62**.
- 5 camadas: partes distantes/rabiolas, pernas/calçados, tronco/fones, braço próximo/mãos, cabeça.

| Movimento | Quadros por direção | Comportamento |
|---|---:|---|
| `idle` | 2 | Respiração, loop |
| `walk` | 4 | Contato e passagem alternados, loop |
| `run` | 6 | Braços dobrados, impulso e suspensão, loop |
| `interact` | 4 | Abaixar, alcançar e retornar |
| `attack` | 6 | Preparar, comandar/lançar e recuperar |
| `hurt` | 2 | Recuo e proteção |
| `victory` | 4 | Comemorar |
| `fall` | 4 | Ceder, agachar e cair |

Os nomes seguem `movimento-DIREÇÃO`, por exemplo `run-NE`. O ataque é um gesto do domador; não contém os efeitos do golpe de assinatura de um Soulmon. Ações sem loop param no último quadro. Os GIFs de revisão repetem todas as ações deliberadamente para facilitar a comparação.

## Abrir

No Pixelgen, botão **Kael · 8 direções e movimentos**. Escolha Direção e Movimento acima da timeline; “Ver só este ciclo” evita navegar pelos 256 quadros de uma vez. O botão carrega o exemplo, sem descartar a possibilidade de desfazer o projeto anterior.

- `kael-library.aseprite`: fonte editável, camadas, tempos e tags nativas.
- `kael-library.pixelgen.json`: documento completo editável.
- `kael-S.pixelgen.json` etc.: oito projetos menores, 32 quadros cada.
- `kael-library-sheet.png` e `kael-library-atlas.json`: folha nativa + coordenadas, tempos e pivôs.
- `kael-library.tres`: SpriteFrames; espera a folha em `res://assets/characters/kael/kael-library-sheet.png`. Use filtro nearest. O controlador deve respeitar loop/ações únicas e ordenar o personagem pelos pés.
- `preview-*.gif`: oito direções sincronizadas para cada movimento, ampliadas 3×.
- `review-*.png`: poses sequenciais para inspeção, sem interpolação.

## Origem e processo

Identidade e cabeças cardinais reaproveitadas do asset nativo aprovado `../rpg-overworld-study-v1/pixelgen-native-v1/kael-professor.pixelgen.json`. Faces diagonais, troncos, membros e poses de queda foram construídos em coordenadas inteiras por um rig de poses-chave no gerador local. Não há rotação arbitrária, redimensionamento por frame, interpolação de imagem ou geração de cores por quadro. Aseprite 1.3.18.6 abriu, validou e reexportou a fonte.

Reproduzir: `node tools/pixelgen/examples/build-kael-library.mjs`, depois os auxiliares `export-preview.py` e `review-kael-library.py` no mesmo diretório. Pillow é necessário apenas para os arquivos de revisão.

## Revisão e limites

Auditagem técnica: 256 quadros presentes, nenhuma borda tocada, alpha 0/255. Reexportação pelo Aseprite: RGBA, durações, 64 tags e 5 camadas conferidos exatamente. Teste funcional de DOM: troca de direção/movimento, reprodução e filtro de timeline; canvas simulado, sem validar layout visual no navegador.

Revisão visual independente das pranchas: **7/10, liberado como rascunho para testar** após corrigir cabeça sem ligação, passos laterais, oposição dos braços e volume da queda. Limites conhecidos: corrida ainda pode ganhar balanço e suspensão; queda tem passagem brusca e mudança de volume; direções próximas compartilham parte da pose final. Não são oito desenhos finais inteiramente distintos de queda. A avaliação das pranchas não comprova fluidez em tempo real.

Não integrado ao cenário Godot, não publicado e não aprovado como arte final. O conjunto cobre oito ações de base; ações narrativas ou equipamentos específicos exigem outros ciclos.
