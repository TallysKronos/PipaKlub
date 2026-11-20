# Mormaço cel + pixel — kit do piloto

Origem: modelos e shaders locais em `art/overworld/pantano-mormaco-v2/blender/`, derivados do concept fornecido pelo dono. Exportação por `exportar_piloto_godot.py`. A identidade das criaturas e do Kael vem dos assets já existentes no projeto.

`kit.json` registra dimensões, recortes, pontos de apoio, colisões e contornos navegáveis. Terreno de 3344 × 1882, 28 árvores, camadas de cercas e rochas, cachoeira com alpha e máscara conservadora de animação da água. PNGs RGBA, filtro nearest no consumidor e mipmaps desligados. As coordenadas do runtime têm escala 2 em relação à análise da prancha, para convivência com Kael sem ampliar seu sprite de 70 px.

O consumidor é `godot/scripts/overworld/mormaco_cel_pilot.gd`. As copas têm movimento de 1 pixel; a água e a cachoeira usam shaders discretizados no tempo. Mormaço usa os quadros existentes de `campaign/mormaco-v1/submerged.png`, com vapor e ondulações procedurais adicionais. Nenhuma animação por vídeo foi gerada.

Proveniência: geometria e exportação procedurais locais no Blender 5.1; sprites de produção existentes. Aprovação visual anterior cobre a direção geral, não uma aprovação presumida deste piloto em movimento.

Abrir pelo atalho `TESTAR-MORMACO-CEL.cmd` na raiz. Esta cena não lê nem grava progresso de campanha; o atalho usa um perfil local próprio para arquivos do Godot.
