# PIP-81 — revisão local das nove plantas

Revisão em 26/10/2026. Fonte editável: `art/overworld/mapas/*.tmj` (formato Tiled). Os ajustes foram feitos diretamente no JSON, preservando a grade e os identificadores de eventos. Não foi executado o importador legado que extrai plantas da campanha. `tools/import-overworld.mjs` apenas compilou essas fontes para a prévia Godot.

## Resultado por área

| Planta | Decisão / correção |
| --- | --- |
| Rua dos Ventos | Mantidas as três pegadas e os acessos: Kael (7,10), Assis (21,10), loja (35,10). Propriedades `porta_u`, `porta_v`, `frente` vinculam fachada e entrada. A camada `zonas` diferencia fundos residenciais, quintais, jardim, praça e trilha do parque, sem alterar colisões. |
| Jardim das Pipas | Árvore e poste retirados da pegada 4×4 do coreto. Lixeiras separadas do vaso e do poste. Caminhos e Sr. Assis alcançáveis. |
| Clareira do Papel | Corrigidas duas sobreposições de lixeiras; mantidos mato alto e saídas para Jardim e Veredas. |
| Veredas do Encanamento | Conferidos dois eixos de ponte, acessos elevados, Nina, Lacertubo e cinco baús. Sem alteração de planta necessária. |
| Praça da Chegada | Oficina, portão, Zeca e escadaria preservados, incluindo o encaixe aprovado pelo usuário. |
| Escadaria da Sombra | Corredor estreito com chegada elevada e árvore como marco. Planta já diferenciada na revisão recebida do Git; preservada. |
| Laje dos Ventos | Largo plano maior e varal mais próximo da borda da laje; preservada a circulação. |
| Mirante da Caixa-d’água | Guarda-corpo junto ao patamar alto e à caixa-d’água, substituindo uma casa gerada em lote bloqueado. Renderer passa a unir toda a largura de três células da escada; não deixa uma rampa cinza separada. |
| Parque dos Ventos | Gramado amplo preservado; árvore grande aproximada do gramado, substituindo uma casa gerada em lote bloqueado. |

Os três mapas intermediários do Morro já têm dimensões de circulação e larguras de escada diferentes no Git recebido. Não foram recriados para satisfazer um diagnóstico antigo da tarefa.

## Evidências

- `plants.json`: conferência das nove fontes, coordenadas de aproximação, rampas, alterações e hashes.
- `references/`: 18 PNGs oficiais, gerados pelos botões do Mapa Studio: uma referência limpa e uma com legendas por área. Dimensões originais preservadas; `exports.json` registra os arquivos.
- `captures/`: vistas de planta e prévia Godot a 1280×720, mais aproximações das portas, Nina e boss.
- `captures/movement.json`: 55 pontos percorridos pela função real de movimento da prévia Godot, com ticks de 1/30 s. Todos alcançados; seguidor terminou cada aproximação a menos de 0,8 célula do jogador. Inclui os cinco baús. Nenhuma recompensa ou save foi alterado.
- `native-render.log`: execução gráfica Godot 4.7.2 sem erros de script/renderização.
- `nove-plantas.png`: prancha de comparação das plantas, não aprovação de arte final.

Não foi rodada a suíte ampla da campanha. As nove prévias web também carregaram e receberam movimento manual por teclado, usando exclusivamente o perfil fictício Kael e o banco local isolado autorizados pelo usuário. `web/visits.json` e os nove PNGs registram essa conferência breve; não representam uma jornada web completa. Os percursos detalhados de aproximação foram conferidos no Godot. A campanha principal continua usando os mapas anteriores (`campaignReplacement:false`).

## Ferramentas

`node tools/overworld/review_plants.mjs` aplica somente os ajustes autorais desta revisão e gera o relatório. `node tools/mapa-studio/inventario.mjs` regenera o inventário. `node tools/import-overworld.mjs` compila as fontes para Godot. Nenhum deles chama `importar-areas.mjs`.

```text
Godot --path godot --script res://tools/plant_review.gd
python tools/overworld/plant_review_board.py
```

O Mapa Studio ganhou detecção de sobreposição entre peças sólidas. Peças de borda sem colisão continuam podendo se encontrar. O modo opcional `MAPA_STUDIO_EXPORT=1`, com URL `?salvar=1`, salva somente referências PNG no diretório fixo desta revisão, com origem local, nome, formato e tamanho validados. Sem essa opção, o servidor permanece somente leitura.

## Entrega e continuidade

Implementação e evidências organizadas na branch local `codex/pip81-plantas-revisadas`. O commit `4d851dc` preserva o acabamento aprovado do Morro e a correção das escadas. As 18 referências foram anexadas às descrições das tarefas PIP-84 (2), PIP-85 (4), PIP-86 (2) e PIP-87 (10), com contagem e capturas de comprovação. Nenhum push ou deploy foi realizado nesta entrega. Os próximos passos de arte são a PIP-84 (Bairro), PIP-85 (Parque) e PIP-86 (Veredas), respeitando as dependências de direção de arte e kit comum. A aprovação da escada não aprova automaticamente o acabamento de todos os biomas.
