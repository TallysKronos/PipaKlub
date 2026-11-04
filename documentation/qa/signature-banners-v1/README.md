# Banners de assinatura — Godot

Portados os banners aprovados do web (`src/signature-banner.js` e CSS): mesmas imagens, nomes e duração de 820 ms. Os PNGs copiados são idênticos por SHA-256. Textos e cores vêm de um manifesto local; imagens são carregadas antes da ativação.

- Rabbito: Pulo do Elo, ciano.
- Lacertubo: Ruptura dos Canos, amarelo.
- Nozinho: Nó de Vendaval, amarelo — apresentação disponível, sem inventar uma habilidade jogável que o combate atual ainda não implementa.

`encounter_model.gd` emite `signature_started` somente após validar alcance, energia, cooldown e estado. A view compartilhada dos encontros e do Morro escuta esse sinal. Não há observação por quadro para inferir ativações, nem repetição ao restaurar um save durante a carga do golpe.

O banner não bloqueia comandos nem pausa a luta. O aviso de área e os sinais de perigo continuam ativos. Em ativações simultâneas, o inimigo tem prioridade; não há fila atrasando avisos. Ao pausar, a apresentação fica oculta e seu relógio para. Ao voltar, continua de onde estava. Resultados limpam a apresentação. Movimento reduzido usa opacidade sem deslocamento lateral.

## Verificação

`signature_banner_checks.gd`: 73 verificações, zero falhas. Ativação real do especial do jogador, ativação inimiga, custo, pausa/retomada, prioridade, cooldown, falta de energia, restauração, resultados e componente compartilhado do Morro. Configurações de janela: 1280×720, 1920×1080 e 800×600, com movimento normal/reduzido. Os limites são conferidos contra o viewport lógico efetivamente renderizado pelo stretch do projeto.

Regressão: boss presentation (67), battle flow (797) e campaign (206), sem falhas nas verificações.

Capturas nativas desta pasta: jogador e inimigo em uma fixture real da batalha, além da prévia visual do Nozinho. Conferidas para crop, legibilidade e preservação da HUD. Não representam uma vitória em playtest humano. Saves isolados.
