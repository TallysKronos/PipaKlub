# Gruta dos Elos — proposta de identidade v2

Revisão orientada pelo pedido do usuário: cenário cavernoso com identidade própria de Soulmonsters e desenho 2D flat. A primeira exploração, em `cavernas-v1`, foi preservada como histórico; não é o alvo desta entrega.

## Ideia central

A geologia lembra os materiais das pipas vivas. As camadas de pedra sugerem dobras de papel; fraturas e veios lembram linhas tensionadas; junções minerais formam pequenos nós. Silhuetas grandes evocam velas, asas e o ritmo das rabiolas. São elementos do ambiente, sem rosto, olhos ou indicação de nova espécie colecionável.

Os nomes abaixo identificam assets e uma direção visual proposta. Não definem bioma canônico, narrativa, raridade, poder, recurso de mineração ou mecânica de gameplay.

## Linguagem gráfica

- Contorno azul-marinho nítido, com poucos traços internos. Grandes áreas de cor fosca; dois ou três planos dominantes por material.
- Ardósia e azul-petróleo nas massas; creme nos planos iluminados; terracota e ocre em pequenos acentos. Turquesa e âmbar ficam nos pontos de interesse.
- Pedras não recebem textura fotográfica, bevel brilhante, dezenas de facetas nem render volumétrico. Piso tem menos contraste e detalhe do que objeto.
- O motivo de pipa transforma a forma do material. Evitar colar um losango em toda pedra, amarrar pipas decorativas em tudo ou usar uma malha regular de símbolos.
- Assimetria de silhueta: uma agulha se curva, uma placa mineral abre uma asa, uma coluna alterna suas dobras. Variar forma e ritmo, não somente cor.

## Família de objetos

- **Agulha do vento:** estalagmite em forma de vela inclinada; a dobra diagonal e uma pequena junção ocre dão identidade.
- **Nós de pedra:** mineral baixo com duas faixas fundidas que formam um nó e deixam um vazio legível.
- **Coluna de rabiolas:** sustentação robusta com três saliências alternadas; o ritmo evoca os laços da rabiola.
- **Pedras dobradas:** massa baixa de poucas lascas grandes; serve para compor sem roubar atenção.
- **Ecos de Azulão:** placas minerais turquesa que sugerem asas e um nó de união, sem um animal escondido no sprite.
- **Brasa de Carcará:** placas em leque com ritmo de penas/velas, em ocre, terracota e creme.
- **Flores de linha:** flora cavernosa com hastes curvas e chapéus de dobra simples.
- **Portal do elo:** boca natural de gruta com poucas placas amplas e uma junção mineral que organiza o arco.

## Composição e integração

Isometria 2:1, célula 64×32, um nível de 64 px. Pivô no apoio do objeto; volume não define colisão. Os objetos enquadram o caminho, com espaço de passagem e contato claro com o chão. Água, espuma e queda ficam em camadas separadas; não encobrem erro de parede.

Pisos têm atlas estático e material de projeção contínua no mundo. O atlas determina as bordas; a pintura atravessa as células sem reiniciar a cada tile. Os fundos de revisão não aprovam colisões, navegação ou uso em campanha.

Referências de identidade lidas: `WORLD-ART-DIRECTION.md`, `art/overworld/estilo/PRANCHA-ESTILO.png` e a direção visual da skill Pipamonsters. Não se copiou anatomia de um mon para registrar uma nova criatura.
