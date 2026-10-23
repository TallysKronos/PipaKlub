# Casa de Kael — reconstrução do piso inferior

## Direção e organização

O piso inferior passa a usar a mesma família de arte e a mesma grade do quarto. À esquerda ficam a porta da rua, janela e sofá; mesa baixa e tapete organizam o estar. Ao fundo estão a mesa de refeições e seus dois bancos. A cozinha fica encostada à parede direita e inclui pia, fogão e geladeira. A escada ocupa a lateral direita, com patamar livre na frente.

O centro e a faixa dianteira permitem ligar rua, mãe e escada sem atravessar móveis. Não foram adicionados serviços novos nem alteradas recompensas ou progressão de campanha.

## Um contrato para duas experiências

`src/home-layout.js` fornece projeto do Iso Studio, pegadas, navegação da abertura e mapa Tiled do overworld. Entrada pela escada, ponto da mãe, parceiro e saída usam esse contrato. O renderer medido agora atende aos dois pisos, cada um com sua própria planta e imagens. Colisões e saves permanecem ortogonais e conservam os IDs `kael-home` e `kael-bedroom`.

O jogador, a mãe, o parceiro, os cliques e os destaques usam a projeção da cena. Objetos altos ficam translúcidos quando encobrem o jogador por trás, mantendo a ordem de profundidade; quando o jogador está à frente, o objeto permanece opaco. Uma posição antiga de save que tenha virado obstáculo segue a recuperação existente para uma entrada segura.

## Arte e reprodução

Veja `art/kael-home-iso-v1/README.md`, `prompts.json` e o projeto `sala-kael.isostudio.json`. A exportação gera dez peças e uma casca de 672×496. O usuário identificou distorções na escada, sofá e outros móveis. A causa era o ajuste por coluna à silhueta das guias, agravado pelo redimensionamento sem preservar proporções. O ajuste da base da escada também foi rejeitado.

Na revisão atual, a sala usa fontes intactas, escala uniforme e preenchimento transparente. A inspeção no navegador confirmou almofadas contínuas, mesas com bordas regulares e degraus inteiros. Evidência: `documentation/evidence/home-v1/sala-sem-deformacao.png`. A perspectiva das fontes ainda precisa de revisão para cumprir exatamente 2:1; o relatório registra as falhas sem ocultá-las. Estado: integração local, sem publicação e sem aprovação geométrica final.

## Verificação

- Histórico anterior à correção: 404 testes aprovados em `.local/home-final-full-tests.log`. Esse resultado não validou integridade visual e não descreve a revisão atual.
- Após remover as deformações: testes de sala e vila com oito aprovações e uma falha no requisito de aprovação geométrica das imagens. A falha permanece visível; não se alterou o teste para aceitar imagens fora da grade.
- O resultado anterior de 10/10 do Iso Studio foi superado pela revisão do usuário. O relatório atual aponta os desvios das fontes.
- Igualdade da área caminhável da abertura/overworld, ações alcançáveis e rotas de Kael/Rabbito/mãe verificadas.
- Portais com ponto seguro de chegada e espaço para se afastar; IDs e retornos preservados.
- Câmera da abertura igual à exploração em testes de 1280×720, 825×885 e 390×700.
- Teste específico de transparência da escada atrás do jogador, opacidade quando ele está à frente e restauração do alpha do Canvas.
- Testes do cenário pintado anterior continuam apontando para o mapa legado, preservando a cobertura do antigo vaso da escada sem exigir sua presença na sala nova.
- Revisão manual na sessão local isolada, sem acesso ao Supabase de produção. Publicação não executada.
- No navegador: conversa com a mãe, subida ao quarto, descida ao patamar, saída para a Rua dos Ventos e retorno pela porta, além de caminhada livre com Rabbito. Abertura completa e rotas do piso inferior cobertas pela suíte automatizada.

`npm run audit:world` passou para o quintal modular legado; esse resultado não foi usado como aprovação artística da sala nova.
