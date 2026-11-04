# PIP-77 · Oficina e abertura

Acabamento integrado localmente ao kit Recorte existente, mantendo a arte atual da oficina. A criação da arte da bancada continua sendo o escopo separado da PIP-59.

- Fundo em cover uniforme ocupando a tela inteira. O tabuleiro interativo mantém sua proporção e seu sistema de coordenadas, com transformação inversa compartilhada pelos gestos.
- As cinco etapas têm placa inclinada numerada, instrução curta em papel, progresso em cinco losangos e materiais disponíveis.
- Medidores com placa inclinada; tempo de voo em Barlow. Sucesso de etapa com respingo ciano e FEITO; ajustes com tinta-3, sem sinal vermelho.
- Qualidade comum/boa/rara derivada das estrelas reais do resultado, com contorno sol. Ao concluir, um adesivo transitório acompanha o retorno à história, sem bloquear a entrada. Elo rompido é identificado separadamente.
- Apenas glyph compacto de pausa durante o jogo normal. Botões de recuperação de armazenamento e reposição continuam contextuais. Pausa por botão/Esc abre o menu compartilhado; retomar cancela gestos pendentes e libera a simulação. Sair pelo menu conserva o progresso da montagem.
- Abertura: dicas de movimento/interação em chip no canto, com glyphs; a dica de movimento some após o primeiro uso, e interação reaparece por proximidade. O botão fixo de salvar/voltar foi substituído pelo glyph de pausa. Diálogo mangá preservado.

## Validação

- journey_playthrough.gd: percurso com gestos reais nas cinco etapas, sem conceder inventário ou resultados para atravessar a campanha.
- pip77_checks.gd: 50 verificações sem falhas, cobrindo pausa compartilhada, simulação congelada, retomada e glyph visível nas cinco etapas e nas duas resoluções.
- player_visual_audit.gd: 16 combinações renderizadas (workshop-0 a workshop-4 e opening-3/11/13 × 1280×720 e 1920×1080), zero achados; capturas e auditoria em mockups/revisao/pip77.

Nenhum teste com controle físico, exportação, envio ao Git ou alteração de status no Linear nesta entrega.
