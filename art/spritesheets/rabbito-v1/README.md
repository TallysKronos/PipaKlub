# Rabbito — spritesheet v1

Arte criada com image_gen a partir do conceito aprovado. Conceito e identidade preservados: coelho de papel creme/lavanda, duas orelhas com varetas, olhos vermelhos, protetor cinza, luvas violetas e rabiola conectada.

Ordem da grade 4 × 4 (índices começam em zero):

| Animação | Quadros | Tempos por quadro (ms) |
| --- | --- | --- |
| Repouso | 00–03 | 220, 150, 220, 220 |
| Voo | 04–07 | 130, 110, 130, 110 |
| Habilidade: soco | 08–11 | 160, 180, 110, 180 |
| Dano | 12–13 | 150, 210 |
| Vitória | 14–15 | 300, 420 |

Abra preview.html para reproduzir os estados. O player usa escala constante por atlas. rabbito.json contém os recortes reais, sem presumir divisibilidade da resolução por quatro. A revisão visual e geométrica confirmou 16 poses distintas, células ocupadas e margem mínima de 39 px no limiar alpha 96. O desenho do personagem mantém as partes conectadas; a geração raster pode exigir ajustes finos de pivô para uma integração futura.

As duas primeiras folhas exigiram correção de margem. Originais preservados na pasta drafts, sem edição de pixels. prompts.txt registra geração e correções. Apenas a folha final rabbito.png deve ser usada com o atlas.

Entrega de assets; ainda sem integração, concessão de item ou publicação no jogo.
