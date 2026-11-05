# F19 — libertação encenada

A vitória na Trovareta agora registra `trovaretaReleasePending` na mesma operação que resolve o duelo. Ao carregar o Bosque C com essa pendência, a câmera enquadra a criatura e o controle aguarda a cena.

1. A linha negra se parte em dois trechos que recolhem, enquanto a criatura recupera suas cores.
2. Trovareta usa o clip de voo aprovado e sobe para fora do enquadramento.
3. A chuva e o escurecimento diminuem; o palco passa ao estado livre.
4. Rato entra por um percurso caminhável, na mesma cota, sem cruzar a posição de Kael. Usa as poses direcionais do spritesheet existente.
5. Somente após sua chegada começa o diálogo de convite e recusa de Kael.
6. Ao fechar o diálogo, uma gravação registra `trovaretaReleaseSeen` e encerra a pendência. Câmera, HUD e controle são devolvidos.

Em movimento reduzido, os mesmos estados e diálogo são apresentados sem deslocamento contínuo. Fechar o aplicativo antes de terminar o diálogo preserva a pendência. Uma falha ao gravar também preserva o estado para retomar no próximo carregamento do Bosque. Saves antigos sem essa nova pendência não recebem uma repetição obrigatória.

Derrota e fuga não liberam a criatura nem iniciam a sequência. O retorno dos duelos de atos finais agora recebe o resultado da luta para não apresentar indevidamente uma mensagem de vitória após derrota/fuga. Não foram alterados XP, itens, condição de vitória ou parâmetros de combate.

## Evidências

- TROVARETA RELEASE: 28 checks; 0 failures, com movimento normal e reduzido.
- ENDGAME STORY: 98 checks; 0 failures.
- Teste percorre abertura do segundo duelo, resolução preparada, recarga, falha ao salvar, sequência visual, diálogo, conclusão e recarga final.
- Capturas do jogo em 1280×720: line-broken.png, taking-flight.png e rato-arrived.png.

## Limitações

Os resultados de batalha são preparados pelo teste. Isso não representa uma partida humana completa dos duelos contra Navalha e Trovareta.

Rato se desloca com as poses direcionais existentes; não há um ciclo de pernas desenhado para caminhada neste spritesheet. Trovareta utiliza seu clip de voo Soulgen aprovado, com deslocamento de cena. Não foram geradas novas imagens nem alterado o terreno.

A retomada reinicia a encenação para manter coerência visual; não tenta continuar no quadro exato da interrupção. Se a última gravação falhar, reabrir o Bosque permite repetir e registrar a conclusão sem conceder recompensas extras.

Alterações locais, sem merge, publicação ou push.
