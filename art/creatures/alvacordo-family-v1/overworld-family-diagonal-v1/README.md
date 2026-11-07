# Família Alvacordo — overworld diagonal

Novas poses: Farpim (bebê), Papisco (criança), Velcão (jovem quadrúpede). Referência adulta: Alvacordo overworld diagonal, aprovado pelo usuário e mantido sem alterações.

Cada personagem tem frente SW e costas NW em canvas 80×80. A prancha coloca frente na primeira linha, costas na segunda, e os quatro estágios em ordem evolutiva. Todas as ampliações são inteiras e sem suavização.

## Escala medida na frente

| Personagem | Ocupação total do sprite |
|---|---|
| Farpim | 30×32 px |
| Papisco | 29×41 px |
| Velcão | 58×55 px |
| Alvacordo | 59×60 px |

A altura inclui orelhas, rabiola e cauda: não é a altura anatômica no mundo. A largura maior do Velcão decorre de quatro patas, velas e cauda. As vistas de cada criatura foram reduzidas com uma escala comum para o par. Não houve normalização individual para forçar dois bounding boxes iguais.

## Origem e edição

image_gen integrada para cada personagem, usando seu concept aprovado como identidade e o Alvacordo como referência de acabamento/câmera. Aseprite MCP headless para recorte, redução, paleta comum de 24 cores, alpha binário, posicionamento e fontes editáveis. Bases e prompts preservados em cada diretório `overworld-diagonal-v1`. Trata-se de adaptação de bases geradas, não de desenho integral manual nem recuperação comprovada de grade.

## Revisão independente

- Farpim: 8/10. Pipa com rosto e orelhas, frente/costas distintas, fio e bandeirola ligados.
- Papisco: 8/10. Criança bípede, peito-pipa, orelha dobrada e encaixes plausíveis.
- Velcão: 8,5/10. Quadrúpede e duas velas legíveis, sobreposições e raiz da cauda coerentes.

Sem achados BLOCKING. Revisão dos PNGs nativos, incluindo fundo claro. Progressão de escala considerada legível. Nenhuma alteração de pixels dos personagens após essa revisão.

## Verificações e limites

`validacao.json`: dimensões, bounding boxes, ocupação, contagem de cores, alpha 0/255 e margens. Conferida visualmente a prancha ampliada. Não foi executado playtest nem validada animação; os dois frames de cada fonte são vistas estáticas. O pivô (40,65) é proposto e precisará de teste no cenário, especialmente para Farpim flutuante e a cauda de Velcão.

`index.html` permite comparar escala e fundos. `familia-native.png` tem 320×160; `familia-4x.png` tem 1280×640; `familia-diagonal.aseprite` preserva a montagem. O HTML foi criado para inspeção local, sem teste automatizado de navegador nesta entrega.

Não houve alteração de runtime, substituição dos sprites anteriores, commit ou push. Próxima etapa: avaliação visual do conjunto, teste de escala junto de Kael e ciclos idle/walk.
