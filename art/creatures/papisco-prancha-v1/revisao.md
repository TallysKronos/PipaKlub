Correção do idle em 13/11/2026, após o jogador apontar um arranco para frente. Os quatro quadros SW/NW foram fixados na primeira pose de repouso. Cabeça, pés, centro, silhueta e pixels fora do peito permanecem idênticos em toda a sequência. Apenas 4 pixels internos SW e 3 pixels internos NW alternam a sombra do peito nos quadros 2/3. Cadência 750/200/750/200 ms, total 1,9 s.

A comparação independente escolheu a versão corrigida, com 7/10 e nenhum bloqueio. O arranco de meia marcha desapareceu. A respiração é quase imperceptível em 1×, limite aceito para esta correção restrita. Nenhum novo vídeo ou geração foi necessário.

Backups de idle PNG/GIF, Aseprite e walk foram preservados em tmp/idle-breathing-fix-v1. A validação de regiões protegidas está em idle-fix-regioes.json. Os vinte quadros do editável mantêm a caminhada pixel a pixel idêntica ao atlas anterior. A correção de arte está concluída; a nova publicação e a captura no jogo são feitas após este handoff.

# RevisÃ£o

RevisÃ£o independente do lote: 7.5/10. Sem bloqueio visual; seguir Ã  conferÃªncia no jogo.

Poses geradas pelo ImageGen, finalizadas em grade/paleta/alpha no Aseprite. A checagem tÃ©cnica das 20 poses passou. Isso nÃ£o certifica cadÃªncia ou ausÃªncia de deslizamento.

Integração e playtest gráfico concluídos localmente. Rodada única de quatro modelos: 1.340 verificações, zero falhas. Suíte de animações:3.994 verificações, zero falhas. Evidência em tmp/overworld-pranchas-lote-02/playtest, com40capturas de deslocamento e12idle por modelo. Inspeção de captura confirmou integridade e escala. Não certifica ausência de deslizamento nem equivale a regressão completa da campanha.

Fix de idle aplicado e conferido no Godot:3.994verifica��es de anima��o e670gr�ficas dos dois modelos sem falhas. Capturadas16poses em2,4s de idle para cobrir ciclo de1,9s e retorno. Caminhada byte a byte id�ntica ao backup e fonte/runtime conferidos. Evid�ncia em tmp/overworld-pranchas-lote-02/idle-fix/.
