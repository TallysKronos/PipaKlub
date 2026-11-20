# Gambalhote — família de overworld diagonal
Novos assets: bebê, jovem e adulto. A criança é a versão base anterior, preservada; na prancha recebeu somente margem transparente em torno de seu canvas, sem reamostragem.

## Arquivos
- `familia-native.png`: prancha 384×192 em fundo cinza.
- `familia-4x.png`: ampliação 1536×768 sem suavização.
- `familia-diagonal.aseprite`: montagem editável, fundo em camada separada.
- `index.html`: compara as oito poses em zoom inteiro e diferentes fundos e oferece as fontes individuais.
- `validacao.json`: dimensões, ocupação, cores e alpha dos novos PNGs.

## Formato e escala
As três novas fontes usam canvas 96×96, pivô de chão proposto (48,81). A altura extra acomoda o sistema suspenso do cavaleiro. O corpo da criança continua no canvas original 80×80, com deslocamento (8,16) somente na prancha. O aumento de canvas não altera a densidade de pixel.

A ocupação frontal é bebê26×32, jovem63×64 e adulto51×77. A criança anterior ocupa52×56 incluindo a cauda/cruzeta; sua altura corporal é menor que a do jovem e do adulto. Acessórios elevados contribuem para a altura total, que não equivale à altura do corpo no mundo.

As frentes de bebê/adulto apontam para SE, a do jovem e criança para SW; as poses foram preservadas sem espelhar silenciosamente a armadura assimétrica. Os nomes das novas poses são neutros (`frente-3q`, `costas-3q`). Direções e retouches de assimetria/luz serão fechados na etapa de animação.

## Origem e edição
Concepts aprovados definem identidade: bebê/jovem v1, adulto v2 com acabamento corrigido. image_gen integrada gerou duas vistas por personagem; uma passagem adicional foi pedida para o alpha adulto. Os originais e prompts estão nas pastas individuais. Aseprite MCP headless normalizou recortes, mesma escala por par, paleta familiar de24cores, alpha binário e posicionamento. No adulto, cores residuais presentes em pixels transparentes da geração não são exportadas como conteúdo opaco.

São adaptações de bases geradas, não desenhos integralmente manuais nem recuperação comprovada de grade original.

## Revisão independente
- Bebê: 8/10, sem achados BLOCKING. Pipa-rosto e rabiola reconhecíveis e conectadas.
- Jovem: 8/10, sem achados BLOCKING. Quatro apoios, vela, cauda/cruzeta e fios coerentes.
- Adulto: 7,5/10, sem achados BLOCKING. Pipa suspensa e cavaleiro, quatro fios e conexões legíveis. Boca humana pouco definida em resolução nativa e câmera elevada mais discreta que no jovem; limitações registradas.

Nenhum pixel dos personagens foi alterado após a revisão.

## Verificado e pendente
Conferidos visualmente PNGs e prancha, incluindo fundo claro. Verificados canvas, alpha0/255, contagens de cores e margens. O comparador HTML não recebeu teste automatizado de navegador. Não houve animação, integração, playtest, mudança de código, commit ou push. Os novos pivôs ainda precisam de teste junto de Kael no cenário.

