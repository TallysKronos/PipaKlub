# Veredas — tiles ilustrados v1

Estado: integrado localmente, aguardando avaliação artística do jogador. Não publicado.

## Fonte e direção
Gerado com a ferramenta integrada ImageGen em 25/10/2026. Referência de estilo: assets/world/park-isometric-v1/canopy.png. Fonte preservada em C:/Users/User1/.codex/generated_images/01a16e5b-42a6-7c81-aa2c-b8e82b34afea/exec-fc21a683-9a7d-4548-a435-fabced1ef96d.png. Nenhuma fonte de terceiros adicionada.

Brief/prompt de geração: atlas de materiais de RPG 2D, quatro quadrantes iguais sem margens, bordas ou textos. Água de riacho azul-petróleo vista de cima, ondulações suaves e áreas de profundidade; rocha natural ocre vista de frente, pedras irregulares e musgo nas fendas; grama baixa verde-oliva vista de cima; terra compactada dourada vista de cima, com pequenas pedras. Planos de cor e contornos ilustrados compatíveis com a copa existente, sem render 3D ou fotorrealismo. Pedido inicial 1024×1024; saída real 1254×1254, registrada no manifesto.

## Contrato do material
Arquivo veredas-terrain-v1.png, RGB opaco, 1254×1254. Quatro células 627×627: água (0,0), rocha (627,0), grama (0,627), terra (627,627). Sem animação embutida. Recorte por quadrantes e repetição espelhada feitos no Canvas, sem alterar o PNG fonte. Repetição de duas células por eixo garante bordas coincidentes; padrões de chão usam fase ancorada no mundo, evitando reinício em cada retângulo.

Consumidor: src/veredas-region-renderer.js, via images.terrain no manifesto do parque. Texturas mapeadas na projeção do piso, nas faces dos barrancos e no plano contínuo das rampas; cache estático do terreno. Os nomes de camada stairs permanecem como identificador de compatibilidade da navegação, mas o visual e os nomes das passagens são rampas. Colisões, alturas e encontros não foram alterados.

Vegetação adicional reutiliza copa e flores existentes. A floresta escura de fundo distingue áreas sem passagem; mato de encontros mantém seu render e funcionamento próprios.

## Verificação
Dimensões e modo de cor conferidos com Pillow, sem edição. Builds local e Pages concluídos. 22 testes de navegação, projeção, recursos e estrutura passaram. Auditoria de mundo aprovada. Conferência visual no navegador das pontes, do mirante e da encosta; screenshots em ../outputs/veredas-tiles (pasta da tarefa, fora do repositório). Não é uma aprovação artística externa nem medição de desempenho em outros aparelhos.

## Revisão dos encaixes — 25/10/2026

O renderer passou a derivar um plano de conexões da geometria existente. Os caminhos de mesma altura são unidos por contorno, com cantos arredondados e textura ancorada no mundo. Não se desenha mais cada retângulo de terra como uma peça independente.

As duas pontes usam decks limitados à largura do canal com 24 unidades de apoio em cada margem. Os trechos restantes da antiga pegada são caminhos de aproximação. Decks, cabeceiras, espessura e sombra são desenhados depois da terra, impedindo sobreposição. A orientação das tábuas acompanha a travessia.

As faces dos barrancos são segmentadas nos intervalos das rampas. Cada rampa tem cunhas laterais e ligações de terra nos dois patamares. O teste de encaixes verifica aberturas sem paredes, ligações superior/inferior e ausência de terra dentro dos decks.

As copas de fundo foram reduzidas e árvores decorativas muito próximas das bases existentes foram removidas. Esta revisão reutiliza o atlas ilustrado v1; os recortes, cantos e apoios são compostos pela geometria nativa de Canvas. Não foi gerado um novo atlas raster de bordas nesta revisão. Colisão e progressão permanecem baseadas no mapa original.
