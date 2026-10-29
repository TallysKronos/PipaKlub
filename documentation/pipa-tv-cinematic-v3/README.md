# Abertura V3 · Kael diante da TV

Kael redesenhado a partir do concept autoral do usuário e do Locutor V4 aprovado. Prancha e retrato em `art/kael-manga-v4/`; o recorte de diálogo tem transparência conferida sobre fundo creme e uma cópia normalizada para 800×1200 no Godot. Cabelo, olhos, jaqueta azul, listras claras e fones turquesa no pescoço vêm da referência do usuário. O sprite de exploração continua sendo o existente.

## Novo plano

O filme V2 de locutor, pipeiros e batalha é preservado. Um quarto clipe MiniMax H3 local recua da luta para revelar a imagem na TV, mostra Kael reagindo e abre para o quarto. A cama permanece à esquerda, TV no fundo, guarda-roupa à direita dela, mesa à direita e escada no canto frontal esquerdo, conforme a sala nativa.

Workflow, imagens e prompts em `art/pipa-tv-cinematic-v3/`. Nenhum nó pago nem modelo novo baixado. O modelo interpreta câmera e atuação; a abertura do enquadramento não é uma reprodução pixel a pixel da cena jogável.

## Continuação no jogo

`opening_tv.gd` apresenta a V3 uma vez, em quadro cinematográfico que cabe no viewport, com botão **Pular abertura**. Fim ou pulo emite um sinal ao front-end. `opening.finish_broadcast` valida que o save ainda está numa das duas falas iniciais da transmissão e grava uma única operação para o passo 2, sem recompensas. Após sucesso, o quarto preservado reaparece pela transição existente e Kael fala; o fluxo normal continua até o jogador poder caminhar à mesa.

Falha de salvamento mantém a cena e oferece **Tentar continuar**, sem avançar só na memória. Pausa e perda de foco pausam o vídeo; a pausa fica acima do filme. Se a V3 não estiver disponível, o vídeo anterior e seu fluxo manual continuam como fallback. Novo retrato de Kael configurado em `content.json`, anterior preservado.

## Exportação e revisão

`tools/extend-pipa-tv-v3.py <quarto.mp4>` monta o V2 com o novo plano, uniformiza fps e áudio, exporta MP4 de revisão e OGV para Godot e registra metadados em `montagem.json`. Geração 864×480/24fps; a versão 1280×720 é redimensionada.

V3 renderizada e montada: 27,26 segundos com áudio. Quadros extraídos mostram o recuo da TV, reação e plano aberto do quarto. O usuário rejeitou a interpretação de Kael nesta animação como cartoon demais e apontou seu retrato como referência anime mais fiel. Esta versão é histórica; a substituição está em `pipa-tv-cinematic-v4/`.

Importação do novo retrato concluída; checagem de sintaxe de `front_end.gd` e `opening_tv.gd` sem erros. Checagem estática de referências sem erros, quatro avisos preexistentes. Sem playthrough, testes de gameplay ou validação em reprodução nativa da passagem automática. Não houve commit ou publicação.
