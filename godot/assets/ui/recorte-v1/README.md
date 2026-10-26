# Recorte · kit de tinta / PIP-63

64 peças em PNG 1× e 2×, normalizadas a partir de nove fontes raster desenhadas com `image_gen`. Fontes e resumos dos prompts: `art/ui/recorte-v1/`. Texto de menu, adesivos e onomatopeias permanece em Labels. Nenhum asset contém nome de golpe, espécie ou palavra de interface. `!` e `?` são pictogramas de emoção pedidos na tarefa.

## Revisão

Abra `components/ink_catalog.tscn` no Godot para a prancha de arte da PIP-63. A cena não usa campanha, rede ou saves. A prancha mostra todas as famílias, a dupla cheio/contorno e os textos dos adesivos como Labels. **INSPECIONAR 9-PATCH** abre larguras de 200, 400, 800 e 1600 px; o seletor percorre as nove molduras/balões e três pinceladas. A última linha usa a fonte 2× com cantos de mesmo tamanho lógico. **OUTRO RESPINGO** apresenta a sequência com semente 63. A PIP-64 passa a usar `components/demo_kit.tscn` para os componentes interativos e shaders; o catálogo original foi preservado.

Prancha nativa: `mockups/kit-tinta.png`. Ainda requer aprovação visual do responsável; não considerar o kit aprovado só por importar sem erros.

## Consumo

- `recorte_ink.gd`: manifesto, definições e texturas em cache, carregadas sob demanda. Não carregar as duas resoluções de todas as peças durante a abertura do jogo.
- `components/ink_frame.tscn` / `recorte_ink_frame.gd`: camada decorativa `NinePatchRect`, `TILE_FIT`, mouse ignorado. `asset_id` escolhe a peça; `high_density` usa a fonte 2× num nó interno em escala 0,5. Os cantos continuam com 48 px lógicos, não 96.
- Molduras e balões: margens `[48,48,48,48]`, centro transparente. O pai fornece preenchimento geométrico, conteúdo e alvo de interação. Respeitar a área segura de conteúdo do manifesto; balões de grito/pensamento precisam de mais respiro do que uma faixa.
- Pinceladas: margens `[48,0,48,0]`, altura lógica 64 px; só o miolo estica, as pontas permanecem fixas. Não repetir a imagem inteira nem escalar suas pontas.
- Os rabichos são imagens separadas. Fala oferece esquerda/direita; pensamento e sussurro têm peças próprias. O grito pode usar o rabicho pontudo de fala, reposicionado/espelhado conforme o retrato.
- Respingos, contornos, linhas de velocidade e retículas usam máscara branca para `modulate` com tokens. Molduras e rabichos têm tinta nanquim. Emoções e adesivos preservam a dupla nanquim/papel; não aplicar uma cor multiplicativa à peça inteira.
- A máscara é **dado numérico opaco**, preto no centro e branco nas bordas, não uma imagem para exibir como decoração. Amostrar sem conversão sRGB no shader de transição.
- Retículas `dots-fine`/`dots-dense` são tiles repetíveis; `dots-ramp` é uma rampa e não deve repetir. Fora do resultado, opacidade máxima 12%.

```gdscript
const SplatSequence = preload("res://scripts/campaign/recorte_splat_sequence.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
var sequence := SplatSequence.new(63) # criar uma vez por fluxo, não a cada frame
var choice := sequence.next("medium")
# choice: id, source_id, rotation, flip_h, flip_v
# O consumidor apresenta uma vez e remove; nada muda a simulação ou o RNG da batalha.
```

O saco por família esgota as variantes antes de repetir e impede a mesma fonte na passagem entre sacos. Rotação/espelho saem do mesmo RNG local com semente. O tempo e o descarte do efeito pertencem ao consumidor: linhas até 250 ms; reduzir movimento usa imagem estática com fade curto. A integração com todas as telas e o Theme é trabalho das próximas tarefas; esta entrega não troca a HUD da campanha em silêncio.

## Produção reproduzível

`node scripts/build-recorte-ink.mjs` reexporta os PNGs e manifesto a partir das fontes preservadas. Requer `sharp`; o script usa o pacote instalado ou o runtime local já existente neste ambiente. `node scripts/inspect-recorte-ink.mjs` inspeciona os arquivos e compara os cantos nas capturas nativas já existentes, sem iniciar gameplay. Importar o projeto no Godot após reexportar.

As fontes geradas têm resolução própria; exportar `@2x` não inventa detalhe ausente. Emblemas, bordas e tamanho lógico devem ser avaliados na tela real, não somente ampliados na prancha.
