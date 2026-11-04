# Correções antes de Beira-Canal

O carregamento da rua e do parque esperava `frame_post_draw` mesmo no renderer headless, onde esse sinal não ocorre. Agora mantém a espera pelo quadro no jogo nativo e usa um quadro de processo sem janela. O teste aguarda quadros físicos durante a transição; também suspende o atualizador de objetivos da cena ao testar um objetivo sintético. A falha de objetivo vinha da cena reescrevendo a mensagem de teste.

Objetivos ganham altura conforme o texto em vez de cortar após duas linhas. Os atalhos Equipe/Bolsa/Menu passam a ter espaço para ícone e legenda completos. Moedas não quebram em uma coluna estreita.

Validação rápida: 163 verificações headless e 163 nativas a 1280×720, zero falhas; capturas em `documentation/qa/hud-exploracao-v2`. A matriz completa é executada separadamente. Avisos de importação de imagens do professor permanecem; não houve teste de controle físico nem exportação. As capturas antigas geradas pelo teste foram restauradas.
