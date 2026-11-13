# Continuidade curta — lote 03

Repositório: C:/Users/user/produto/pipa-club-integracao-atualizada. Lote concluído: rabbito, carcara, mata-verde, azulao, doberman-c. Todos integrados localmente e testados. Configuração em batch.json, fontes nas pastas <id>-prancha-v1 e sprites originais em soulmonsters-overworld-v2. Alturas 55/55/55/55/70, célula 112×112, apoio 56,100, escala 1.

12 gerações ImageGen: dez caminhadas iniciais e duas correções do Rabbito. 100 quadros finais (60 de deslocamento e 40 de idle). Idles autorados do repouso original no Aseprite, com 2–4 pixels internos variando, sem deslocamento global, ciclo de 1,9 s. Não reintroduzir arrancos. RAWs, prompts e backups preservados.

Revisão independente: Rabbito R1 7, Carcará 7,5, Mata Verde 7, Azulão 7,5 e Dóber 7,5; sem bloqueios. Rabbito perdeu porte infantil inicialmente; R1 recuperou cabeça/peito arredondados e pés curtos. Pequena diferença de massa residual foi aceita. Os idles e os outros quatro walks permaneceram intactos na correção.

Pipeline único: prancha-batch.py, prancha-import.lua e prancha-review.py. authored_idle e overrides em batch.json. Publicação exata via hybrid-review.py. Testes finais: 4.042 checks de animação e 1.672 gráficos, zero falhas nessas suítes. GIFs/capturas em tmp/overworld-pranchas-lote-03/playtest/. Galeria local index.html. Não declarar regressão completa ou ausência certificada de deslizamento.

Fila de vídeos explicitamente parada; não retomar sem novo pedido. Sem merge/push. Economia de tokens não foi medida. Próximo lote somente mediante continuidade do usuário; aproveitar este arquivo e a configuração sem reler o histórico inteiro.

## Corre��o posterior do Carcar�

Usu�rio reprovou Carcar�-prancha-v1 por perda de identidade. Essa vers�o foi retirada, marcada reprovada e escondida da galeria. Nova fonte ativa: art/creatures/carcara-hibrido-v1, identidade_revision2, sem novas gera��es. Corpo/rosto/bico/losango/varetas/n�s/rabiola da fonte preservados pixel a pixel em20poses, somente asas articulam discretamente. Cr�ticaR1=7,5sem bloqueios ap�s remo��o pontual de res�duos; amplitude discreta � limite aceito, n�o aprova��o humana. Runtime publicado com source_folder da nova pasta. N�o republicar a prancha rejeitada. Evid�ncia em tmp/overworld-pranchas-lote-03/carcara-fix/. Demais modelos intactos.
