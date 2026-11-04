# Gruta dos Elos — vento e papel vivo

Biblioteca visual local; ainda não integrada à campanha.

- Abra `godot/scenes/overworld/caves-v3/gruta-ventos.tscn` para a gruta inundada, ou `gruta-seca-ventos.tscn` para a seca.
- As cenas instanciam a montagem aprovada, incluindo o poço rebaixado, sem copiar sua geometria.
- Duas Flores de Linha usam malha subdividida: deslocamento zero na raiz e abaixo dela; sombras de contato permanecem imóveis.
- Uma rabiola de papel é amarrada à borda superior da coluna. Somente o papel se deforma; a coluna não balança.
- Três traços discretos seguem o caminho aberto até a saída frontal. São pistas visuais ambientais, não alteram navegação.
- Rajada em ciclo de oito segundos, fases diferentes por planta. `wind_strength` ajusta a força; `reduced_motion` deixa papel em repouso e oculta os traços. Água mantém seu movimento próprio.
- `set_animation_time(t)` fixa o instante para auditoria; `-1` retoma o relógio da cena. Os elementos procedurais não são gravados como filhos duplicados.

## Revisão

Capturas Godot nativas 1280×720, duas cenas instanciadas, 96 quadros a 12 fps e captura de movimento reduzido. Sem testes de gameplay, sem salvar campanha. `auditoria.json` registra a diferença entre os extremos do ciclo.

Galeria viva: execute Godot com `--path godot --script res://tools/cave_wind_preview.gd -- --live`.

Fonte da rabiola gerada com imagegen, normalizada para transparência, escala pequena e pivô superior. Original em `art/overworld/kits/cavernas-v3/fontes/rabiola-vento.png`; versão de jogo em `ambient/rabiola-vento.png`.

Regra: vento deve deformar apenas partes flexíveis, sempre com raiz ou amarração fixa. Sua direção precisa corresponder a uma passagem existente; nunca apontar para parede fechada. Não pintar vento ou sombras na textura do piso.
