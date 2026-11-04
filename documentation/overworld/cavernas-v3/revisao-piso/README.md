# Piso da gruta — placas e terra, revisão 4

Revisão local da biblioteca visual, sem integração à campanha.

Geradas duas pinturas com a ferramenta imagegen integrada: ardósia fraturada em placas irregulares e terra compactada com lascas parcialmente enterradas. Prompts completos e origem em `geracao.json`; originais anteriores preservados em `originais/`. Novas fontes em `art/overworld/kits/cavernas-v3/fontes/piso-placas-v4.png` e `piso-terra-v4.png`.

As quatro entradas existentes de piso usam essas duas famílias. Contratos preservados: losango 64×32, 47 máscaras e oito centros por entrada. Preparação determinística faz projeção, recortes, atlas e correção periódica das bordas; não desenha novas pedras. `refresh_cave_floors.py` permite reproduzir a entrega sem reconstruir paredes ou props.

Também corrigido o mapeamento do shader `cave_floor.gdshader`: coordenadas de repetição são limitadas explicitamente com `fract` antes da amostragem. Na captura nativa, depender apenas da configuração do sampler esticava as bordas da pintura em faixas. As pinturas agora mantêm a escala espacial contínua entre os polígonos.

Revisão: cenas seca e inundada em 1280×720, detalhes de piso e margem, repetição 3×3 e encaixes dos quatro materiais. `encaixes.json` registra igualdade dos texels das bordas opostas, que complementa a inspeção visual; não prova ausência de todo padrão perceptível. Galeria animada de vento recapturada, incluindo opção de movimento reduzido. Nenhuma suíte de gameplay executada.

Comparação: `ANTES-DEPOIS-PISO.png`. Prévia atualizada: `../ventos/GRUTA-VENTOS.gif`. Pacote: `../ventos/gruta-com-ventos-godot.zip`.
