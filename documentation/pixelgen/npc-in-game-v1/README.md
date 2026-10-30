# NPCs aplicados no Godot

## Correção de escala após revisão do usuário

A primeira integração conservou a altura antiga de 72 px dos NPCs do Morro, enquanto o Kael tinha cerca de 59,7 px. O usuário apontou a diferença na captura. A escala foi corrigida em todos os consumidores usando a silhueta opaca medida do Kael (86 px na vista SE), multiplicada pela escala real de cada cena. Jovens ficam na mesma altura; mãe +8%; Assis e Tião +12%. A revisão atual verifica também a altura opaca carregada do PNG contra essa proporção, tolerando até 3,5% pela variação entre vistas: 74 verificações, zero falhas. A captura `morro-area-3.png` coloca Kael ao lado de Juninho e Lia sobre a mesma cota de chão.

As oito identidades do lote `art/characters/npc-ds-directions-v1/` foram copiadas para `godot/assets/npc-ds/` e ligadas aos consumidores reais da campanha e dos protótipos de overworld. A cidade agora mostra a Lia correta, em vez de reutilizar a Bia. Os rótulos dos rivais foram afastados para não encobrir a cabeça.

O helper `scripts/npc_pixel_sprite.gd` compartilha o contrato: células 64×96, pivô 32,94, nearest e altura visível por contexto. Mantém as posições e a ordenação de profundidade existentes. O atlas tem oito direções estáticas; a mãe acompanha a direção do caminho da abertura, com entrada/saída pela escada e recorte de revelação adaptado ao novo atlas. Não há ciclo novo de passos.

Mikka e Lacertubo não pertencem à família produzida e conservam a arte original. Retratos dos diálogos também continuam separados dos sprites do mapa.

## Verificação

- `godot/tools/npc_pixel_review.gd`: 65 verificações, zero falhas; dez estados da campanha, presença das oito identidades, caminho da mãe nos dois sentidos, recortes, apoio e filtro. Sem acesso ao save pessoal. Resultado em `review.json`.
- `godot/tests/campaign_view_checks.gd`: 30 verificações, zero falhas, usando um slot fictício separado.
- `godot/tools/npc_park_review.gd`: captura do consumidor real das Veredas com câmera estabilizada; textura correta da Nina e zona de conversa confirmadas. Não cria sessão nem grava saves.
- Capturas nativas 1280×720 nesta pasta: abertura, professor, bairro, Veredas e cinco áreas do Morro. A captura `park.png` vem da revisão isolada da câmera das Veredas.

Durante a revisão, foi corrigido o cancelamento de uma encenação: as funções de espera/caminhada agora checam a validade antes de exigir um Node2D que pode já ter sido liberado ao sair da cena.

Integração local; sem commit, publicação ou migração de banco neste pedido.
