# PIP-64 · Theme, componentes e shaders Recorte

Implementação na branch `godot`, após a entrega local da PIP-63 (`66c8ede`). Sem push, deploy, banco ou alterações de regras de jogo.

## Entrega

- `godot/assets/ui/recorte-v1/theme/recorte_theme.tres` como Theme global do projeto; `Hud.make_theme()` é um adaptador para o mesmo recurso. Cobre os controles pedidos e as variações semânticas de papel, diálogo, nome, pausa, lista, XP e energia.
- 53 estilos `StyleBoxFlat` nomeados, com geometria inclinada, sombra sólida e estados de hover/foco/pressionado/desabilitado. Os PNGs da PIP-63 ficam na camada de traço, separados de geometria, texto e área de interação. Marcadores de controles são SVGs geométricos derivados dos tokens; os ícones ilustrados continuam na PIP-65.
- Removidas todas as chamadas `add_theme_color_override` e `add_theme_stylebox_override` de `godot/scripts/`. Telas usam `theme_type_variation`; diferenças legítimas de margens têm variações nomeadas, não cópias locais. Tamanhos de texto e constantes de layout continuam podendo variar conforme o conteúdo.
- Migrados campanha, menus, diálogo inicial, inventário, pausa, treino, Oficina, exploração e placas auxiliares. Renderizadores específicos de batalha continuam com sua composição própria até as tarefas correspondentes; os elementos nativos deles usam o Theme.
- `RecorteUX` instala a decoração por sinais, fora da medição dos Containers, sem polling por frame. Mantido durante as trocas de tela. Herança do Theme também funciona através de `Node2D`, `CanvasLayer` e `SubViewport`.
- Foco com rabiola de três triângulos, pincelada, inversão e deslocamento visual `(24,-5)` em 120 ms `TRANS_QUART/EASE_OUT`; rabiola com atraso de 40 ms. A área lógica de input permanece estável durante hover. O modo reduzido cancela o deslocamento corrente, zera a posição e preserva feedback geométrico com fade de 80 ms.
- Shaders `halftone`, `speedlines` e `ink_wipe` em `assets/ui/recorte-v1/shaders/`, renderizados com Compatibility e `--rendering-driver opengl3`. Retícula em espaço de tela, linhas radiais/paralelas e wipe com a máscara numérica da PIP-63. Não usam `TIME`, loop ou animação contínua.
- `SplatSpawner` usa a sequência local por semente, recolore por token, elimina o evento em 600 ms e limita a 12 sprites visíveis. Trocar para modo reduzido encerra os efeitos já ativos. O adaptador de transição da campanha usa wipe de 450 ms ou fade de 80 ms e remove apenas sua camada temporária.
- `components/demo_kit.tscn` agora é a demonstração interativa do Theme: estados lado a lado, controles editáveis/desabilitados, foco real, barras, diálogos, retícula, crítico e transição. Alterna as duas resoluções e modo reduzido. O catálogo de arte anterior está preservado em `components/ink_catalog.tscn`.

## Conferência efetivamente realizada

Importação e compilação no Godot 4.7.2 oficial, renderer Compatibility/OpenGL, GPU RTX 5070. Capturas do laboratório em 1280×720 e 1920×1080, nos modos normal e reduzido. A captura 1280 normal demonstra linhas paralelas; a 1920 normal, concentração. Prints e metadados em `godot/assets/ui/recorte-v1/mockups/revisao/`.

Também foram renderizadas seis situações reais em 1280×720, com fixtures e diretório de armazenamento isolado: menu, configurações, diálogo inicial, mochila cheia, batalha e aviso longo. A auditoria encontrou uma linha parcialmente visível no fim da lista rolável da mochila (P3); todas as seis linhas ficaram acessíveis por foco. Sem achado de botão essencial cortado ou texto sobre botão nos seis cenários conferidos. Isso não equivale a auditar toda a campanha ou todas as proporções de tela.

A revisão corrigiu a herança da placa de nome através de `Node2D`, respiro insuficiente nos painéis claros, trilhos invisíveis e decoração aplicada indevidamente sobre sliders/abas. Logs finais sem erros de execução ou de compilação dos shaders nas capturas. Não houve teste com controle físico.

## Testes criados, execução pendente

`godot/tests/recorte_theme_checks.gd` cobre o contrato do Theme, ausência de overrides locais, foco de teclado com geometria adicional, cancelamento do deslocamento quando reduz movimento, ausência de Tween repetido, limite/limpeza de respingos e wipe reduzido. O arquivo foi compilado com `--check-only`; seu corpo de teste **não foi executado**.

`hud_checks.gd` foi atualizado para conferir a geometria e as margens do Theme, em vez de propriedades `texture_margin_*` do antigo skin. Não foi executado novamente. As demais suítes e o percurso da campanha também não foram executados nesta tarefa, respeitando a orientação do usuário para não rodar testes sem pedido.

Os três critérios de implementação/renderização da PIP-64 estão atendidos; a validação por execução do teste novo fica pendente de autorização. Não marcar a tarefa Done com base apenas em compilação e capturas.

## Registro da PIP-63

A tentativa de registrar a prancha anterior como aprovada e concluir a PIP-63 foi bloqueada pela revisão automática: ela não considerou “ótimo” uma aprovação explícita da prancha pelo responsável. Nenhuma aprovação foi marcada e não houve tentativa por caminho alternativo. A implementação da PIP-64 continuou conforme o pedido do usuário; a conclusão administrativa da PIP-63 continua aguardando confirmação explícita.

## Uso e reprodução

Abrir `res://assets/ui/recorte-v1/components/demo_kit.tscn` no editor e usar F6. A demonstração não cria campanha nem salva preferências. Para reexportar o Theme: `node scripts/build-recorte-theme-icons.mjs`, importar o projeto e executar `--headless --path godot --script res://tools/build_recorte_theme.gd`.

O teste de UI, quando autorizado, usa `--headless --path godot --script res://tests/recorte_theme_checks.gd`. Também será necessário executar o `hud_checks.gd` alterado antes de declarar seu aceite aprovado.

Detalhes dos componentes, variações e efeitos em `godot/assets/ui/recorte-v1/theme/README.md`.
