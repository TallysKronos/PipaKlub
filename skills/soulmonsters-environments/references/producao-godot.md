# Produção e revisão no Godot

## Preparação e integração

Preserve o fonte gerado, registre ferramenta/prompt, normalize para o tamanho de consumo e salve o resultado dentro do projeto. Para props: verificar alpha verdadeiro, silhueta completa e pivô medido na área opaca da base. Centro da imagem não equivale ao apoio.

Para superfícies: corrigir as bordas opostas, conferir repetição 3×3 e depois os encaixes na câmera isométrica. Igualdade dos texels opostos não prova ausência de padrão perceptível. Se o consumidor usa atlas/autotiles, manter máscaras e escala dele; se usa polígonos/malhas com pintura contínua, não inventar um atlas para provar encaixe.

Quando a direção pede cores chapadas, normalização de paleta sem dithering pode remover grão e gradientes do fonte. Não usar isso como substituto de uma geração com formas melhores. Na animação de um cenário, evite copiar dados ou texturas em cada frame: atualizar uniformes ou posições de efeitos pequenos.

## Falhas observadas e correções

| Sintoma | Diagnóstico útil | Correção |
| --- | --- | --- |
| Chão parece um tapete retangular | Fronteira de material coincide com o polígono sobreposto | Misturar dois materiais na mesma superfície com distância à borda, irregularidade estática e faixa curta; variar a forma do percurso |
| Textura vira linhas paralelas | Amostragem fora de 0–1 sendo limitada nas bordas | Inspecionar coordenadas; usar `fract` para repetição explícita quando adequado e fontes com bordas compatíveis |
| Rampa fica preta ou esticada | UVs de Polygon2D interpretados em unidade diferente da máscara em células | Usar UVs explícitos em ArrayMesh/MeshInstance2D ou um contrato de coordenadas conhecido; conferir ambos os encaixes e a escala |
| Pedra não responde a modulate | Shader escreve COLOR sem usar a cor do CanvasItem | Aplicar uma cor uniforme por instância no shader, preservando padrão branco, ou propagar a modulação corretamente |
| Margem parece só uma borda desenhada | Não existe corte/face entre cotas | Corrigir o volume e sua oclusão, depois o material |
| Planta solta do chão | Sprite inteiro deslocado ou pivô central | Base medida, malha subdividida e peso zero no apoio |
| Cena salva duplica água/efeitos | Filhos procedurais foram serializados e reconstruídos | Salvar só a fonte de reconstrução ou excluir os filhos transitórios da propriedade da cena |
| PNG novo não aparece | Runtime lê textura importada antiga | Reimportar as imagens alteradas antes da captura, sem regenerar assets alheios |
| ZIP funciona só no checkout | Dependências dinâmicas ou includes ficaram de fora | Conferir referências `res://`, manifestos, texturas dinâmicas e `.gdshaderinc`; não presumir que copiar a cena basta |

## Transição compartilhada

O recurso `assets/terrain_transition.gdshaderinc` desta skill contém projeção, ruído estático e mistura com ombros quebrados. `terrain_blend(distance, cell, variation, width)` recebe distância negativa no interior do material de cima. O chamador desenha a máscara de trilha, mancha ou margem; a função não sabe qual bioma está em uso.

Use coordenadas locais para a máscara e uma fase consistente para as texturas conectadas. Movimentar a cena inteira não deve fazer a pintura escorregar. Nas faces, manter projeção/UV adequada à orientação da superfície. Um material de piso não se aplica automaticamente a uma parede.

## Animação e auditoria

Controle o relógio por uma função como `set_animation_time(t)`, com modo de captura determinística e retomada explícita. Normalize o tempo pelo período antes de enviar aos shaders para evitar deriva. Escolha períodos compatíveis; oito segundos e 96 quadros a 12 fps foram usados nos exemplos, sem serem obrigatórios.

Revisão mínima para a parte alterada:

- Captura nativa geral e detalhes críticos ampliados.
- Terreno sem props e sem efeitos se houver novas juntas ou novas misturas.
- Cores geométricas para alturas, rampas e rebaixos novos.
- Ciclo completo e primeiro/último instante quando a mudança for animada.
- Verificar log de import/render e registrar limitações de gameplay.

Movimento reduzido deve impedir deformação e partículas desnecessárias, preservando uma leitura estática. Pausar só o relógio global de shader pode não parar todos os componentes; controlar o relógio de cada efeito.

Evite transformar a auditoria em uma bateria de testes não solicitada. Não chamar uma captura isolada de validação de colisão, caminhada, navegação ou travessia.

## Exemplos mantidos no PipaKlub

Resolver estes caminhos relativamente à raiz do checkout. Eles são exemplos, não dependências instaladas pela skill:

| Exemplo | Implementação | Evidências |
| --- | --- | --- |
| Caverna/poço | `godot/scripts/overworld/cave_basin.gd`, `cave_ground.gd`, `cave_wind.gd` | `documentation/overworld/cavernas-v3/` |
| Planície flat | `plains_showcase.gd`, `godot/shaders/overworld/plains_ground.gdshader` | `documentation/overworld/planicie-v1/revisao-flat/` |
| Rio de lava | `lava_showcase.gd`, `lava_surface.gdshader`, `lava_ground.gdshader` | `documentation/overworld/lava-v1/` |
| Areia/dunas | `sand_showcase.gd`, `sand_ground.gdshader` | `documentation/overworld/areia-v1/` |
| Submerso/relevo | `underwater_showcase.gd`, `underwater_terrain.gd` | `documentation/overworld/submerso-v1/relevo/` |

Os nomes de script sem pasta acima ficam em `godot/scripts/overworld/`; os shaders em `godot/shaders/overworld/`. Fontes e prompts ficam em `art/overworld/kits/`, e arquivos runtime em `godot/assets/overworld/kits/`. Os builders/packagers específicos estão em `tools/overworld/`.

Para usar uma galeria existente, localizar o executável instalado e executar, por exemplo:

```text
godot --path godot --script res://tools/underwater_preview.gd --log-file CAMINHO_ABSOLUTO -- --live
```

O flag `--live` só deve ser passado se a galeria realmente o suporta. Para importação headless, incluir `--quit` e um log de caminho absoluto. Não incorporar caminhos pessoais de runtime ou perfil na skill.
