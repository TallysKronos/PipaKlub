# Kael — caminhada de overworld v1

Atlas `walk.png`: 320×160 px; quatro colunas de frames 80×80; primeira linha vista frontal 3/4, segunda traseira 3/4. Pivô (40,65), corpo normalizado a 44 px. O runtime espelha horizontalmente. 130 ms por frame andando; 85 ms correndo. Idle usa as poses aprovadas já existentes.

`source.png` conserva a imagem gerada, `preview.png` amplia o atlas por nearest. A normalização reproduzível está em `tools/plant-lab/build-kael-walk.py`: recorte por alpha, alpha binário, nearest e quantização de 28 cores por frame sem dithering. Nenhum blur/interpolação foi aplicado.

Origem: ferramenta integrada de geração de imagem, saída `exec-3f2bef83-ec4e-4ebe-bfb4-ee37335a5085.png` da sessão de 05/11/2026. Direção usada: manter cabelo azul escuro, roupa e proporções do Kael aprovado; ciclo de passos em quatro poses por vista, corpo unido, pés ancorados, pixel art top-down, fundo transparente e nenhuma alteração de identidade.

Verificação: prancha ampliada inspecionada; atlas executado no navegador e no Godot. O usuário ainda pode solicitar refinamento artístico do ciclo; esta é a versão funcional desta entrega, sem atribuir uma nova aprovação visual ao usuário.
