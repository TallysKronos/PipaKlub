# Banner de aquisição · 31/10/2026

Substitui a abertura automática da carteira e as duas passagens de objeto na entrega dos documentos. A carteira completa continua acessível no menu de pausa.

## Sequência integrada

1. Kael termina o treino e volta andando até Assis.
2. Assis faz uma introdução curta.
3. Banner da **Carteira de Pipeiro**, por 2,5 segundos.
4. Banner do **Porta-emblemas**, por 2,5 segundos.
5. Assis explica os doze espaços e como acessar Carteira de Pipeiro, equipe, mochila e mapa pelo menu de pausa.
6. A conversa segue diretamente à oficina. Não há abertura automática da carteira completa nem cabeçalho “Key item obtido”.

Cada banner usa faixa escura semitransparente com extremos em degradê, retícula e traços laterais, ícone pixelado de 128×128, brilho discreto e placa angular ciano com apenas o nome do item. A animação tem entrada suave, pequeno impacto do ícone, leitura e saída suave. Movimento reduzido remove escala e raios de impacto.

`front_end.gd::_present_key_item(id, nome)` é reutilizável para outras entregas; não concede recompensas. Pausa movimento/combate enquanto apresenta e restaura o estado anterior se a cena continuar válida. Os documentos são concedidos pela operação já existente do treino. Se houver interrupção antes da orientação final, os banners retomam sem duplicar os itens. Uma falha ao salvar a confirmação oferece **Tentar novamente** ou **Voltar ao menu**.

## Evidência

- `key_item_banner_checks.gd`: 28 verificações, incluindo imagens 128×128, alfa binário, até 13 cores, duração, entrada/saída, impacto, movimento reduzido, transparência nas bordas, bloqueio de Escape, ordem dos dois banners, interrupção, conflito de gravação e retomada.
- `pipeiro_identity_checks.gd`: 77 verificações, atualizadas para o novo fluxo.
- `campaign_checks.gd`: 206 verificações aprovadas.
- `demo_completion_checks.gd`: 43 verificações aprovadas.

Total: **354 verificações aprovadas**. Saves isolados. Capturas do renderer nativo inspecionadas em [1280×720](banner-1280x720.png) e [1920×1080](banner-1920x1080.png). Os testes da sequência confirmam diálogos automaticamente e aceleram a espera dos banners; não representam playtest humano. Os tempos normais permanecem 2,5 segundos por item.

Fontes editáveis dos ícones e revisão independente em `art/ui/key-items-v1/`. Não houve push nesta etapa.
