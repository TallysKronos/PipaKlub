# Jardim das Marés

Cenário visual submerso reutilizável Godot, isometria 64×32. Ainda fora da campanha; sem colisão, natação, oxigênio, combate ou salvamento.

## Composição e arte

A câmera está sob a água: leito claro, manchas de rocha, pradaria aquática e faixa central aberta. Não existe uma superfície de água desenhada como retângulo sobre um cenário seco. O contexto submerso vem da paleta do leito, profundidade de cor do fundo, feixes discretos, cáusticas e bolhas.

Algas como rabiolas dobradas e corais em leques de papel vivo, com planos chapados e contorno seletivo. Fontes criadas com imagegen integrado; prompts exatos em `art/overworld/kits/submerso-v1/geracao.json`. Preparação em `tools/overworld/build_underwater_showcase.py`: alpha, escala, cinco cores por prop e pivôs de apoio. Originais preservados em `fontes/`.

Areia e rocha reaproveitam superfícies das bibliotecas anteriores, reinterpretadas na paleta submersa pelo material. As três áreas usam a mesma função de transição irregular `terrain_transition.gdshaderinc`. Luz e bolhas não fazem parte das pinturas do chão.

## Relevo e barrancos — revisão 2

Três cotas de solo: patamar rochoso a +32 px, leito intermediário a 0 e depressão arenosa a −24 px. Duas rampas conectam essas cotas: 32 px em três células e 24 px em 2,5 células. As pegadas recortam o piso intermediário antes de desenhar as faces; as bocas das rampas descontam a parede correspondente. Laterais fecham em cunha, sem tiras verticais sob a ponta baixa.

`underwater_terrain.gd` compartilha os contornos entre topos, faces, rampas e função de apoio dos objetos. Textura de parede usa fase espacial contínua; topos de patamares conservam coordenadas da planta, e rampas usam UVs explícitos em malha para manter a escala até os dois encaixes. A profundidade é geométrica, não uma sombra ou cor pintada no chão. A altura ainda não está integrada à navegação ou colisão de gameplay.

Auditoria em `geometria-relevo-1280x720.png`, detalhes das duas rampas sem objetos em `relevo/` e comparação `relevo/ANTES-DEPOIS-RELEVO.png`. `relevo/geometria.json` registra cotas e comprimentos. A vegetação foi afastada das juntas para deixar os encontros legíveis.

## Movimento

Seis grupos de algas usam malha subdividida e pivô no apoio. Deslocamento quadrático até a ponta; na raiz e abaixo dela o peso é zero. Sombras e raízes permanecem fixas. Corais e rochas não balançam.

Cáusticas suaves no leito, três feixes de baixa opacidade e nove bolhas pequenas compõem o ambiente. Ciclo de oito segundos com relógio controlável; sem cópia de tela ou distorção da câmera. A luz anima, a textura do solo permanece ancorada.

`effects_enabled` desliga cáusticas, feixes e bolhas para revisão. `reduced_motion` mantém a luz em uma fase estática, deixa as algas em repouso e oculta as bolhas. `set_animation_time(t)` fixa a fase para captura; `-1` retoma o relógio da cena.

## Abrir e conferir

Cena: `godot/scenes/overworld/underwater/jardim-das-mares.tscn`.
Galeria: Godot `--path godot --script res://tools/underwater_preview.gd -- --live`.

Capturas nativas 1280×720: geral, sem objetos, máscaras, sem efeitos e movimento reduzido. Prévia: `JARDIM-DAS-MARES.gif`. Detalhe: `ALGAS-ANIMADAS.webp`. Medidas do ciclo em `auditoria.json`. Pacote: `jardim-das-mares-godot.zip`.

Nenhuma suíte de gameplay executada. A montagem valida arte e animação na captura nativa; não valida mecânicas subaquáticas de personagem.
