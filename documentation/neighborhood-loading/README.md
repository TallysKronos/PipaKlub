# Entrada da rua · cobertura de carregamento

Pedido: mostrar uma cobertura durante a espera da rua, um ícone no extremo inferior e retirar a cobertura pela esquerda quando a cena estiver pronta.

`hud_scene_loading.gd` é uma CanvasLayer acima do filtro CRT, com bloqueio de input, cobertura azul-escura e pequeno ícone de pipa/arco no canto inferior direito (42px/38px de margem). A cobertura entra em 140ms; após um frame desenhado, `_show_neighborhood` constrói a rua. O novo personagem fica pausado até o SubViewport desenhar seu primeiro quadro e a saída terminar. A cobertura desliza para a esquerda em 420ms. Sem porcentagem fictícia ou tempo mínimo artificial de loading. Com movimento reduzido: entrada de80ms, saída por fade de100ms e ícone sem rotação.

O overlay sobrevive ao `_clear` da campanha e impede o wipe de tinta duplicado. Reentradas durante loading são ignoradas; não é criado um segundo bairro. O fechamento da janela durante a troca não salva uma cena parcialmente montada: o checkpoint de destino já foi confirmado pelo fluxo existente. A versão nativa do bairro conserva sua lógica de posição, colisões e save.

Esta alteração cobre a espera, não acelera a geometria ou o bake de profundidade. Esses passos ainda são síncronos e podem interromper temporariamente a rotação do ícone; a cobertura e o ícone são apresentados antes deles. Não confundir isso com carregamento totalmente em background.

## Verificação

- Parse estático de `front_end.gd`: sem erros.
- Capturas nativas1280×720 da cobertura, saída parcial e rua pronta: `01-cobertura.png`, `02-saida-esquerda.png`, `03-rua-pronta.png`.
- Mesmo percurso visual com movimento reduzido em `reduced/`; saída parcial é um fade nesse modo.
- `godot/tools/neighborhood_loading_preview.gd` usa estado fictício em memória e perfil APPDATA isolado; não cria slots nem chama operações de campanha. Os dois renders concluíram sem erros de runtime. Sem suíte de gameplay ou publicação.

O escopo é a entrada na Vila do Primeiro Vento, inclusive retornos ao bairro. As demais telas mantêm as transições anteriores.
